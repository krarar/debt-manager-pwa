import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 900;
}
