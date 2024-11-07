import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './question_service.dart';
import '../firebase/firesbase_init.dart';

class QuestionScreen extends StatefulWidget {
  final String resumeId;
  const QuestionScreen({Key? key, required this.resumeId}) : super(key: key);

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final QuestionService _questionService = QuestionService();
  final String userId = FirebaseInit().auth.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("initState called, resumeId: ${widget.resumeId}, userId: $userId"); // 디버깅: 초기 상태 출력
  }

  // 질문 생성 함수
  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    print("Generating new questions...");

    // 새로운 질문 생성
    await _questionService.genQuestion(widget.resumeId);

    setState(() {
      _isLoading = false; // 로딩 완료
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              print("Add button pressed. Generating questions...");
              await _generateQuestions(); // 새로운 질문 생성
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, String>>>(
        stream: _questionService.getQuestions(widget.resumeId),
        builder: (context, snapshot) {
          print("StreamBuilder triggered, connectionState: ${snapshot.connectionState}");
          
          if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
            print("Loading or waiting for data...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            return const Center(child: Text('Error loading questions'));
          }

          final combinedData = snapshot.data;
          print("Questions loaded: ${combinedData?.length ?? 0}");

          if (combinedData == null || combinedData.isEmpty) {
            return const Center(
              child: Text(
                'No questions available. Press the add button to generate new questions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: combinedData.length,
            itemBuilder: (context, index) {
              final topic = combinedData[index]['topic'] ?? '';
              final question = combinedData[index]['question'] ?? '';

              return ListTile(
                leading: const Icon(Icons.question_answer),
                title: Text(
                  topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // 질문 삭제 로직 추가 필요
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
