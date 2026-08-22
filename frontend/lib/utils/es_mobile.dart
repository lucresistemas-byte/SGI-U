import 'package:flutter/material.dart';

bool esMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 900;
}
