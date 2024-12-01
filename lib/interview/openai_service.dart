import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService {
  final String _flaskApiUrl = "http://192.168.200.104:5000/analyze-answer"; // Flask 서버 URL

  /// Flask 서버를 통해 질문과 답변을 평가
  Future<String> evaluateAnswer({
    required String question,
    required String answer,
  }) async {
    final Map<String, dynamic> requestBody = {
      "question": question,
      "answer": answer,
    };

    try {
      final response = await http.post(
        Uri.parse(_flaskApiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Flask 서버에서 반환된 데이터를 처리
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['feedback']; // Flask 응답에서 feedback 추출
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
        return "Error: Failed to evaluate answer.";
      }
    } catch (e) {
      print("Error: $e");
      return "Error: Unable to connect to Flask server.";
    }
  }
}
