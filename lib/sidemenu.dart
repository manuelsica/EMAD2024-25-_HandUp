import "package:flutter/material.dart";
import "package:hand_up_interface/consultazione.dart";
import "app_colors.dart";
import "multiplayer_home.dart";
import "classifiche.dart";
import "home.dart";
import 'login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SideMenu extends StatelessWidget {
  final storage = const FlutterSecureStorage();

  SideMenu({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await storage.delete(key: 'access_token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

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
            //Header della sidebar con icona utente, username e password
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple.shade800.withOpacity(0.5),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.purple,
                        child:
                            Icon(Icons.person, size: 35, color: Colors.white),
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
                  //Icona per il logout
                  Positioned(
                    top: 0,
                    right: -10,
                    child: IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _logout(context),
                    ),
                  ),
                ],
              ),
            ),
            //Pulsante per tornare alla home
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title:
                  const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              ),
            ),
            //Pulsante per accedere alla modalità multiplayer
            ListTile(
              leading: const Icon(Icons.sports_esports, color: Colors.white),
              title:
                  const Text('MultiPlayer', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final token = await storage.read(key: 'access_token');
                if (token != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MultiplayerHome()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devi effettuare il login per accedere a Multiplayer')),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
            //Pulsante per accedere alle classifiche
            ListTile(
              leading: const Icon(Icons.star, color: Colors.white),
              title: const Text('Classifiche',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaderboardScreen()),
              ),
            ),
            //Pulsante per accedere allo shop
            ListTile(
              leading: const Icon(Icons.store, color: Colors.white),
              title: const Text('Shop',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MultiplayerHome()),
              ),
            ),
            //Pulsante per accedere alla pagina di consultazione
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.white),
              title: const Text('Consultazione',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Consultazione()),
              ),
            ),
            //Pulsante per accedere alla pagina delle impostazioni
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
