import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceScreen extends StatefulWidget {
  final String token;

  const VoiceScreen({super.key, required this.token});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  static const String baseUrl = "https://finora-backend-xiys.onrender.com";

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isListening = false;
  bool _speechEnabled = false;

  String _spokenText = "Tap the mic and speak";
  String _response = "";

  String _selectedLanguage = "en-US";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0.9, end: 1.2).animate(_controller);

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == "done") {
          setState(() {
            _isListening = false;
          });
          _controller.stop();
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        _controller.stop();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> speak(String text) async {
    await _tts.setLanguage(_selectedLanguage);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> _toggleListening() async {

    if (!_speechEnabled) return;

    if (!_isListening) {

      setState(() {
        _isListening = true;
        _spokenText = "Listening...";
      });

      _controller.repeat(reverse: true);

      await _speech.listen(
        localeId: _selectedLanguage,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {

          setState(() {
            _spokenText = result.recognizedWords;
          });

          if (result.finalResult) {

            _speech.stop();
            _controller.stop();

            setState(() {
              _isListening = false;
            });

            if (_spokenText.trim().isNotEmpty) {
              _sendToBackend(_spokenText);
            }
          }
        },
      );

    } else {

      await _speech.stop();
      _controller.stop();

      setState(() {
        _isListening = false;
      });

    }
  }

  Future<void> _sendToBackend(String text) async {

    try {

      final response = await http.post(
        Uri.parse("$baseUrl/voice/voice-command"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        String message = data["message"] ?? "Command processed";

        setState(() {
          _response = message;
        });

        await speak(message);

      } else {

        final data = jsonDecode(response.body);

        String message = data["detail"] ?? "Server error";

        setState(() {
          _response = message;
        });

        await speak(message);
      }

    } catch (e) {

      setState(() {
        _response = "Unable to connect to server";
      });

      await speak("Unable to connect to server");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Finora AI Voice Banking"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Finora Voice Assistant",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Tap the microphone and speak your command",
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 30),

              const Text(
                "Your Voice Command",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _spokenText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              const Text(
                "Finora Response",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _response,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              DropdownButton<String>(
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(value: "en-US", child: Text("English")),
                  DropdownMenuItem(value: "hi-IN", child: Text("Hindi")),
                  DropdownMenuItem(value: "te-IN", child: Text("Telugu")),
                  DropdownMenuItem(value: "ta-IN", child: Text("Tamil")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {

                    return Transform.scale(
                      scale: _isListening ? _animation.value : 1,

                      child: Container(
                        width: 90,
                        height: 90,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.red : Colors.blue,
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha:0.6),
                                    blurRadius: 25,
                                    spreadRadius: 6,
                                  )
                                ]
                              : [],
                        ),

                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}