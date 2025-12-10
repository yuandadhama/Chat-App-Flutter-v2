import 'package:flutter/material.dart';
import 'package:smart_daily_planner/services/auth/auth_service.dart';

import '../components/my_button.dart';
import '../components/my_textfield.dart';
import 'register_page.dart';
import '../components/popup_message.dart'; // ⬅ penting!

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  LoginPage({super.key});

  void login(BuildContext context) async {
    final auth = AuthService();

    try {
      await auth.signInWithEmailPassword(
        _emailController.text.trim(),
        _pwController.text.trim(),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showFriendlyError(context, e.toString());
    }
  }

  void _showFriendlyError(BuildContext context, String error) {
    String message = "Something went wrong";

    if (error.contains("invalid-email")) message = "Email not valid!";
    if (error.contains("user-not-found")) message = "No account found!";
    if (error.contains("wrong-password")) message = "Incorrect password!";
    if (error.contains("user-disabled")) message = "This account is disabled.";

    PopupMessage.show(
      context,
      message: message,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F3F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 35),

              // ICON
              Icon(
                Icons.message,
                size: 70,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),

              // WELCOME TEXT
              Text(
                "Welcome back 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You've been missed!",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              // EMAIL
              MyTextfield(
                hintText: "Email",
                obscureText: false,
                controller: _emailController,
              ),

              const SizedBox(height: 15),

              // PASSWORD
              MyTextfield(
                hintText: "Password",
                obscureText: true,
                controller: _pwController,
              ),

              const SizedBox(height: 22),

              // LOGIN BUTTON
              MyButton(
                text: "Login",
                onTap: () => login(context),
              ),

              const SizedBox(height: 25),

              // REGISTER TEXT
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Not a member?",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      "Register now",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
