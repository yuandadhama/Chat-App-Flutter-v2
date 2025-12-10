import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/popup_message.dart'; // <-- penting

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();

  bool isLoading = false;

  void register() async {
    // cek password match
    if (_pwController.text != _confirmPwController.text) {
      _showError("Passwords do not match!");
      return;
    }

    setState(() => isLoading = true);

    try {
      final auth = AuthService();
      await auth.signUpWithEmailPassword(
        _emailController.text.trim(),
        _pwController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(_friendlyMessage(e.toString()));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _friendlyMessage(String error) {
    if (error.contains("email-already-in-use")) {
      return "Email already registered!";
    }
    if (error.contains("weak-password")) {
      return "Password is too weak!";
    }
    if (error.contains("invalid-email")) {
      return "Email is not valid!";
    }
    return "Something went wrong.";
  }

  void _showError(String msg) {
    PopupMessage.show(
      context,
      message: msg,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F3F5),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.person_add,
                  size: 70, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                "Create your account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 30),
              MyTextfield(
                hintText: "Email",
                obscureText: false,
                controller: _emailController,
              ),
              MyTextfield(
                hintText: "Password",
                obscureText: true,
                controller: _pwController,
              ),
              MyTextfield(
                hintText: "Confirm Password",
                obscureText: true,
                controller: _confirmPwController,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : MyButton(text: "Register", onTap: register),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Login now",
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
