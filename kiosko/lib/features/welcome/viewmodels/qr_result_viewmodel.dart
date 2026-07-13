import 'package:flutter/material.dart';

class QrResultViewModel extends ChangeNotifier {
  final String scannedValue;

  QrResultViewModel({required this.scannedValue});
}
