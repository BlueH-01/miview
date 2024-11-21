import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../firebase/firesbase_init.dart';
import '../firebase/file_upload.dart';

class QuestionService {
  final FileUploadService _fileUploadService = FileUploadService();
  final FirebaseFirestore _firestore = FirebaseInit().firestore;
  final String userId = FirebaseInit().auth.currentUser!.uid;

  Stream<List<Map<String, String>>> getQuestions(String resumeId) {
    print("Fetching questions for resume: $resumeId"); 
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('questions')
        .where('resumeId', isEqualTo: resumeId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final topicsSnapshot = await doc.reference.collection('topic').get();
            final commentsSnapshot = await doc.reference.collection('comment').get();
            
            if (topicsSnapshot.docs.isNotEmpty && commentsSnapshot.docs.isNotEmpty) {
              final topicsData = topicsSnapshot.docs.first.data() as Map<String, dynamic>;
              final commentsData = commentsSnapshot.docs.first.data() as Map<String, dynamic>;

              List<Map<String, String>> combinedData = [];
              for (int i = 1; i <= 5; i++) {
                final topic = topicsData['topic$i'] as String? ?? '';
                final question = commentsData['question$i'] as String? ?? '';
                combinedData.add({
                  'topic': topic,
                  'question': question,
                });
              }

              print("Combined topics and questions: $combinedData"); 
              return combinedData;
            }
          }
          return <Map<String, String>>[];
        })
        .handleError((error) {
          print("Error fetching questions: $error"); 
        });
  }

  Future<String?> getPdfUrl(String resumeId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('resumes')
          .doc(resumeId)
          .get();
      if (doc.exists) {
        return doc['downloadURL'];
      } else {
        print("Error: Document does not exist");
      }
    } catch (e) {
      print("Error getting PDF URL: $e");
    }
    return null;
  }

  Future<Map<String, Map<String, String>>?> genQuestion(String resumeId) async {
    String? pdfUrl = await getPdfUrl(resumeId);
    if (pdfUrl == null) {
      print("Error: PDF URL is null");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('http://223.194.138.140:5000/generate-questions'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pdf_url': pdfUrl}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        if (data['questions'] != null) {
          Map<String, Map<String, String>> questions = {};
          for (var i = 1; i <= 5; i++) {
            questions['q$i'] = {
              'topic': data['questions']['q$i']['topic'],
              'question': data['questions']['q$i']['question']
            };
          }

          // 기존 질문 삭제
          await _deleteExistingQuestions(resumeId);

          // 새로운 질문 업로드
          await _fileUploadService.uploadQuestions(questions, userId, resumeId);
          return questions;
        } else {
          print("Error: No questions found in response.");
        }
      } else {
        print("Error: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error analyzing PDF: $e");
    }
    return null;
  }

  Future<void> _deleteExistingQuestions(String resumeId) async {
    final questionCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('questions')
        .where('resumeId', isEqualTo: resumeId);

    final querySnapshot = await questionCollection.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }
}
