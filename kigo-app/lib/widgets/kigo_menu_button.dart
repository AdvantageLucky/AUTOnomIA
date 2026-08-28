import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Destinos que no ocupan pestaña en el bottom nav y se llegan desde el menú
/// de la barra superior.
enum _OpcionMenu { invitaciones, ajustes }

/// Menú desplegable de la esquina superior derecha.
///
/// Vive en el `AppBar` del shell y no en cada pestaña: así el acceso a
/// invitaciones y ajustes está siempre en el mismo lugar, se navegue donde se
/// navegue.
class KigoMenuButton extends StatelessWidget {
  const KigoMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OpcionMenu>(
      icon: const Icon(Icons.menu, color: AppTheme.primaryOrange),
      // 24 es el tamaño con el que BottomNavigationBar dibuja sus iconos, para
      // que el de arriba pese lo mismo que los de abajo.
      iconSize: 24,
      tooltip: 'Más opciones',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      onSelected: (opcion) {
        switch (opcion) {
          case _OpcionMenu.invitaciones:
            Navigator.pushNamed(context, '/my_invitations');
          case _OpcionMenu.ajustes:
            Navigator.pushNamed(context, '/settings');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _OpcionMenu.invitaciones,
          child: _Opcion(
            icono: Icons.mail_outline,
            color: AppTheme.blue,
            texto: 'Mis invitaciones',
          ),
        ),
        PopupMenuItem(
          value: _OpcionMenu.ajustes,
          child: _Opcion(icono: Icons.settings_outlined, texto: 'Ajustes'),
        ),
      ],
    );
  }
}

/// Un Row y no un ListTile: dentro del menú el ancho está acotado, y el
/// ListTile parte "Mis invitaciones" en dos renglones.
class _Opcion extends StatelessWidget {
  const _Opcion({required this.icono, required this.texto, this.color});

  final IconData icono;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 20, color: color ?? Theme.of(context).iconTheme.color),
        const SizedBox(width: 14),
        // Flexible y no Text a secas: el ancho del menú está acotado, y con
        // una escala de fuente grande la etiqueta debe recortarse, no
        // desbordar la fila.
        Flexible(
          child: Text(texto, softWrap: false, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
