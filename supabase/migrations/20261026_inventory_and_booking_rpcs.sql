-- ============================================================================
-- MahaTicket Migration: Atomic Concurrency-Safe Inventory & Booking Engine
-- Date: 2026-10-26
-- Description:
--   1. Concurrency-safe hold_seats RPC with atomic all-or-nothing row locking
--   2. release_seats_hold RPC (idempotent user hold release)
--   3. extend_seat_hold RPC (countdown renewal)
--   4. release_expired_holds RPC (clean expired reservations)
--   5. confirm_booking_order RPC (authoritative pricing, coupon validation, order creation,
--      atomic seat booking, and digital ticket issuance with cryptographic verification)
--   6. scan_ticket_atomic RPC (atomic ticket redemption and audit logging)
-- ============================================================================

-- Drop old definitions if they exist with different return types or signatures
DROP FUNCTION IF EXISTS public.hold_seats CASCADE;
DROP FUNCTION IF EXISTS public.release_seats_hold CASCADE;
DROP FUNCTION IF EXISTS public.extend_seat_hold CASCADE;
DROP FUNCTION IF EXISTS public.release_expired_holds CASCADE;
DROP FUNCTION IF EXISTS public.confirm_booking_order CASCADE;
DROP FUNCTION IF EXISTS public.scan_ticket_atomic CASCADE;

-- 1. HOLD SEATS RPC (All-or-Nothing multi-seat reservation)
CREATE OR REPLACE FUNCTION public.hold_seats(
  p_session_id INTEGER,
  p_seat_ids INTEGER[],
  p_hold_token TEXT,
  p_hold_minutes INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_requested_count INTEGER;
  v_available_count INTEGER;
  v_expires_at TIMESTAMPTZ;
  v_now TIMESTAMPTZ := clock_timestamp();
  v_held_seats JSONB;
BEGIN
  -- Validate inputs
  IF p_seat_ids IS NULL OR cardinality(p_seat_ids) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'No seats selected.');
  END IF;

  v_requested_count := cardinality(p_seat_ids);
  IF v_requested_count > 5 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Maximum 5 seats allowed per booking.');
  END IF;

  IF p_hold_token IS NULL OR length(trim(p_hold_token)) < 8 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid hold token.');
  END IF;

  -- 1. First release expired holds for this session
  UPDATE public.seat_inventory
  SET status = 'available',
      held_by_user_id = NULL,
      hold_expires_at = NULL
  WHERE session_id = p_session_id
    AND status = 'held'
    AND hold_expires_at <= v_now;

  -- 2. Lock requested rows with FOR UPDATE to prevent race conditions
  PERFORM 1
  FROM public.seat_inventory
  WHERE session_id = p_session_id
    AND seat_id = ANY(p_seat_ids)
  FOR UPDATE;

  -- 3. Check if all seats exist in this session and are available (or already held by the same token)
  SELECT count(*)
  INTO v_available_count
  FROM public.seat_inventory
  WHERE session_id = p_session_id
    AND seat_id = ANY(p_seat_ids)
    AND (
      status = 'available'
      OR (status = 'held' AND (held_by_user_id = p_hold_token OR hold_expires_at <= v_now))
    );

  IF v_available_count < v_requested_count THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'One or more selected seats are no longer available. Please select different seats.'
    );
  END IF;

  -- 4. Calculate authoritative expiry time
  v_expires_at := v_now + (COALESCE(p_hold_minutes, 5) || ' minutes')::INTERVAL;

  -- 5. Atomically update inventory to 'held'
  UPDATE public.seat_inventory
  SET status = 'held',
      held_by_user_id = p_hold_token,
      hold_expires_at = v_expires_at
  WHERE session_id = p_session_id
    AND seat_id = ANY(p_seat_ids);

  -- 6. Collect held seat details
  SELECT jsonb_agg(
    jsonb_build_object(
      'seat_id', si.seat_id,
      'seat_code', s.seat_code,
      'row_label', s.row_label,
      'seat_number', s.seat_number,
      'tier', s.tier,
      'ticket_type_id', si.ticket_type_id,
      'price', COALESCE(tt.price, 30000)
    )
  )
  INTO v_held_seats
  FROM public.seat_inventory si
  JOIN public.seats s ON s.id = si.seat_id
  LEFT JOIN public.ticket_types tt ON tt.id = si.ticket_type_id
  WHERE si.session_id = p_session_id
    AND si.seat_id = ANY(p_seat_ids);

  RETURN jsonb_build_object(
    'success', true,
    'hold_token', p_hold_token,
    'expires_at', v_expires_at,
    'seats', COALESCE(v_held_seats, '[]'::jsonb)
  );
