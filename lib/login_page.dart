import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:trackmate/Homepage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String selectedCountryCode = "+1";
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool _isSendingOTP = false;
  bool _isverifyingOTP = false;
  Route _createRoute(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _verifyPhoneNumber() async {
    setState(() {
      _isSendingOTP = true;
    });
    String phoneNumber = "+91" +
        mobileController.text
            .trim(); // Modify this according to your country code.

    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential credential) async {
      print(
          "Phone number automatically verified and user signed in: ${_auth.currentUser?.uid}");
    };

    PhoneVerificationFailed verificationFailed = (FirebaseAuthException e) {
      print("Phone verification failed: ${e.message}");
      _showErrorDialog("Phone verification failed. Please try again.");
      setState(() {
        _isSendingOTP = false;
      });
    };

    PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      _verificationId = verificationId;
      print("Verification code sent to ${mobileController.text}");
      setState(() {
        _isSendingOTP = false;
      });
    };

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      print("Auto retrieval timeout");
      setState(() {
        _isSendingOTP = false;
      });
    };

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      print("Failed to verify phone number: ${e.toString()}");
      _showErrorDialog("Failed to verify phone number. Please try again.");
      setState(() {
        _isSendingOTP = false;
      });
    }
  }

  void _signInWithPhoneNumber(String smsCode) async {
    try {
      setState(() {
        _isSendingOTP = true;
        _isverifyingOTP = true;
      });
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential).then((value) {
        final ref = FirebaseDatabase.instance.ref('users');
        final uid = FirebaseAuth.instance.currentUser?.uid;
        ref.child('${uid}/name').set("${nameController.text}");

        Navigator.pushReplacement(context, _createRoute(homePage()));
      });
      print("User signed in: ${_auth.currentUser?.uid}");
    } catch (e) {
      print("Failed to sign in with phone number: ${e.toString()}");
      _showErrorDialog("Invalid OTP. Please try again.");
      setState(() {
        _isverifyingOTP = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // First Input Box for Name
              SizedBox(height: 20.0),
              Image.asset(
                "assets/images/logo.png",
                height: 400,
              ),
              SizedBox(height: 20.0),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Second Input Box for Mobile Number with Country Code Selector
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CountryCodePicker(
                      onChanged: (CountryCode code) {
                        setState(() {
                          selectedCountryCode = code.toString();
                        });
                      },
                      initialSelection: '+1',
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              ElevatedButton(
                onPressed: _isSendingOTP ? null : _verifyPhoneNumber,
                style: ElevatedButton.styleFrom(
                  primary: _isSendingOTP ? Colors.green : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), // Set the desired border radius here
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _isSendingOTP
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Send OTP'),
                ),
              ),
              SizedBox(height: 30),
              // Third Input Box for OTP
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Buttons with no action (for demonstration purposes)

              ElevatedButton(
                onPressed: _isverifyingOTP
                    ? null
                    : () => _signInWithPhoneNumber(otpController.text.trim()),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), // Set the desired border radius here
                  ),
                ),
                child: _isverifyingOTP
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
