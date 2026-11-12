// Velvet Herald — animated loading screen.
//
// The herald chuckles (shoulders + head on separate soft-edged layers),
// says "GOOD DAY!" in a parchment bubble, and a gold LOADING sits in the
// middle of the screen. One Ticker drives everything, so all motion stays
// in sync and costs a single rebuild per frame.
//
// Usage:
//   const VelvetLoadingScreen()
//
// Uses bundled images and the system Georgia font.
// Requires in pubspec.yaml:
//   flutter:
//     assets:
//       - assets/herald/

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class VelvetLoadingScreen extends StatefulWidget {
  const VelvetLoadingScreen({
    super.key,
    this.greeting = 'GOOD DAY!',
    this.label = 'LOADING',
  });

  final String greeting;
  final String label;

  @override
  State<VelvetLoadingScreen> createState() => _VelvetLoadingScreenState();
}

// ---------------------------------------------------------------- palette
const _velvet = Color(0xFF1B0D14);
const _gold = Color(0xFFE9C37A);
const _goldDeep = Color(0xFFB9853A);
const _imageAspect = 515 / 498;

// ---------------------------------------------------------------- curves
// Strong curves (same values as the web version).
const _easeOut = Cubic(0.23, 1, 0.32, 1);
const _easeInOut = Cubic(0.77, 0, 0.175, 1);
const _ease = Cubic(0.25, 0.1, 0.25, 1);

const double _cycle = 6.0; // seconds — one laugh + greeting

