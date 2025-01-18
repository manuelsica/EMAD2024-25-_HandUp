// lib/registration.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'home.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "backend_config.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import "selezione_gioco.dart";
import "main.dart";
import "animated_button.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const RegistrationPage());
  });
}

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const RegistrationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final FocusNode _textFieldFocusNodeName = FocusNode();
  final FocusNode _textFieldFocusNodeMail = FocusNode();
  final FocusNode _textFieldFocusNodePass = FocusNode();
  final FocusNode _textFieldFocusNodePass2 = FocusNode();

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

  Future<void> _register() async {
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Per favore, compila tutti i campi.', isError: true);
      setState(() => _isLoading = false);
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Le password non corrispondono.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final emailRegex = RegExp(r"[^@]+@[^@]+\.[^@]+");
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Email non valida.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse(BackendConfig.registerUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Leggiamo i campi dal server
        final accessToken = responseData['access_token'];
        final userId = responseData['user_id']; // <-- user_id
        final points = responseData['points'] ?? 0;
        final returnedUsername = responseData['username'] ?? username;

        print('Access Token Received: $accessToken');
        print('Username Received: $returnedUsername');
        print('Points Received: $points');
        print('User ID Received: $userId');

        if (accessToken != null && userId != null) {
          await storage.write(key: 'access_token', value: accessToken);
          await storage.write(key: 'user_id', value: userId.toString());
          await storage.write(key: 'username', value: returnedUsername);
          await storage.write(key: 'points', value: points.toString());

          _showMessage('Registrazione avvenuta con successo.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GameSelectionScreen()),
          );
        } else {
          _showMessage('Token o ID utente non ricevuti dal server.',
              isError: true);
        }
      } else {
        _showMessage(
            responseData['error'] ?? 'Errore durante la registrazione.',
            isError: true);
      }
    } catch (error) {
      print('Errore di connessione: $error');
      _showMessage('Errore di connessione al server.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _textFieldFocusNodeMail.dispose();
    _textFieldFocusNodePass.dispose();
    _textFieldFocusNodePass2.dispose();
    _textFieldFocusNodeName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _textFieldFocusNodeMail.unfocus();
        _textFieldFocusNodePass.unfocus();
        _textFieldFocusNodePass2.unfocus();
        _textFieldFocusNodeName.unfocus();
      }, // Tocca sfondo -> chiude tastiera
      child: WillPopScope(
        onWillPop: () async {
          if (_allowPop) {
            // Reset della variabile e consentiamo il pop
            _allowPop = false;
            return true;
          }
          // Blocchiamo il pop (impediamo lo swipe back)
          return false;
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: AppColors.gradientText('Registrazione', screenWidth * 0.05),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
      
                      // Username
                      Container(
                        width: screenWidth * 0.8,
                        margin: EdgeInsets.only(top: screenHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          focusNode: _textFieldFocusNodeName,
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Username',
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
      
                      // Conferma Password
                      Container(
                        width: screenWidth * 0.8,
                        margin: EdgeInsets.only(top: screenHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          focusNode: _textFieldFocusNodePass2,
                          controller: _confirmPasswordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Conferma Password',
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
      
                      // Bottone Registrati
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
                                  Color.fromARGB(110, 140, 53, 232)
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
                              onPressed: _isLoading ? null : _register,
                              child: _isLoading
                                  ? SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Text(
                                      'Registrati',
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
