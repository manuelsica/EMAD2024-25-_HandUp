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
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient firstPlaceGradient = LinearGradient(
    colors: [Color.fromARGB(255, 74, 234, 255),
            Color.fromARGB(255, 152, 120, 240),
            Color.fromARGB(255, 207, 42, 180),
            Color.fromARGB(255, 238, 44, 167),
            Color.fromARGB(255, 251, 105, 158),
            Color.fromARGB(255, 254, 248, 76),
      ],
      stops: [0.0, 0.5, 0.75, 0.88, 0.94, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Shader getTextShader(screenWidth, screenHeight, text, textStyle){

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    return textGradient.createShader(Rect.fromLTWH(0, 0, textWidth, textHeight));
  }

  static const LinearGradient containerBorderGradient = LinearGradient(
    colors: [containerBorderColor4, containerBorderColor5],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Widget gradientText(String text, double fontSize) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => textGradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static Widget firstPlaceGradientText(String text, double fontSize) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => firstPlaceGradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
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
          gradient.createShader(Rect.fromLTWH(0, 0, size.width + 10, size.height));

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
