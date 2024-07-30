import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({Key? key, required this.showRegisterPage}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future signIn() async {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    final String textFieldResult = checkTextFields(email, password);

    if (textFieldResult == '') {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password);
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(textFieldResult),
            );
      });
    }
  }

  void textFunctions() {
    //correct
    checkTextFields('rumeysa@gmail.com', 'ru1234');

    // wrong there is no @ in email
    checkTextFields('rumeysagmail.com', 'ru1234');

    //wrong password section is empty
    checkTextFields('rumeysa@gmail.com', '');
  }

  String checkTextFields(String email, String password) {
    if (email.isEmpty || email.length < 8 || !email.contains('@')) {
        return 'Please fill email section!';
    }

    if (password.isEmpty || password.length < 5) {
        return 'Please fill password section!';
    }

    return '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
            child: SingleChildScrollView(
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Image(
                image: AssetImage('assets/images/splash_icon.png'),
              ),
              const SizedBox(height: 80),
              Text(
                'Smart Car Parking',
                style: GoogleFonts.openSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome',
                style: GoogleFonts.openSans(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'E-Mail',
                          ),
                        ),
                      ))),
              const SizedBox(height: 30),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Password',
                          ),
                        ),
                      ))),
              const SizedBox(height: 50),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: signIn,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                          child: Text(
                        'Sign In',
                        style: GoogleFonts.openSans(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      )),
                    ),
                  )),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member?',
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.showRegisterPage,
                    child: Text(
                      ' Register now',
                      style: GoogleFonts.openSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              )
            ]),
          ),
        )));
  }
}
