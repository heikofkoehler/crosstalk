import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> sendChat(String message, String level, List<Map<String, String>> history) async {
    // Map the Flutter history to Genkit's expected role structure
    final genkitHistory = history.where((msg) => msg['sender'] != null && msg['text'] != null).map((msg) => {
      'role': msg['sender'] == 'You' ? 'user' : 'model',
      'text': msg['text']
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'data': {
          'message': message,
          'level': level,
          'history': genkitHistory
        }
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['result']; // Unwrap Genkit callable result
    } else {
      throw Exception('Failed to load chat response: ${response.statusCode}');
    }
  }
}
