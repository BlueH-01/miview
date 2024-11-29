import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chap22/firebase/firesbase_init.dart';
import 'package:camera/camera.dart';
import './interview_service.dart';
import 'videoplayer_screen.dart';

class InterviewScreen extends StatefulWidget {
  final String resumeId;
  const InterviewScreen({super.key, required this.resumeId});

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
  bool isUploading = false; // 업로드 상태 추가
  bool isDisposed = false; // dispose 상태를 추적
  List<String> topics = [];
  List<String> questions = [];
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

    await fetchVideoUrls();
    if (!isDisposed) {
      setState(() {
        cameraInitialized = true;
      });
    }
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
      QuerySnapshot topicSnapshot =
          await questionDocRef.collection('topic').get();
      if (topicSnapshot.docs.isNotEmpty) {
        DocumentSnapshot topicDoc = topicSnapshot.docs.first;
        for (int i = 1; i <= 2; i++) {
          String topicKey = 'topic$i';
          topics.add(topicDoc[topicKey] ?? '');
        }
      } else {
        print("Topic document does not exist");
        return;
      }

      // Question 데이터 가져오기
      QuerySnapshot commentSnapshot =
          await questionDocRef.collection('comment').get();
      if (commentSnapshot.docs.isNotEmpty) {
        DocumentSnapshot commentDoc = commentSnapshot.docs.first;
        for (int i = 1; i <= 2; i++) {
          String questionKey = 'question$i';
          questions.add(commentDoc[questionKey] ?? '');
        }
      } else {
        print("Comment document does not exist");
        return;
      }

      if (!isDisposed) {
        setState(() {});
      }

      print("Fetched topics: $topics");
      print("Fetched questions: $questions");
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> fetchVideoUrls() async {
    if (interviewId == null) return;

    try {
      DocumentSnapshot interviewDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('interviews')
          .doc(interviewId)
          .get();

      if (interviewDoc.exists) {
        for (int i = 1; i <= 2; i++) {
          String? videoUrl = interviewDoc.get('videoUrl$i') as String?;
          if (videoUrl != null) {
            videoUrls.add(videoUrl);
          }
        }
        setState(() {});
      }
    } catch (e) {
      print("Error fetching video URLs: $e");
    }
  }

  Future<void> recordAnswer() async {
    if (interviewId == null) {
      print("Creating a new interview because interviewId is null");
      interviewId = await _interviewService.createInterview(widget.resumeId);
    }

    if (!isRecording) {
      setState(() {
        isRecording = true; // 즉시 녹화 상태로 업데이트
      });
      await _interviewService.startRecording();
    } else {
      setState(() {
        isRecording = false; // 즉시 녹화 중지 상태로 업데이트
      });

      XFile? videoFile = await _interviewService.stopRecording();

      if (videoFile != null && interviewId != null) {
        if (currentQuestionIndex >= questions.length) {
          print("Error: All questions have been answered.");
          return;
        }

        // 업로드 상태를 설정
        setState(() {
          isUploading = true;
        });

        String videoUrl = await _interviewService.uploadVideoForInterview(
          userId,
          interviewId!,
          videoFile,
          currentQuestionIndex + 1,
          questions[currentQuestionIndex],
        );

        setState(() {
          videoUrls.add(videoUrl); // 비디오 URL 추가
          currentQuestionIndex++;
          isUploading = false; // 업로드 상태 종료
        });
      } else {
        print("Error: Video file or interview ID is not available.");
      }
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    _interviewService.cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentQuestionIndex < topics.length
              ? topics[currentQuestionIndex]
              : 'Result',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black38,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentQuestionIndex < topics.length
            ? buildQuestionView()
            : buildResultView(),
      ),
    );
  }

  Widget buildQuestionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey, width: 2),
          ),
          child: Text(
            questions.isNotEmpty
                ? questions[currentQuestionIndex]
                : "Loading question...",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        cameraInitialized
            ? Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CameraPreview(_interviewService.cameraController!),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 20),
        isUploading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (!isDisposed) {
                    await recordAnswer();
                  }
                },
                icon: Icon(
                  isRecording ? Icons.stop : Icons.videocam,
                  color: Colors.white,
                ),
                label: Text(
                  isRecording ? "녹화 중지" : "녹화 시작",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
      ],
    );
  }

  Widget buildResultView() {
    return videoUrls.isNotEmpty
        ? ListView.builder(
            itemCount: videoUrls.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill,
                      color: Colors.deepPurple, size: 36),
                  title: Text("Play Video ${index + 1}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          videoUrl: videoUrls[index],
                          question: questions[index],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }
}
