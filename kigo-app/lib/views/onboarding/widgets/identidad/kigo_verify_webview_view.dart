import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// URL centinela: cuando el WebView navega aqui, Kigo Verify ya termino
/// (exito o falla) y no hace falta seguir mostrando la pagina web.
const _urlRedirectFinal = 'https://autonomia.local/kigo-verify-listo';

/// Abre enrollmentUrl en un WebView de pantalla completa. Regresa true si
/// detecto el redirect de fin (el flujo del lado de Kigo ya termino, sea
/// exito o falla — el estado real se resuelve con polling despues, ver
/// KigoVerifyServicio), o false si el usuario cerro manualmente antes.
Future<bool> mostrarKigoVerifyWebview(BuildContext context, String enrollmentUrl) async {
  final resultado = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => _KigoVerifyWebviewView(enrollmentUrl: enrollmentUrl)),
  );
  return resultado ?? false;
}

class _KigoVerifyWebviewView extends StatefulWidget {
  final String enrollmentUrl;
  const _KigoVerifyWebviewView({required this.enrollmentUrl});

  @override
  State<_KigoVerifyWebviewView> createState() => _KigoVerifyWebviewViewState();
}

class _KigoVerifyWebviewViewState extends State<_KigoVerifyWebviewView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith(_urlRedirectFinal)) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.enrollmentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación con Kigo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
