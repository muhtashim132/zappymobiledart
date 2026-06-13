import '../pages/legal/legal_page.dart';

class LegalConstants {
  // --- CUSTOMER ---
  static final List<LegalSection> customerTerms = [
    LegalSection(heading: '1. Platform Role', content: 'Enything operates as an intermediary marketplace facilitating hyper-local logistics. The contract of sale is strictly between you and the respective Seller.'),
    LegalSection(heading: '2. Account Integrity', content: 'You must provide accurate delivery locations and valid contact details. You must be at least 18 years old to order restricted items (e.g., specific medicines).'),
    LegalSection(heading: '3. Prohibited Use', content: 'You agree not to order illegal, hazardous, or banned substances.'),
    LegalSection(heading: '4. Limitation of Liability', content: 'Enything is not liable for the quality, safety, or legality of the products delivered, including food items and medicines.'),
  ];

  static final List<LegalSection> customerPrivacy = [
    LegalSection(heading: '1. Data Collection', content: 'We collect location data to facilitate hyper-local deliveries and contact information for account management.'),
    LegalSection(heading: '2. Data Sharing', content: 'Your information is shared with Sellers and Delivery Partners solely for order fulfillment. We do not sell your data.'),
  ];

  static final List<LegalSection> customerRefund = [
    LegalSection(heading: '1. Eligibility', content: 'Refunds are applicable if an order is cancelled before seller acceptance or if a dispute regarding missing/damaged items is verified by Enything.'),
    LegalSection(heading: '2. Non-Refundable', content: 'Once an order is prepared or out for delivery, cancellations are not permitted, and refunds are voided.'),
    LegalSection(heading: '3. Processing Time', content: 'Approved refunds are processed back to the original payment method within 5–7 business days.'),
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
