/* ANIMACIÓN SIMPLE: ROSTROS (HOMBRE/MUJER) ACERCÁNDOSE A LA PANTALLA */

import 'dart:math';
import 'package:flutter/material.dart';

class FaceApproachAnimation extends StatefulWidget {
  const FaceApproachAnimation({super.key});

  @override
  State<FaceApproachAnimation> createState() => _FaceApproachAnimationState();
}

class _FaceApproachAnimationState extends State<FaceApproachAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Widget _manFace = _buildFace(isMan: true);
  late final Widget _womanFace = _buildFace(isMan: false);

  static const Color _skinColor = Color(0xFFF7C9A3);
  static const Color _hairColor = Color(0xFF3E2C20);
  static const Color _eyeColor = Color(0xFF000000);
  static const Color _whiteColor = Color(0xFFFFFFFF);
  static const Color _manJacketColor = Color(0xFF2E3B4E);
  static const Color _manTieColor = Color(0xFF7C5A8C);
  static const Color _womanTopColor = Color(0xFF2FA6D8);

  // Límites de fase como fracción [0,1] del ciclo total: acercarse, sostener,
  // alejarse y desaparecer para cada personaje, con una pausa entre ambos.
  static const double _manApproachEnd = 0.18;
  static const double _manHoldEnd = 0.28;
  static const double _manRecedeEnd = 0.46;
  static const double _gap1End = 0.50;
  static const double _womanApproachEnd = 0.68;
  static const double _womanHoldEnd = 0.78;
  static const double _womanRecedeEnd = 0.96;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _ease(double t) => 0.5 - 0.5 * cos(pi * t);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  ({bool isMan, double scale, double opacity, double liftY}) _computeFrame(double t) {
    if (t < _manApproachEnd) {
      final lt = _ease(t / _manApproachEnd);
      return (isMan: true, scale: _lerp(0.30, 1.0, lt), opacity: _lerp(0.15, 1.0, lt), liftY: _lerp(24, 0, lt));
    }
    if (t < _manHoldEnd) {
      return (isMan: true, scale: 1.0, opacity: 1.0, liftY: 0.0);
    }
    if (t < _manRecedeEnd) {
      final lt = _ease((t - _manHoldEnd) / (_manRecedeEnd - _manHoldEnd));
      return (isMan: true, scale: _lerp(1.0, 0.22, lt), opacity: _lerp(1.0, 0.0, lt), liftY: _lerp(0, -16, lt));
    }
    if (t < _gap1End) {
      return (isMan: true, scale: 0.0, opacity: 0.0, liftY: 0.0);
    }
    if (t < _womanApproachEnd) {
      final lt = _ease((t - _gap1End) / (_womanApproachEnd - _gap1End));
      return (isMan: false, scale: _lerp(0.30, 1.0, lt), opacity: _lerp(0.15, 1.0, lt), liftY: _lerp(24, 0, lt));
    }
    if (t < _womanHoldEnd) {
      return (isMan: false, scale: 1.0, opacity: 1.0, liftY: 0.0);
    }
    if (t < _womanRecedeEnd) {
      final lt = _ease((t - _womanHoldEnd) / (_womanRecedeEnd - _womanHoldEnd));
      return (isMan: false, scale: _lerp(1.0, 0.22, lt), opacity: _lerp(1.0, 0.0, lt), liftY: _lerp(0, -16, lt));
    }
    return (isMan: false, scale: 0.0, opacity: 0.0, liftY: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final f = _computeFrame(_controller.value);
          if (f.opacity <= 0.01 || f.scale <= 0.02) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: f.opacity,
            child: Transform.translate(
              offset: Offset(0, f.liftY),
              child: Transform.scale(
                scale: f.scale,
                child: f.isMan ? _manFace : _womanFace,
              ),
            ),
          );
        },
      ),
    );
  }

  // Busto simple estilo ilustración plana: torso/hombros, cuello, cabeza,
  // cabello, ojos ovalados negros y una sonrisa de "media luna" blanca.
  // El hombre lleva saco y corbata, y su cabello son solo los dos óvalos
  // largos de la frente; la mujer lleva una blusa con cabello largo que cae
  // detrás de todo el cuerpo.
  Widget _buildFace({required bool isMan}) {
    const cx = 115.0;
    const headCy = 100.0;
    const r = 56.0;

    return SizedBox(
      width: 230,
      height: 280,
      child: Stack(
        children: [
          // Cabello largo de la mujer: se dibuja hasta atrás, detrás del torso,
          // y es más ancho que este para que se vea asomando a ambos lados.
          if (!isMan)
            _rect(
              x1: cx - r * 1.65,
              y1: headCy + r * 0.6,
              x2: cx + r * 1.65,
              y2: 280,
              color: _hairColor,
              radius: r * 0.35,
            ),
          _rect(
            x1: cx - r * 1.5,
            y1: headCy + r * 0.85,
            x2: cx + r * 1.5,
            y2: 280,
            color: isMan ? _manJacketColor : _womanTopColor,
            topRadius: r * 0.8,
          ),
          if (isMan) ..._buildCollarAndTie(cx: cx, headCy: headCy, r: r),
          _rect(
            x1: cx - r * 0.18,
            y1: headCy + r * 0.6,
            x2: cx + r * 0.18,
            y2: headCy + r * 0.95,
            color: _skinColor,
            radius: r * 0.08,
          ),
          if (!isMan)
            _rect(x1: cx - r * 1.2, y1: headCy - r * 1.3, x2: cx + r * 1.2, y2: headCy + r * 1.0, color: _hairColor, radius: r * 0.7),
          _circle(cx: cx, cy: headCy, r: r, color: _skinColor),
          ..._buildForeheadHair(isMan: isMan, cx: cx, cy: headCy, r: r),
          for (final side in [-1, 1]) _buildEye(cx: cx, cy: headCy, r: r, side: side),
          _halfMoonMouth(cx: cx, topY: headCy + r * 0.38, width: r * 0.55, fullHeight: r * 0.4, color: _whiteColor),
        ],
      ),
    );
  }

  // Óvalos de cabello sobre la frente. La mujer lleva un solo casquete ancho,
  // con el nacimiento del cabello liso. El hombre lleva dos óvalos largos
  // inclinados que se cruzan arriba y abren hacia abajo una cuña de frente.
  List<Widget> _buildForeheadHair({required bool isMan, required double cx, required double cy, required double r}) {
    if (!isMan) {
      return [
        _oval(cx: cx, cy: cy - r * 0.80, width: r * 1.75, height: r * 1.05, color: _hairColor),
      ];
    }
    return [
      for (final side in [-1, 1])
        _oval(
          cx: cx + side * r * 0.42,
          cy: cy - r * 0.58,
          width: r * 1.24,
          height: r * 0.74,
          color: _hairColor,
          angleDeg: side * 45.0,
        ),
    ];
  }

  List<Widget> _buildCollarAndTie({required double cx, required double headCy, required double r}) {
    return [
      Positioned(
        left: cx - r * 0.36,
        top: headCy + r * 0.68,
        child: Transform.rotate(
          angle: 35 * pi / 180,
          alignment: Alignment.topRight,
          child: Container(width: r * 0.4, height: r * 0.16, color: _whiteColor),
        ),
      ),
      Positioned(
        left: cx - r * 0.04,
        top: headCy + r * 0.68,
        child: Transform.rotate(
          angle: -35 * pi / 180,
          alignment: Alignment.topLeft,
          child: Container(width: r * 0.4, height: r * 0.16, color: _whiteColor),
        ),
      ),
      _rect(
        x1: cx - r * 0.09,
        y1: headCy + r * 0.85,
        x2: cx + r * 0.09,
        y2: headCy + r * 1.6,
        color: _manTieColor,
        radius: r * 0.04,
      ),
    ];
  }

  Widget _buildEye({required double cx, required double cy, required double r, required int side}) {
    final ex = cx + side * r * 0.30;
    final eyeY = cy - r * 0.02;
    return _oval(cx: ex, cy: eyeY, width: r * 0.20, height: r * 0.28, color: _eyeColor);
  }

  // Sonrisa en forma de media luna horizontal: la mitad inferior de un óvalo.
  Widget _halfMoonMouth({required double cx, required double topY, required double width, required double fullHeight, required Color color}) {
    final halfHeight = fullHeight / 2;
    return Positioned(
      left: cx - width / 2,
      top: topY,
      child: SizedBox(
        width: width,
        height: halfHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              top: -halfHeight,
              child: Container(
                width: width,
                height: fullHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.all(Radius.elliptical(width / 2, halfHeight)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rect({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required Color color,
    double radius = 0,
    double? topRadius,
  }) {
    return Positioned(
      left: x1,
      top: y1,
      child: Container(
        width: x2 - x1,
        height: y2 - y1,
        decoration: BoxDecoration(
          color: color,
          borderRadius: topRadius != null
              ? BorderRadius.only(topLeft: Radius.circular(topRadius), topRight: Radius.circular(topRadius))
              : BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _circle({required double cx, required double cy, required double r, required Color color}) {
    return Positioned(
      left: cx - r,
      top: cy - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _oval({
    required double cx,
    required double cy,
    required double width,
    required double height,
    required Color color,
    double angleDeg = 0,
  }) {
    final Widget oval = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.elliptical(width / 2, height / 2)),
      ),
    );
    return Positioned(
      left: cx - width / 2,
      top: cy - height / 2,
      child: angleDeg == 0 ? oval : Transform.rotate(angle: angleDeg * pi / 180, child: oval),
    );
  }
}
