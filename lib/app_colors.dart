import "package:flutter/material.dart";

class AppColors {
  //Solid colors
  static const Color backgroundColor = Color.fromARGB(255, 5, 14, 55);
  static const Color textColor1 = Color.fromARGB(255, 255, 0, 208);
  static const Color textColor2 = Color.fromARGB(190, 198, 27, 220);
  static const Color textColor3 = Color.fromARGB(255, 27, 105, 255);
  static const Color containerBorderColor4 = Color.fromARGB(255, 115, 0, 101);
  static const Color containerBorderColor5 = Color.fromARGB(255, 83, 0, 171);

  static const Color containerOpaqueColor = Color.fromARGB(95, 64, 23, 108);


  //Gradient colors
  static const LinearGradient textGradient = LinearGradient(
    colors: [textColor1, textColor2, textColor3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Shader getTextShader(screenWidth, screenHeight){
    return textGradient.createShader(Rect.fromLTWH(0, 0, screenWidth * 0.85, 70.0));
  }

  static const LinearGradient containerBorderGradient = LinearGradient(
    colors: [containerBorderColor4, containerBorderColor5],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}

class GradientIconPainter extends CustomPainter {
  final IconData icon;
  final Gradient gradient;

  GradientIconPainter({required this.icon, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size.height,
          fontFamily: icon.fontFamily,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
