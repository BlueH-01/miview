import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

// 인터뷰 처리 클래스
class InterviewProcess {
  CameraController? _cameraController;
  List<CameraDescription> cameras = [];
  late FirebaseStorage _storage;
  late FirebaseFirestore _firestore;

  InterviewProcess() {
    _storage = FirebaseStorage.instance;
    _firestore = FirebaseFirestore.instance;
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

  // Firebase Storage에 영상 업로드
  Future<String?> uploadVideoToStorage(XFile videoFile, String userId, int questionNumber) async {
    try {
      File file = File(videoFile.path);
      String filePath = '$userId/interview/question_$questionNumber.mp4';

      Reference storageRef = _storage.ref().child(filePath);
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Error uploading video: $e");
      return null;
    }
  }

  // Firestore에 영상 URL 저장
  Future<void> saveVideoUrlToFirestore(String userId, int questionNumber, String videoUrl) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('interview_responses')
        .doc('question_$questionNumber')
        .set({
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Interview',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InterviewScreen(),
    );
  }
}

class InterviewScreen extends StatefulWidget {
  @override
  _InterviewScreenState createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final InterviewProcess _interviewProcess = InterviewProcess();
  int currentQuestionIndex = 0; // 현재 질문 인덱스
  bool isRecording = false;
  bool cameraInitialized = false; // 카메라 초기화 상태 변수
  List<String> questions = [
    "Tell me about yourself.",
    "Why do you want this job?",
    "What are your strengths and weaknesses?",
  ];

  @override
  void initState() {
    super.initState();
    initializeCameraOnce(); // 앱 시작 시 카메라 한 번만 초기화
  }

  // 카메라 한 번만 초기화하는 함수
  Future<void> initializeCameraOnce() async {
    await _interviewProcess.initializeCamera();
    setState(() {
      cameraInitialized = true;
    });
  }

  // 녹화 시작 및 업로드
  Future<void> recordAnswer() async {
    if (!isRecording) {
      setState(() {
        isRecording = true;
      });
      await _interviewProcess.startRecording();
    } else {
      XFile? videoFile = await _interviewProcess.stopRecording();

      if (videoFile != null) {
        String? videoUrl = await _interviewProcess.uploadVideoToStorage(
            videoFile, 'userId', currentQuestionIndex);

        if (videoUrl != null) {
          await _interviewProcess.saveVideoUrlToFirestore('userId', currentQuestionIndex, videoUrl);
        }

        // 다음 질문으로 이동
        setState(() {
          currentQuestionIndex++;
          isRecording = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Interview Question ${currentQuestionIndex + 1}"),
      ),
      body: currentQuestionIndex < questions.length
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(questions[currentQuestionIndex]),
                ElevatedButton(
                  onPressed: recordAnswer,
                  child: Text(isRecording ? "Stop Recording" : "Start Recording"),
                ),
                // 카메라 미리보기 표시
                cameraInitialized
                    ? SizedBox(
                        height: 200,
                        child: CameraPreview(_interviewProcess._cameraController!),
                      )
                    : Center(child: CircularProgressIndicator()), // 초기화 완료 전 로딩 표시
              ],
            )
          : Center(
              child: Text("Interview completed!"),
            ),
    );
  }

  @override
  void dispose() {
    _interviewProcess._cameraController?.dispose();
    super.dispose();
  }
}
