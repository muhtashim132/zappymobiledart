import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings & Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile Info
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    user.initials,
                    style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(user.phone, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.roleDisplay,
                          style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Role Specific Settings
            if (user.activeSessionRole == 'customer') _buildCustomerSettings(isDark),
            if (user.activeSessionRole == 'seller') _buildSellerSettings(isDark),
            if (user.activeSessionRole == 'delivery_partner') _buildDeliverySettings(isDark),

            const SizedBox(height: 24),
            _buildSectionTitle('General', isDark),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              subtitle: 'Manage push notifications',
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.security_rounded,
              title: 'Privacy & Security',
              subtitle: 'Password, PIN, and biometrics',
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQs and contact support',
              isDark: isDark,
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'About Zappy',
              subtitle: 'App version, Terms, Privacy Policy',
              isDark: isDark,
              onTap: () {},
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/auth/role', (_) => false);
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: Text('Logout', style: GoogleFonts.outfit(color: AppColors.danger, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'Zappy v1.0.0',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSettings(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account Settings', isDark),
        const SizedBox(height: 16),
        _buildSettingTile(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          subtitle: 'View your order history',
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, '/customer/orders'),
        ),
        _buildSettingTile(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'Update your name, email and phone',
          isDark: isDark,
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          subtitle: 'Manage delivery locations',
          isDark: isDark,
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.payment_outlined,
          title: 'Payment Methods',
          subtitle: 'Manage saved cards and UPI',
          isDark: isDark,
          onTap: () {},
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSellerSettings(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Shop Management', isDark),
        const SizedBox(height: 16),
        _buildSettingTile(
          icon: Icons.storefront_outlined,
          title: 'Shop Details',
          subtitle: 'Name, description, and categories',
          isDark: isDark,
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.access_time,
          title: 'Business Hours',
          subtitle: 'Set opening and closing times',
          isDark: isDark,
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.account_balance_outlined,
          title: 'Payout Settings',
          subtitle: 'Bank accounts for settlements',
          isDark: isDark,
          onTap: () {},
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeliverySettings(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Partner Settings', isDark),
        const SizedBox(height: 16),
        _buildSettingTile(
          icon: Icons.two_wheeler,
          title: 'Vehicle Information',
          subtitle: 'Update vehicle type and reg no',
          isDark: isDark,
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.badge_outlined,
          title: 'Documents',
          subtitle: 'License, Aadhar, and approvals',
          isDark: isDark,
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.account_balance_outlined,
          title: 'Bank Details',
          subtitle: 'Manage weekly payout account',
          isDark: isDark,
          onTap: () {},
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardTheme.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
