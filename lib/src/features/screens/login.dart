import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:untitled/src/features/screens/home_screen.dart';
import 'package:untitled/src/features/screens/signup.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _useFaceAuth = false;
  File? _faceImage;
  bool _isLoading = false;

  Future<bool> _containsFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
    );
    final faceDetector = FaceDetector(options: options);
    final List<Face> faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    return faces.isNotEmpty;
  }

  Future<void> _signInWithPassword() async {
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        "Erreur de connexion",
        "Email ou mot de passe incorrect",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFace() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      Get.snackbar("Erreur", "Aucune photo prise",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final faceImage = File(pickedFile.path);

    setState(() {
      _faceImage = faceImage;
      _isLoading = true;
    });

    final hasFace = await _containsFace(faceImage);

    if (!hasFace) {
      setState(() => _isLoading = false);
      Get.snackbar("Erreur", "Aucun visage détecté",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = false);

    Get.snackbar("Succès", "Connexion par visage réussie 🎉",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);

    Get.offAll(() => const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/login_image/login.png',
                      height: height * 0.3),
                ),
                const SizedBox(height: 30),
                Text(
                  "Welcome back!",
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Connexion par reconnaissance faciale"),
                    Switch(
                      value: _useFaceAuth,
                      onChanged: (val) {
                        setState(() => _useFaceAuth = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      if (!_useFaceAuth)
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline),
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (_useFaceAuth && _faceImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.file(_faceImage!, height: 100),
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            if (_useFaceAuth) {
                              _signInWithFace();
                            } else {
                              _signInWithPassword();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : const Text(
                            "Sign In",
                            style: TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("You don't have an account?"),
                          TextButton(
                            onPressed: () =>
                                Get.to(() => const SignUpScreen()),
                            child: const Text("Sign Up"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
