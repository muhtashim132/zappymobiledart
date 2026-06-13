import '../pages/legal/legal_page.dart';

class LegalConstants {
  // --- CUSTOMER ---
  static final List<LegalSection> customerTerms = [
    LegalSection(heading: '1. Platform Role', content: 'Enything operates as an intermediary marketplace facilitating hyper-local logistics. The contract of sale is strictly between you and the respective Seller.'),
    LegalSection(heading: '2. Account Integrity', content: 'You must provide accurate delivery locations and valid contact details. You must be at least 18 years old to order restricted items (e.g., specific medicines).'),
    LegalSection(heading: '3. Prohibited Use', content: 'You agree not to order illegal, hazardous, or banned substances.'),
    LegalSection(heading: '4. Limitation of Liability', content: 'Enything is not liable for the quality, safety, or legality of the products delivered, including food poisoning, allergic reactions, or adverse medical events.'),
    LegalSection(heading: '5. Payments', content: 'All payments must be completed via approved gateways or Cash on Delivery (where applicable). Deliberate chargeback fraud will result in permanent account suspension.'),
  ];

  static final List<LegalSection> customerPrivacy = [
    LegalSection(heading: '1. Data Collection', content: 'We collect your name, phone number, real-time GPS location coordinates, delivery addresses, and order history.'),
    LegalSection(heading: '2. Location Tracking', content: 'Precise GPS data is required to calculate delivery fees, show local sellers, and pinpoint exact delivery destinations.'),
    LegalSection(heading: '3. Data Sharing', content: 'Your order details are shared with the Seller. Your name, masked phone number, and exact GPS delivery location are shared with the Delivery Partner solely for fulfillment.'),
    LegalSection(heading: '4. Security', content: 'Data is encrypted and retained as per the Digital Personal Data Protection Act (DPDPA) and Information Technology Act of India.'),
  ];

  static final List<LegalSection> customerRefund = [
    LegalSection(heading: '1. Cancellation Window', content: 'You may cancel an order without penalty within 60 seconds of placement. After this window, a 100% cancellation fee applies if the Seller has accepted the order.'),
    LegalSection(heading: '2. Fresh Food & Restaurants', content: 'Non-returnable. Refunds are only issued for spoiled food, foreign objects, or incorrect items, requiring photographic proof within 15 minutes of delivery.'),
    LegalSection(heading: '3. Groceries', content: 'Packaged goods are returnable within 24 hours if damaged/expired. Perishables must be inspected and rejected at the doorstep.'),
    LegalSection(heading: '4. Medicines & Pharmacy', content: 'Strictly non-returnable once delivered, per Indian regulations, unless the wrong medicine or an expired batch was delivered.'),
    LegalSection(heading: '5. Hardware & Home Goods', content: '7-day return policy for structural defects or missing components in original packaging.'),
    LegalSection(heading: '6. Jewelry', content: 'High-value items cannot be returned post-delivery. Doorstep inspection and secure OTP verification are mandatory; items must be rejected immediately if defective.'),
  ];

  // --- SELLER ---
  static final List<LegalSection> sellerTerms = [
    LegalSection(heading: '1. Platform Intermediary', content: 'You acknowledge Enything is an intermediary. You are the legal retailer and bear full liability for product quality, safety, and regulatory compliance.'),
    LegalSection(heading: '2. Mandatory Licensing', content: 'You must maintain valid FSSAI (for food/groceries), Drug Licenses (for pharmacies), and GST registrations as applicable.'),
    LegalSection(heading: '3. Pharmacy Specific Regulations', content: 'Pharmacies must mandate customer prescription uploads for Schedule H drugs. Dispensing must occur under a registered pharmacist. Sale of Schedule X drugs and narcotics (NDPS Act) via the platform is strictly prohibited.'),
    LegalSection(heading: '4. Financial Terms', content: 'You agree to the platform commission fee structure. Tax Collection at Source (TCS) under GST will be deducted as per Indian law.'),
    LegalSection(heading: '5. Fulfillment SLAs', content: 'You must accept orders within the stipulated timeframe and hand them over to Delivery Partners without unreasonable delay.'),
  ];

