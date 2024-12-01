import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './question_service.dart';
import '../firebase/firesbase_init.dart';

class QuestionScreen extends StatefulWidget {
  final String resumeId;
  const QuestionScreen({super.key, required this.resumeId});

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
    print("initState called, resumeId: \${widget.resumeId}, userId: \$userId");
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
        title: const Text(
          '질문 생성',
          style: TextStyle(
            fontWeight: FontWeight.bold, // 굵게 설정
            fontSize: 22, // 크기 조정
            color: Colors.white, // 제목 색상 설정
          ),
        ),
        backgroundColor: Colors.grey.shade800,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew, color: Colors.white),
            onPressed: () async {
              print("질문 생성중..");
              await _generateQuestions(); // 새로운 질문 생성
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<List<Map<String, String>>>(
              stream: _questionService.getQuestions(widget.resumeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading questions',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final combinedData = snapshot.data;

                if (combinedData == null || combinedData.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No questions available.\nPress the add button to generate new questions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: const Icon(Icons.question_answer,
                                color: Color.fromARGB(145, 0, 0, 0)),
                          ),
                          title: Text(
                            topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              question,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
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
