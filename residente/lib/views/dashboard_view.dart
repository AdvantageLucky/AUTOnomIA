import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Crear Invitación',
        'icon': Icons.qr_code_2,
        'hoverIcon': Icons.qr_code_scanner,
        'route': '/generate',
        'animateType': 'scale',
      },
      {
        'title': 'Mis Invitaciones',
        'icon': Icons.mail,
        'hoverIcon': Icons.drafts,
        'route': '/my_invitations',
        'animateType': 'mail',
      },
      {
        'title': 'Accesos',
        'icon': Icons.door_sliding_outlined,
        'hoverIcon': Icons.door_sliding,
        'route': null,
        'animateType': 'scale',
      },
      {
        'title': 'Historial',
        'icon': Icons.history,
        'hoverIcon': Icons.update,
        'route': null,
        'animateType': 'scale',
      },
      {
        'title': 'Mi PIN',
        'icon': Icons.lock_outline,
        'hoverIcon': Icons.lock_open,     
        'route': '/my_pin',
        'animateType': 'scale',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('KIGO DASHBOARD', style: TextStyle(letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primaryOrange),
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryOrange,
                            child: Icon(Icons.person, size: 35, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenido, ${auth.currentUserName}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('Residencial Kigo / Usuario Activo', style: TextStyle(color: AppTheme.textGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: AppTheme.textGrey, size: 24),
                          hoverColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Configuración estará disponible en la siguiente etapa.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return AnimatedMenuCard(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedMenuCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const AnimatedMenuCard({super.key, required this.item});

  @override
  State<AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<AnimatedMenuCard> {
  bool _isHovered = false;

  void _showPinDialog(BuildContext context, String pin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.lock_outline, color: AppTheme.primaryOrange, size: 48),
              const SizedBox(height: 16),
              const Text('Mi PIN de Acceso', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              const Text('Usa este código para ingresar a la propiedad:', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.5), width: 1.5)
                ),
                child: Text(
                  pin,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange, letterSpacing: 8),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    double scale = 1.0;
    if (_isHovered) {
      scale = item['animateType'] == 'scale' || item['animateType'] == 'mail' ? 1.06 : 1.03;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Card(
          child: InkWell(
            onTap: () async {
              if (item['route'] == '/my_pin') {
                final authVM = context.read<AuthViewModel>();
                final pin = await authVM.generateUniquePin();
                if (context.mounted) {
                  _showPinDialog(context, pin);
                }
              } else if (item['route'] != null) {
                Navigator.pushNamed(context, item['route']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['title']} estará disponible en la siguiente etapa.')),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    _isHovered ? item['hoverIcon'] : item['icon'],
                    key: ValueKey(_isHovered),
                    size: _isHovered && item['animateType'] == 'scale' ? 40 : 36, 
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}