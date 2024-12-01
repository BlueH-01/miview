import '../resume/resume_screen.dart';
import 'package:flutter/material.dart';
import '../configure/palette.dart';
import '../firebase/firesbase_init.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _authentication = FirebaseInit().auth;

  bool isSignupScreen = true; // 사인업 관리
  final _formKey = GlobalKey<FormState>();
  String userName = '';
  String userEmail = '';
  String userPassword = '';

  void _tryValidation() {
    final isValid = _formKey.currentState!.validate(); //null 체크 form의 유효성 검사
    if (isValid) {
      _formKey.currentState!.save();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/backg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.only(top: 200, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 140), // My를 왼쪽으로 보내기
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            text: 'My', // 첫 번째 줄
                            style: TextStyle(
                              fontFamily: 'Serif',
                              letterSpacing: 1.0,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(115, 0, 0, 0), // 흰색으로 변경
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5), // 첫 번째 줄과 두 번째 줄 사이에 여백
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          text: 'InterViewer', // 두 번째 줄
                          style: TextStyle(
                            fontFamily: 'Serif',
                            letterSpacing: 1.0,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(110, 0, 0, 0), // 흰색으로 변경
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //배경
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              top: 350, //로그인 박스 위치
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                padding: const EdgeInsets.all(20),
                height: isSignupScreen ? 290.0 : 240.0, //박스 크기
                width: MediaQuery.of(context).size.width - 40,
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      )
                    ]),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isSignupScreen = false;
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: !isSignupScreen
                                        ? const Color.fromARGB(
                                            145, 0, 0, 0) //선택시
                                        : Colors.grey, //선택 안했을시
                                  ),
                                ),
                                if (!isSignupScreen)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    height: 2,
                                    width: 55,
                                    color: Colors.grey, //선택시 밑줄
                                  )
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isSignupScreen = true;
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  '회원 가입',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSignupScreen
                                        ? const Color.fromARGB(
                                            145, 0, 0, 0) //선택시
                                        : Colors.grey, //선택 안했을시
                                  ),
                                ),
                                if (isSignupScreen) //if inline!
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    height: 2,
                                    width: 55,
                                    color: Colors.grey,
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isSignupScreen)
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  key: const Key('username'),
                                  validator: (value) {
                                    if (value!.isEmpty || value.length < 4) {
                                      return 'Please enter at least 4 characters';
                                    } else {
                                      return null;
                                    }
                                  },
                                  onSaved: (value) {
                                    userName = value!;
                                  },
                                  onChanged: (value) {
                                    userName = value;
                                  },
                                  decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.account_circle,
                                        color: Color.fromARGB(
                                            145, 0, 0, 0), //사용자아이콘
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              145, 0, 0, 0), //테두리
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(35.0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(145, 0, 0, 0),
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(35.0),
                                        ),
                                      ),
                                      hintText: '이름',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      contentPadding: EdgeInsets.all(10)),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  key: const Key('email'),
                                  validator: (value) {
                                    if (value!.isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email address';
                                    } else {
                                      return null;
                                    }
                                  },
                                  onSaved: (value) {
                                    userEmail = value!;
                                  },
                                  onChanged: (value) {
                                    userEmail = value;
                                  },
                                  decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: Color.fromARGB(145, 0, 0, 0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(145, 0, 0, 0),
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(35.0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(145, 0, 0, 0),
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(35.0),
                                        ),
                                      ),
                                      hintText: '이메일',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      contentPadding: EdgeInsets.all(10)),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                TextFormField(
                                  obscureText: true,
                                  key: const Key('password'),
                                  validator: (value) {
                                    if (value!.isEmpty || value.length < 6) {
                                      return 'Please enter at least 7 characters long';
                                    } else {
                                      return null;
                                    }
                                  },
                                  onSaved: (value) {
                                    userPassword = value!;
                                  },
                                  onChanged: (value) {
                                    userPassword = value;
                                  },
                                  decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: Color.fromARGB(145, 0, 0, 0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(145, 0, 0, 0),
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(35.0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromARGB(145, 0, 0, 0),
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(35.0),
                                        ),
                                      ),
                                      hintText: '비밀번호',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      contentPadding: EdgeInsets.all(10)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!isSignupScreen)
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  key: const Key('login_email'),
                                  validator: (value) {
                                    if (value!.isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email address';
                                    } else {
                                      return null;
                                    }
                                  },
                                  onSaved: (value) {
                                    userEmail = value!;
                                  },
                                  onChanged: (value) {
                                    userEmail = value;
                                  },
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: Color.fromARGB(145, 0, 0, 0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(145, 0, 0, 0),
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(145, 0, 0, 0),
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35.0),
                                      ),
                                    ),
                                    hintText: '이메일',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(height: 8), // 공간 조정
                                TextFormField(
                                  obscureText: true,
                                  key: const Key('login_password'),
                                  validator: (value) {
                                    if (value!.isEmpty || value.length < 6) {
                                      return 'Please enter at least 7 characters long';
                                    } else {
                                      return null;
                                    }
                                  },
                                  onSaved: (value) {
                                    userPassword = value!;
                                  },
                                  onChanged: (value) {
                                    userPassword = value;
                                  },
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock, // 비밀번호 필드에는 일반적으로 자물쇠 아이콘을 사용
                                      color: Color.fromARGB(145, 0, 0, 0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(145, 0, 0, 0),
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35.0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(145, 0, 0, 0),
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35.0),
                                      ),
                                    ),
                                    hintText: '비밀번호',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(
                                    height: 8), // 로그인 상태에서 필드 간 여백을 조정
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            //텍스트 폼 필드
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              top: isSignupScreen ? 573 : 520.0,
              right: 0,
              left: 245,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  height: 70, //로그인 화살표
                  width: 70,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(50)),
                  child: GestureDetector(
                    onTap: () async {
                      if (isSignupScreen) {
                        try {
                          final newUser = await _authentication
                              .createUserWithEmailAndPassword(
                                  email: userEmail, password: userPassword);
                          if (newUser.user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return const ResumeListScreen();
                              }),
                            );
                          }
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please check your email and password'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      }
                      _tryValidation();
                      if (!isSignupScreen) {
                        try {
                          _tryValidation();
                          final newUser =
                              await _authentication.signInWithEmailAndPassword(
                                  email: userEmail, password: userPassword);
                          if (newUser.user != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return const ResumeListScreen();
                              }),
                            );
                          }
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please check your email and password'),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [
                                Colors.grey,
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ]),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            //전송 버튼
            // 추가적인 UI 구성 요소가 필요할 경우 이곳에 추가
          ],
        ),
      ),
    );
  }
}
