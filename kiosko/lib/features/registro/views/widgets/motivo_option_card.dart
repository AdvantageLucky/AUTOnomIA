import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/models/motivo_visita_model.dart';

class MotivoOptionCard extends StatelessWidget {
  final MotivoVisitaModel motivo;
  final VoidCallback onTap;

  const MotivoOptionCard({super.key, required this.motivo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1B1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF302A2A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3A2420),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(motivo.icon, color: const Color(0xFFFF542F), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                motivo.label,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8F8989), size: 28),
          ],
        ),
      ),
    );
  }
}
