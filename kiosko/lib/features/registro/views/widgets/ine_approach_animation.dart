/* ANIMACIÓN SIMPLE: TARJETA TIPO CREDENCIAL ACERCÁNDOSE A LA PANTALLA */

import 'package:flutter/material.dart';

class IneApproachAnimation extends StatefulWidget {
  const IneApproachAnimation({super.key});

  @override
  State<IneApproachAnimation> createState() => _IneApproachAnimationState();
}

class _IneApproachAnimationState extends State<IneApproachAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _liftY;

  static const Color _accentRed = Color(0xFFA23B3B);
  static const Color _cardColor = Color(0xFFEFE7D6);
  static const Color _titleGray = Color(0xFF616161); // gris oscuro: posiciones de título
  static const Color _dataGray = Color(0xFFBDBDBD); // gris claro: posiciones de dato
  static const Color _headerBandColor = Color(0xFF9E9E9E); // más claro que el gris oscuro, más oscuro que la tarjeta

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(curve);
    _opacity = Tween<double>(begin: 0.35, end: 1.0).animate(curve);
    _liftY = Tween<double>(begin: 26, end: 0).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _liftY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
          );
        },
        child: _buildCard(),
      ),
    );
  }

  // Tarjeta simplificada inspirada en el formato de una credencial INE:
  // misma proporción y distribución de campos, pero sin escudo nacional,
  // sin holograma, sin texto y con los campos representados como barras.
  Widget _buildCard() {
    const cardWidth = 260.0;
    const cardHeight = cardWidth / 1.586;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB9AE95), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja izquierda: alusión al borde rojo decorativo, sin el patrón real.
              Container(width: 5, color: _accentRed),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderBand(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBand() {
    return Container(
      width: double.infinity,
      height: 28,
      color: _headerBandColor,
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFDCD2B7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFB9AE95)),
            ),
            child: const Icon(Icons.person, color: Color(0xFF8B7E96), size: 36),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _field(titleWidth: 38, valueWidth: double.infinity), // NOMBRE
                _field(titleWidth: 56, valueWidth: double.infinity), // DOMICILIO
                _field(titleWidth: 86, valueWidth: 120), // CLAVE DE ELECTOR
                _field(titleWidth: 32, valueWidth: 130), // CURP
                Row(
                  children: [
                    _miniField(),
                    _miniField(),
                    _miniField(),
                    _miniField(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cada campo = una barra corta (título, gris oscuro) sobre una barra
  // más larga (dato, gris claro), en vez del texto real.
  Widget _field({required double titleWidth, required double valueWidth}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _bar(width: titleWidth, height: 5, color: _titleGray),
        const SizedBox(height: 3),
        _bar(width: valueWidth, height: 7, color: _dataGray),
      ],
    );
  }

  Widget _miniField() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(width: 24, height: 4, color: _titleGray),
            const SizedBox(height: 3),
            _bar(width: double.infinity, height: 6, color: _dataGray),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
