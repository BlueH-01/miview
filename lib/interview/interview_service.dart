import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../firebase/firesbase_init.dart';

class InterviewService {
  final List<String> videoUrls = []; // 업로드된 비디오 URL 리스트
  final String userId = FirebaseInit().auth.currentUser!.uid;
  CameraController? _cameraController;
  final FirebaseStorage _storage = FirebaseInit().storage;
  final FirebaseFirestore _firestore = FirebaseInit().firestore;

  CameraController? get cameraController => _cameraController;

  InterviewService();

  // 이력서 기반 질문 생성 함수
  Future<List<String>> createQuestion(String? resumeId) async {
    List<String> questions = [];

    if (resumeId != null) {
      try {
        DocumentSnapshot resumeDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('resumes')
            .doc(resumeId)
            .get();

        if (resumeDoc.exists) {
          String downloadUrl = resumeDoc['downloadURL'];

          final response = await http.post(
            Uri.parse('http://223.194.138.140:5000/generate-questions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'resumeUrl': downloadUrl}),
          );

          if (response.statusCode == 200) {
            List<dynamic> jsonResponse = json.decode(response.body);
            questions = List<String>.from(jsonResponse);
          } else {
            print('Failed to load questions: ${response.statusCode}');
          }
        } else {
          print('Resume document does not exist.');
        }
      } catch (e) {
        print('Error fetching questions: $e');
      }
    } else {
      questions.addAll([
        'What are your long-term career goals?',
        'How do you handle stress?',
        'Why should we hire you?'
      ]);
    }
    return questions;
  }

  // 인터뷰 생성 메서드
  Future<String> createInterview(String? resumeId) async {
    try {
      DocumentReference docRef;
      if (resumeId != null) {
        docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('interviews')
            .add({
          'resumeId': resumeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('interviews_not_resume')
            .add({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      print("Interview created with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("Error creating interview: $e");
      throw Exception("인터뷰 생성 실패: $e");
    }
  }

  // 카메라 초기화 메서드
  Future<void> initializeCamera() async {
    if (_cameraController != null) return;

    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    print("카메라 초기화 완료");
  }

  // 영상 녹화 시작 메서드
  Future<void> startRecording() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.startVideoRecording();
      print("녹화 시작");
    }
  }

  // 영상 녹화 중단 메서드
  Future<XFile?> stopRecording() async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      XFile videoFile = await _cameraController!.stopVideoRecording();
      print("녹화 중단");
      return videoFile;
    }
    return null;
  }

  // 비디오 업로드 메서드 - URL 반환하도록 설정
Future<String> uploadVideoForInterview(
  String userId, String? interviewId, XFile? videoFile, int currentQuestionIndex) async {
  
  // 인터뷰 ID 및 비디오 파일 유효성 검사
  if (interviewId == null || interviewId.isEmpty) {
    print("Error: interviewId is null or empty");
    return '';
  }

  if (videoFile == null) {
    print("Error: videoFile is null");
    return '';
  }

  try {
    // Firebase Storage에 비디오 파일 업로드 경로 설정
    File file = File(videoFile.path);
    String filePath = 'users/$userId/interviews/$interviewId/videos/Answer$currentQuestionIndex.mp4';

    Reference storageRef = _storage.ref().child(filePath);
    UploadTask uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),  // MIME 유형 설정
    );

    // Firebase Storage에 비디오 파일 업로드
    TaskSnapshot snapshot = await uploadTask;
    String videoUrl = await snapshot.ref.getDownloadURL();
    videoUrls.add(videoUrl); // 비디오 URL 리스트에 추가

    // Firestore 인터뷰 문서에 비디오 URL 업데이트
    DocumentReference interviewDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('interviews')
        .doc(interviewId);

    await interviewDocRef.update({
      'videoUrl$currentQuestionIndex': videoUrl,
    });

    print("Video uploaded successfully: $videoUrl");
    return videoUrl;
  } catch (e) {
    print("Error uploading video: $e");
    return '';
  }
}



}
