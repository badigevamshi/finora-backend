import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionScreen extends StatefulWidget {
  final String token;

  const TransactionScreen({super.key, required this.token});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {

  List transactions = [];
  bool isLoading = true;
  String message = "";

  static const String baseUrl = "https://finora-backend-xiys.onrender.com";

  Future<void> loadTransactions() async {

    try {

      final response = await http.get(
        Uri.parse("$baseUrl/transactions"),
        headers: {
          "Authorization": "Bearer ${widget.token}"
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {

        Map<String, dynamic> data = {};

        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body);
        }

        setState(() {
          transactions = data["transactions"] ?? [];
          isLoading = false;
        });

      } else {

        setState(() {
          message = "Failed to load transactions";
          isLoading = false;
        });

      }

    } catch (e) {

      if (!mounted) return;

      setState(() {
        message = "Unable to connect to server";
        isLoading = false;
      });

    }

  }

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Transaction History"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: isLoading
            ? const Center(child: CircularProgressIndicator())

            : message.isNotEmpty
                ? Center(
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )

                : transactions.isEmpty
                    ? const Center(
                        child: Text(
                          "No transactions found",
                          style: TextStyle(fontSize: 16),
                        ),
                      )

                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {

                          final txn = transactions[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,

                            child: ListTile(

                              leading: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.indigo,
                              ),

                              title: Text(
                                "₹${txn["amount"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const SizedBox(height: 4),

                                  Text("From: ${txn["sender"]}"),
                                  Text("To: ${txn["receiver"]}"),

                                  if (txn["timestamp"] != null)
                                    Text(
                                      "Time: ${txn["timestamp"]}",
                                      style: const TextStyle(fontSize: 12),
                                    ),

                                ],
                              ),

                            ),
                          );

                        },
                      ),
      ),
    );
  }
}