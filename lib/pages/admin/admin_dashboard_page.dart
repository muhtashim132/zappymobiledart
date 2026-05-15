import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rbac_provider.dart';
import '../../providers/team_provider.dart';

import '../../config/routes.dart';
import '../../widgets/rbac/rbac_widgets.dart';
import 'rbac/roles_list_page.dart';
import 'rbac/team_members_page.dart';
import 'rbac/audit_logs_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        duration: const Duration(seconds: 10), vsync: this)
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isAdminVerified) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.roleSelect, (_) => false);
        return;
      }
      // Load RBAC state
      final userId = auth.currentUserId;
      if (userId != null) {
        context.read<RbacProvider>().loadCurrentAdmin(userId);
      }
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _signOut() {
    context.read<AuthProvider>().adminSignOut();
    context.read<RbacProvider>().clear();
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.roleSelect, (_) => false);
  }

  List<_NavItem> _navItems(RbacProvider rbac) => [
    _NavItem(Icons.dashboard_rounded, 'Overview', true),
    _NavItem(Icons.receipt_long_rounded, 'Orders', rbac.can('orders.view')),
    _NavItem(Icons.people_rounded, 'Users', rbac.can('customers.view')),
    _NavItem(Icons.store_rounded, 'Sellers', rbac.can('sellers.view')),
    _NavItem(Icons.delivery_dining_rounded, 'Riders', rbac.can('riders.view')),
    _NavItem(Icons.account_balance_rounded, 'Finance', rbac.can('finance.view')),
    _NavItem(Icons.admin_panel_settings_rounded, 'RBAC', rbac.can('roles.view') || rbac.isSuperAdmin),
  ].where((n) => n.visible).toList();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rbac = context.watch<RbacProvider>();
    final name = auth.user?.fullName.split(' ').first ??
        rbac.currentAdmin?.fullName.split(' ').first ?? 'Admin';
    final navItems = _navItems(rbac);
    final safeIndex = _currentIndex.clamp(0, navItems.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -100 + (_bgAnim.value * 20),
                left: -50,
                child: _aura(350, const Color(0xFF6A0DAD), 0.15),
              ),
              Positioned(
                bottom: -150 - (_bgAnim.value * 30),
                right: -100,
                child: _aura(450, const Color(0xFF3D008C), 0.12),
              ),
            ]),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(name, rbac),
                const Divider(color: Colors.white10, height: 1),
                Expanded(child: _buildBody(safeIndex, navItems, rbac)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(navItems, safeIndex),
    );
  }

  Widget _buildHeader(String name, RbacProvider rbac) {
    final role = rbac.currentAdmin?.role;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B2FC9), Color(0xFF5C00A3)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF8B2FC9).withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GOD MODE',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Row(children: [
                  Text('Welcome, $name',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 6),
                  if (role != null)
                    RoleBadge(name: role.name, color: role.badgeColor, small: true),
                ]),
              ],
            ),
          ),
          if (rbac.loading)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  color: Color(0xFF8B2FC9), strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white54),
              onPressed: _signOut,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(int index, List<_NavItem> items, RbacProvider rbac) {
    if (items.isEmpty) return _placeholder('No modules available');
    final label = items[index].label;
    return switch (label) {
      'Overview' => _buildOverview(rbac),
      'RBAC' => _buildRbacHub(rbac),
      _ => _placeholder('$label (coming soon)'),
    };
  }

  Widget _buildOverview(RbacProvider rbac) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: GoogleFonts.outfit(
                  color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              ShowIfCan(
                permission: 'roles.view',
                child: _QuickCard(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Manage Roles',
                  color: const Color(0xFF8B2FC9),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RolesListPage())),
                ),
              ),
              ShowIfCan(
                permission: 'roles.assign',
                child: _QuickCard(
                  icon: Icons.people_rounded,
                  label: 'Team Members',
                  color: const Color(0xFF2196F3),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(create: (_) => TeamProvider()),
                        ],
                        child: const TeamMembersPage(),
                      ))),
                ),
              ),
              ShowIfCan(
                permission: 'audit.view',
                child: _QuickCard(
                  icon: Icons.history_rounded,
                  label: 'Audit Logs',
                  color: const Color(0xFF3F51B5),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuditLogsPage())),
                ),
              ),
              ShowIfCan(
                permission: 'analytics.view',
                child: _QuickCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  color: const Color(0xFF607D8B),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _PermissionSummaryCard(rbac: rbac),
        ],
      ),
    );
  }

  Widget _buildRbacHub(RbacProvider rbac) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HubTile(
          icon: Icons.shield_rounded,
          title: 'Roles & Permissions',
          subtitle: '${rbac.allRoles.length} roles configured',
          color: const Color(0xFF8B2FC9),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RolesListPage())),
        ),
        _HubTile(
          icon: Icons.group_rounded,
          title: 'Team Members',
          subtitle: 'Manage staff access',
          color: const Color(0xFF2196F3),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => TeamProvider()),
                ],
                child: const TeamMembersPage(),
              ))),
        ),
        if (rbac.can('audit.view'))
          _HubTile(
            icon: Icons.history_rounded,
            title: 'Audit Logs',
            subtitle: 'Track all admin actions',
            color: const Color(0xFF3F51B5),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AuditLogsPage())),
          ),
      ],
    );
  }

  Widget _placeholder(String msg) => Center(
        child: Text(msg, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15)),
      );

  Widget _buildNavBar(List<_NavItem> items, int selected) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A1F),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: selected,
        onTap: (i) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = i);
        },
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFB44FE0),
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
        elevation: 0,
        items: items
            .map((n) => BottomNavigationBarItem(
                icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }

  Widget _aura(double size, Color color, double opacity) => Opacity(
        opacity: opacity,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color, color.withOpacity(0.0)]),
          ),
        ),
      );
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool visible;
  const _NavItem(this.icon, this.label, this.visible);
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text(label,
                style: GoogleFonts.outfit(
                    color: const Color(0xDEFFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _HubTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.07))),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(
                color: const Color(0xDEFFFFFF), fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      ),
    );
  }
}

class _PermissionSummaryCard extends StatelessWidget {
  final RbacProvider rbac;
  const _PermissionSummaryCard({required this.rbac});

  @override
  Widget build(BuildContext context) {
    final count = rbac.permissionCodes.length;
    final role = rbac.currentAdmin?.role;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B2FC9).withOpacity(0.15),
            const Color(0xFF3D008C).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B2FC9).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF8B2FC9), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rbac.isSuperAdmin ? 'Super Admin — Full Access' : role?.name ?? 'No Role',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  rbac.isSuperAdmin
                      ? 'Unrestricted access to all modules'
                      : '$count permissions granted',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
