import 'package:chap22/IdProvider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../firebase/firesbase_init.dart';
import './interview_service.dart';
import 'package:provider/provider.dart';

class InterviewScreen extends StatefulWidget {
  final String resumeId;
  const InterviewScreen({Key? key, required this.resumeId}) : super(key: key);
  
  @override
  _InterviewScreenState createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  String? interviewId;
  String userId = FirebaseInit().auth.currentUser!.uid; 
  final InterviewService _interviewService = InterviewService();
  int currentQuestionIndex = 0;
  bool isInterviewing = false;
  bool isRecording = false;
  bool cameraInitialized = false;
  List<String> questions = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // 초기화: 카메라와 인터뷰 생성 및 질문 불러오기
  Future<void> initialize() async {
    await _interviewService.initializeCamera();
    await fetchQuestionsFromFirestore(); 

    // 인터뷰가 존재하지 않으면 생성하여 interviewId 할당
    interviewId = await _interviewService.createInterview(widget.resumeId);

    setState(() {
      cameraInitialized = true;
    });
  }

  // Firestore에서 질문 데이터를 가져오는 메서드
  Future<void> fetchQuestionsFromFirestore() async {
    try {
      CollectionReference questionsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('questions');
      
      QuerySnapshot questionSnapshot = await questionsCollection.get();
      if (questionSnapshot.docs.isEmpty) {
        print("No question documents found for userId: $userId");
        return;
      }

      DocumentReference questionDocRef = questionSnapshot.docs.first.reference;
      QuerySnapshot topicSnapshot = await questionDocRef.collection('topic').get();
      Map<String, String> topics = {};

      if (topicSnapshot.docs.isNotEmpty) {
        DocumentSnapshot topicDoc = topicSnapshot.docs.first;
        for (int i = 1; i <= 5; i++) {
          String topicKey = 'topic$i';
          topics[topicKey] = topicDoc[topicKey] ?? '';
        }
      } else {
        print("Topic document does not exist");
        return;
      }

      QuerySnapshot commentSnapshot = await questionDocRef.collection('comment').get();
      Map<String, String> comments = {};

      if (commentSnapshot.docs.isNotEmpty) {
        DocumentSnapshot commentDoc = commentSnapshot.docs.first;
        for (int i = 1; i <= 5; i++) {
          String questionKey = 'question$i';
          comments[questionKey] = commentDoc[questionKey] ?? '';
        }
      } else {
        print("Comment document does not exist");
        return;
      }

      for (int i = 1; i <= 5; i++) {
        String topic = topics['topic$i'] ?? '';
        String question = comments['question$i'] ?? '';
        questions.add('$topic: $question');
      }

      print("Fetched questions: $questions");
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  // 녹화 시작 및 업로드
  Future<void> recordAnswer() async {
    // interviewId가 없을 경우 생성하여 설정
    if (interviewId == null) {
      print("Creating a new interview because interviewId is null");
      interviewId = await _interviewService.createInterview(widget.resumeId);
    }

    if (!isRecording) {
      setState(() {
        isRecording = true;
      });
      await _interviewService.startRecording();
    } else {
      XFile? videoFile = await _interviewService.stopRecording();

      if (videoFile != null && interviewId != null) {
        await _interviewService.uploadVideoForInterview(userId, interviewId!, videoFile, currentQuestionIndex);

        setState(() {
          currentQuestionIndex++;
          isRecording = false;
        });
      } else {
        print("Error: Video file or interview ID is not available.");
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
                cameraInitialized
                    ? SizedBox(
                        height: 200,
                        child: CameraPreview(_interviewService.cameraController!),
                      )
                    : Center(child: CircularProgressIndicator()),
              ],
            )
          : Center(
              child: Text("Interview completed!"),
            ),
    );
  }

  @override
  void dispose() {
    _interviewService.cameraController?.dispose();
    super.dispose();
  }
}

