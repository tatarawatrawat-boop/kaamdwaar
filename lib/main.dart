  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:io';
  import 'package:image_picker/image_picker.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:razorpay_flutter/razorpay_flutter.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:flutter_sound/flutter_sound.dart';
  import 'package:just_audio/just_audio.dart';
  import 'package:path_provider/path_provider.dart';
  import 'modern_drawer.dart';
  import 'package:kaamdwaar/worker_detail_screen.dart';
  import 'worker_detail_screen.dart';
  import 'services/hire_listener.dart';






  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
  }
  
  // 🔥 YAHAN ADD KARO
  void setupFCMListeners() {
  
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  
      ScaffoldMessenger.of(
          navigatorKey.currentContext!)
          .showSnackBar(
        SnackBar(
          content: Text(
            message.notification?.title ?? "New Notification",
          ),
        ),
      );
  
    });
  
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const IncomingRequestsScreen(),
        ),
      );
  
    });
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    setupFCMListeners();

    // 🔥 ADD THIS (MOST IMPORTANT)
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    runApp(MyApp(initialMessage: initialMessage));
  }


  class MyApp extends StatelessWidget {

    final RemoteMessage? initialMessage;

    const MyApp({super.key, this.initialMessage});
  
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: AuthCheckScreen(initialMessage: initialMessage),
      );
    }
  }

  class AuthCheckScreen extends StatefulWidget {

    final RemoteMessage? initialMessage;

    const AuthCheckScreen({super.key, this.initialMessage});

    @override
    State<AuthCheckScreen> createState() => _AuthCheckScreenState();
  }

  class _AuthCheckScreenState extends State<AuthCheckScreen> {

    @override
    void initState() {
      super.initState();

      WidgetsBinding.instance.addPostFrameCallback((_) {

        checkUser();

        // 🔥 Notification click handle
        if (widget.initialMessage != null) {

          Future.delayed(const Duration(seconds: 2), () {

            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => const IncomingRequestsScreen(),
              ),
            );

          });

        }

      });
    }

    Future<void> checkUser() async {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {

        String role = doc["role"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(role: role),
          ),
        );

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );

      }
    }

    @override
    Widget build(BuildContext context) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }
  
  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});
  
    @override
    State<SplashScreen> createState() => _SplashScreenState();
  }
  
  class _SplashScreenState extends State<SplashScreen> {
  
    @override
    void initState() {
      super.initState();
  
      Timer(const Duration(seconds: 2), () {
  
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthCheckScreen(),
          ),
        );
  
      });
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            "assets/images/logo.png",
            height: 300, // 🔥 Logo bada kiya
          ),
        ),
      );
    }
  }
  
  
  // ===== LOGIN SCREEN (LOGO + SINGLE LOGIN BUTTON) =====
  
  // ===== LOGIN SCREEN =====
  
  class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});
  
    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }
  
  class _LoginScreenState extends State<LoginScreen> {
  
    final TextEditingController phoneController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),

        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const SizedBox(height: 40),

                  Image.asset(
                    "assets/images/logo.png",
                    height: 250,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Welcome to KaamDwaar",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixText: "+91 ",
                      hintText: "Enter mobile number",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {

                        if (phoneController.text.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Enter valid 10 digit number")),
                          );
                          return;
                        }

                        await FirebaseAuth.instance.verifyPhoneNumber(
                          phoneNumber: "+91${phoneController.text.trim()}",

                          verificationCompleted:
                              (PhoneAuthCredential credential) {},

                          verificationFailed: (FirebaseAuthException e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      e.message ?? "Verification Failed")),
                            );
                          },

                          codeSent:
                              (String verificationId, int? resendToken) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OtpScreen(
                                        verificationId: verificationId),
                              ),
                            );
                          },

                          codeAutoRetrievalTimeout:
                              (String verificationId) {},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Login करें",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  // ===== OTP SCREEN WITH FIREBASE VERIFY =====
  
  class OtpScreen extends StatefulWidget {
    final String verificationId;
  
    const OtpScreen({super.key, required this.verificationId});
  
    @override
    State<OtpScreen> createState() => _OtpScreenState();
  }
  
  class _OtpScreenState extends State<OtpScreen> {
  
    final TextEditingController otpController = TextEditingController();
  
    void verifyOTP() async {
  
      if (otpController.text.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter valid 6 digit OTP")),
        );
        return;
      }
  
      try {
  
        PhoneAuthCredential credential =
        PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpController.text.trim(),
        );
  
        await FirebaseAuth.instance
            .signInWithCredential(credential);
  
        // 🔥 OTP Success → Role Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const RoleSelectionScreen(),
          ),
        );
  
      } catch (e) {
  
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Failed: $e")),
        );
      }
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
  
              const Text(
                "OTP Verify करें",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
  
              const SizedBox(height: 30),
  
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "------",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
  
              const SizedBox(height: 25),
  
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: verifyOTP, // 🔥 IMPORTANT
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Verify करें",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // ===== ROLE SELECTION SCREEN (FINAL UI LIKE IMAGE) =====
  class RoleSelectionScreen extends StatefulWidget {
    const RoleSelectionScreen({super.key});
  
    @override
    State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
  }
  
  class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  
    String? selectedRole;
  
    Future<void> saveRoleAndContinue() async {
      if (selectedRole == null) return;
  
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("user_role", selectedRole!);
  
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(role: selectedRole!),
        ),
      );
    }
  
    Widget roleCard({
      required String image,
      required String title,
    }) {
      bool isSelected = selectedRole == title;
  
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = (title == "मज़दूर") ? "worker" : "employer";
          });
        },

        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 25),
          padding: const EdgeInsets.symmetric(vertical: 35),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset(image, height: 110),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  const SizedBox(height: 50),

                  const Text(
                    "आप क्या काम करते हैं?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 40),

                  roleCard(
                    image: "assets/images/mazdoor.png",
                    title: "मज़दूर",
                  ),

                  const SizedBox(height: 20),

                  roleCard(
                    image: "assets/images/thekedaar.png",
                    title: "ठेकेदार",
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: selectedRole == null
                        ? null
                        : saveRoleAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "आगे बढ़ें",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 30),

                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  
  // TEMP NEXT SCREEN
  class NextScreen extends StatelessWidget {
    const NextScreen({super.key});
  
    @override
    Widget build(BuildContext context) {
      return const Scaffold(
        body: Center(child: Text("Next Screen")),
      );
    }
  }
  
  
  // ===== _ProfileSetupScreen =====
  
  
  
  class ProfileSetupScreen extends StatefulWidget {
    final String role;
  
    const ProfileSetupScreen({super.key, required this.role});
  
    @override
    State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
  }
  
  class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  
    final _formKey = GlobalKey<FormState>();
  
    final nameController = TextEditingController();
    final workTypeController = TextEditingController();
    final areaController = TextEditingController();
    final pinController = TextEditingController();
  
    File? selectedImage;
    String? imageUrl;
  
    final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
    String? audioPath;
    bool isRecording = false;
    int recordingSeconds = 0;
    Timer? recordingTimer;
  
    bool isLoading = false;
  
    String? selectedState;
    String? selectedDistrict;
  
    // 🔵 STATE - DISTRICT DATA
    final Map<String, List<String>> stateDistrictMap = {
      "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur", "Kota"],
      "Uttar Pradesh": ["Lucknow", "Kanpur", "Agra"],
      "Madhya Pradesh": ["Bhopal", "Indore", "Gwalior"],
    };
  
    // ================= AUDIO RECORD =================
    Future<void> startRecording() async {
      await _recorder.openRecorder();
  
      final dir = await getTemporaryDirectory();
      String path =
          "${dir.path}/intro_${DateTime.now().millisecondsSinceEpoch}.aac";
  
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
  
      setState(() {
        isRecording = true;
        audioPath = path;
        recordingSeconds = 0;
      });
  
      recordingTimer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) {
          setState(() {
            recordingSeconds++;
          });
        },
      );
    }
    Future<void> stopRecording() async {
      recordingTimer?.cancel();
  
      await _recorder.stopRecorder();
  
      setState(() {
        isRecording = false;
      });
  
  
    }
  
    Future<String?> uploadAudio(File file) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
  
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_audio/${user.uid}.m4a");
  
        await ref.putFile(file);
        return await ref.getDownloadURL();
      } catch (e) {
        print("Audio upload error: $e");
        return null;
      }
    }
  
  
    // 📸 PICK IMAGE
    Future<void> pickImage() async {
      try {
        PermissionStatus status;
  
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
        }
  
        if (status.isGranted) {
          final XFile? pickedFile = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 60,
          );
  
          if (pickedFile != null) {
            setState(() {
              selectedImage = File(pickedFile.path);
            });
          }
        }
      } catch (e) {
        print("Image Picker Error: $e");
      }
    }
  
    // ☁ UPLOAD IMAGE
    Future<String?> uploadImage(File image) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
  
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_images/${user.uid}.jpg");
  
        await ref.putFile(image);
        return await ref.getDownloadURL();
      } catch (e) {
        print("Upload error: $e");
        return null;
      }
    }
    Future<Position> getUserLocation() async {
  
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }
  
      LocationPermission permission = await Geolocator.checkPermission();
  
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
  
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied.");
      }
  
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
    // 💾 SAVE PROFILE
    Future<void> saveProfile() async {
      try {
  
        if (!_formKey.currentState!.validate()) return;
  
        if (selectedState == null || selectedDistrict == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("राज्य और जिला चुनना आवश्यक है")),
          );
          return;
        }
  
        setState(() {
          isLoading = true;
        });
  
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            isLoading = false;
          });
          return;
        }
  
        /// 🔥 LOCATION GET KARO
        Position position = await getUserLocation();
  
        String? finalImageUrl = imageUrl;
        String? finalAudioUrl;
  
        if (audioPath != null) {
          finalAudioUrl = await uploadAudio(File(audioPath!));
        }
  
        if (selectedImage != null) {
          finalImageUrl = await uploadImage(selectedImage!);
        }
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "name": nameController.text.trim(),
          "phone": user.phoneNumber ?? "",
          "role": widget.role,
          "workType": workTypeController.text.trim(),
          "state": selectedState,
          "district": selectedDistrict,
          "area": areaController.text.trim(),
          "pin": pinController.text.trim(),
          "dp": finalImageUrl ?? "",
  
          // 🔥 IMPORTANT DEFAULT FIELDS
          "wallet": 0,
          "totalJobs": 0,
          "totalEarned": 0,
          "isAvailable": true,
  
          // ⭐ RATING SYSTEM DEFAULT
          "rating": 0.0,
          "totalRatings": 0,
  
          "latitude": position.latitude,
          "longitude": position.longitude,
  
          "createdAt": Timestamp.now(),
  
          "audioUrl": finalAudioUrl ?? "",
          "hasIntro": finalAudioUrl != null,
        });
  
        setState(() {
          isLoading = false;
        });
  
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(role: widget.role),
          ),
        );
  
      } catch (e) {
  
        setState(() {
          isLoading = false;
        });
  
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile Setup"),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
  
                  const SizedBox(height: 20),
  
                  Text(
                    "Selected Role: ${widget.role}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
  
                  const SizedBox(height: 30),
  
                  // 📸 DP
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                      selectedImage != null ? FileImage(selectedImage!) : null,
                      child: selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
  
                  const SizedBox(height: 30),
  
                  GestureDetector(
                    onLongPressStart: (_) => startRecording(),
                    onLongPressEnd: (_) => stopRecording(),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: isRecording
                            ? Text(
                          "Recording... $recordingSeconds s",
                          style: const TextStyle(color: Colors.white),
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Hold to Record Intro",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
  
                  buildField("पूरा नाम", nameController),
  
                  buildField(
                    widget.role == "मज़दूर"
                        ? "आप कौन सा काम करते हैं?"
                        : "आप किस प्रकार का काम देते हैं?",
                    workTypeController,
                  ),
  
                  // 🔽 STATE DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedState,
                    hint: const Text("राज्य चुनें"),
                    items: stateDistrictMap.keys.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedState = value;
                        selectedDistrict = null;
                      });
                    },
                    validator: (value) =>
                    value == null ? "राज्य चुनना आवश्यक है" : null,
                  ),
  
                  const SizedBox(height: 20),
  
                  // 🔽 DISTRICT DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedDistrict,
                    hint: const Text("जिला चुनें"),
                    items: selectedState == null
                        ? []
                        : stateDistrictMap[selectedState]!
                        .map((district) => DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDistrict = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? "जिला चुनना आवश्यक है" : null,
                  ),
  
                  const SizedBox(height: 20),
  
                  buildField("क्षेत्र", areaController),
                  buildField("पिन कोड", pinController,
                      keyboard: TextInputType.number),
  
                  const SizedBox(height: 30),
  
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize:
                      const Size(double.infinity, 50),
                    ),
                    child: const Text("Save & Continue"),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
  
    Widget buildField(String hint, TextEditingController controller,
        {TextInputType keyboard = TextInputType.text}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "यह फील्ड खाली नहीं हो सकता";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
  
    @override
    void dispose() {
  
      recordingTimer?.cancel();
      nameController.dispose();
      workTypeController.dispose();
      areaController.dispose();
      pinController.dispose();
      super.dispose();
    }
  }
  
  
  //============== DashboardScreen=============
  class DashboardScreen extends StatefulWidget {
    final String role;
    const DashboardScreen({super.key, required this.role});
  
    @override
    State<DashboardScreen> createState() => _DashboardScreenState();
  }
  
  class _DashboardScreenState extends State<DashboardScreen> {
    final FlutterSoundRecorder dashboardRecorder = FlutterSoundRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();

    String? dashboardAudioPath;

    String audioUrl = "";

    bool isRecordingDashboard = false;
    int recordSeconds = 0;
    Timer? recordTimer;

    Future<void> loadAudioUrl() async {
      try {
        var doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        setState(() {
          audioUrl = doc.data()?["audioUrl"] ?? "";
        });
      } catch (e) {
        print("Error loading audioUrl: $e");
      }
    }

    Future<String?> uploadDashboardAudio(File file) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print("❌ USER NULL");
          return null;
        }

        print("📤 Upload start");

        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_audio/${user.uid}.m4a");

        UploadTask uploadTask = ref.putFile(file);

        TaskSnapshot snapshot = await uploadTask;

        String url = await snapshot.ref.getDownloadURL();

        print("✅ UPLOAD DONE: $url");

        return url;

      } catch (e) {
        print("❌ Upload error: $e");
        return null;
      }
    }



    Future<void> startDashboardRecording() async {
      try {
        var status = await Permission.microphone.request();

        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Mic permission nahi mili")),
          );
          return;
        }

        // 🔥 ADD THIS (MOST IMPORTANT)
        if (!dashboardRecorder.isRecording) {
          await dashboardRecorder.openRecorder();
        }

        final dir = await getTemporaryDirectory();

        // 🔥 EXTENSION FIX
        String path =
            "${dir.path}/intro_${DateTime.now().millisecondsSinceEpoch}.m4a";

        await dashboardRecorder.startRecorder(
          toFile: path,
          codec: Codec.aacMP4,
        );

        print("🎤 STARTED");

        setState(() {
          isRecordingDashboard = true;
          recordSeconds = 0;
          dashboardAudioPath = path;
        });

        recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            recordSeconds++;
          });
          print("⏱ $recordSeconds");
        });

      } catch (e) {
        print("❌ START ERROR: $e");
      }
    }

    Future<void> stopDashboardRecording() async {
      recordTimer?.cancel();

      await dashboardRecorder.stopRecorder();

      setState(() {
        isRecordingDashboard = false;
      });

      // ❗ short recording check
      if (recordSeconds < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Recording too short")),
        );
        return;
      }

      // 🎧 PREVIEW DIALOG ///// yeha kaam kar rahe hai
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Preview Intro 🎧"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ⏱ Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "$recordSeconds sec",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                Text("Play karke check kar lo"),
              ],
            ),

            actions: [

              // ▶️ PLAY
              TextButton(
                onPressed: () async {
                  if (dashboardAudioPath != null) {
                    await audioPlayer.setFilePath(dashboardAudioPath!);
                    audioPlayer.play();
                  }
                },
                child: Text("Play"),
              ),

              // ❌ DISCARD
              TextButton(
                onPressed: () async {
                  await audioPlayer.stop();
                  Navigator.pop(context);
                },
                child: Text("Discard"),
              ),

              // ✅ SAVE
              TextButton(
                onPressed: () async {
                  await audioPlayer.stop();
                  Navigator.pop(context);

                  try {
                    if (dashboardAudioPath == null) {
                      print("❌ Path null");
                      return;
                    }

                    File file = File(dashboardAudioPath!);

                    print("📁 File exists: ${file.existsSync()}");

                    String? url = await uploadDashboardAudio(file);

                    print("🔥 FINAL URL: $url");

                    // 🔥 IMPORTANT CHECK
                    if (url == null || url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❌ Upload failed")),
                      );
                      return;
                    }

                    // 🔥 FIRESTORE SAVE (FINAL FIX)
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .set({
                      "audioUrl": url,
                      "hasIntro": true, // 🔥 MUST
                    }, SetOptions(merge: true));

                    print("✅ Firestore UPDATED");

                    setState(() {
                      audioUrl = url;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ Intro Saved")),
                    );

                  } catch (e) {
                    print("❌ SAVE ERROR: $e");
                  }
                },
                child: Text("Save"),
              )
            ],
          );
        },
      );
    }


    // 🔥 TIMER VARIABLES ADD KARO

    Timer? requestTimer;
    int remainingSeconds = 30;
    bool isDialogOpen = false;

    Timer? paymentTimer;
    int paymentSeconds = 600;

    bool isDetailOpen = false;

    final AudioPlayer ringtonePlayer = AudioPlayer();
  
    // Variables jo data store karenge
    String name = "Loading...";
    String dp = "";
    String area = "...";
    int wallet = 0;
    bool isAvailable = true;

    Future<void> checkActiveRequest() async {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      // 🔥 Sender side request check
      QuerySnapshot senderSnapshot = await FirebaseFirestore.instance
          .collection("hireRequests")
          .where("senderId", isEqualTo: uid)
          .get();

      for (var doc in senderSnapshot.docs) {

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data["status"] ?? "pending";

        if (status == "accepted") {

          data["id"] = doc.id;

          showReceiverPaymentDialog(data);
          return;

        }

      }

      // 🔥 Receiver side request check
      QuerySnapshot receiverSnapshot = await FirebaseFirestore.instance
          .collection("hireRequests")
          .where("receiverId", isEqualTo: uid)
          .where("status", isEqualTo: "pending")
          .get();

      for (var doc in receiverSnapshot.docs) {

        showHireDialog(doc.id);
        return;

      }

    }

    @override
    void initState() {
      super.initState();

      getUserData();
      loadAudioUrl(); // 🔥 YAHI ADD KARNA HAI

      saveFCMToken();
      checkActiveRequest();

      listenIncomingRequests();
      listenReceiverPayment();
      listenBothPaymentComplete();

      listenSenderUpdates();
    }

    void listenBothPaymentComplete() {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      FirebaseFirestore.instance
          .collection("hireRequests")
          .where("status", isEqualTo: "accepted")
          .snapshots()
          .listen((snapshot) async {

        for (var doc in snapshot.docs) {

          Map<String, dynamic> data = doc.data();

          String senderId = data["senderId"];
          String receiverId = data["receiverId"];

          bool senderPaid = data["senderPaid"] ?? false;
          bool receiverPaid = data["receiverPaid"] ?? false;

          if (senderPaid && receiverPaid && !isDetailOpen) {

            isDetailOpen = true;

            if (uid == senderId || uid == receiverId) {

              String otherUserId =
              uid == senderId ? receiverId : senderId;

              DocumentSnapshot otherUserDoc =
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(otherUserId)
                  .get();

              Map<String, dynamic> otherUser =
              (otherUserDoc.data() ?? {}) as Map<String, dynamic>;

              Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => WorkerDetailScreen(
                    name: otherUser["name"] ?? "",
                    work: otherUser["workType"] ?? "",
                    area: otherUser["area"] ?? "",
                    phone: otherUser["phone"] ?? "",
                    lat: (otherUser["latitude"] ?? 0).toDouble(),
                    lng: (otherUser["longitude"] ?? 0).toDouble(),
                    rating: (otherUser["rating"] ?? 0).toDouble(),
                    introAudio: otherUser["audioUrl"] ?? "",
                  ),
                ),
              ).then((_) {
                isDetailOpen = false;
              });

            }

          }

        }

      });

    }


    void listenSenderUpdates() {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      FirebaseFirestore.instance
          .collection("hireRequests")
          .where("senderId", isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {

        for (var change in snapshot.docChanges) {

          if (change.type == DocumentChangeType.modified) {

            Map<String, dynamic> data =
            change.doc.data() as Map<String, dynamic>;

            String status = data["status"] ?? "pending";

            if (status == "accepted") {

              Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => const WorkerAcceptedScreen(),
                ),
              );

            }

            if (status == "rejected") {

              ScaffoldMessenger.of(navigatorKey.currentContext!)
                  .showSnackBar(
                const SnackBar(
                  content: Text("Worker rejected your request"),
                ),
              );

            }

            if (status == "expired") {

              ScaffoldMessenger.of(navigatorKey.currentContext!)
                  .showSnackBar(
                const SnackBar(
                  content: Text("Request expired"),
                ),
              );

            }

          }

        }

      });

    }



    void listenIncomingRequests() {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      FirebaseFirestore.instance
          .collection("hireRequests")
          .where("receiverId", isEqualTo: uid)
          .where("status", isEqualTo: "pending")
          .snapshots()
          .listen((snapshot) {

        for (var doc in snapshot.docs) {

          if (!isDialogOpen) {

            String requestId = doc.id;

            showHireDialog(requestId);

          }

        }

      });
    }



    Future<void> playAudio(String url) async {
      try {
        await audioPlayer.setUrl(url);
        audioPlayer.play();
      } catch (e) {
        print("Audio error: $e");
      }
    }


    Widget _buildHorizontalMajdoorCard(
        Map<String, dynamic> data,
        ) {
      String name = data["name"] ?? "";
      String work = data["workType"] ?? "";
      String area = data["area"] ?? "";
      String dp = data["dp"] ?? "";
      bool isAvailable = data["isAvailable"] ?? false;
      String audioUrl = data["audioUrl"] ?? "";

      print("USER: $name | AUDIO: $audioUrl");

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [

            Container(
              width: 4,
              height: 75,
              decoration: BoxDecoration(
                color: isAvailable ? Color(0xFF43A047) : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            SizedBox(width: 12),

            CircleAvatar(
              radius: 28,
              backgroundImage: dp.isNotEmpty ? NetworkImage(dp) : null,
              child: dp.isEmpty ? Icon(Icons.person) : null,
            ),

            SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),

                      Row(
                        children: [

                          // 🔊 AUDIO BUTTON
                          if (audioUrl != null && audioUrl.toString().isNotEmpty)
                            GestureDetector(
                              onTap: () => playAudio(audioUrl),
                              child: Container(
                                margin: EdgeInsets.only(right: 6),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.play_arrow, size: 14, color: Colors.blue),
                                    SizedBox(width: 3),
                                    Text("Intro", style: TextStyle(fontSize: 10, color: Colors.blue)),
                                  ],
                                ),
                              ),
                            ),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAvailable ? Color(0xFFE8F5E9) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAvailable ? "Available" : "Offline",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isAvailable ? Color(0xFF2E7D32) : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 6),

                  Text(
                    work,
                    style: TextStyle(color: Color(0xFF1E88E5)),
                  ),

                  SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(area, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  
    Future<void> saveFCMToken() async {
  
      String? token =
      await FirebaseMessaging.instance.getToken();
  
      if (token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "fcmToken": token,
        });
      }
    }
    // DATA FETCH KARNE KA FUNCTION
    void getUserData() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            name = doc.data()?['name'] ?? "No Name";
            dp = doc.data()?['dp'] ?? "";
            area = doc.data()?['area'] ?? "";
            wallet = doc.data()?['wallet'] ?? 0;
            isAvailable = doc.data()?['isAvailable'] ?? true;
          });
        }
      }
    }
    void showHireDialog(String requestId) async {

      await ringtonePlayer.setAsset("assets/sounds/ringtone.mp3");
      ringtonePlayer.setLoopMode(LoopMode.one);
      ringtonePlayer.play();

      isDialogOpen = true;
      remainingSeconds = 30;
      requestTimer?.cancel();

      // 🔥 Request Data Fetch
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection("hireRequests")
          .doc(requestId)
          .get();

      String senderId = requestDoc["senderId"];

      DocumentSnapshot senderDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(senderId)
          .get();

      String senderName = senderDoc["name"] ?? "";
      String workType = senderDoc["workType"] ?? "";
      String area = senderDoc["area"] ?? "";
      String dp = senderDoc["dp"] ?? "";

      double senderLat = (senderDoc["latitude"] ?? 0).toDouble();
      double senderLng = (senderDoc["longitude"] ?? 0).toDouble();

      String receiverId = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot receiverDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(receiverId)
          .get();

      double receiverLat = (receiverDoc["latitude"] ?? 0).toDouble();
      double receiverLng = (receiverDoc["longitude"] ?? 0).toDouble();

      double distanceMeters = Geolocator.distanceBetween(
        receiverLat,
        receiverLng,
        senderLat,
        senderLng,
      );

      String distanceText =
      distanceMeters < 1000
          ? "${distanceMeters.toStringAsFixed(0)} m"
          : "${(distanceMeters / 1000).toStringAsFixed(1)} KM";

      showGeneralDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        barrierLabel: "HireRequest",
        barrierColor: Colors.black.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {

          return StatefulBuilder(
            builder: (context, setStateDialog) {

              requestTimer ??= Timer.periodic(
                const Duration(seconds: 1),
                    (timer) async {

                  if (remainingSeconds <= 0) {

                    timer.cancel();
                    requestTimer = null;

                    await ringtonePlayer.stop();

                    // 🔥 पहले request status check करो
                    DocumentSnapshot doc = await FirebaseFirestore.instance
                        .collection("hireRequests")
                        .doc(requestId)
                        .get();

                    String status = doc["status"] ?? "pending";

                    // सिर्फ pending होने पर expire करो
                    if (status == "pending") {
                      await FirebaseFirestore.instance
                          .collection("hireRequests")
                          .doc(requestId)
                          .update({"status": "expired"});
                    }

                    Navigator.pop(context);
                    isDialogOpen = false;

                  } else {
                    setStateDialog(() {
                      remainingSeconds--;
                    });
                  }

                },
              );

              return Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        /// ⏰ Time
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            TimeOfDay.now().format(context),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "New Hire Request",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// 🔥 Sender Info
                        Row(
                          children: [

                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                              dp.isNotEmpty ? NetworkImage(dp) : null,
                              child: dp.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    workType,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14,
                                          color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$area • $distanceText",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),



                        const SizedBox(height: 20),

                        /// ⏱ Timer
                        Stack(
                          alignment: Alignment.center,
                          children: [

                            SizedBox(
                              height: 120,
                              width: 120,
                              child: CircularProgressIndicator(
                                value: remainingSeconds / 30,
                                strokeWidth: 8,
                                backgroundColor:
                                Colors.orange.shade100,
                                valueColor:
                                const AlwaysStoppedAnimation(
                                    Colors.orange),
                              ),
                            ),

                            Text(
                              "00:${remainingSeconds.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        Row(
                          children: [

                            /// ❌ Reject
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {

                                  requestTimer?.cancel();
                                  requestTimer = null;

                                  await ringtonePlayer.stop();

                                  await FirebaseFirestore.instance
                                      .collection("hireRequests")
                                      .doc(requestId)
                                      .update({"status": "rejected"});

                                  Navigator.of(context).pop();
                                  isDialogOpen = false;
                                },
                                icon: const Icon(Icons.close),
                                label: const Text("Reject"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            /// ✅ Accept
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {

                                  requestTimer?.cancel();
                                  requestTimer = null;

                                  await ringtonePlayer.stop();

                                  await FirebaseFirestore.instance
                                      .collection("hireRequests")
                                      .doc(requestId)
                                      .update({
                                    "status": "accepted",
                                    "acceptedAt": Timestamp.now(),
                                    "paymentExpiry": Timestamp.fromDate(
                                        DateTime.now().add(const Duration(minutes: 10))),
                                  });

                                  Navigator.of(context).pop();
                                  isDialogOpen = false;

                                  /// 🔥 Request Data Fetch
                                  DocumentSnapshot doc = await FirebaseFirestore.instance
                                      .collection("hireRequests")
                                      .doc(requestId)
                                      .get();

                                  Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>;

                                  data["id"] = doc.id;

                                  /// 🔥 Payment Dialog Open
                                  showReceiverPaymentDialog(data);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text("Accept"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    void showReceiverPaymentDialog(
        Map<String, dynamic> data,
        ) {

      isDialogOpen = true;

      final context = navigatorKey.currentContext;

      if (context == null) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "Payment",
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 300),

        pageBuilder: (dialogContext, animation, secondaryAnimation) {

          return Center(
            child: Material(
              color: Colors.transparent,

              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// LOCK ICON
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "🔒 Direct Connection Unlock",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "To contact this worker directly,\ncomplete the ₹5 secure connection fee.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Valid for next 10 minutes",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [

                        /// NOT NOW BUTTON
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              isDialogOpen = false;
                            },
                            child: const Text("Not Now"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// PAY BUTTON
                        Expanded(
                          child: ElevatedButton(

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            onPressed: () async {

                              try {

                                /// 🔥 WALLET ₹5 DEDUCT
                                await processHireWithCommission(
                                  user1Id: FirebaseAuth.instance.currentUser!.uid,
                                  user2Id: data["senderId"],
                                );

                                await FirebaseFirestore.instance
                                    .collection("hireRequests")
                                    .doc(data["id"])
                                    .update({
                                  "receiverPaid": true
                                });

                                Navigator.of(dialogContext).pop();
                                isDialogOpen = false;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("₹5 Payment Successful"),
                                  ),
                                );

                                /// WORKER PROFILE OPEN
                                String workerId = data["senderId"];

                                DocumentSnapshot workerDoc =
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(workerId)
                                    .get();

                                Map<String, dynamic> worker =
                                (workerDoc.data() ?? {}) as Map<String, dynamic>;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkerDetailScreen(
                                      name: worker["name"] ?? "",
                                      work: worker["workType"] ?? "",
                                      area: worker["area"] ?? "",
                                      phone: worker["phone"] ?? "",
                                      lat: (worker["latitude"] ?? 0).toDouble(),
                                      lng: (worker["longitude"] ?? 0).toDouble(),
                                      rating: (worker["rating"] ?? 0).toDouble(),
                                      introAudio: worker["audioUrl"] ?? "",
                                    ),
                                  ),
                                );

                              } catch (e) {

                                isDialogOpen = false;

                                /// 🔴 WALLET BALANCE NAHI HAI
                                if (e.toString().contains("Balance Required")) {

                                  Navigator.of(dialogContext).pop();

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WalletScreen(),
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Wallet में ₹5 नहीं है, पहले recharge करें"),
                                    ),
                                  );

                                } else {

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );

                                }

                              }

                            },

                            child: const Text(
                              "Pay ₹5 Securely",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    void listenReceiverPayment() {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      FirebaseFirestore.instance
          .collection("hireRequests")
          .where("senderId", isEqualTo: uid)
          .where("status", isEqualTo: "accepted")
          .where("receiverPaid", isEqualTo: true)
          .snapshots()
          .listen((snapshot) async {

        if (snapshot.docs.isNotEmpty) {

          var doc = snapshot.docs.first;
          Map<String, dynamic> data = doc.data();

          if (!isDialogOpen && !isDetailOpen) {

            isDetailOpen = true;

            String otherUserId = data["receiverId"];

            DocumentSnapshot workerDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(otherUserId)
                .get();

            Map<String, dynamic> worker =
            (workerDoc.data() ?? {}) as Map<String, dynamic>;

            Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => WorkerDetailScreen(
                  name: worker["name"] ?? "",
                  work: worker["workType"] ?? "",
                  area: worker["area"] ?? "",
                  phone: worker["phone"] ?? "",
                  lat: (worker["latitude"] ?? 0).toDouble(),
                  lng: (worker["longitude"] ?? 0).toDouble(),
                  rating: (worker["rating"] ?? 0).toDouble(),
                  introAudio: worker["audioUrl"] ?? "",
                ),
              ),
            ).then((_) {
              isDetailOpen = false;
            });

          }

        }

      });

    }
  
  
    // ================= NEARBY JOBS METHOD =================
    Widget _buildNearbyJobs() {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getNearbyJobsStream(),
        builder: (context, snapshot) {
  
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
  
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("कोई nearby मजदूर नहीं मिला"),
            );
          }
  
          var workers = snapshot.data!;
  
          return SizedBox(
            height: 260, // Mazdoor list card height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: workers.length,
              itemBuilder: (context, index) {
  
                var data = workers[index];

                return Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: const EdgeInsets.only(right: 12),
                  child: buildMazdoorCard(
                    context: context,
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    workerId: data["id"],
                    data: data,
                    playAudio: playAudio,
                    processHireWithCommission: processHireWithCommission,
                    isThekedar: widget.role == "मज़दूर",
                  ),
                );
              },
            ),
          );
        },
      );
    }
  
    Future<void> processHireWithCommission({
      required String user1Id,
      required String user2Id,
    }) async {

      const int commission = 5;

      await FirebaseFirestore.instance.runTransaction((transaction) async {

        DocumentReference user1Ref =
        FirebaseFirestore.instance.collection("users").doc(user1Id);

        DocumentReference user2Ref =
        FirebaseFirestore.instance.collection("users").doc(user2Id);

        DocumentReference adminRef =
        FirebaseFirestore.instance.collection("admin").doc("main");

        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot user2Snap = await transaction.get(user2Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);

        int user1Wallet = user1Snap["wallet"] ?? 0;
        int user2Wallet = user2Snap["wallet"] ?? 0;
        int adminWallet = adminSnap["wallet"] ?? 0;

        if (user1Wallet < commission || user2Wallet < commission) {
          throw Exception("₹5 Balance Required");
        }

        transaction.update(user1Ref, {
          "wallet": user1Wallet - commission,
        });

        transaction.update(user2Ref, {
          "wallet": user2Wallet - commission,
        });

        transaction.update(adminRef, {
          "wallet": adminWallet + (commission * 2),
          "totalEarning": FieldValue.increment(commission * 2),
        });
      });
    }
    Stream<List<Map<String, dynamic>>> _getNearbyJobsStream() async* {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      var userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
  
      if (!userDoc.exists) {
        yield [];
        return;
      }
  
      double userLat = (userDoc.data()?["latitude"] ?? 0).toDouble();
      double userLng = (userDoc.data()?["longitude"] ?? 0).toDouble();

      String role = widget.role.toString().trim();

      String targetRole =
      (role == "worker" || role == "मज़दूर")
          ? "ठेकेदार"
          : "मज़दूर";

      yield* FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: targetRole)
          .where("isAvailable", isEqualTo: true)
          .snapshots()
          .asyncMap((snapshot) async {

        List<Map<String, dynamic>> nearbyWorkers = [];

        for (var doc in snapshot.docs) {

          if (doc.id == user.uid) continue;

          var data = doc.data() as Map<String, dynamic>;

          print("FILTER ROLE: ${widget.role}");
          print("DOC ROLE: ${data["role"]}");

          data["id"] = doc.id;

          double workerLat = (data["latitude"] ?? 0).toDouble();
          double workerLng = (data["longitude"] ?? 0).toDouble();

          double distance = Geolocator.distanceBetween(
              userLat, userLng, workerLat, workerLng);

          if (distance <= 50000 ) {
            data["distance"] = distance;
            nearbyWorkers.add(data);
          }
        }

        nearbyWorkers.sort(
              (a, b) => a["distance"].compareTo(b["distance"]),
        );

        return nearbyWorkers;
      });
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
  
        // ================= SIDE DRAWER (Wallet shift yahan kiya hai) =================
        drawer: _buildDrawer(context),
  
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("Dashboard", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
  
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= PROFILE HEADER =================
                _buildCompactProfile(),
  
                const SizedBox(height: 15),
  
                // ================= BANNER PLACEHOLDER (Balance/Trans ki jagah) =================
                _buildBannerSlider(),
  
                const SizedBox(height: 15),
  
  
                // ================= NAV BUTTONS =================
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _smallNavButton(Icons.people_alt, "मजदूर लिस्ट", Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MajdoorListScreen()));
                    }),
                    _smallNavButton(Icons.business, "ठेकेदार लिस्ट", Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ThekedarListScreen()));
                    }),

                    _smallNavButton(Icons.notifications, "Requests", Colors.orange, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestsUpdatesScreen(),
                        ),
                      );
                    }),
                  ],
                ),
  
  
                const SizedBox(height: 18),
  
  
                // ================= NEARBY JOBS =================
                _smallSectionHeader("Nearby Jobs"),
                const SizedBox(height: 8),
  
                _buildNearbyJobs(),
  
                const SizedBox(height: 18),
                // ================= WORK HISTORY =================
                _smallSectionHeader("My Work History"),
                const SizedBox(height: 8),
                _compactJobScroll([
                  _compactJobItem("Brickwork", "Civil Lines", "₹8002 dy", 4),
                  _compactJobItem("Unloading Cement", "Sahadatganj", "₹200", 4),
                ]),
              ],
            ),
          ),
        ),
      );
    }
  
    // --- Drawer Widget (Wallet Option Yahan Hai) ---
    Widget _buildDrawer(BuildContext context) {
  
      String uid = FirebaseAuth.instance.currentUser!.uid;

      return Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;

            String name = data["name"] ?? "";
            String role = data["role"] ?? "";
            String dp = data["dp"] ?? "";
            int wallet = data["wallet"] ?? 0;

            return Column(
              children: [

                // 🔥 MODERN HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 55, bottom: 25),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [

                      CircleAvatar(
                        radius: 45,
                        backgroundImage:
                        dp.isNotEmpty ? NetworkImage(dp) : null,
                        child: dp.isEmpty
                            ? const Icon(Icons.person,
                            size: 40, color: Colors.white)
                            : null,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),

                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    title: const Text(
                      "My Wallet",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      "₹$wallet",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WalletScreen(),
                        ),
                      );
                    },
                  ),
                ),

                // 🔽 MENU SECTION
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [

                      _drawerTile(Icons.edit, "Edit Profile", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileSetupScreen(role: role),
                          ),
                        );
                      }),

                      _drawerTile(Icons.bar_chart, "Earnings Report", () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EarningsReportScreen()));
                      }),

                      const Divider(),

                      _drawerTile(Icons.work, "My Jobs", () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MyJobsScreen()));
                      }),

                      _drawerTile(Icons.history, "Hire History", () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const HireHistoryScreen()));
                      }),



                      const Divider(),

                      _drawerTile(Icons.star, "My Ratings", () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MyRatingsScreen()));
                      }),

                      _drawerTile(Icons.workspace_premium, "Premium Badge", () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PremiumScreen()));
                      }),

                      const Divider(),

                      _drawerTile(Icons.settings, "Settings", () {}),

                      _drawerTile(Icons.language, "Language / भाषा", () {
                        showLanguageDialog(context);
                      }),

                      _drawerTile(Icons.logout, "Logout", () async {

                        final user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(user.uid)
                              .set({"isAvailable": false},
                              SetOptions(merge: true));
                        }

                        await FirebaseAuth.instance.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                        );

                      }, isLogout: true),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    Widget _drawerTile(IconData icon, String title,
        VoidCallback onTap,
        {bool isLogout = false}) {
      return ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Colors.green,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black,
          ),
        ),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      );
    }


    void showLanguageDialog(BuildContext context) {

      showDialog(
        context: context,
        builder: (context) {

          return AlertDialog(

            title: const Text("Select Language"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Hindi (हिंदी)"),
                  onTap: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("हिंदी चुनी गई")),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("English"),
                  onTap: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("English Selected")),
                    );
                  },
                ),

              ],
            ),
          );

        },
      );
    }


  
    // --- Banner Placeholder (Upar wale dono card hata kar ye lagaya hai) ---
    Widget _buildBannerSlider() {
      return SizedBox(
        height: 150,
        child: PageView(
          children: [
  
            _bannerImage("assets/images/banner1.png"),
            _bannerImage("assets/images/banner2.png"),
            _bannerImage("assets/images/banner1.png"),
  
          ],
        ),
      );
    }
  
    Widget _bannerImage(String imagePath) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  
    // --- Profile Header ---
    Widget _buildCompactProfile() {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
  
                // 🔥 REAL DP
                CircleAvatar(
                  radius: 28,
                  backgroundImage: dp.isNotEmpty
                      ? NetworkImage(dp)
                      : null,
                  child: dp.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
  
                const SizedBox(width: 10),
  
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
  
                      // 🔥 REAL NAME
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
  
                      // 🔥 ROLE
                      Text(
                        widget.role,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
  
                      const SizedBox(height: 4),
  
                      // 🔥 REAL AREA
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            area,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
  
                _buildAvailabilityToggle(),
              ],
            ),
  
            const SizedBox(height: 10),
  
            _smallProfileProgress(),
          ],
        ),
      );
    }
  
  
  
    Widget _buildAvailabilityToggle() {
      return GestureDetector(
        onTap: toggleAvailability,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                isAvailable ? "Available" : "Offline",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
  
    Future<void> toggleAvailability() async {
      String uid = FirebaseAuth.instance.currentUser!.uid;
  
      setState(() {
        isAvailable = !isAvailable;
      });
  
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "isAvailable": isAvailable,
      });
    }

    Widget _smallProfileProgress() {
      return GestureDetector(
        onLongPressStart: (_) => startDashboardRecording(),
        onLongPressEnd: (_) => stopDashboardRecording(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(Icons.mic, color: Colors.white, size: 18),
              SizedBox(width: 8),

              Text(
                isRecordingDashboard
                    ? "Recording... $recordSeconds s"
                    : (audioUrl ?? "").isNotEmpty
                    ? "Intro Available ✅ (Hold to Replace)"
                    : "Hold to Record Intro",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
        ),
      );
    }
  
    // Ye naya code hai jo click karne par dusri screen par le jayega
    Widget _smallNavButton(IconData icon, String text, Color color, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap, // Click hone par kya hoga, wo yahan se decide hoga
        child: Container(
          width: 95,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            // Thoda shadow add kiya hai taaki button jaisa lage
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(text,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10
                ),
              ),
            ],
          ),
        ),
      );
    }
  
    Widget _smallSectionHeader(String title) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("और देखें >", style: TextStyle(color: Colors.grey, fontSize: 11))
        ],
      );
    }
  
    Widget _compactJobScroll(List<Widget> items) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: items),
      );
    }
  
    Widget _compactJobItem(String title, String loc, String price, int stars) {
      return Container(
        width: 185,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 4),
            Row(children: List.generate(5, (i) => Icon(Icons.star, size: 10, color: i < stars ? Colors.orange : Colors.grey.shade200))),
            const SizedBox(height: 10),
            // Yahan se maine Price (RS) hata diya hai
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Button ko right side rakhne ke liye
              children: [
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                  child: const Center(
                      child: Text("Apply", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                  ),
                )
              ],
            )
          ],
        ),
      );
    }
  }
  
  
  //================= MAJDOOR LIST =================
  
  class MajdoorListScreen extends StatefulWidget {
    const MajdoorListScreen({super.key});
  
    @override
    State<MajdoorListScreen> createState() => _MajdoorListScreenState();
  }
  
  class _MajdoorListScreenState extends State<MajdoorListScreen> {
  
    // 🔥 ₹5 + ₹5 Commission System
    Future<void> processHireWithCommission({
      required String user1Id,
      required String user2Id,
    }) async {
  
      const int commission = 5;
  
      await FirebaseFirestore.instance.runTransaction((transaction) async {
  
        DocumentReference user1Ref =
        FirebaseFirestore.instance.collection("users").doc(user1Id);
  
        DocumentReference user2Ref =
        FirebaseFirestore.instance.collection("users").doc(user2Id);
  
        DocumentReference adminRef =
        FirebaseFirestore.instance.collection("admin").doc("main");
  
        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot user2Snap = await transaction.get(user2Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);
  
        int user1Wallet = user1Snap["wallet"] ?? 0;
        int user2Wallet = user2Snap["wallet"] ?? 0;
        int adminWallet = adminSnap["wallet"] ?? 0;
  
        if (user1Wallet < commission ||
            user2Wallet < commission) {
          throw Exception("₹5 Balance Required");
        }
  
        // 🔻 Deduct ₹5 from both users
        transaction.update(user1Ref, {
          "wallet": user1Wallet - commission,
        });
  
        transaction.update(user2Ref, {
          "wallet": user2Wallet - commission,
        });
  
        // 🔺 Add ₹10 to Admin
        transaction.update(adminRef, {
          "wallet": adminWallet + (commission * 2),
          "totalEarning": FieldValue.increment(commission * 2),
        });
  
        // 🔥 User1 Transaction
        transaction.set(
          user1Ref.collection("transactions").doc(),
          {
            "amount": commission,
            "type": "debit",
            "message": "Platform Fee",
            "createdAt": Timestamp.now(),
          },
        );
  
        // 🔥 User2 Transaction
        transaction.set(
          user2Ref.collection("transactions").doc(),
          {
            "amount": commission,
            "type": "debit",
            "message": "Platform Fee",
            "createdAt": Timestamp.now(),
          },
        );
  
        // 🔥 Admin Transaction
        transaction.set(
          adminRef.collection("transactions").doc(),
          {
            "amount": commission * 2,
            "type": "credit",
            "message": "Platform Commission",
            "createdAt": Timestamp.now(),
          },
        );
      });
    }

    @override
    Widget build(BuildContext context) {
  
      String currentUserId =
          FirebaseAuth.instance.currentUser!.uid;
  
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
  
        appBar: AppBar(
          title: const Text("मजदूर लिस्ट",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .where("role", isEqualTo: "मज़दूर")
              .where("isAvailable", isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
  
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }
  
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text("कोई मजदूर उपलब्ध नहीं है"));
            }
  
            var docs = snapshot.data!.docs;
  
            return ListView.builder(
              padding:
              const EdgeInsets.symmetric(vertical: 10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
  
                var doc = docs[index];
                var data =
                doc.data() as Map<String, dynamic>;
  
                String workerId = doc.id;
  
                // 🔥 Apne aap ko list me mat dikhao
                if (workerId == currentUserId) {
                  return const SizedBox();
                }
  
                String audioUrl = data["audioUrl"] ?? "";
                String name = data["name"] ?? "";
                String work = data["workType"] ?? "";
                String area = data["area"] ?? "";
                String dp = data["dp"] ?? "";
  
                double distance =
                (data["distance"] ?? 0).toDouble();
  
                bool isAvailable = data["isAvailable"] ?? false;
  
                double rating =
                (data["rating"] ?? 0.0).toDouble();
  
                int totalRatings =
                (data["totalRatings"] ?? 0);
  
                String? rate = data["rate"]?.toString();
  
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
  
                      /// ===== TOP SECTION =====
                      Row(
                        children: [
  
                          /// DP with Green Ring
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage:
                              dp.isNotEmpty
                                  ? NetworkImage(dp)
                                  : null,
                              child: dp.isEmpty
                                  ? Text(
                                name.isNotEmpty
                                    ? name[0]
                                    : "",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                    FontWeight.bold),
                              )
                                  : null,
                            ),
                          ),
  
                          const SizedBox(width: 14),
  
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
  
                                /// Name + Active
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.circle,
                                        size: 10,
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      isAvailable
                                          ? "Active"
                                          : "Offline",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
  
                                const SizedBox(height: 4),
  
                                /// Work Type
                                Text(
                                  work,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
  
                      const Divider(height: 20),
  
                      /// Location + Distance
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16,
                              color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            "$area • ${distance < 1000
                                ? "${distance.toStringAsFixed(0)} m"
                                : "${(distance / 1000).toStringAsFixed(1)} KM"}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
  
                      const Divider(height: 20),
  
                      /// Rating + Rate
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
  
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16,
                                  color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                "${rating.toStringAsFixed(1)} ($totalRatings)",
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
  
                          Text(
                            rate != null && rate.isNotEmpty
                                ? "₹$rate / Day"
                                : "Rate Negotiable",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
  
                      const SizedBox(height: 16),
  
                      /// Bottom Buttons
                      Row(
                        children: [
  
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
  
                                if (audioUrl.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("No intro available")),
                                  );
                                  return;
                                }
  
                                final player = AudioPlayer();
                                await player.setUrl(audioUrl);
                                player.play();
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.mic, size: 18),
                                      SizedBox(width: 6),
                                      Text("Listen Intro"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("hireRequests")
                                    .where("senderId", isEqualTo: currentUserId)
                                    .where("receiverId", isEqualTo: workerId)
                                    .where("status", isEqualTo: "pending")
                                    .snapshots(),
                                builder: (context, snapshot) {

                                  bool isPending =
                                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                                  return ElevatedButton(
                                    onPressed: isPending
                                        ? null
                                        : () async {

                                      try {

                                        await sendHireRequest(
                                          senderId: currentUserId,
                                          receiverId: workerId,
                                        );

                                      } catch (e) {

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );

                                      }

                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      isPending ? Colors.grey : Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),

                                    child: Text(
                                      isPending ? "Pending" : "Hire ₹5",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }
  Future<void> submitRating(
      String workerId, double newRating) async {
  
    final workerRef =
    FirebaseFirestore.instance.collection("users").doc(workerId);
  
    final snapshot = await workerRef.get();
  
    if (snapshot.exists) {
  
      double currentRating =
      (snapshot["rating"] ?? 0).toDouble();
  
      int totalRatings =
      (snapshot["totalRatings"] ?? 0);
  
      double updatedRating =
          ((currentRating * totalRatings) + newRating) /
              (totalRatings + 1);
  
      await workerRef.update({
        "rating": updatedRating,
        "totalRatings": totalRatings + 1,
      });
    }
  }

  Future<void> sendHireRequest({
    required String senderId,
    required String receiverId,
  }) async {

    const int fee = 5;

    DocumentSnapshot receiverDoc =
    await FirebaseFirestore.instance
        .collection("users")
        .doc(receiverId)
        .get();

    bool isAvailable = receiverDoc["isAvailable"] ?? false;

    if (!isAvailable) {
      throw Exception("Worker is offline");
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {

      DocumentReference senderRef =
      FirebaseFirestore.instance.collection("users").doc(senderId);

      DocumentReference requestRef =
      FirebaseFirestore.instance.collection("hireRequests").doc();

      DocumentSnapshot senderSnap = await transaction.get(senderRef);

      int wallet = senderSnap["wallet"] ?? 0;

      if (wallet < fee) {

        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) => const WalletScreen(),
          ),
        );

        throw Exception("Please recharge wallet");
      }



      transaction.set(requestRef, {
        "senderId": senderId,
        "receiverId": receiverId,
        "senderPaid": true,
        "receiverPaid": false,
        "status": "pending",
        "createdAt": Timestamp.now(),
      });

    });
  }

  Widget buildMazdoorCard({
    required BuildContext context,
    required String currentUserId,
    required String workerId,
    required Map<String, dynamic> data,
    required Future<void> Function(String url) playAudio,
    required Future<void> Function({
    required String user1Id,
    required String user2Id,
    }) processHireWithCommission,
    bool isThekedar = false,   // 🔥 NEW
  }) {


    String audioUrl = data["audioUrl"] ?? "";
    String name = data["name"] ?? "";
    String work = data["workType"] ?? "";
    String area = data["area"] ?? "";
    String dp = data["dp"] ?? "";
    double distance = (data["distance"] ?? 0).toDouble();
    bool isAvailable = data["isAvailable"] ?? false;
    double rating = (data["rating"] ?? 0.0).toDouble();
    int totalRatings = data["totalRatings"] ?? 0;
    String? rate = data["rate"]?.toString();
  
  
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
  
          /// ===== TOP SECTION =====
          Row(
            children: [
  
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAvailable ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage:
                  dp.isNotEmpty ? NetworkImage(dp) : null,
                  child: dp.isEmpty
                      ? Text(name.isNotEmpty ? name[0] : "")
                      : null,
                ),
              ),
  
              const SizedBox(width: 14),
  
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [

                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // 🔥 INTRO BUTTON (YAHI LAGAO)
                        if (audioUrl != null && audioUrl.toString().isNotEmpty)
                          GestureDetector(
                            onTap: () => playAudio(audioUrl),
                            child: Container(
                              margin: EdgeInsets.only(right: 6),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.play_arrow, size: 14, color: Colors.blue),
                                  SizedBox(width: 3),
                                  Text("Intro",
                                      style: TextStyle(fontSize: 10, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ),

                        Icon(Icons.circle,
                            size: 10,
                            color: isAvailable ? Colors.green : Colors.grey),
                        const SizedBox(width: 4),

                        Text(
                          isAvailable ? "Active" : "Offline",
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),

                    Text(
                      work,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
  
          const Divider(height: 20),
  
          /// Location + Distance
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "$area • ${distance < 1000
                    ? "${distance.toStringAsFixed(0)} m"
                    : "${(distance / 1000).toStringAsFixed(1)} KM"}",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
  
          const Divider(height: 20),
  
          /// Rating + Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    "${rating.toStringAsFixed(1)} ($totalRatings)",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              Text(
                rate != null && rate.isNotEmpty
                    ? "₹$rate / Day"
                    : "Rate Negotiable",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),


          if (audioUrl != null && audioUrl.toString().isNotEmpty)
            GestureDetector(
              onTap: () => playAudio(audioUrl),
              child: Container(
                margin: EdgeInsets.only(right: 6),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, size: 14, color: Colors.blue),
                    SizedBox(width: 3),
                    Text("Intro",
                        style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
              ),
            ),

          Row(
            children: [

              // 🎧 LISTEN INTRO
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    String audioUrl = data["audioUrl"] ?? "";

                    if (audioUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No audio available")),
                      );
                      return;
                    }

                    await playAudio(audioUrl);
                  },
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, size: 18),
                          SizedBox(width: 6),
                          Text("Listen Intro"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 💰 APPLY / HIRE BUTTON
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("hireRequests")
                        .where("senderId", isEqualTo: currentUserId)
                        .where("receiverId", isEqualTo: workerId)
                        .where("status", isEqualTo: "pending")
                        .snapshots(),
                    builder: (context, snapshot) {

                      bool isPending =
                          snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                      return ElevatedButton(
                        onPressed: isPending
                            ? null
                            : () async {

                          try {

                            await sendHireRequest(
                              senderId: currentUserId,
                              receiverId: workerId,
                            );

                          } catch (e) {

                            String error = e.toString();

                            if (error.contains("Balance Required")) {

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Wallet में ₹5 नहीं है, पहले recharge करें"),
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WalletScreen(),
                                ),
                              );

                            } else {

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );

                            }

                          }

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending ? Colors.grey : Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          isPending
                              ? "Pending"
                              : (isThekedar ? "काम के लिए Apply" : "Hire ₹5"),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  //================= THEKEDAR LIST =================
  
  class ThekedarListScreen extends StatefulWidget {


    const ThekedarListScreen({super.key});


  
    @override
    State<ThekedarListScreen> createState() => _ThekedarListScreenState();
  }
  
  class _ThekedarListScreenState extends State<ThekedarListScreen> {

    final AudioPlayer audioPlayer = AudioPlayer();

    Future<void> playAudio(String url) async {
      try {
        await audioPlayer.setUrl(url);
        audioPlayer.play();
      } catch (e) {
        print("Audio error: $e");
      }
    }
  
    // 🔥 ₹5 + ₹5 Commission System
    Future<void> processHireWithCommission({
      required String user1Id,
      required String user2Id,
    }) async {
  
      const int commission = 5;
  
      await FirebaseFirestore.instance.runTransaction((transaction) async {
  
        DocumentReference user1Ref =
        FirebaseFirestore.instance.collection("users").doc(user1Id);
  
        DocumentReference user2Ref =
        FirebaseFirestore.instance.collection("users").doc(user2Id);
  
        DocumentReference adminRef =
        FirebaseFirestore.instance.collection("admin").doc("main");
  
        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot user2Snap = await transaction.get(user2Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);
  
        Map<String, dynamic> user1Data =
            user1Snap.data() as Map<String, dynamic>? ?? {};
  
        Map<String, dynamic> user2Data =
            user2Snap.data() as Map<String, dynamic>? ?? {};
  
        Map<String, dynamic> adminData =
            adminSnap.data() as Map<String, dynamic>? ?? {};
  
        int user1Wallet = user1Data["wallet"] ?? 0;
        int user2Wallet = user2Data["wallet"] ?? 0;
        int adminWallet = adminData["wallet"] ?? 0;
  
        if (user1Wallet < commission ||
            user2Wallet < commission) {
          throw Exception("₹5 Balance Required");
        }
  
        // 🔻 Deduct ₹5 from both
        transaction.update(user1Ref, {
          "wallet": user1Wallet - commission,
        });
  
        transaction.update(user2Ref, {
          "wallet": user2Wallet - commission,
        });
  
        // 🔺 Add ₹10 to Admin
        if (!adminSnap.exists) {
          transaction.set(adminRef, {
            "wallet": commission * 2,
            "totalEarning": commission * 2,
          });
        } else {
          transaction.update(adminRef, {
            "wallet": adminWallet + (commission * 2),
            "totalEarning": FieldValue.increment(commission * 2),
          });
        }
  
        // 🔥 User1 Transaction
        transaction.set(
          user1Ref.collection("transactions").doc(),
          {
            "amount": commission,
            "type": "debit",
            "message": "Platform Fee",
            "createdAt": Timestamp.now(),
          },
        );
  
        // 🔥 User2 Transaction
        transaction.set(
          user2Ref.collection("transactions").doc(),
          {
            "amount": commission,
            "type": "debit",
            "message": "Platform Fee",
            "createdAt": Timestamp.now(),
          },
        );
  
        // 🔥 Admin Transaction
        transaction.set(
          adminRef.collection("transactions").doc(),
          {
            "amount": commission * 2,
            "type": "credit",
            "message": "Platform Commission",
            "createdAt": Timestamp.now(),
          },
        );
      });
    }


  
    @override
    Widget build(BuildContext context) {
  
      String currentUserId =
          FirebaseAuth.instance.currentUser!.uid;
  
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
  
        appBar: AppBar(
          title: const Text("ठेकेदार लिस्ट",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),


  
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .where("role", isEqualTo: "ठेकेदार")
              .where("isAvailable", isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
  
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }
  
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text("कोई ठेकेदार उपलब्ध नहीं है"));
            }
  
            var docs = snapshot.data!.docs;
  
            return ListView.builder(
              padding:
              const EdgeInsets.symmetric(vertical: 10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
  
                var doc = docs[index];
                var data =
                doc.data() as Map<String, dynamic>;
  
                String thekedarId = doc.id;
  
                if (thekedarId == currentUserId) {
                  return const SizedBox();
                }
  
                String name = data["name"] ?? "";
                String work = data["workType"] ?? "";
                String area = data["area"] ?? "";
                String dp = data["dp"] ?? "";



                return buildMazdoorCard(
                  context: context,
                  currentUserId: currentUserId,
                  workerId: thekedarId,
                  data: data,
                  playAudio: playAudio, // 🔥 ADD THIS
                  processHireWithCommission: processHireWithCommission,
                  isThekedar: true,
                );
              },
            );
          },
        ),
      );
    }
  }
  //==============WalletScreen================
  class WalletScreen extends StatefulWidget {
    const WalletScreen({super.key});
  
    @override
    State<WalletScreen> createState() => _WalletScreenState();
  }
  
  class _WalletScreenState extends State<WalletScreen> {
  
    final TextEditingController amountController = TextEditingController();
    late Razorpay _razorpay;
  
    @override
    void initState() {
      super.initState();
  
      _razorpay = Razorpay();
  
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
  
    void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  
      String uid = FirebaseAuth.instance.currentUser!.uid;
      int amount = int.tryParse(amountController.text.trim()) ?? 0;
  
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "wallet": FieldValue.increment(amount),
        "totalEarned": FieldValue.increment(amount),
      });
  
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("transactions")
          .add({
        "amount": amount,
        "type": "credit",
        "message": "Wallet Recharge",
        "createdAt": Timestamp.now(),
      });
  
      amountController.clear();
  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RequestsUpdatesScreen(),
        ),
      );
    }
  
    void _handlePaymentError(PaymentFailureResponse response) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Failed")),
      );
    }
  
    void openCheckout(int amount) {
  
      var options = {
        'key': 'rzp_test_SJeW8zM6X7fQQI', // 🔥 apna Razorpay test key daalna
        'amount': amount * 100,
        'name': 'Rozgaar Peetha',
        'description': 'Wallet Recharge',
      };
  
      try {
        _razorpay.open(options);
      } catch (e) {
        print(e);
      }
    }
  
    @override
    void dispose() {
      _razorpay.clear();
      super.dispose();
    }
  
    @override
    Widget build(BuildContext context) {
  
      String uid = FirebaseAuth.instance.currentUser!.uid;
  
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
  
        appBar: AppBar(
          title: const Text("मेरा वॉलेट"),
          backgroundColor: Colors.green,
        ),
  
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, userSnapshot) {
  
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
  
            var userData =
            userSnapshot.data!.data() as Map<String, dynamic>;
  
            int wallet = userData["wallet"] ?? 0;
  
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
  
                  // 💰 BALANCE CARD
                  Container(
                    width: 220,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "कुल बैलेंस",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "₹${wallet.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
  
                  const SizedBox(height: 40),
  
                  const Text(
                    "रिचार्ज करें",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
  
                  const SizedBox(height: 15),
  
                  // 💵 Amount Input
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee),
                      hintText: "राशि डालें (जैसे 100)",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 20),
  
                  // 🔋 Recharge Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
  
                        int amount =
                            int.tryParse(amountController.text.trim()) ?? 0;
  
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("सही राशि डालें")),
                          );
                          return;
                        }
  
                        openCheckout(amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "रिचार्ज करें",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 40),
  
                  const Text(
                    "ट्रांजेक्शन हिस्ट्री",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
  
                  const SizedBox(height: 10),
  
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(uid)
                        .collection("transactions")

                        .snapshots(),
                    builder: (context, snapshot) {
  
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text(
                          "कोई ट्रांजेक्शन नहीं",
                          style: TextStyle(color: Colors.grey),
                        );
                      }
  
                      return ListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
  
                          var data =
                          snapshot.data!.docs[index];
  
                          int amount = data["amount"];
                          String type = data["type"];
                          String message = data["message"];
  
                          bool isCredit =
                              type == "credit";
  
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCredit
                                  ? Colors.green
                                  : Colors.red,
                              child: Icon(
                                isCredit
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(message),
                            trailing: Text(
                              "${isCredit ? "+" : "-"}₹$amount",
                              style: TextStyle(
                                color: isCredit
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
  Future<void> hireWorker({
    required String contractorId,
    required String workerId,
    required int amount,
  }) async {
  
    FirebaseFirestore.instance.runTransaction((transaction) async {
  
      DocumentReference contractorRef =
      FirebaseFirestore.instance.collection("users").doc(contractorId);
  
      DocumentReference workerRef =
      FirebaseFirestore.instance.collection("users").doc(workerId);
  
      DocumentSnapshot contractorSnap =
      await transaction.get(contractorRef);
  
      DocumentSnapshot workerSnap =
      await transaction.get(workerRef);
  
      int contractorWallet =
          contractorSnap["wallet"] ?? 0;
  
      if (contractorWallet < amount) {
        throw Exception("Insufficient Balance");
      }
  
      // 🔻 Deduct from Contractor
      transaction.update(contractorRef, {
        "wallet": contractorWallet - amount,
      });
  
      // 🔺 Add to Worker
      int workerWallet =
          workerSnap["wallet"] ?? 0;
  
      transaction.update(workerRef, {
        "wallet": workerWallet + amount,
      });
  
      // 🔥 Contractor Transaction
      transaction.set(
        contractorRef.collection("transactions").doc(),
        {
          "amount": amount,
          "type": "debit",
          "message": "Worker Hire Payment",
          "createdAt": Timestamp.now(),
        },
      );
  
      // 🔥 Worker Transaction
      transaction.set(
        workerRef.collection("transactions").doc(),
        {
          "amount": amount,
          "type": "credit",
          "message": "Job Payment Received",
          "createdAt": Timestamp.now(),
        },
      );
    });
  }
  
  class IncomingRequestsScreen extends StatelessWidget {
    const IncomingRequestsScreen({super.key});
  
    @override
    Widget build(BuildContext context) {
  
      String currentUserId =
          FirebaseAuth.instance.currentUser!.uid;
  
      return Scaffold(
        appBar: AppBar(
          title: const Text("Incoming Requests"),
          backgroundColor: Colors.green,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("hireRequests")
              .where("receiverId", isEqualTo: currentUserId)
              .where("status", isEqualTo: "pending")
              .snapshots(),
          builder: (context, snapshot) {
  
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No Incoming Requests"),
              );
            }
  
            var docs = snapshot.data!.docs;
  
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
  
                var request = docs[index];
  
                return ListTile(
                  title: Text("New Hire Request"),
                  subtitle: Text("Tap to Accept"),
                  trailing: ElevatedButton(
                    onPressed: () async {
  
                      await FirebaseFirestore.instance
                          .collection("hireRequests")
                          .doc(request.id)
                          .update({
                        "status": "accepted"
                      });
  
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                            content: Text("Accepted")),
                      );
                    },
                    child: const Text("Accept"),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }

  class MyRatingsScreen extends StatelessWidget {
    const MyRatingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Ratings")),
        body: const Center(child: Text("Ratings Coming Soon")),
      );
    }
  }

  class MyJobsScreen extends StatelessWidget {
    const MyJobsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Jobs")),
        body: const Center(child: Text("Jobs Coming Soon")),
      );
    }
  }

  class EditProfileScreen extends StatelessWidget {
    const EditProfileScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: const Center(child: Text("Edit Profile Coming Soon")),
      );
    }
  }

  class HireHistoryScreen extends StatelessWidget {
    const HireHistoryScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hire History")),
        body: const Center(child: Text("History Coming Soon")),
      );
    }
  }

  class EarningsReportScreen extends StatelessWidget {
    const EarningsReportScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Earnings Report")),
        body: const Center(child: Text("Report Coming Soon")),
      );
    }
  }

  class PremiumScreen extends StatelessWidget {
    const PremiumScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Premium Badge")),
        body: const Center(child: Text("Premium Feature Coming Soon")),
      );
    }
  }


  class RequestsUpdatesScreen extends StatelessWidget {
    const RequestsUpdatesScreen({super.key});

    Future<void> processHireWithCommission({
      required String user1Id,
      required String user2Id,
    }) async {

      const int commission = 5;

      await FirebaseFirestore.instance.runTransaction((transaction) async {

        DocumentReference user1Ref =
        FirebaseFirestore.instance.collection("users").doc(user1Id);

        DocumentReference user2Ref =
        FirebaseFirestore.instance.collection("users").doc(user2Id);

        DocumentReference adminRef =
        FirebaseFirestore.instance.collection("admin").doc("main");

        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot user2Snap = await transaction.get(user2Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);

        int user1Wallet = user1Snap["wallet"] ?? 0;
        int user2Wallet = user2Snap["wallet"] ?? 0;
        int adminWallet = adminSnap["wallet"] ?? 0;

        if (user2Wallet < commission) {
          throw Exception("₹5 Balance Required");
        }

        transaction.update(user1Ref, {
          "wallet": user1Wallet - commission,
        });

        transaction.update(user2Ref, {
          "wallet": user2Wallet - commission,
        });

        transaction.update(adminRef, {
          "wallet": adminWallet + (commission * 2),
          "totalEarning": FieldValue.increment(commission * 2),
        });

      });
    }

    void showReceiverPaymentDialog(BuildContext context, Map<String, dynamic> data) {

      int remainingSeconds = 600;
      Timer? timer;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {

          return StatefulBuilder(
            builder: (context, setStateDialog) {

              timer ??= Timer.periodic(
                const Duration(seconds: 1),
                    (t) {

                  if (remainingSeconds <= 0) {

                    t.cancel();
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Payment time expired"),
                      ),
                    );

                  } else {

                    setStateDialog(() {
                      remainingSeconds--;
                    });

                  }

                },
              );

              int minutes = remainingSeconds ~/ 60;
              int seconds = remainingSeconds % 60;

              return AlertDialog(

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                title: Column(
                  children: const [

                    Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.green,
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Direct Connection Unlock",
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),

                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Text(
                      "To contact this worker directly complete the ₹5 secure connection fee.",
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    Stack(
                      alignment: Alignment.center,
                      children: [

                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            value: remainingSeconds / 600,
                            strokeWidth: 8,
                          ),
                        ),

                        Text(
                          "${minutes.toString().padLeft(2,'0')}:${seconds.toString().padLeft(2,'0')}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Valid for next 10 minutes",
                      style: TextStyle(
                        color: Colors.orange,
                      ),
                    ),

                  ],
                ),

                actions: [

                  TextButton(
                    onPressed: () {

                      timer?.cancel();
                      Navigator.pop(dialogContext);

                    },
                    child: const Text("Not Now"),
                  ),

                  ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),

                    onPressed: () async {

                      try {

                        timer?.cancel();

                        await processHireWithCommission(
                          user1Id: FirebaseAuth.instance.currentUser!.uid,
                          user2Id: data["receiverId"],
                        );

                        await FirebaseFirestore.instance
                            .collection("hireRequests")
                            .doc(data["id"])
                            .update({
                          "receiverPaid": true
                        });

                        Navigator.pop(dialogContext);

                      } catch (e) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );

                      }

                    },

                    child: const Text("Pay ₹5"),

                  )

                ],
              );
            },
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      return Scaffold(
        appBar: AppBar(
          title: const Text("My Requests"),
          backgroundColor: Colors.green,
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("hireRequests")
              .where("senderId", isEqualTo: uid)

              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text("No requests yet"),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {

                var data = docs[index].data() as Map<String, dynamic>;
                String status = data["status"] ?? "pending";

                return ListTile(
                  leading: Icon(
                    status == "accepted"
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color: status == "accepted"
                        ? Colors.green
                        : Colors.orange,
                  ),

                  title: Text(
                    status == "accepted"
                        ? "Worker accepted your request"
                        : "Waiting for worker response",
                  ),

                  subtitle: status == "accepted"
                      ? const Text("Tap to unlock connection")
                      : Text("Status: $status"),

                  onTap: () {

                    if (status == "accepted") {

                      Map<String, dynamic> requestData =
                      docs[index].data() as Map<String, dynamic>;

                      requestData["id"] = docs[index].id;

                      showReceiverPaymentDialog(context, requestData);

                    }

                  },
                );
              },
            );
          },
        ),
      );
    }
  }



  //--------WorkerAcceptedScreen-----------

  class WorkerAcceptedScreen extends StatelessWidget {
    const WorkerAcceptedScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Request Accepted"),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 90,
              ),

              const SizedBox(height: 20),

              const Text(
                "Worker accepted your request",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Back"),
              )

            ],
          ),
        ),
      );
    }
  }