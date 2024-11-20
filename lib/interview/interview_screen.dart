import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chap22/firebase/firesbase_init.dart';
import 'package:camera/camera.dart';
import './interview_service.dart';
import 'videoplayer_screen.dart'; // 새로 만든 동영상 페이지

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
  bool isRecording = false;
  bool cameraInitialized = false;
  bool _isDownloading = false;
  List<String> topics = []; // topics 리스트 (topic1 ~ topic5)
  List<String> questions = []; // questions 리스트 (question1 ~ question5)
  List<String> videoUrls = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await _interviewService.initializeCamera();
    await fetchQuestionsFromFirestore();

    interviewId = await _interviewService.createInterview(widget.resumeId);
    if (interviewId == null) {
      print("Error: Failed to create interview. Interview ID is null.");
      return;
    } else {
      print("Interview created with ID: $interviewId");
    }

    setState(() {
      cameraInitialized = true;
    });
  }

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

      // Topic 데이터 가져오기
      QuerySnapshot topicSnapshot = await questionDocRef.collection('topic').get();
      if (topicSnapshot.docs.isNotEmpty) {
        DocumentSnapshot topicDoc = topicSnapshot.docs.first;
        for (int i = 1; i <= 5; i++) {
          String topicKey = 'topic$i';
          topics.add(topicDoc[topicKey] ?? ''); // topics에 topic1~5를 추가
        }
      } else {
        print("Topic document does not exist");
        return;
      }

      // Question 데이터 가져오기
      QuerySnapshot commentSnapshot = await questionDocRef.collection('comment').get();
      if (commentSnapshot.docs.isNotEmpty) {
        DocumentSnapshot commentDoc = commentSnapshot.docs.first;
        for (int i = 1; i <= 5; i++) {
          String questionKey = 'question$i';
          questions.add(commentDoc[questionKey] ?? ''); // questions에 question1~5를 추가
        }
      } else {
        print("Comment document does not exist");
        return;
      }

      setState(() {}); // UI 갱신
      print("Fetched topics: $topics");
      print("Fetched questions: $questions");
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> recordAnswer() async {
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
        // 비디오가 5개 이상이면 더 이상 업로드하지 않음
        if (videoUrls.length >= 5) {
          print("Error: Maximum of 5 videos allowed.");
          return;
        }

        // 비디오 URL을 1번부터 저장하도록 변경
        String videoUrl = await _interviewService.uploadVideoForInterview(
            userId, interviewId!, videoFile, currentQuestionIndex + 1);

        // 문제를 방지하기 위해 비디오 URL이 중복되지 않도록 확인하고 추가
        if (!videoUrls.contains(videoUrl)) {
          videoUrls.add(videoUrl);
        }

        print("Video URL added: $videoUrl");
        print("videoUrls length after add: ${videoUrls.length}");

        setState(() {
          currentQuestionIndex = videoUrls.length; // update currentQuestionIndex to match the new 1-based indexing
          isRecording = false;
        });
      } else {
        print("Error: Video file or interview ID is not available.");
      }
    }
  }

  @override
  void dispose() {
    _interviewService.cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentQuestionIndex < topics.length ? '${topics[currentQuestionIndex]}' : 'Result'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentQuestionIndex < topics.length
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "${questions[currentQuestionIndex]}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  cameraInitialized
                      ? Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CameraPreview(_interviewService.cameraController!),
                          ),
                        )
                      : Center(child: CircularProgressIndicator()),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecording ? Colors.red : Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: recordAnswer,
                    child: Text(
                      isRecording ? "Stop Recording" : "Start Recording",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              )
            : videoUrls.isNotEmpty
                ? ListView.builder(
                    itemCount: videoUrls.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 36),
                          title: Text("Play Video ${index + 1}"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  videoUrl: videoUrls[index],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
      ),
    );
  }
}
