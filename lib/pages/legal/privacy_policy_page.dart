import 'package:flutter/material.dart';
import 'legal_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPage(
      title: 'Privacy Policy',
      sections: [
        LegalSection(
          heading: '1. Information We Collect',
          content: 'We collect personal information you provide directly to us, such as your name, phone number, delivery address, and payment preferences. For Sellers, we also collect KYC documents including PAN, Aadhaar, and GSTIN for legal compliance.',
        ),
        LegalSection(
          heading: '2. Location Data',
          content: 'Zappy collects real-time location data (GPS) to calculate delivery distances, provide accurate ETA, and enable tracking of orders by Customers and Delivery Partners. This data is collected even when the app is in the background for active riders.',
        ),
        LegalSection(
          heading: '3. How We Use Information',
          content: 'We use your data to facilitate order fulfillment, process payments, ensure security, and comply with Indian tax regulations. We do not sell your personal data to third parties for marketing purposes.',
        ),
        LegalSection(
          heading: '4. Data Sharing',
          content: 'We share your contact number and address with Delivery Partners assigned to your order. Shop details are shared with Customers for identification. We may share information with law enforcement if required by the CGST Act or other legal mandates.',
        ),
        LegalSection(
          heading: '5. Data Security',
          content: 'Your data is encrypted and stored using industry-standard protocols. While we strive to protect your information, no method of transmission over the internet is 100% secure.',
        ),
        LegalSection(
          heading: '6. User Control',
          content: 'You can update your profile information at any time via the Settings menu. To request account deletion or data removal, please contact our support team at support@zappy.in.',
        ),
      ],
    );
  }
}
