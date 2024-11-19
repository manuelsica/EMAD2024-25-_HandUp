import "package:flutter/material.dart";
import "package:hand_up_interface/main.dart";
import "app_colors.dart";
import "multiplayer_home.dart";
import "main.dart";

class SideMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade900.withOpacity(0.8),
                Colors.purple.shade800.withOpacity(0.8),
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.purple.shade800.withOpacity(0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.person, size: 35, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'USERNAME',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'punti: 1000',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title:
                    const Text('Home', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sports_esports, color: Colors.white),
                title:
                    const Text('MultiPlayer', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MultiplayerHome()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.white),
                title: const Text('Classifiche',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.store, color: Colors.white),
                title: const Text('Shop',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.white),
                title: const Text('Consultazione',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text('Settings',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
  }
}