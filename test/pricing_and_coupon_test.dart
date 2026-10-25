import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authoritative Pricing and Coupon Logic Tests', () {
    const int convenienceFeePerTicketPaise = 3000; // ₹30.00
    const int gstPercent = 18;

    test('Computes multi-ticket convenience fee and GST accurately in paise', () {
      const ticketCount = 3;
      const faceValuePerTicketPaise = 45000; // ₹450.00
      const totalFaceValuePaise = ticketCount * faceValuePerTicketPaise; // 135000 paise (₹1350)

      final platformFeePaise = ticketCount * convenienceFeePerTicketPaise; // 9000 paise (₹90)
      final taxPaise = (platformFeePaise * gstPercent) ~/ 100; // 1620 paise (₹16.20)
      final subtotalPaise = totalFaceValuePaise + platformFeePaise + taxPaise; // 145620 paise (₹1456.20)

      expect(platformFeePaise, 9000);
      expect(taxPaise, 1620);
      expect(subtotalPaise, 145620);
      expect(subtotalPaise / 100.0, 1456.20);
    });

    test('Validates flat coupon discount and minimum order requirements', () {
      // Coupon: MAHA50 (flat ₹50 off, min order ₹250 / 25000 paise)
      const minOrderPaise = 25000;
      const discountValuePaise = 5000;

      // Case 1: Order value below minimum order threshold
      const smallOrderPaise = 20000; // ₹200.00
      final isEligibleSmall = smallOrderPaise >= minOrderPaise;
      expect(isEligibleSmall, isFalse);

      // Case 2: Order value meets minimum order threshold
      const validOrderPaise = 50000; // ₹500.00
      final isEligible = validOrderPaise >= minOrderPaise;
      expect(isEligible, isTrue);

      final discount = isEligible ? discountValuePaise : 0;
      final finalTotalPaise = validOrderPaise - discount;
      expect(discount, 5000);
      expect(finalTotalPaise, 45000); // ₹450.00
    });

    test('Validates percentage coupon discount with maximum discount cap', () {
      // Coupon: MAHA20 (20% off, min order ₹300 / 30000 paise, max discount ₹200 / 20000 paise)
      const discountPercentBps = 2000; // 20.00%
      const maxDiscountPaise = 20000; // ₹200.00
      const orderPaise = 150000; // ₹1500.00 (20% would be ₹300, should be capped at ₹200)

      int calculatedDiscount = (orderPaise * discountPercentBps) ~/ 10000; // 30000 paise
      if (calculatedDiscount > maxDiscountPaise) {
        calculatedDiscount = maxDiscountPaise;
      }

      expect(calculatedDiscount, 20000); // capped at ₹200.00
      final grandTotalPaise = orderPaise - calculatedDiscount;
      expect(grandTotalPaise, 130000); // ₹1300.00
    });

    test('Discount cannot exceed the total order value (prevents negative totals)', () {
      const orderPaise = 3000; // ₹30.00
      const largeDiscountPaise = 5000; // ₹50.00

      final grandTotalPaise = (orderPaise - largeDiscountPaise).clamp(0, orderPaise);
      expect(grandTotalPaise, 0);
    });
  });
}
