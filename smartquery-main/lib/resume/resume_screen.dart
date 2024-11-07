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
  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  final _firebaseAuth  =FirebaseInit().auth;
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
    print("Navigating to question screen with resume ID: $resumeId"); //내가 가는 resumeId
    Provider.of<Idprovider>(context, listen: false).setResumeId(resumeId); //현재사용할 resumeId의값을 매개변수로 받은 resumeId로변경한다.
    // QuestionScreen으로 이력서 ID를 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestionScreen(resumeId: Provider.of<Idprovider>(context).resumeId!), // resume ID 전달 //questionsscreen에서 사용하는 resumeId는
      ),
    );
  }

  void navigateToInterviewScreen(String resumeId) {
    print("Navigating to interview screen with resume ID: $resumeId"); //내가 가는 resumeId
    Provider.of<Idprovider>(context, listen: false).setResumeId(resumeId); //현재사용할 resumeId의값을 매개변수로 받은 resumeId로변경한다.
    // QuestionScreen으로 이력서 ID를 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InterviewScreen(resumeId: Provider.of<Idprovider>(context).resumeId!), // resume ID 전달 //questionsscreen에서 사용하는 resumeId는
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume List'),
      ),
      body: loggedUser != null
          ? StreamBuilder<List<PlatformFile>>(
              stream: _resumeService.getUserResumes(loggedUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No resumes found.'));
                }

                final resumes = snapshot.data!;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Resumes',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          // 검색 관련 로직 추가
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: resumes.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.file_copy),
                                title: Text(resumes[index].name),
                                subtitle:
                                    Text('File path: ${resumes[index].path}'),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index; // 선택된 인덱스 저장
                                  });
                                },
                                tileColor: _selectedIndex == index
                                    ? Colors.grey[300]
                                    : null, // 선택된 타일 배경색 변경
                                trailing: _selectedIndex ==
                                        index // 선택된 타일일 경우 버튼 추가
                                    ? SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          ElevatedButton(
                                          onPressed: () {
                                            // 이력서 ID 가져오기
                                            String? resumeId = resumes[index]
                                                .identifier; // 또는 Firestore에서 ID를 가져오는 방법으로 수정
                                      
                                            if (resumeId != null) {
                                              print(resumeId);
                                              navigateToQuestionScreen(
                                                  resumeId); // 질문 페이지로 이동
                                            } else {
                                              print('Error: resumeId is null');
                                              // 적절한 에러 처리 로직 추가 (예: 사용자에게 오류 메시지 표시)
                                            }
                                          },
                                          child: const Text('질문 생성'),
                                        ),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            // 이력서 ID 가져오기
                                            String? resumeId = resumes[index]
                                                .identifier; // 또는 Firestore에서 ID를 가져오는 방법으로 수정
                                      
                                            if (resumeId != null) {
                                              print(resumeId);
                                              navigateToInterviewScreen(
                                                  resumeId); // 질문 페이지로 이동
                                            } else {
                                              print('Error: resumeId is null');
                                              // 적절한 에러 처리 로직 추가 (예: 사용자에게 오류 메시지 표시)
                                            }
                                          },
                                          child: const Text('면접 시작'),
                                        ),
                                        ],),
                                    )
                                    
                                    : null,
                              ),
                              if (_selectedIndex == index)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            )
          : Center(child: Text('Please log in to see your resumes.')),
      floatingActionButton: FloatingActionButton(
        onPressed: pickAndUploadPDF, // 이력서 추가 버튼 연결
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
