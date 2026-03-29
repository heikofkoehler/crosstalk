import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Note: You'll need to run 'flutterfire configure' to generate this file
// or provide the options manually if you're not using the CLI.
// For now, we'll assume a standard Firebase initialization.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // If you haven't run flutterfire configure, this may need manual options
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp(); 
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const ChatScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🇪🇸 Crosstalk AI',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _signInWithGoogle(context),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
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
  String _currentLevel = 'Beginner';

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

  void _simplify() {
    _sendMessage("[SIMPLIFY]");
  }

  void _sendMessage(String text) async {
    if (text == "[SIMPLIFY]") {
      setState(() {
        _messages.add({'sender': 'You', 'text': '¿Qué?'});
      });
    } else {
      setState(() {
        _messages.add({'sender': 'You', 'text': text});
      });
    }

    try {
      final response = await _apiService.sendChat(text, _currentLevel);
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
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crosstalk Spanish'),
        actions: [
          DropdownButton<String>(
            value: _currentLevel,
            dropdownColor: const Color(0xFF1F2937),
            onChanged: (String? newValue) {
              setState(() {
                _currentLevel = newValue!;
              });
            },
            items: <String>['Superbeginner', 'Beginner', 'Intermediate']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
        centerTitle: true,
        backgroundColor: const Color(0xFF1F2937),
      ),
      body: Column(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Hola, ${user.displayName}!', style: const TextStyle(color: Colors.grey)),
            ),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _listen,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'Listening...' : 'Speak English'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _simplify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('¿Qué?', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
