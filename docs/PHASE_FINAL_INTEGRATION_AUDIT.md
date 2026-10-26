# PHASE: FINAL INTEGRATION AUDIT — MahaTicket Flutter

**Date:** 2026-10-26  
**Branch:** `main` @ `a3b4c90`  
**Projects:** `kalpkrut_mahaticket` (Flutter) ↔ `ticketghar` (authoritative backend)  
**Commands run:** `flutter pub get`, `flutter analyze` (0 issues), `flutter test` (25 passed), `flutter build web --release`

---

## Executive verdict

Core catalog, seat holds (Supabase RPC), role-based admin/organizer shells, and gate-scan RPC are wired to the shared Postgres schema. **Payments are simulated on the client** (fabricated Razorpay IDs → `confirm_booking_order` with no HMAC). That is a **Critical** booking-integrity and security failure versus ticketghar (`create-order` → Razorpay → server `verify`). Secrets present in local `.env` are also listed as Flutter assets, which is unsafe if a real secret-bearing file is ever shipped.

Do **not** treat screens as working features. Status below is evidence-based.

---

## Scorecard

| Area | Status | Evidence | Remaining work |
|---|---|---|---|
| Authentication | PARTIAL / FAIL (OTP+Google) | Email/password + session restore via Supabase Auth (`auth_provider.dart`). OTP APIs exist but UI `_useOtp` never enabled. No Google OAuth. Roles from `users.role`. | Enable OTP toggle; add Google if backend configured; align with ticketghar email-OTP where required |
| Database integration | PASS (read) / PARTIAL (write authz) | Same tables as Drizzle (`events`, `venues`, `seat_inventory`, `orders`, `tickets`, …). Client uses anon key + SECURITY DEFINER RPCs. | Prefer ticketghar APIs for privileged writes; audit RPC `GRANT`/`RLS` on live DB |
| Seat availability | PASS (code) / NOT TESTED (concurrent) | `hold_seats` FOR UPDATE all-or-nothing, max 5, 5‑min TTL, realtime channel. Unit tests for token/limit only. | Live dual-device race test against Supabase |
| Payments | **FAIL** | `checkout_screen.dart` builds `pay_…` / `rzp_ord_…` locally; `PaymentService` calls RPC with those IDs; `EnvConfig.razorpayKeyId` unused; no `razorpay_flutter` | Wire `APP_URL` → `/api/payments/create-order` + Razorpay Checkout + `/api/payments/verify` |
| Ticket generation | PARTIAL | RPC issues tickets + QR; on-screen pass works. No PDF package. Group QR (`MTGRP`) path weaker than ticketghar. | PDF via `/api/orders/[id]/pdf`; strengthen QR crypto verify |
| Email delivery | **FAIL** | SMTP keys in `.env` unused; FAQ claims email/WhatsApp send | Call `/api/tickets/[code]/email` after confirm |
| Customer application | PARTIAL | Explore → detail → seats → checkout → ticket UI exists. Payment fake; cancel/refund absent; showtime picker orphaned | Fix payment; refund API; wire showtime if needed |
| Organizer portal | **FAIL** (finance) / PARTIAL (scan) | Console loads organizers/settlements but KPIs hardcoded (`_grossGMV = 184500`). Payout = SnackBar stub. Scanner = manual entry (`mobile_scanner` unused) | Real metrics from `orders`/`settlements`; camera scan; attendance API |
| Admin portal | PARTIAL | Events/venues/orders/coupons/scraper real Supabase CRUD. No announcements CMS. Authz is UI role hide, not always server policy | Announcements table; harden RLS/RPC |
| Flutter web | PASS (build) / NOT TESTED (E2E) | `flutter build web --release` succeeded | Deployed E2E + CORS for API calls |
| Android | NOT TESTED (release) | Analyze clean; release APK not run in this audit pass | `flutter build apk --release` + device smoke |

---

## Severity-ranked findings

### Critical
1. **Fake Razorpay confirmation** — Anyone can confirm bookings without paying by calling the same RPC path the app uses. Evidence: `checkout_screen.dart` ~606–620; SQL `confirm_booking_order` trusts `p_razorpay_payment_id` for idempotency only (migration ~266–300).  
2. **Secret-bearing `.env` as Flutter asset** — `pubspec.yaml` assets include `.env`. Local file contains `SUPABASE_SERVICE_ROLE_KEY`, `RAZORPAY_KEY_SECRET`, `SMTP_PASS`, `TICKET_SECRET`, `ADMIN_PASSWORD`. Even if unused in Dart, bundling is a shipping risk. `.env` is gitignored but asset packaging still embeds whatever is on disk at build time.

### High
3. **Organizer financial KPIs hardcoded** — `organizer_console_screen.dart` lines 21–25.  
4. **No PDF / email ticket delivery** despite FAQ claims.  
5. **Architectural split** — Flutter RPC hold/confirm vs ticketghar Next.js hold/pay/verify. Holds can coexist on `seat_inventory`, but payment must use ticketghar verify.  
6. **Gate scanner lacks camera** — `mobile_scanner` in pubspec, unused; Profile gates scanner to superAdmin.

### Medium
7. OTP UI dead path; Google login missing.  
8. `TicketCrypto` marks MTSEC format-valid without HMAC verify.  
9. No announcements admin; cancel/refund customer flow missing.  
10. `ShowtimePickerScreen` orphaned.  
11. Dummy anon-key fallback client in `supabase_service.dart`.  
12. Help WhatsApp number placeholder `919420000000`.

