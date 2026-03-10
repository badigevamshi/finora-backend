import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isSuccess = false;
  String message = "";

  static const String baseUrl = "https://finora-backend-xiys.onrender.com";

  Future<void> register() async {

    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        message = "Please enter username and password";
        isSuccess = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = "";
    });

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint("Register Status: ${response.statusCode}");
      debugPrint("Register Response: ${response.body}");

      if (!mounted) return;

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }

      if (response.statusCode == 200) {

        setState(() {
          message = "Registration successful!";
          isSuccess = true;
        });

        usernameController.clear();
        passwordController.clear();

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.pop(context);

      } else {

        setState(() {
          message = data["detail"] ?? "Registration failed";
          isSuccess = false;
        });

      }

    } catch (e) {

      if (!mounted) return;

      setState(() {
        message = "Unable to connect to server";
        isSuccess = false;
      });

      debugPrint("Register error: $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: isLoading ? null : register,

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Register",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }
}