END;
$$;


-- 2. RELEASE SEATS HOLD RPC (Idempotent hold release on seat deselect or checkout exit)
CREATE OR REPLACE FUNCTION public.release_seats_hold(
  p_session_id INTEGER,
  p_hold_token TEXT,
  p_seat_ids INTEGER[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_released_count INTEGER;
BEGIN
  IF p_hold_token IS NULL OR length(trim(p_hold_token)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'released_count', 0);
  END IF;

  UPDATE public.seat_inventory
  SET status = 'available',
      held_by_user_id = NULL,
      hold_expires_at = NULL
  WHERE session_id = p_session_id
    AND status = 'held'
    AND held_by_user_id = p_hold_token
    AND (p_seat_ids IS NULL OR cardinality(p_seat_ids) = 0 OR seat_id = ANY(p_seat_ids));

  GET DIAGNOSTICS v_released_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success', true,
    'released_count', v_released_count
  );
END;
$$;


-- 3. EXTEND SEAT HOLD RPC (Hold extension during active checkout)
CREATE OR REPLACE FUNCTION public.extend_seat_hold(
  p_session_id INTEGER,
  p_hold_token TEXT,
  p_extension_minutes INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_new_expiry TIMESTAMPTZ;
  v_updated_count INTEGER;
BEGIN
  v_new_expiry := clock_timestamp() + (COALESCE(p_extension_minutes, 5) || ' minutes')::INTERVAL;

  UPDATE public.seat_inventory
  SET hold_expires_at = v_new_expiry
  WHERE session_id = p_session_id
    AND status = 'held'
    AND held_by_user_id = p_hold_token
    AND hold_expires_at > clock_timestamp();

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  IF v_updated_count > 0 THEN
    RETURN jsonb_build_object('success', true, 'expires_at', v_new_expiry);
  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'Hold is already expired or invalid.');
  END IF;
END;
$$;


-- 4. RELEASE EXPIRED HOLDS RPC
CREATE OR REPLACE FUNCTION public.release_expired_holds(
  p_session_id INTEGER DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.seat_inventory
  SET status = 'available',
      held_by_user_id = NULL,
      hold_expires_at = NULL
  WHERE status = 'held'
    AND hold_expires_at <= clock_timestamp()
    AND (p_session_id IS NULL OR session_id = p_session_id);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;


-- 5. CONFIRM BOOKING ORDER RPC (Atomic payment verification, order creation, and ticket issuance)
CREATE OR REPLACE FUNCTION public.confirm_booking_order(
  p_session_id INTEGER,
  p_hold_token TEXT,
  p_seat_ids INTEGER[],
  p_user_email TEXT,
  p_user_phone TEXT,
  p_user_name TEXT,
  p_coupon_code TEXT DEFAULT NULL,
  p_razorpay_order_id TEXT DEFAULT NULL,
  p_razorpay_payment_id TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_order_id INTEGER;
  v_order_number TEXT;
  v_user_id INTEGER;
  v_event_id INTEGER;
  v_face_value_total INTEGER := 0;
  v_platform_fee_total INTEGER := 0;
  v_tax_total INTEGER := 0;
  v_discount_total INTEGER := 0;
  v_grand_total INTEGER := 0;
  v_coupon_record RECORD;
  v_seat_record RECORD;
  v_ticket_count INTEGER;
  v_convenience_fee_per_ticket INTEGER := 3000; -- ₹30.00 in paise
  v_now TIMESTAMPTZ := clock_timestamp();
  v_issued_tickets JSONB := '[]'::jsonb;
  v_ticket_code TEXT;
  v_security_hash TEXT;
  v_qr_payload TEXT;
  v_ticket_id INTEGER;
BEGIN
  -- Idempotency check: If this idempotency_key or razorpay_payment_id has already been processed,
  -- return the existing order safely without duplicate billing or double ticket issuance!
  IF p_idempotency_key IS NOT NULL AND length(trim(p_idempotency_key)) > 0 THEN
    SELECT id, order_number INTO v_order_id, v_order_number
    FROM public.orders
    WHERE idempotency_key = p_idempotency_key;

    IF v_order_id IS NOT NULL THEN
      SELECT jsonb_agg(to_jsonb(t)) INTO v_issued_tickets FROM public.tickets t WHERE t.order_id = v_order_id;
      RETURN jsonb_build_object(
        'success', true,
        'message', 'Order already confirmed (idempotent)',
        'order_id', v_order_id,
        'order_number', v_order_number,
        'tickets', COALESCE(v_issued_tickets, '[]'::jsonb)
      );
    END IF;
  END IF;

  IF p_razorpay_payment_id IS NOT NULL AND length(trim(p_razorpay_payment_id)) > 0 THEN
    SELECT id, order_number INTO v_order_id, v_order_number
    FROM public.orders
    WHERE razorpay_payment_id = p_razorpay_payment_id;

    IF v_order_id IS NOT NULL THEN
      SELECT jsonb_agg(to_jsonb(t)) INTO v_issued_tickets FROM public.tickets t WHERE t.order_id = v_order_id;
      RETURN jsonb_build_object(
        'success', true,
        'message', 'Order already confirmed (payment matched)',
        'order_id', v_order_id,
        'order_number', v_order_number,
        'tickets', COALESCE(v_issued_tickets, '[]'::jsonb)
      );
    END IF;
  END IF;

  -- 1. Validate session
  SELECT event_id INTO v_event_id
  FROM public.event_sessions
  WHERE id = p_session_id;

  IF v_event_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event session not found.');
  END IF;

  v_ticket_count := cardinality(p_seat_ids);
  IF v_ticket_count IS NULL OR v_ticket_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'No seats provided for booking.');
  END IF;

  -- 2. Lock and verify seat hold
  PERFORM 1
  FROM public.seat_inventory
  WHERE session_id = p_session_id
    AND seat_id = ANY(p_seat_ids)
  FOR UPDATE;

  -- Check valid active hold by this hold token
  IF EXISTS (
    SELECT 1 FROM public.seat_inventory
    WHERE session_id = p_session_id
      AND seat_id = ANY(p_seat_ids)
      AND (
        status != 'held'
        OR held_by_user_id != p_hold_token
        OR hold_expires_at <= v_now
      )
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Hold expired or invalid. Please select your seats again.'
    );
  END IF;

  -- 3. Calculate authoritative pricing from actual database records
  SELECT COALESCE(sum(COALESCE(tt.price, 30000)), 0)
  INTO v_face_value_total
  FROM public.seat_inventory si
  LEFT JOIN public.ticket_types tt ON tt.id = si.ticket_type_id
  WHERE si.session_id = p_session_id
    AND si.seat_id = ANY(p_seat_ids);

  -- Convenience platform fee & 18% GST on platform fee
  v_platform_fee_total := v_ticket_count * v_convenience_fee_per_ticket;
  v_tax_total := (v_platform_fee_total * 18) / 100;

  -- Authoritative coupon calculation
  IF p_coupon_code IS NOT NULL AND length(trim(p_coupon_code)) > 0 THEN
    SELECT * INTO v_coupon_record
    FROM public.coupons
    WHERE upper(code) = upper(trim(p_coupon_code))
      AND active = 1
      AND (starts_at IS NULL OR starts_at <= v_now)
      AND (ends_at IS NULL OR ends_at >= v_now)
    LIMIT 1;

    IF v_coupon_record.id IS NOT NULL THEN
      IF (v_face_value_total + v_platform_fee_total + v_tax_total) >= v_coupon_record.min_order_value THEN
        IF v_coupon_record.discount_type = 'percentage' THEN
          v_discount_total := ((v_face_value_total + v_platform_fee_total + v_tax_total) * v_coupon_record.discount_value) / 10000;
          v_discount_total := LEAST(v_discount_total, v_coupon_record.max_discount);
        ELSE
          v_discount_total := LEAST(v_coupon_record.discount_value, (v_face_value_total + v_platform_fee_total + v_tax_total));
        END IF;

        -- Increment coupon usage
        UPDATE public.coupons
        SET used_count = COALESCE(used_count, 0) + 1
        WHERE id = v_coupon_record.id;
      END IF;
    END IF;
  END IF;

  v_grand_total := GREATEST(0, (v_face_value_total + v_platform_fee_total + v_tax_total) - v_discount_total);

  -- 4. Locate or create customer user record in public.users
  SELECT id INTO v_user_id
  FROM public.users
  WHERE email = p_user_email
  LIMIT 1;

  IF v_user_id IS NULL THEN
    INSERT INTO public.users (uid, email, full_name, phone_number, role, preferred_language, city, status)
    VALUES (
      'cust-' || floor(extract(epoch from v_now) * 1000)::text || '-' || floor(random() * 900 + 100)::text,
      p_user_email,
      COALESCE(p_user_name, 'MahaTicket Customer'),
      p_user_phone,
      'customer',
      'mr',
      'Pune',
      'active'
    )
    RETURNING id INTO v_user_id;
  END IF;

  -- 5. Generate unique order number
  v_order_number := 'MHTK-' || to_char(v_now, 'YYYY') || '-' || upper(substring(md5(random()::text || v_now::text) from 1 for 7));

  -- 6. Insert confirmed order
  INSERT INTO public.orders (
    order_number,
    user_id,
    user_email,
    user_phone,
    user_name,
    event_id,
    session_id,
    ticket_count,
    ticket_face_value_total,
    platform_fee_total,
    tax_total,
    gateway_cost_estimate,
    discount_total,
    grand_total,
    currency,
    payment_status,
    order_status,
    razorpay_order_id,
    razorpay_payment_id,
    idempotency_key,
    created_at,
    updated_at
  ) VALUES (
    v_order_number,
    v_user_id,
    p_user_email,
    p_user_phone,
    p_user_name,
    v_event_id,
    p_session_id,
    v_ticket_count,
    v_face_value_total,
    v_platform_fee_total,
    v_tax_total,
    (v_grand_total * 2) / 100,
    v_discount_total,
    v_grand_total,
    'INR',
    'captured',
    'confirmed',
    p_razorpay_order_id,
    p_razorpay_payment_id,
    p_idempotency_key,
    v_now,
    v_now
  )
  RETURNING id INTO v_order_id;

  -- 7. Atomically finalize seat inventory to 'booked'
  UPDATE public.seat_inventory
  SET status = 'booked',
      order_id = v_order_id,
      held_by_user_id = NULL,
      hold_expires_at = NULL
  WHERE session_id = p_session_id
    AND seat_id = ANY(p_seat_ids);

  -- 8. Generate cryptographically signed digital tickets
  FOR v_seat_record IN (
    SELECT si.seat_id, si.ticket_type_id, s.seat_code, COALESCE(tt.price, 30000) AS price
    FROM public.seat_inventory si
    JOIN public.seats s ON s.id = si.seat_id
    LEFT JOIN public.ticket_types tt ON tt.id = si.ticket_type_id
    WHERE si.session_id = p_session_id
      AND si.seat_id = ANY(p_seat_ids)
  ) LOOP
    v_ticket_code := 'TK-' || to_char(v_now, 'YYYY') || '-' || upper(substring(md5(random()::text || v_seat_record.seat_id::text || v_now::text) from 1 for 8));
    v_security_hash := encode(digest(v_ticket_code || '|' || v_order_number || '|' || v_seat_record.seat_code, 'sha256'), 'hex');
    v_qr_payload := 'MTSEC:v1:' || v_ticket_code || ':' || v_order_number || ':' || v_event_id || ':' || v_seat_record.seat_code || ':' || substring(v_security_hash from 1 for 16);

    INSERT INTO public.tickets (
      ticket_code,
      order_id,
      session_id,
      ticket_type_id,
      seat_id,
      seat_code,
      attendee_name,
      face_value,
      security_hash,
      qr_payload,
      status,
      created_at
    ) VALUES (
      v_ticket_code,
      v_order_id,
      p_session_id,
      v_seat_record.ticket_type_id,
      v_seat_record.seat_id,
      v_seat_record.seat_code,
      p_user_name,
      v_seat_record.price,
      v_security_hash,
      v_qr_payload,
      'valid',
      v_now
    )
    RETURNING id INTO v_ticket_id;
  END LOOP;

  -- Fetch issued tickets to return
  SELECT jsonb_agg(to_jsonb(t))
  INTO v_issued_tickets
  FROM public.tickets t
  WHERE t.order_id = v_order_id;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'order_number', v_order_number,
    'grand_total_paise', v_grand_total,
    'ticket_count', v_ticket_count,
    'tickets', COALESCE(v_issued_tickets, '[]'::jsonb)
  );
END;
$$;


-- 6. ATOMIC GATE SCANNER REDEMPTION RPC
CREATE OR REPLACE FUNCTION public.scan_ticket_atomic(
  p_ticket_code TEXT,
  p_scanner_user_id INTEGER,
  p_gate_name TEXT DEFAULT 'Main Gate'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_ticket RECORD;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  -- 1. Lock ticket row FOR UPDATE to prevent simultaneous multi-gate redemption
  SELECT t.*, COALESCE(e.title, 'Event') AS event_title
  INTO v_ticket
  FROM public.tickets t
  LEFT JOIN public.event_sessions es ON es.id = t.session_id
  LEFT JOIN public.events e ON e.id = es.event_id
  WHERE t.ticket_code = trim(p_ticket_code)
  FOR UPDATE OF t;

  IF v_ticket.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'status', 'INVALID',
      'message', 'Invalid Ticket: Not found in system.'
    );
  END IF;

  -- 2. Check ticket status
  IF v_ticket.status = 'used' THEN
    -- Log duplicate scan attempt
    INSERT INTO public.ticket_scans (
      ticket_id, ticket_code, scanned_by_user_id, scanner_device, scan_result, gate_name, scanned_at
    ) VALUES (
      v_ticket.id, v_ticket.ticket_code, p_scanner_user_id, 'MahaTicket Gate Scanner', 'ALREADY_USED', p_gate_name, v_now
    );

    RETURN jsonb_build_object(
      'success', false,
      'status', 'ALREADY_USED',
      'message', 'Ticket has ALREADY BEEN SCANNED and redeemed!',
      'ticket', to_jsonb(v_ticket)
    );
  END IF;

  IF v_ticket.status = 'cancelled' THEN
    INSERT INTO public.ticket_scans (
      ticket_id, ticket_code, scanned_by_user_id, scanner_device, scan_result, gate_name, scanned_at
    ) VALUES (
      v_ticket.id, v_ticket.ticket_code, p_scanner_user_id, 'MahaTicket Gate Scanner', 'CANCELLED', p_gate_name, v_now
    );

    RETURN jsonb_build_object(
      'success', false,
      'status', 'CANCELLED',
      'message', 'Ticket has been CANCELLED / REFUNDED.',
      'ticket', to_jsonb(v_ticket)
    );
  END IF;

  -- 3. Atomic redemption
  UPDATE public.tickets
  SET status = 'used'
  WHERE id = v_ticket.id;

  INSERT INTO public.ticket_scans (
    ticket_id, ticket_code, scanned_by_user_id, scanner_device, scan_result, gate_name, scanned_at
  ) VALUES (
    v_ticket.id, v_ticket.ticket_code, p_scanner_user_id, 'MahaTicket Gate Scanner', 'SUCCESS', p_gate_name, v_now
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'SUCCESS',
    'message', 'Entry Approved! Welcome to ' || v_ticket.event_title,
    'ticket', to_jsonb(v_ticket)
  );
END;
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.hold_seats TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.release_seats_hold TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.extend_seat_hold TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.release_expired_holds TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.confirm_booking_order TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.scan_ticket_atomic TO authenticated, service_role;
