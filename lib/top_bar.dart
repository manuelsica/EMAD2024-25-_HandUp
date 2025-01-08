import 'package:flutter/material.dart';
import "app_colors.dart";

class TopBar extends StatelessWidget {
  //Variabili per il contenuto della top bar
  final String username;
  final int points;
  //Variabili per decidere se mostrare il menu e l'utente
  final bool showMenu;
  final bool showUser;

  const TopBar({
    Key? key,
    required this.username,
    required this.points,
    required this.showMenu,
    required this.showUser,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showMenu)
            Builder(builder: (BuildContext context) {
              return IconButton(
                icon: CustomPaint(
                  size: Size(24, 24),
                  painter: GradientIconPainter(
                    icon: Icons.menu,
                    gradient: AppColors.textGradient,
                  ),
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            })
          else
            const SizedBox(width: 48),

          if (showUser)
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'punti: $points',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