### Low
13. Default Flutter README; no prior phase markdown reports.  
14. Marketing copy overclaims on help screen.  
15. Web vs Android: no go_router; browser back not audited E2E.

---

## Feature inventory

| Feature | Completed & verified | Implemented untested | Partial | Missing |
|---|---|---|---|---|
| Public event browse/search | Analyze/build only | Live DB filter | | |
| Event detail + posters | Code path | Network images | | |
| Seat map + hold RPC | Unit token tests | Concurrent hold | | |
| Checkout UI | | | Fake pay | Real Razorpay |
| My Tickets | | Email-keyed fetch | | Ownership authz parity |
| Auth password/session | | | | OTP UI, Google |
| Admin events/venues/orders | | | | Announcements |
| Organizer console | | Settlements list | Fake KPIs/payout | |
| QR scan | | Manual + RPC | No camera | Attendance dashboard |
| PDF/email | | | | Full |
| Refunds | | | Policy text only | API |

---

## Workflow traces (screen → backend)

| Workflow | Path | Authoritative? |
|---|---|---|
| Event list | `events` SELECT status=published | Yes (table) |
| Seat hold | RPC `hold_seats` | Yes (engine) / parallel to Next `/api/bookings/hold` |
| Payment | Fabricated IDs → RPC `confirm_booking_order` | **No** — must be Next verify |
| Tickets | RPC insert `tickets` | Partial |
| Scan | RPC `scan_ticket_atomic` | Yes (weaker than Next scanner scopes) |
| Admin CRUD | Direct PostgREST | Depends on RLS |

---

## Environment (keys only)

Client-safe expected: `NEXT_PUBLIC_APP_NAME`, `NEXT_PUBLIC_DEFAULT_CITY`, `APP_URL`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_RAZORPAY_KEY_ID` / `RAZORPAY_KEY_ID`.

Must never ship in Flutter: `SUPABASE_SERVICE_ROLE_KEY`, `RAZORPAY_KEY_SECRET`, `SMTP_*`, `TICKET_SECRET`, `ADMIN_PASSWORD`.

`APP_URL` currently `http://localhost:3000`. RN production API: `https://mahaticket.kalpkrutinfotech.com`.

---

## Build / test evidence

| Check | Result |
|---|---|
| `flutter pub get` | OK |
| `flutter analyze` | **No issues found** |
| `flutter test` | **25 passed** (unit/widget; no live payment/RPC E2E) |
| `flutter build web --release` | Succeeded (this audit) |
| Android release / device | Not run this pass |
| Destructive DB ops | None performed |

---

## Fix priority (execution order)

1. Stop secret asset bundling; client-only env template.  
2. Replace fake payment with ticketghar `create-order` → Razorpay → `verify` (Android first).  
3. Organizer metrics from real `settlements`/`orders`.  
4. Camera QR scan + organizer access.  
5. Email/PDF via existing ticketghar APIs.  
6. OTP UI + Google if configured.  
7. Responsive UI polish / regression tests.  
8. Android release build + live payment test (test mode).

---

## Fixes applied in this phase (verified in source + builds)

| Fix | Files | Verified |
|---|---|---|
| Client-only env asset (no secrets in bundle) | `pubspec.yaml`, `.env.client`, `.env.example`, `env_config.dart`, `tool/vercel-build.sh` | Analyze + web/apk build |
| Real Razorpay path via TicketGhar API | `backend_api_service.dart`, `payment_service.dart`, `razorpay_checkout_*.dart`, `checkout_screen.dart` | Fabricated `pay_` IDs removed; create-order→checkout→verify wired |
| Organizer KPIs from DB | `organizer_console_screen.dart`, `getOrganizerTicketStats` | Hardcoded 184500 removed |
| Camera QR + organizer access | `qr_gate_scanner_screen.dart`, `profile_screen.dart` | `mobile_scanner` used; organizer can open scanner |
| OTP UI toggle | `auth_bottom_sheet.dart` | Email OTP path reachable |
| FAQ honesty | `help_support_screen.dart` | No false instant email/WhatsApp claim |

**Still NOT live-tested:** real Razorpay test payment on device, concurrent seat race, email/PDF send, Google OAuth.

---

## Post-fix scorecard (code-level)

| Area | Status | Notes |
|---|---|---|
| Authentication | PARTIAL | Password + OTP UI + session OK; Google still missing |
| Database integration | PASS (read) / PARTIAL | Same schema; privileged writes still mix PostgREST + Next API |
| Seat availability | PASS (code) | Concurrent live race still NOT TESTED |
| Payments | FIXED (untested live) | Server verify required; needs Razorpay test-mode device smoke |
| Ticket generation | PARTIAL | On-screen + QR; PDF/email still via future API call |
| Email delivery | FAIL | API helper exists; not wired into post-checkout UX yet |
| Customer application | PARTIAL → improved | Checkout no longer fakes payment |
| Organizer portal | PARTIAL → improved | Real metrics; camera scan access |
| Admin portal | PARTIAL | Unchanged CRUD; announcements still missing |
| Flutter web | PASS (build) | `flutter build web --release` OK after fixes |
| Android | PASS (build) | `flutter build apk --release` OK; device E2E NOT TESTED |

---

## Verified vs untested (this document)

- **Verified:** static analysis clean; 25 unit/widget tests pass; web + Android release builds succeed after payment/security fixes; fabricated payment path removed from checkout.  
- **Untested live:** Razorpay test payment on Android device, concurrent seats, OTP email delivery, Google login, ticket email/PDF, production web deploy CORS.
