import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:local_auth/local_auth.dart';

class SendMoneyScreen extends StatefulWidget {
  final String token;

  const SendMoneyScreen({super.key, required this.token});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {

  final receiverController = TextEditingController();
  final amountController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  static const String baseUrl = "https://finora-backend-xiys.onrender.com";

  String message = "";
  bool isLoading = false;
  bool isSuccess = false;

  Future<bool> authenticateUser() async {
    try {

      bool isDeviceSupported = await auth.isDeviceSupported();
      bool canCheckBiometrics = await auth.canCheckBiometrics;

      if (!isDeviceSupported || !canCheckBiometrics) {
        return false;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: "Authenticate to send money",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return authenticated;

    } catch (e) {
      return false;
    }
  }

  Future<void> sendMoney() async {

    String receiver = receiverController.text.trim();
    String amountText = amountController.text.trim();

    if (receiver.isEmpty || amountText.isEmpty) {
      setState(() {
        message = "Please fill all fields";
        isSuccess = false;
      });
      return;
    }

    double? amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() {
        message = "Enter a valid amount";
        isSuccess = false;
      });
      return;
    }

    bool authenticated = await authenticateUser();

    if (!authenticated) {
      setState(() {
        message = "Authentication failed";
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
        Uri.parse("$baseUrl/transactions/send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
        body: jsonEncode({
          "receiver": receiver,
          "amount": amount
        }),
      );

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }

      if (!mounted) return;

      if (response.statusCode == 200) {

        setState(() {
          message = data["message"] ?? "Money sent successfully";
          isSuccess = true;
        });

        receiverController.clear();
        amountController.clear();

      } else {

        setState(() {
          message = data["detail"] ?? "Transaction failed";
          isSuccess = false;
        });

      }

    } catch (e) {

      if (!mounted) return;

      setState(() {
        message = "Unable to connect to server";
        isSuccess = false;
      });

    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    receiverController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Send Money"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: receiverController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Receiver Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: isLoading ? null : sendMoney,

                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Send Money",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }
}