  static final List<LegalSection> sellerPrivacy = [
    LegalSection(heading: '1. Data Collection', content: 'We collect merchant name, store GPS coordinates, PAN, GSTIN, bank details, and regulatory license copies.'),
    LegalSection(heading: '2. Data Usage', content: 'Used for KYC verification, automated payout routing, and calculating delivery radii.'),
    LegalSection(heading: '3. Data Sharing', content: 'Store location and contact details are shared with Customers and assigned Delivery Partners. Financial data is shared with payment gateways and Indian tax authorities for statutory compliance.'),
  ];

  static final List<LegalSection> sellerRefund = [
    LegalSection(heading: '1. Auto-Cancellation', content: 'Orders unaccepted within the SLA window will be auto-canceled, negatively impacting your seller rating.'),
    LegalSection(heading: '2. Seller Liability for Refunds', content: 'If an order is refunded to a customer due to missing items, spoilage, expired goods, or incorrect fulfillment by your store, the refund amount will be deducted from your settlement.'),
    LegalSection(heading: '3. Out of Stock', content: 'You must keep inventory updated. Cancellations due to "Out of Stock" after order acceptance will incur a platform penalty.'),
  ];

  // --- DELIVERY PARTNER ---
  static final List<LegalSection> deliveryTerms = [
    LegalSection(heading: '1. Independent Contractor', content: 'You are an independent contractor, not an employee of Enything. You are not entitled to employee benefits, health insurance, or provident fund (PF).'),
    LegalSection(heading: '2. Revenue Share', content: 'You are entitled to 80% of the delivery charge paid by the customer for each successfully completed order. Payout cycles will be processed directly to your registered bank account.'),
    LegalSection(heading: '3. Vehicle & Compliance', content: 'You are solely responsible for vehicle maintenance, fuel, maintaining a valid Driving License, Vehicle Registration (RC), and active Vehicle Insurance.'),
    LegalSection(heading: '4. Code of Conduct', content: 'Zero tolerance for theft, order tampering, unsafe driving, traffic violations, or unprofessional behavior towards Customers or Sellers. Violations result in immediate deactivation.'),
  ];

  static final List<LegalSection> deliveryPrivacy = [
    LegalSection(heading: '1. Data Collection', content: 'We collect your Aadhaar, PAN, Driving License, RC, bank account details, and continuous background GPS location data.'),
    LegalSection(heading: '2. Continuous Location Tracking', content: 'You consent to background GPS tracking even when the app is minimized. This is strictly required to route active orders, optimize dispatch, and provide live tracking to Customers and Sellers.'),
    LegalSection(heading: '3. Data Sharing', content: 'Your name, live GPS location, and vehicle details are shared with the Customer and Seller during an active delivery cycle. KYC details are shared with statutory verification agencies.'),
  ];

  static final List<LegalSection> deliveryRefund = [
    LegalSection(heading: '1. Order Acceptance', content: 'You have the right to accept or reject assigned orders. However, frequent cancellations after acceptance will lower your dispatch priority.'),
    LegalSection(heading: '2. Penalty for Tampering', content: 'Any verified instance of opening sealed packages, consuming food orders, or stealing items will result in immediate termination, withholding of pending payouts, and potential legal action.'),
    LegalSection(heading: '3. Deactivation', content: 'Enything reserves the right to suspend or terminate your profile for consistent late deliveries, poor ratings, expired vehicular documents, or breach of conduct.'),
  ];

  static List<LegalSection> getTerms(String? role) {
    if (role == 'seller') return sellerTerms;
    if (role == 'delivery_partner') return deliveryTerms;
    return customerTerms;
  }

  static List<LegalSection> getPrivacy(String? role) {
    if (role == 'seller') return sellerPrivacy;
    if (role == 'delivery_partner') return deliveryPrivacy;
    return customerPrivacy;
  }

  static List<LegalSection> getThirdPolicy(String? role) {
    if (role == 'seller') return sellerRefund;
    if (role == 'delivery_partner') return deliveryRefund;
    return customerRefund;
  }

  static String getThirdPolicyTitle(String? role) {
    if (role == 'seller') return 'Refund & Auto-Cancellation Policy';
    if (role == 'delivery_partner') return 'Order Assignment & Deactivation';
    return 'Refund & Cancellation Policy';
  }
}
