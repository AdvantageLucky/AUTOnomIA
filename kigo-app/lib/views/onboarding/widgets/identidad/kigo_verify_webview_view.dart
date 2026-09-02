import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../l10n/app_localizations.dart';

/// Abre enrollmentUrl en un WebView de pantalla completa. Regresa true si
/// detecto el redirect de fin (el flujo del lado de Kigo ya termino, sea
/// exito o falla — el estado real se resuelve con polling despues, ver
/// KigoVerifyServicio), o false si el usuario cerro manualmente antes.
///
/// [urlRedirectFinal] es la URL centinela: cuando el WebView navega ahi, Kigo
/// ya termino y no hace falta seguir mostrando la pagina. La manda el backend
/// (es la misma que le pidio a Kigo como redirect_url) en vez de estar fija
/// aqui — el centinela y lo que Kigo hace tienen que ser el mismo valor.
Future<bool> mostrarKigoVerifyWebview(
  BuildContext context,
  String enrollmentUrl,
  String urlRedirectFinal,
) async {
  final resultado = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => _KigoVerifyWebviewView(
        enrollmentUrl: enrollmentUrl,
        urlRedirectFinal: urlRedirectFinal,
      ),
    ),
  );
  return resultado ?? false;
}

class _KigoVerifyWebviewView extends StatefulWidget {
  final String enrollmentUrl;
  final String urlRedirectFinal;
  const _KigoVerifyWebviewView({
    required this.enrollmentUrl,
    required this.urlRedirectFinal,
  });

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
            // startsWith y no ==: Kigo le pega ?enrollment_id=...&status=...
            if (request.url.startsWith(widget.urlRedirectFinal)) {
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
        title: Text(AppLocalizations.t(context, 'kigo_verify_webview_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
