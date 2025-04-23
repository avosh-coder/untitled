import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:untitled/src/features/firebase_authentication/auth_service.dart';
import 'package:untitled/src/features/screens/home_screen.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _useFaceAuth = false;
  File? _faceImage;

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      final inputImage = InputImage.fromFile(imageFile);
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      );
      final faceDetector = FaceDetector(options: options);
      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isNotEmpty) {
        setState(() => _faceImage = imageFile);
        Get.snackbar("Succès", "Visage détecté ✔️",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Erreur", "Aucun visage détecté sur l’image",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } else {
      Get.snackbar("Erreur", "Aucune image capturée",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_useFaceAuth && _faceImage == null) {
      Get.snackbar("Erreur", "Prenez une photo valide avec un visage",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      setState(() => _isLoading = false);
      return;
    }

    final user = await _authService.signUpWithEmailAndPassword(email, password);

    if (user != null) {
      String? imageUrl;

      if (_useFaceAuth && _faceImage != null) {
        final fileName = path.basename(_faceImage!.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("face_images")
            .child("${user.uid}_$fileName");

        try {
          await storageRef.putFile(_faceImage!);
          imageUrl = await storageRef.getDownloadURL();

          print("Image uploaded to Firebase Storage: $imageUrl");
          // Enregistre l'URL dans Firestore si nécessaire
        } catch (e) {
          Get.snackbar("Erreur", "Échec de l'envoi de l'image",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      }

      Get.snackbar("Succès", "Inscription réussie 🎉",
          backgroundColor: Colors.green, colorText: Colors.white);
      Get.offAll(() => const HomeScreen());
    } else {
      Get.snackbar("Erreur", "Inscription échouée",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset('assets/login_image/login.png',
                    height: height * 0.3),
              ),
              const SizedBox(height: 20),
              Text(
                "Create your account",
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Utiliser la reconnaissance faciale"),
                  Switch(
                    value: _useFaceAuth,
                    onChanged: (val) => setState(() => _useFaceAuth = val),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        labelText: "Nom",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Nom requis" : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || !value.contains('@')
                          ? "Email invalide"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        labelText: "Mot de passe",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? "Mot de passe trop court"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (_useFaceAuth)
                      Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Prendre une photo"),
                            onPressed: _isLoading ? null : _takePicture,
                          ),
                          if (_faceImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Image.file(_faceImage!, height: 100),
                            ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("S'inscrire"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
