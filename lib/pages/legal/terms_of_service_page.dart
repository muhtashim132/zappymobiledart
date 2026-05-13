import 'package:flutter/material.dart';
import 'legal_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPage(
      title: 'Terms of Service',
      sections: [
        LegalSection(
          heading: '1. Acceptance of Terms',
          content:
              'By accessing or using the Zappy application, you agree to be bound by these Terms of Service. If you do not agree to all terms, please do not use the application.',
        ),
        LegalSection(
          heading: '2. Platform Services',
          content:
              'Zappy acts as an e-commerce marketplace aggregator connecting Customers, Sellers, and Delivery Partners. Zappy does not own the inventory or products listed by Sellers and is not responsible for the quality, safety, or legality of items.',
        ),
        LegalSection(
          heading: '3. Pricing & Payments',
          content:
              'Zappy charges a 5% platform commission on the base price of products sold. A fixed Handling/Platform Fee of ₹15 is charged per order. All payments are processed securely via third-party payment gateways. Cash on Delivery is strictly prohibited to ensure merchant and rider security.',
        ),
        LegalSection(
          heading: '4. GST Compliance',
          content:
              'Zappy is an E-Commerce Operator (ECO) under Section 9(5) of the CGST Act. For Restaurant food, Zappy collects and remits 5% GST directly to the government. For all other retail goods, Zappy acts as a passthrough agent, and the Seller is responsible for final GST remittance.',
        ),
        LegalSection(
          heading: '5. Cancellation & Refunds',
          content:
              'Orders can only be cancelled before they are accepted by the Seller. Once prepared or picked up, cancellations are not permitted. Refunds are issued solely at Zappy\'s discretion in cases of missing items or delivery failure attributable to Zappy.',
        ),
        LegalSection(
          heading: '6. User Responsibilities',
          content:
              'Users are responsible for providing accurate delivery addresses and contact information. Any misuse of the platform, including fake orders or harassment of riders, will lead to immediate account termination.',
        ),
        LegalSection(
          heading: '7. Grievance Redressal Mechanism',
          content:
              'In accordance with the Information Technology Act, 2000 and rules made thereunder, the name and contact details of the Grievance Officer are provided below:\nName: Grievance Officer\nEmail: grievance@zappy.in\nTime: Mon - Fri (9:00 AM - 6:00 PM).',
        ),
      ],
    );
  }
}
