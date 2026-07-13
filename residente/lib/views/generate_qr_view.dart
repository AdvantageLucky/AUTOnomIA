import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../models/invitation_model.dart';

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _reasonController = TextEditingController();
  final _timeController = TextEditingController(text: "12:00");
  final _durationController = TextEditingController(text: "3");
  final DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _reasonController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _generate() {
    if (_formKey.currentState!.validate()) {
      final invitation = context.read<InvitationViewModel>().createInvitation(
        name: _nameController.text,
        company: _companyController.text,
        reason: _reasonController.text,
        date: _selectedDate,
        time: _timeController.text,
        duration: int.parse(_durationController.text),
      );

      _showQrDialog(invitation);
    }
  }

  void _showQrDialog(InvitationModel invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: 280, // Forzar un ancho fijo para el diálogo en Web
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text('Invitación Creada', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
              const SizedBox(height: 12),
              Text(invitation.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
              const SizedBox(height: 8),
              const Text('Código de Acceso QR generado:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              const SizedBox(height: 16),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: invitation.id,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                'ID: ${invitation.id.substring(0, 8)}...',
                style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('ENTENDIDO', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GENERAR INVITACIÓN')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Visitante',
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryOrange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _companyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Empresa / Procedencia',
                      prefixIcon: const Icon(Icons.business_outlined, color: AppTheme.primaryOrange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Ingresa la procedencia' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Motivo de Visita',
                      prefixIcon: const Icon(Icons.info_outline, color: AppTheme.primaryOrange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Ingresa un motivo' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Hora de Entrada',
                            prefixIcon: const Icon(Icons.access_time, color: AppTheme.primaryOrange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duración (Horas)',
                            prefixIcon: const Icon(Icons.timelapse, color: AppTheme.primaryOrange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _generate,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 8),
                        Text('GENERAR CÓDIGO QR'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}