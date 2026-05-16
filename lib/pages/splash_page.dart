import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _ring1, _ring2, _ring3;
  late Animation<double> _logoScale, _logoFade;
  late Animation<double> _textSlide, _textFade, _taglineFade;
  late Animation<double> _shimmerAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _ringCtrl = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this);
    _ring1 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOut));
    _ring2 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.15, 0.80, curve: Curves.easeOut));
    _ring3 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.30, 1.00, curve: Curves.easeOut));

    _logoCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));

    _shimmerCtrl = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.055).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _textCtrl = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _textSlide = Tween<double>(begin: 36, end: 0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _taglineFade = CurvedAnimation(parent: _textCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    _ringCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final auth = context.read<AuthProvider>();
      // Wait for profile to load after session restore
      for (int i = 0; i < 10; i++) {
        if (auth.user != null) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted) return;
      final role = auth.user?.activeSessionRole ?? auth.user?.role;
      final status = auth.user?.verificationStatus ?? 'verified';

      if (role == 'seller') {
        if (status == 'verified') {
          Navigator.pushReplacementNamed(context, AppRoutes.sellerDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.sellerPendingVerification);
        }
      } else if (role == 'delivery_partner') {
        if (status == 'verified') {
          Navigator.pushReplacementNamed(context, AppRoutes.deliveryDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.deliveryPendingVerification);
        }
      } else if (role == 'admin') {
        // Admin must re-pass 2FA password gate on every app restart
        Navigator.pushReplacementNamed(context, AppRoutes.adminPassword);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      }
    } else {
      // No active session — go to role selection first, then OTP
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelect);
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _ringCtrl.dispose(); _logoCtrl.dispose();
    _shimmerCtrl.dispose(); _pulseCtrl.dispose(); _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _ringCtrl, _logoCtrl, _textCtrl, _shimmerCtrl, _pulseCtrl]),
        builder: (_, __) => Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF04091E), const Color(0xFF07124A), _bgAnim.value)!,
                const Color(0xFF02061A),
                Color.lerp(const Color(0xFF08043E), const Color(0xFF120860), _bgAnim.value)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Aurora blobs ──────────────────────────────────────────────
              Positioned(
                top: -size.height * 0.08,
                left: -size.width * 0.25,
                child: _aurora(size.width * 0.85, const Color(0xFF2B4FD4), 0.18 + _bgAnim.value * 0.12),
              ),
              Positioned(
                bottom: -size.height * 0.12,
                right: -size.width * 0.25,
                child: _aurora(size.width * 0.95, const Color(0xFF6230C8), 0.15 + (1 - _bgAnim.value) * 0.12),
              ),
              // Gold center glow
              Opacity(
                opacity: (_logoFade.value * 0.18).clamp(0.0, 1.0),
                child: _aurora(size.shortestSide * 0.65, const Color(0xFFF4C542), 1.0),
              ),

              // ── Expanding rings ──────────────────────────────────────────
              ...[
                (_ring1, size.shortestSide * 0.42, const Color(0xFFF4C542), 2.0),
                (_ring2, size.shortestSide * 0.30, const Color(0xFF4C6EF5), 1.4),
                (_ring3, size.shortestSide * 0.22, const Color(0xFFF4C542), 0.9),
              ].map((r) => _RingWidget(progress: r.$1.value, maxRadius: r.$2, color: r.$3, strokeW: r.$4)),

              // ── Star field ───────────────────────────────────────────────
              CustomPaint(size: size, painter: _StarPainter(_bgCtrl.value)),

              // ── Central content — perfectly centered ─────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: ScaleTransition(
                        scale: _pulseAnim,
                        child: _ZappyLogo(
                          logoSize: size.shortestSide * 0.27,
                          shimmer: _shimmerAnim,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Text block
                  FadeTransition(
                    opacity: _textFade,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ZAPPY wordmark
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFFFFE566), Color(0xFFF4C542), Color(0xFFE89A00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(b),
                            child: Text('ZAPPY',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 60,
                                fontWeight: FontWeight.w900, letterSpacing: 12, height: 1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          FadeTransition(
                            opacity: _taglineFade,
                            child: Text(
                              'Delivered at the speed of life',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom loading indicator ─────────────────────────────────
              Positioned(
                bottom: 52,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: AnimatedBuilder(
                    animation: _bgCtrl,
                    builder: (_, __) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final wave = (math.sin((_bgCtrl.value * 6) - i * 1.0) + 1) / 2;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == 1 ? 9 : 5.5,
                          height: i == 1 ? 9 : 5.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(Colors.white.withOpacity(0.15), const Color(0xFFF4C542), wave),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aurora(double size, Color color, double opacity) => Opacity(
    opacity: opacity.clamp(0.0, 1.0),
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    ),
  );
}

// ─── Zappy Logo Widget ────────────────────────────────────────────────────────
class _ZappyLogo extends StatelessWidget {
  final double logoSize;
  final Animation<double> shimmer;
  const _ZappyLogo({required this.logoSize, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final r = logoSize * 0.28;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: logoSize + 32, height: logoSize + 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFFF4C542).withOpacity(0.40), blurRadius: 52, spreadRadius: 10),
              BoxShadow(color: const Color(0xFF3B5BDB).withOpacity(0.25), blurRadius: 30, spreadRadius: 4),
            ],
          ),
        ),
        // Main container
        Container(
          width: logoSize, height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF162AC4), Color(0xFF0A178C), Color(0xFF06104E)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: const Color(0xFFF4C542).withOpacity(0.30), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: shimmer,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        stops: [
                          (shimmer.value - 0.45).clamp(0.0, 1.0),
                          shimmer.value.clamp(0.0, 1.0),
                          (shimmer.value + 0.45).clamp(0.0, 1.0),
                        ],
                        colors: [Colors.transparent, Colors.white.withOpacity(0.07), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(logoSize * 0.60, logoSize * 0.60),
                  painter: _ZappyLogoPainter(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────
class _ZappyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final goldShader = const LinearGradient(
      colors: [Color(0xFFFFE566), Color(0xFFF4C542), Color(0xFFCC8800)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    // ── Bold Z body (filled) ──────────────────────────────────────────────
    final t = h * 0.12;   // bar thickness
    final lm = w * 0.06;
    final rm = w * 0.06;

    final zPath = Path()
      ..moveTo(lm, 0)
      ..lineTo(w - rm, 0)
      ..lineTo(w - rm, t)
      ..lineTo(lm + t * 1.05, h - t)
      ..lineTo(w - rm, h - t)
      ..lineTo(w - rm, h)
      ..lineTo(lm, h)
      ..lineTo(lm, h - t)
      ..lineTo(w - rm - t * 1.05, t)
      ..lineTo(lm, t)
      ..close();

    canvas.drawPath(zPath, Paint()..shader = goldShader..style = PaintingStyle.fill);

    // Subtle white outline
    canvas.drawPath(
      zPath,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022,
    );

    // ── Lightning bolt cutout / overlay centered on the diagonal ─────────
    // Renders as a crisp white bolt punched on the Z
    final cx = w * 0.50;
    final cy = h * 0.50;
    final bh = h * 0.46;
    final bw = w * 0.22;

    final boltPath = Path()
      ..moveTo(cx + bw, cy - bh * 0.5)
      ..lineTo(cx - bw * 0.3, cy + bh * 0.04)
      ..lineTo(cx + bw * 0.18, cy + bh * 0.04)
      ..lineTo(cx - bw, cy + bh * 0.5)
      ..lineTo(cx + bw * 0.3, cy - bh * 0.04)
      ..lineTo(cx - bw * 0.18, cy - bh * 0.04)
      ..close();

    // Dark backing (so bolt reads over the Z)
    canvas.drawPath(boltPath, Paint()..color = const Color(0xFF0A178C)..style = PaintingStyle.fill);
    // White bolt
    canvas.drawPath(boltPath,
      Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.5),
    );
  }

  @override
  bool shouldRepaint(_ZappyLogoPainter _) => false;
}

class _RingWidget extends StatelessWidget {
  final double progress, maxRadius, strokeW;
  final Color color;
  const _RingWidget({required this.progress, required this.maxRadius, required this.color, required this.strokeW});
  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    return SizedBox.expand(
      child: CustomPaint(
        painter: _RingPainter(radius: maxRadius * progress, opacity: (1 - progress).clamp(0.0, 1.0) * 0.5, color: color, strokeWidth: strokeW),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double radius, opacity, strokeWidth;
  final Color color;
  const _RingPainter({required this.radius, required this.opacity, required this.color, required this.strokeWidth});
  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || radius <= 0) return;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()..color = color.withOpacity(opacity)..style = PaintingStyle.stroke..strokeWidth = strokeWidth,
    );
  }
  @override
  bool shouldRepaint(_RingPainter o) => o.radius != radius || o.opacity != opacity;
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);
  static final _rnd = math.Random(13);
  static final _stars = List.generate(55, (_) => [
    _rnd.nextDouble(), _rnd.nextDouble(),
    _rnd.nextDouble() * 1.6 + 0.5,
    _rnd.nextDouble() * math.pi * 2,
  ]);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      final tw = (math.sin(t * math.pi * 2 + s[3]) + 1) / 2;
      p.color = Colors.white.withOpacity(0.03 + tw * 0.15);
      canvas.drawCircle(Offset(s[0] * size.width, s[1] * size.height), s[2], p);
    }
  }
  @override
  bool shouldRepaint(_StarPainter o) => o.t != t;
}
