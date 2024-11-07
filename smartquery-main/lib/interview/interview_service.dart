import 'package:chap22/IdProvider.dart';
import 'package:chap22/firebase/firesbase_init.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // HTTP 요청을 위해 추가
import 'dart:convert'; // JSON 변환을 위해 추가


// 인터뷰 처리 클래스
class InterviewService {
  List <String> videoUrls=[]; // 비디오 url 리스트
  String userId = FirebaseInit().auth.currentUser!.uid; //로그인한 유저의 id
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  late FirebaseStorage _storage;
  late FirebaseFirestore _firestore;
  CameraController? get cameraController => _cameraController;
    InterviewService() {
    _storage = FirebaseInit().storage;
    _firestore = FirebaseInit().firestore;
  }
// 기본적인 이력서 기반 질문 생성함수
Future<List<String>> createQuestion(String? resumeId) async {
  List<String> questions = [];

  if (resumeId != null) {
    try {
      // Firestore에서 이력서 문서 가져오기
      DocumentSnapshot resumeDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('resumes')
          .doc(resumeId)
          .get();

      if (resumeDoc.exists) {
        String downloadUrl = resumeDoc['downloadURL']; // 이력서 PDF URL 가져오기

        // Flask 서버에 질문 요청
        final response = await http.post(
          Uri.parse('http://223.194.153.150:5000//generate-questions'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'resumeUrl': downloadUrl,
          }),
        );

        if (response.statusCode == 200) {
          // 서버로부터 받은 질문을 파싱하여 리스트에 추가
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
    // resumeId가 null일 경우 기본 질문을 추가할 수 있습니다.
    questions.addAll([
      'What are your long-term career goals?',
      'How do you handle stress?',
      'Why should we hire you?'
    ]);
  }
  return questions;
}

  Future<String> createInterview(String? resumeId) async {
  DocumentReference docRef;
  try {
    if (resumeId != null) {
      // 이력서 기반 인터뷰 생성
      print("Creating interview with resume ID: $resumeId");
      docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('interviews')
          .add({
            // 이력서 기반 인터뷰 관련 데이터
            'resumeId': resumeId, // 예시로 이력서 ID 추가
            'createdAt': FieldValue.serverTimestamp(), // 생성 시간 추가
            // 추가적인 데이터 삽입
          });
    } else {
      // 비이력서 기반 인터뷰 생성
      print("Creating interview without resume ID");
      docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('interviews_not_resume')
          .add({
            // 비이력서 기반 인터뷰 관련 데이터
            'createdAt': FieldValue.serverTimestamp(), // 생성 시간 추가
            // 추가적인 데이터 삽입
          });
    }
    print("Interview created with ID: ${docRef.id}"); // 생성된 인터뷰 ID 로그
    return docRef.id; // Firestore가 생성한 고유한 인터뷰 ID 반환
  } catch (e) {
    print("Error creating interview: $e"); // 오류 로그
    throw Exception("인터뷰 생성 실패: $e"); // 예외 처리
  }
}

  // 카메라 초기화 (전면 카메라 선택)
  Future<void> initializeCamera() async {
    if (_cameraController != null) {
      return; // 이미 초기화된 경우 다시 초기화하지 않음
    }
    cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    print("카메라 초기화!");
  }

  // 영상 녹화 시작
  Future<void> startRecording() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.startVideoRecording();
      print("카메라 녹화중!");
    }
  }

  // 영상 녹화 중단 및 저장
  Future<XFile?> stopRecording() async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      XFile videoFile = await _cameraController!.stopVideoRecording();
      print("카메라 녹화중단!");
      return videoFile;
    }
    return null;
  }
  // interviewId에 따른 영상 업로드
Future<void> uploadVideoForInterview(String userId, String? interviewId, XFile videoFile, int currentQuestionIndex) async {
  // interviewId가 null 또는 빈 문자열인지 확인
  if (interviewId == null || interviewId.isEmpty) {
    print("Error: interviewId is null or empty");
    return;
  }

  try {
    // Firebase Storage에 비디오 파일 업로드 경로 설정
    File file = File(videoFile.path);
    String filePath = 'users/$userId/interviews/$interviewId/videos/Answer${currentQuestionIndex}.mp4';

    Reference storageRef = _storage.ref().child(filePath);
    UploadTask uploadTask = storageRef.putFile(file);

    // Firebase Storage에 비디오 파일 업로드
    TaskSnapshot snapshot = await uploadTask;
    String videoUrl = await snapshot.ref.getDownloadURL();
    videoUrls.add(videoUrl); // 비디오 URL 리스트에 추가

    // Firestore 인터뷰 문서 참조 생성
    DocumentReference interviewDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('interviews')
        .doc(interviewId);

    // Firestore에서 해당 인터뷰 문서가 존재하는지 확인
    final docSnapshot = await interviewDocRef.get();
    if (docSnapshot.exists) {
      // 문서가 존재할 경우 비디오 URL 업데이트
      await interviewDocRef.update({
        'videoUrl$currentQuestionIndex': videoUrl,
      });
      print("비디오 업로드 완료: $videoUrl");
    } else {
      print("Error: Interview document with ID $interviewId not found in Firestore.");
    }
  } catch (e) {
    print("비디오 업로드 중 오류 발생: $e");
  }
}


  // flask로 비디오 url list와 question 리스트를 전부 보내서 답변 추출과 피드백을 받음(아마도 json)
  // 형태는 Q1 A1 FEEDBACK1 을 한객체로 하고 
  
}