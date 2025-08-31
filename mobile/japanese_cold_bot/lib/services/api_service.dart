import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _hostIpAddress = '192.168.10.127';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://$_hostIpAddress:8000';
    }
  }
  
  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      print('🔗 Connecting to: $baseUrl/chat');
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ API Error in sendMessage: $e');
      return {
        'response': 'そう...サーバーが応答しないみたい。接続を確認して。',
        'audio_url': null,
      };
    }
  }

  Future<String?> synthesizeVoice(String text) async {
    // This method is now legacy and will be replaced by streaming.
    // It can be kept for fallback or removed.
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/synthesize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['audio_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Connects to the /stream-voice endpoint and returns the HTTP stream.
  Future<http.StreamedResponse> getVoiceStream(String text) async {
    try {
      final url = Uri.parse('$baseUrl/stream-voice').replace(queryParameters: {'text': text});
      print('STREAMING 🎤 Requesting voice stream from: $url');
      
      final request = http.Request('GET', url);
      final streamedResponse = await http.Client().send(request).timeout(const Duration(seconds: 20));

      if (streamedResponse.statusCode == 200) {
        print('STREAMING 🎤 Stream connection successful. Status: 200.');
        return streamedResponse;
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('STREAMING 🎤 Error body: $errorBody');
        throw Exception('Failed to get voice stream: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('❌ API Error in getVoiceStream: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Health check failed'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed: $e'};
    }
  }
}