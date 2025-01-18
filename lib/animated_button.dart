//Classe per astrarre l'animazione dei bottoni
//NON ANCORA IMPLEMENTATA

import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child; // The content of the button (text, icon, etc.)
  final VoidCallback onPressed; // Action when the button is pressed
  final Duration duration; // Duration of the animation
  final double scaleFactor; // How much the button scales when pressed
  final BoxDecoration? decoration; // Optional custom decoration for the button
  final EdgeInsetsGeometry padding; // Padding inside the button
  final bool isLocked; // If the button is locked

  const AnimatedButton({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.isLocked,
    this.duration = const Duration(milliseconds: 50),
    this.scaleFactor = 0.80,
    this.decoration,
    this.padding = const EdgeInsets.all(1.0),
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(_controller);
    _controller.addStatusListener((status) {
      if(status == AnimationStatus.completed){
        widget.onPressed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => {
        if (!widget.isLocked) _controller.forward(),},
      onTapUp: (_) {
        if (!widget.isLocked){
          _controller.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () => { if (!widget.isLocked) _controller.reverse(),},
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: widget.decoration ??
              BoxDecoration(
                color: Colors.transparent, // Default color
                borderRadius: BorderRadius.circular(10), // Default radius
              ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
