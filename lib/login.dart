// lib/login.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'home.dart';
import 'registration.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "backend_config.dart";
import 'package:provider/provider.dart';
import 'socket_service.dart';
import "main.dart";
import "selezione_gioco.dart";
import "animated_button.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const LoginPage());
  });
}

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _textFieldFocusNodeMail = FocusNode();
  final FocusNode _textFieldFocusNodePass = FocusNode();

  final storage = FlutterSecureStorage(); 

  bool _isLoading = false;
  
  // Variabile per controllare se consentire il pop
  bool _allowPop = false;

  void _showMessage(String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isError ? 'Errore' : 'Successo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Per favore, inserisci email e password.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final emailRegex = RegExp(r"[^@]+@[^@]+\.[^@]+");
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Email non valida.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse(BackendConfig.loginUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          final token   = responseData['access_token'];
          final userId  = responseData['user_id'];    // <-- Leggiamo l'ID utente
          final username= responseData['username'];
          final points  = responseData['points'];

          if (token != null && userId != null && username != null && points != null) {
            // Salviamo TUTTI i dati (incluso user_id)
            await storage.write(key: 'access_token', value: token);
            await storage.write(key: 'user_id',      value: userId.toString());
            await storage.write(key: 'username',     value: username);
            await storage.write(key: 'points',       value: points.toString());

            _showMessage('Login effettuato con successo.');

            // Avvia la connessione Socket.IO
            final socketService = Provider.of<SocketService>(context, listen: false);
            await socketService.connect();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GameSelectionScreen()),
            );
          } else {
            _showMessage('Dati utente mancanti nella risposta del server.', isError: true);
          }
        } else {
          _showMessage('Risposta del server non valida.', isError: true);
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          _showMessage(responseData['error'] ?? 'Errore durante il login.', isError: true);
        } catch (e) {
          _showMessage('Errore durante il login. Risposta del server non valida.', isError: true);
        }
      }
    } catch (error) {
      print('Error during login: $error');
      _showMessage('Errore di connessione al server.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _textFieldFocusNodeMail.dispose();
    _textFieldFocusNodePass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _textFieldFocusNodeMail.unfocus();
        _textFieldFocusNodePass.unfocus();
      }, // Tocca sfondo -> chiude tastiera
      child: WillPopScope(
        onWillPop: () async {
          if (_allowPop) {
            // Reset the flag and allow pop
            _allowPop = false;
            return true;
          }
          // Blocca il pop (impedisce lo swipe back)
          return false;
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: AppColors.gradientText('Login', screenWidth * 0.05),
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: CustomPaint(
                size: const Size(45, 45),
                painter: GradientIconPainter(
                  icon: Icons.arrow_back,
                  gradient: AppColors.textGradient,
                ),
              ),
              onPressed: () {
                setState(() {
                  _allowPop = true;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );

              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      // Logo
                      Container(
                        margin: EdgeInsets.only(
                          top: screenHeight * 0.08,
                          bottom: screenHeight * 0.01,
                        ),
                        child: Image.asset(
                          'assets/logo_handup.png',
                          width: screenWidth * 1,
                          height: screenHeight * 0.35,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Icon(Icons.error,
                                size: screenWidth * 0.8, color: Colors.red);
                          },
                        ),
                      ),
                      // Email
                      Container(
                        width: screenWidth * 0.8,
                        margin: EdgeInsets.only(top: screenHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          focusNode: _textFieldFocusNodeMail,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: screenWidth * 0.04,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      // Password
                      Container(
                        width: screenWidth * 0.8,
                        margin: EdgeInsets.only(top: screenHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          focusNode: _textFieldFocusNodePass,
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: screenWidth * 0.04,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      // Bottone Login
                      AnimatedButton(
                        onPressed: () {},
                        isLocked: false,
                        child: Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.025),
                          width: screenWidth * 0.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textColor1.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(110, 214, 57, 196),
                                  Color.fromARGB(110, 255, 0, 208),
                                  Color.fromARGB(110, 140, 53, 232),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Text(
                                      'Entra',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Link per registrarsi
                      SizedBox(height: screenHeight * 0.02),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RegistrationPage()),
                          );
                        },
                        child: AppColors.gradientText(
                          'Non hai un account? Registrati',
                          screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}