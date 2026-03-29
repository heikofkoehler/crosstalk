import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const CrosstalkApp());
}

class CrosstalkApp extends StatelessWidget {
  const CrosstalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crosstalk AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111827),
        primaryColor: Colors.blueAccent,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ApiService _apiService = ApiService(baseUrl: ''); 
  
  bool _isListening = false;
  String _lastWords = '';
  final List<Map<String, String>> _messages = [];
  String _svgContent = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"></svg>';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setLanguage("es-ES");
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _sendMessage(_lastWords);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage(String text) async {
    setState(() {
      _messages.add({'sender': 'You', 'text': text});
    });

    try {
      final response = await _apiService.sendChat(text, 'Beginner');
      setState(() {
        _messages.add({'sender': 'AI (Spanish)', 'text': response['text']});
        _svgContent = _wrapInSvg(response['svg_draw']);
      });
      _flutterTts.speak(response['text']);
    } catch (e) {
      print("Error: $e");
    }
  }

  String _wrapInSvg(String path) {
    if (path.startsWith('<svg')) return path;
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">$path</svg>';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crosstalk Spanish'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F2937),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.string(
                _svgContent,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${msg['sender']}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: msg['text']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton.icon(
              onPressed: _listen,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Listening...' : 'Hold to Speak English'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
