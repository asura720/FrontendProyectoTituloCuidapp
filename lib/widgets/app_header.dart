import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A56DB), Color(0xFF1E40AF)],
);

/// Barra superior unificada (sliver) para las pestañas con CustomScrollView.
/// Misma altura, color y estilo en todas.
SliverAppBar sectionSliverAppBar(String title, {List<Widget>? actions}) {
  return SliverAppBar(
    pinned: true,
    elevation: 2,
    backgroundColor: const Color(0xFF1A56DB),
    foregroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    centerTitle: false,
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    actions: actions,
    flexibleSpace: const DecoratedBox(
      decoration: BoxDecoration(gradient: _gradient),
    ),
  );
}

/// Barra superior unificada (AppBar normal) para pantallas sin sliver.
PreferredSizeWidget gradientAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    elevation: 2,
    backgroundColor: const Color(0xFF1A56DB),
    foregroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    centerTitle: false,
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    actions: actions,
    flexibleSpace: const DecoratedBox(
      decoration: BoxDecoration(gradient: _gradient),
    ),
  );
}
