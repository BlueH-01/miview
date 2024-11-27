import 'package:chap22/IdProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../firebase/firesbase_init.dart';
import './resume_service.dart';
import '../question/question_screen.dart';
import 'package:provider/provider.dart';
import '../interview/interview_screen.dart';

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  final _firebaseAuth = FirebaseInit().auth;
  User? loggedUser;
  final ResumeService _resumeService = ResumeService();

  int? _selectedIndex; // 선택된 타일 인덱스

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  // 로그인한 유저 초기화
  void getCurrentUser() {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        loggedUser = user;
        print("Logged in user email: ${loggedUser!.email}");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickAndUploadPDF() async {
    try {
      PlatformFile? pickedFile = await _resumeService.pickPDF();

      if (pickedFile != null && loggedUser != null) {
        print('PDF file selected');
        await _resumeService.uploadPDF(pickedFile, loggedUser!.uid);
      } else {
        print('Error: pickedFile or loggedUser is null');
      }
    } catch (e) {
      print('Error in pickAndUploadPDF: $e');
    }
  }

  void navigateToQuestionScreen(String resumeId) {
    print(
        "Navigating to question screen with resume ID: $resumeId"); //내가 가는 resumeId
    Provider.of<Idprovider>(context, listen: false)
        .setResumeId(resumeId); //현재사용할 resumeId의값을 매개변수로 받은 resumeId로변경한다.
    // QuestionScreen으로 이력서 ID를 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
            resumeId: Provider.of<Idprovider>(context)
                .resumeId!), // resume ID 전달 //questionsscreen에서 사용하는 resumeId는
      ),
    );
  }

  void navigateToInterviewScreen(String resumeId) {
    print(
        "Navigating to interview screen with resume ID: $resumeId"); //내가 가는 resumeId
    Provider.of<Idprovider>(context, listen: false)
        .setResumeId(resumeId); //현재사용할 resumeId의값을 매개변수로 받은 resumeId로변경한다.
    // QuestionScreen으로 이력서 ID를 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewScreen(
            resumeId: Provider.of<Idprovider>(context)
                .resumeId!), // resume ID 전달 //questionsscreen에서 사용하는 resumeId는
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '이력서 목록',
          style: TextStyle(
            fontWeight: FontWeight.bold, // 굵게 설정
            fontSize: 23,
          ),
        ),
        centerTitle: true, // 타이틀을 가운데 정렬
      ),
      body: loggedUser != null
          ? Column(
              children: [
                // SizedBox로 여백 추가
                const SizedBox(height: 20), // 제목과 리스트 사이의 여백
                Expanded(
                  child: StreamBuilder<List<PlatformFile>>(
                    stream: _resumeService.getUserResumes(loggedUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No resumes found.'));
                      }

                      final resumes = snapshot.data!;

                      return ListView.builder(
                        itemCount: resumes.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.file_copy),
                                  title: Text(
                                    resumes[index].name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      textBaseline: TextBaseline.alphabetic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index; // 선택된 인덱스 저장
                                    });
                                  },
                                  tileColor: _selectedIndex == index
                                      ? Colors.grey[300]
                                      : null, // 선택된 타일 배경색 변경
                                  trailing: _selectedIndex == index
                                      ? SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  // 이력서 ID 가져오기
                                                  String? resumeId =
                                                      resumes[index].identifier;

                                                  if (resumeId != null) {
                                                    print(resumeId);
                                                    navigateToQuestionScreen(
                                                        resumeId); // 질문 페이지로 이동
                                                  } else {
                                                    print(
                                                        'Error: resumeId is null');
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor: Colors.grey,
                                                ),
                                                child: const Text('질문 생성'),
                                              ),
                                              const SizedBox(height: 10),
                                              ElevatedButton(
                                                onPressed: () {
                                                  // 이력서 ID 가져오기
                                                  String? resumeId =
                                                      resumes[index].identifier;

                                                  if (resumeId != null) {
                                                    print(resumeId);
                                                    navigateToInterviewScreen(
                                                        resumeId); // 면접 시작 페이지로 이동
                                                  } else {
                                                    print(
                                                        'Error: resumeId is null');
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor: Colors.grey,
                                                ),
                                                child: const Text('면접 시작'),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(child: Text('Please log in to see your resumes.')),
      floatingActionButton: FloatingActionButton(
        onPressed: pickAndUploadPDF, // 이력서 추가 버튼 연결
        backgroundColor: Colors.grey,
        child: const Icon(Icons.add),
      ),
    );
  }
}
