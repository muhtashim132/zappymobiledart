import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rbac_provider.dart';
import '../../config/routes.dart';

// ============================================================================
// Admin Password Gate — shown after OTP when admin is detected.
// Acts as a 2nd-factor: "Something you know" after "Something you have (phone)".
// ============================================================================

class AdminPasswordPage extends StatefulWidget {
  const AdminPasswordPage({super.key});
  @override
  State<AdminPasswordPage> createState() => _AdminPasswordPageState();
}

class _AdminPasswordPageState extends State<AdminPasswordPage>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..forward();
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final pw = _passwordCtrl.text.trim();
    if (pw.isEmpty) {
      setState(() => _error = 'Please enter your admin password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyAdminPassword(pw);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      HapticFeedback.heavyImpact();
      // Load RBAC state before navigating
      final userId = auth.currentUserId;
      if (userId != null) {
        await context.read<RbacProvider>().loadCurrentAdmin(userId);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.adminDashboard, (_) => false);
    } else {
      HapticFeedback.vibrate();
      setState(() => _error = 'Incorrect admin password. Access denied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Background — deep purple aura
            Positioned(
              top: -120,
              left: -80,
              child: _aura(400, const Color(0xFF6A0DAD), 0.25),
            ),
            Positioned(
              bottom: -120,
              right: -80,
              child: _aura(400, const Color(0xFF3D008C), 0.20),
            ),
            // Grid overlay
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: _buildShieldIcon(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '⚠️  Admin Access Required',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: const Color(0xFFF4C542),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'God Mode',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your secondary admin password\nto access the Zappy Control Tower.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '(Test Account Password: admin)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 36),
                    // Password field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _error != null
                                ? const Color(0xFFFF6B6B).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.10)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: Colors.white38, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: 2),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 18),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _verifyPassword(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.white38,
                                size: 20),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF6B6B), size: 16),
                          const SizedBox(width: 8),
                          Text(_error!,
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF6B6B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Unlock button
                    GestureDetector(
                      onTap: _loading ? null : _verifyPassword,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B2FC9), Color(0xFF5C00A3)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF8B2FC9)
                                    .withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.shield_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text('Unlock God Mode',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.roleSelect, (_) => false),
                      child: Text('← Not you? Switch account',
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldIcon() => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [Color(0xFF8B2FC9), Color(0xFF5C00A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF8B2FC9).withValues(alpha: 0.5),
                blurRadius: 32,
                spreadRadius: 4),
          ],
        ),
        child: const Center(
          child: Text('👑', style: TextStyle(fontSize: 44)),
        ),
      );

  Widget _aura(double size, Color color, double opacity) => Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.0)]),
          ),
        ),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
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