class _VelvetLoadingScreenState extends State<VelvetLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0; // elapsed seconds

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _ticker.isActive) _ticker.stop();
    if (!reduceMotion && !_ticker.isActive) _ticker.start();
    for (final name in ['herald', 'herald_body', 'herald_head']) {
      precacheImage(AssetImage('assets/herald/$name.png'), context);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final p = reduceMotion
        ? 0.3
        : (_t % _cycle) / _cycle; // 0..1 phase of the main cycle

    return Scaffold(
      backgroundColor: _velvet,
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          final wide = w > h;

          // Portrait frame geometry (mirrors the web layout).
          final double frameH, frameW, frameLeft;
          if (wide) {
            frameH = math.min(h, w / _imageAspect * 0.9);
            frameW = frameH * _imageAspect;
            frameLeft = 0;
          } else {
            frameW = w * 1.12;
            frameH = frameW / _imageAspect;
            frameLeft = w / 2 - frameW * 0.55;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.4, -0.2),
                    radius: 1.1,
                    colors: [Color(0xFF3A1520), _velvet, Color(0xFF0D060A)],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
              Positioned(
                left: frameLeft,
                bottom: 0,
                width: frameW,
                height: frameH,
                child: _Portrait(
                  phase: p,
                  reduceMotion: reduceMotion,
                  wide: wide,
                  screenH: h,
                  greeting: widget.greeting,
                ),
              ),
              if (!reduceMotion) ..._leaves(w, h),
              Align(
                alignment: Alignment(0, wide ? 0 : -0.24), // 50% / 38%
                child: _Loading(
                  t: reduceMotion ? 0.5 : _t,
                  label: widget.label,
                  reduceMotion: reduceMotion,
                  fontSize: wide ? (h * 0.06).clamp(28.0, 64.0) : w * 0.085,
                  tracking: wide ? 0.32 : 0.22,
                  barWidth: (w * 0.28).clamp(180.0, 340.0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _leaves(double w, double h) {
    const specs = [
      // left%, duration s, delay s, color
      (0.62, 11.0, -2.0, Color(0xCCC4572A)),
      (0.78, 14.0, -7.0, Color(0xCCD98A3A)),
      (0.88, 12.0, -4.0, Color(0xCCC4572A)),
      (0.70, 16.0, -11.0, Color(0xCCA8401F)),
    ];
    return [
      for (final (left, dur, delay, color) in specs)
        Builder(
          builder: (_) {
            final q = ((_t - delay) / dur) % 1.0;
            // two linear legs: 0→50%, 50→100%
            final double dx, dy, rot;
            if (q < 0.5) {
              final k = q / 0.5;
              dx = _lerp(0, -0.04 * w, k);
              dy = _lerp(0, 0.55 * h, k);
              rot = _lerp(0, 200, k);
            } else {
              final k = (q - 0.5) / 0.5;
              dx = _lerp(-0.04 * w, 0.02 * w, k);
              dy = _lerp(0.55 * h, 1.10 * h, k);
              rot = _lerp(200, 380, k);
            }
            return Positioned(
              left: left * w + dx,
              top: -0.04 * h + dy,
              child: Transform.rotate(
                angle: rot * math.pi / 180,
                child: Container(
                  width: 12,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.elliptical(9.6, 6.4),
                      bottomLeft: Radius.elliptical(9.6, 6.4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }
}

// ======================================================== the portrait
class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.phase,
    required this.reduceMotion,
    required this.wide,
    required this.screenH,
    required this.greeting,
  });

  final double phase;
  final bool reduceMotion;
  final bool wide;
  final double screenH;
  final String greeting;

  // Keyframes: (position 0..1, value). Body/head Y is % of frame height.
  static const _bodyY = _Keys([
    (0.0, 0.0),
    (.06, 0.0),
    (.10, -.5),
    (.14, .1),
    (.18, -.45),
    (.22, .1),
    (.26, -.3),
    (.32, 0.0),
    (.60, 0.0),
    (.78, -.25),
    (1.0, 0.0),
  ]);
  static const _bodyR = _Keys([
    (0.0, 0.0),
    (.06, 0.0),
    (.10, -.25),
    (.14, 0.0),
    (.18, -.2),
    (.22, 0.0),
    (.26, -.12),
    (.32, 0.0),
    (1.0, 0.0),
  ]);
  static const _headY = _Keys([
    (0.0, 0.0),
    (.06, 0.0),
    (.10, -.6),
    (.14, .05),
    (.18, -.55),
    (.22, .05),
    (.26, -.35),
    (.34, 0.0),
    (.60, 0.0),
    (.78, -.2),
    (1.0, 0.0),
  ]);
  static const _headR = _Keys([
    (0.0, 0.0),
    (.06, 0.0),
    (.10, -1.1),
    (.14, -.3),
    (.18, -1.0),
    (.22, -.3),
    (.26, -.7),
    (.34, .3),
    (.44, 0.0),
    (.60, 0.0),
    (.78, .15),
    (1.0, 0.0),
  ]);
  static const _glow = _Keys([
    (0.0, .55),
    (.06, .55),
    (.16, 1.0),
    (.24, 1.0),
    (.40, .55),
    (1.0, .55),
  ]);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fh = c.maxHeight;

        Widget layer(String name, _Keys ys, _Keys rs, Alignment origin) {
          final img = Image.asset(
            'assets/herald/$name.png',
            fit: BoxFit.fill,
            gaplessPlayback: true,
          );
          if (reduceMotion) return img;
          final dy = ys.at(phase, _easeInOut) / 100 * fh;
          final rad = rs.at(phase, _easeInOut) * math.pi / 180;
          return Transform(
            alignment: origin,
            transform: Matrix4.translationValues(0, dy, 0)..rotateZ(rad),
            child: img,
          );
        }

        final picture = Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/herald/herald.png',
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
            // origin 40% 100% → Alignment(-0.2, 1)
            layer('herald_body', _bodyY, _bodyR, const Alignment(-0.2, 1)),
            // origin 42% 44% → Alignment(-0.16, -0.12)
            layer('herald_head', _headY, _headR, const Alignment(-0.16, -0.12)),
            IgnorePointer(
              child: Opacity(
                opacity: reduceMotion ? 0.55 : _glow.at(phase, _ease),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.16, -0.52),
                      radius: 0.4,
                      colors: [Color(0x38FFC478), Color(0x00FFC478)],
                    ),
                    backgroundBlendMode: BlendMode.screen,
                  ),
                ),
              ),
            ),
          ],
        );

        // Fade the picture into the velvet: right edge and top edge.
        final faded = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white],
            stops: [0, 0.12],
          ).createShader(r),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              colors: [Colors.white, Colors.transparent],
              stops: [0.7, 1],
            ).createShader(r),
            child: picture,
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: faded),
            Positioned(
              left: c.maxWidth * (wide ? 0.58 : 0.50),
              top: fh * (wide ? 0.09 : 0.0),
              child: _Bubble(
                phase: phase,
                text: greeting,
                reduceMotion: reduceMotion,
                fontSize: wide ? (screenH * 0.032).clamp(16.0, 34.0) : 15,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================== speech bubble
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.phase,
    required this.text,
    required this.reduceMotion,
    required this.fontSize,
  });

  final double phase;
  final String text;
  final bool reduceMotion;
  final double fontSize;

  static const _opacity = _Keys([
    (0.0, 0.0),
    (.08, 0.0),
    (.13, 1.0),
    (.52, 1.0),
    (.58, 0.0),
    (1.0, 0.0),
  ]);
  static const _y = _Keys([
    (0.0, 6.0),
    (.08, 6.0),
    (.13, 0.0),
    (.52, 0.0),
    (.58, -4.0),
    (1.0, -4.0),
  ]);
  static const _scale = _Keys([
    (0.0, .94),
    (.08, .94),
    (.13, 1.0),
    (.52, 1.0),
    (.58, .97),
    (1.0, .97),
  ]);
  static const _letterO = _Keys([
    (0.0, 0.0),
    (.10, 0.0),
    (.15, 1.0),
    (1.0, 1.0),
  ]);
  static const _letterY = _Keys([
    (0.0, .35),
    (.10, .35),
    (.15, 0.0),
    (1.0, 0.0),
  ]);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Georgia',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: fontSize * 0.08,
      color: const Color(0xFF3B1A12),
    );

    final chars = text.characters.toList();
    final letters = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          Builder(
            builder: (_) {
              if (reduceMotion) return Text(chars[i], style: style);
              // 45 ms stagger per letter, expressed in cycle phase
              final lp = (phase - i * 0.045 / _cycle) % 1.0;
              return Opacity(
                opacity: _letterO.at(lp, _easeOut),
                child: Transform.translate(
                  offset: Offset(0, _letterY.at(lp, _easeOut) * fontSize),
                  child: Text(chars[i], style: style),
                ),
              );
            },
          ),
      ],
    );

    Widget bubble = CustomPaint(
      painter: _BubblePainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          fontSize,
          fontSize * 0.55,
          fontSize * 0.92,
          fontSize * 0.6,
        ),
        child: letters,
      ),
    );

    final o = _opacity.at(phase, _easeOut);
    if (reduceMotion) return Opacity(opacity: o, child: bubble);
    return Opacity(
      opacity: o,
      child: Transform.translate(
        offset: Offset(0, _y.at(phase, _easeOut)),
        child: Transform.scale(
          scale: _scale.at(phase, _easeOut),
          alignment: Alignment.bottomLeft,
          child: bubble,
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    const r = Radius.circular(18);
    final body = RRect.fromRectAndRadius(Offset.zero & s, r);
    // tail pointing down-left toward his mouth
    final tail = Path()
      ..moveTo(2, s.height - 30)
      ..lineTo(-14, s.height - 6)
      ..lineTo(14, s.height - 12)
      ..close();
    final shape = Path.combine(
      PathOperation.union,
      Path()..addRRect(body),
      tail,
    );

    canvas.drawShadow(shape, Colors.black, 10, false);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6E6C3), Color(0xFFE7CF9C)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawRRect(
      body.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0x40FFFFFF),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _goldDeep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ======================================================== LOADING
class _Loading extends StatelessWidget {
  const _Loading({
    required this.t,
    required this.label,
    required this.reduceMotion,
    required this.fontSize,
    required this.tracking,
    required this.barWidth,
  });

  final double t;
  final String label;
  final bool reduceMotion;
  final double fontSize;
  final double tracking;
  final double barWidth;

  static const _dot = _Keys([(0.0, .25), (.4, 1.0), (1.0, .25)]);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Georgia',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: fontSize * tracking,
      color: Colors.white,
      shadows: const [Shadow(color: Color(0x2EE9C37A), blurRadius: 18)],
    );

    // gold sheen sweeping across the word (3 s, linear)
    final sheen = reduceMotion ? 0.5 : (t % 3.0) / 3.0;
    final word = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) {
        final gw = r.width * 2.5;
        final centre = _lerp(r.width * 1.6, -r.width * 0.6, sheen);
        return const LinearGradient(
          colors: [_goldDeep, _gold, Color(0xFFFFF3D4), _gold, _goldDeep],
          stops: [0, .4, .5, .6, 1],
        ).createShader(Rect.fromLTWH(centre - gw / 2, 0, gw, r.height));
      },
      // letterSpacing adds space after the last letter; mirror it on the left so the word stays centred
      child: Padding(
        padding: EdgeInsets.only(left: fontSize * tracking),
        child: Text(label, style: style, maxLines: 1, softWrap: false),
      ),
    );

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(
              left: fontSize * 0.35 * (i == 0 ? 0.3 : 1.0),
            ),
            child: Opacity(
              opacity: _dot.at(((t - i * 0.2) % 1.2) / 1.2, _ease),
              child: Container(
                width: fontSize * 0.16,
                height: fontSize * 0.16,
                decoration: const BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );

    final barT = (t % 1.6) / 1.6;
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: barWidth,
        height: 3,
        color: const Color(0x2EE9C37A),
        alignment: Alignment.centerLeft,
        child: reduceMotion
            ? null
            : Transform.translate(
                offset: Offset(_lerp(-1, 2.9, barT) * barWidth * 0.35, 0),
                child: Container(
                  width: barWidth * 0.35,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00E9C37A), _gold, Color(0x00E9C37A)],
                    ),
                  ),
                ),
              ),
      ),
    );

    return Semantics(
      liveRegion: true,
      label: 'Loading',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xB30D060A), Color(0x000D060A)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(44, 26, 44, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    word,
                    Padding(
                      padding: EdgeInsets.only(bottom: fontSize * 0.28),
                      child: dots,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              bar,
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================== helpers
double _lerp(double a, double b, double k) => a + (b - a) * k;

/// CSS-style keyframes: each segment eased with [curve].
class _Keys {
  const _Keys(this.stops);
  final List<(double, double)> stops;

  double at(double p, Curve curve) {
    for (var i = 1; i < stops.length; i++) {
      final (t1, v1) = stops[i];
      if (p <= t1) {
        final (t0, v0) = stops[i - 1];
        if (t1 == t0) return v1;
        final k = curve.transform(((p - t0) / (t1 - t0)).clamp(0.0, 1.0));
        return _lerp(v0, v1, k);
      }
    }
    return stops.last.$2;
  }
}
