import 'package:flutter/foundation.dart';

class ResidentWelcomeViewModel extends ChangeNotifier {
  final String nombre;
  final String casaDestino;

  ResidentWelcomeViewModel({required this.nombre, required this.casaDestino});
}
