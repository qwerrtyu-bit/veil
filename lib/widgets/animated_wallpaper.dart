import 'package:flutter/material.dart';

class AnimatedWallpaper extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final VoidCallback? onTimeChanged;

  const AnimatedWallpaper({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFFFF9A9E),
      Color(0xFFFAD0C4),
    ],
    this.onTimeChanged,
  });

  @override
  State<AnimatedWallpaper> createState() => _AnimatedWallpaperState();
}

class _AnimatedWallpaperState extends State<AnimatedWallpaper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: widget.colors[0],
      end: widget.colors.length > 1 ? widget.colors[1] : widget.colors[0],
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}