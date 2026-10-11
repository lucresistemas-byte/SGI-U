import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fondo del área de contenido de una sección. El menú lateral, el AppBar y
/// el drawer los pone AppShell, una sola vez para toda la app.
class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisFondo,
      body: body,
    );
  }
}
