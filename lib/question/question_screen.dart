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
    print("initState called, resumeId: \${widget.resumeId}, userId: \$userId"); // 디버깅: 초기 상태 출력
  }

  // 질문 생성 함수
  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    print("Generating new questions...");

    // 새로운 질문 생성
    await _questionService.genQuestion(widget.resumeId);

    // 위젯이 여전히 트리에 있는지 확인한 후 setState 호출
    if (mounted) {
      setState(() {
        _isLoading = false; // 로딩 완료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Questions'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              print("Add button pressed. Generating questions...");
              await _generateQuestions(); // 새로운 질문 생성
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, String>>>(
              stream: _questionService.getQuestions(widget.resumeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading questions'));
                }

                final combinedData = snapshot.data;

                if (combinedData == null || combinedData.isEmpty) {
                  return const Center(
                    child: Text(
                      'No questions available. Press the add button to generate new questions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: combinedData.length,
                    itemBuilder: (context, index) {
                      final topic = combinedData[index]['topic'] ?? '';
                      final question = combinedData[index]['question'] ?? '';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: const Icon(Icons.question_answer, color: Colors.deepPurple, size: 32),
                          title: Text(
                            topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              question,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
