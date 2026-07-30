/* VISTA PARA SELECCIONAR EL MOTIVO DE VISITA */
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/models/motivo_visita_model.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/motivo_option_card.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';

class MotivoVisitaView extends StatelessWidget {
  const MotivoVisitaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171313),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 42, right: 42, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIndicator(currentStep: 2, totalSteps: 5),
              const SizedBox(height: 42),
              const Text(
                '¿Cuál es el motivo de tu visita?',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              ...motivosVisita.map(
                (m) => MotivoOptionCard(
                  motivo: m,
                  onTap: () => Navigator.pop(context, m.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
