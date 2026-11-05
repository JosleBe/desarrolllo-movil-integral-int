import 'package:flutter/material.dart';

/// Envuelve un widget y le da un efecto de "hundido" al presionarlo:
/// escala suavemente hacia abajo mientras está presionado y vuelve al
/// soltarse. Da una sensación táctil agradable a botones y tarjetas.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.scale = 0.96,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Escala mínima al mantener presionado (0.96 = 4% más pequeño).
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
