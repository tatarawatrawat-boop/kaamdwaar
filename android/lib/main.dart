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
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';


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

  setupFCMListeners(); // 🔥 Ye call rehna chahiye

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {

  @override
  void initState() {
    super.initState();
    checkUser();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

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
                      const SnackBar(content: Text("Enter valid 10 digit number")),
                    );
                    return;
                  }

                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: "+91${phoneController.text.trim()}",

                    verificationCompleted: (PhoneAuthCredential credential) {},

                    verificationFailed: (FirebaseAuthException e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? "Verification Failed")),
                      );
                    },

                    codeSent: (String verificationId, int? resendToken) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OtpScreen(verificationId: verificationId),
                        ),
                      );
                    },

                    codeAutoRetrievalTimeout: (String verificationId) {},
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
          ],
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
          selectedRole = title;
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

              roleCard(
                image: "assets/images/thekedaar.png",
                title: "ठेकेदार",
              ),

              const Spacer(),

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

  // 🔥 TIMER VARIABLES ADD KARO
  Timer? requestTimer;
  int remainingSeconds = 30;
  bool isDialogOpen = false;

  // Variables jo data store karenge
  String name = "Loading...";
  String dp = "";
  String area = "...";
  int wallet = 0;
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    getUserData();
    saveFCMToken();
    listenIncomingRequests();
    listenReceiverPayment();// 🔥 ADD THIS
  }

  void listenIncomingRequests() {

    String uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection("hireRequests")
        .where("receiverId", isEqualTo: uid)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snapshot) {

      if (snapshot.docs.isNotEmpty && !isDialogOpen) {

        String requestId = snapshot.docs.first.id;

        showHireDialog(requestId);
      }
    });
  }


  Widget _buildHorizontalMajdoorCard(
      String name,
      String work,
      String area,
      String dp,
      bool isAvailable,
      ) {
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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [

          /// Modern Accent Line
          Container(
            width: 4,
            height: 75,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF43A047)
                  : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 12),

          /// Profile Image
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
            dp.isNotEmpty ? NetworkImage(dp) : null,
            child: dp.isEmpty
                ? Text(
              name.isNotEmpty
                  ? name[0].toUpperCase()
                  : "",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            )
                : null,
          ),

          const SizedBox(width: 14),

          /// Details Section
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                /// Name + Availability Badge
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFFE8F5E9)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAvailable ? "Available" : "Offline",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isAvailable
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// Work Type
                Text(
                  work,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E88E5),
                  ),
                ),

                const SizedBox(height: 6),

                /// Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      area,
                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
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
  void showHireDialog(String requestId) {

    isDialogOpen = true;
    remainingSeconds = 30;
    requestTimer?.cancel();

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

                  await FirebaseFirestore.instance
                      .collection("hireRequests")
                      .doc(requestId)
                      .update({"status": "expired"});

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

                      // ⏰ Time Badge
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

                      const SizedBox(height: 6),

                      const Text(
                        "₹5 देकर कनेक्शन स्वीकार करें",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔥 Circular Timer
                      Stack(
                        alignment: Alignment.center,
                        children: [

                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CircularProgressIndicator(
                              value: remainingSeconds / 30,
                              strokeWidth: 8,
                              backgroundColor: Colors.orange.shade100,
                              valueColor: const AlwaysStoppedAnimation(
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

                          // ❌ Reject
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {

                                // 🔥 Stop 30 sec timer
                                requestTimer?.cancel();
                                requestTimer = null;

                                try {

                                  // 🔥 Update status to payment_pending
                                  await FirebaseFirestore.instance
                                      .collection("hireRequests")
                                      .doc(requestId)
                                      .update({
                                    "status": "payment_pending",
                                    "paymentPendingBy": "receiver",
                                    "paymentDeadline": Timestamp.fromDate(
                                      DateTime.now().add(const Duration(minutes: 10)),
                                    ),
                                  });

                                  // 🔥 Close 30 sec dialog
                                  Navigator.of(context).pop();

                                  // 🔥 VERY IMPORTANT: reset flag
                                  isDialogOpen = false;

                                  // 🔥 Small delay to avoid context conflict
                                  await Future.delayed(const Duration(milliseconds: 200));

                                  // 🔥 Open payment dialog immediately
                                  showReceiverPaymentDialog(requestId);

                                } catch (e) {

                                  isDialogOpen = false;

                                  ScaffoldMessenger.of(
                                    navigatorKey.currentContext!,
                                  ).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
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
                          ),

                          const SizedBox(width: 15),

                          // ✅ Accept
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {

                                // 🔥 Stop 30 sec timer
                                requestTimer?.cancel();
                                requestTimer = null;

                                try {

                                  // 🔥 Update request status
                                  await FirebaseFirestore.instance
                                      .collection("hireRequests")
                                      .doc(requestId)
                                      .update({
                                    "status": "payment_pending",
                                    "paymentPendingBy": "receiver",
                                    "paymentDeadline": Timestamp.fromDate(
                                      DateTime.now().add(const Duration(minutes: 10)),
                                    ),
                                  });

                                  // 🔥 Close 30 sec dialog
                                  Navigator.of(context).pop();

                                  // 🔥 Reset flag
                                  isDialogOpen = false;

                                  // 🔥 Small delay
                                  await Future.delayed(const Duration(milliseconds: 200));

                                  // 🔥 OPEN PAYMENT DIALOG
                                  showReceiverPaymentDialog(requestId);

                                } catch (e) {
                                  isDialogOpen = false;
                                  ScaffoldMessenger.of(navigatorKey.currentContext!)
                                      .showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }

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
      },
    );
  }

  void showReceiverPaymentDialog(String requestId) {

    // 🔥 VERY IMPORTANT
    isDialogOpen = true;

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {

        return AlertDialog(
          title: const Text("Complete Payment"),
          content: const Text("10 मिनट के अंदर ₹5 भुगतान करें"),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
                isDialogOpen = false;   // 🔥 reset
              },
              child: const Text("Later"),
            ),

            ElevatedButton(
              onPressed: () async {

                try {

                  String currentUserId =
                      FirebaseAuth.instance.currentUser!.uid;

                  DocumentSnapshot snap =
                  await FirebaseFirestore.instance
                      .collection("hireRequests")
                      .doc(requestId)
                      .get();

                  // 🔥 SAFE CHECK
                  if (!snap.exists) {
                    throw Exception("Request not found");
                  }

                  // 🔥 Deduct ₹5 from receiver only
                  await FirebaseFirestore.instance
                      .runTransaction((transaction) async {

                    DocumentReference receiverRef =
                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUserId);

                    DocumentReference adminRef =
                    FirebaseFirestore.instance
                        .collection("admin")
                        .doc("main");

                    DocumentSnapshot receiverSnap =
                    await transaction.get(receiverRef);

                    DocumentSnapshot adminSnap =
                    await transaction.get(adminRef);

                    int receiverWallet =
                        (receiverSnap.data() as Map)["wallet"] ?? 0;

                    int adminWallet =
                        (adminSnap.data() as Map)["wallet"] ?? 0;

                    if (receiverWallet < 5) {
                      throw Exception("₹5 Balance Required");
                    }

                    transaction.update(receiverRef, {
                      "wallet": receiverWallet - 5,
                    });

                    transaction.update(adminRef, {
                      "wallet": adminWallet + 5,
                      "totalEarning": FieldValue.increment(5),
                    });
                  });

                  // 🔥 Update request status
                  await FirebaseFirestore.instance
                      .collection("hireRequests")
                      .doc(requestId)
                      .update({
                    "receiverPaid": true,
                    "status": "completed"
                  });

                  Navigator.pop(context);
                  isDialogOpen = false;

                  ScaffoldMessenger.of(
                      navigatorKey.currentContext!)
                      .showSnackBar(
                    const SnackBar(
                        content: Text("Payment Successful")),
                  );

                } catch (e) {

                  isDialogOpen = false;

                  ScaffoldMessenger.of(
                      navigatorKey.currentContext!)
                      .showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text("Pay ₹5 Now"),
            ),
          ],
        );
      },
    );
  }
  void listenReceiverPayment() {

    String uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection("hireRequests")
        .where("receiverId", isEqualTo: uid)
        .where("status", isEqualTo: "payment_pending")
        .snapshots()
        .listen((snapshot) {

      if (snapshot.docs.isNotEmpty) {

        String requestId = snapshot.docs.first.id;

        if (!isDialogOpen) {

          isDialogOpen = true;

          showReceiverPaymentDialog(requestId);
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
                  workerId: data["id"],
                  currentUserId: FirebaseAuth.instance.currentUser!.uid,
                  data: data,
                  processHireWithCommission: processHireWithCommission,

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

    yield* FirebaseFirestore.instance
        .collection("users")
        .where(
      "role",
      isEqualTo: widget.role == "मज़दूर" ? "ठेकेदार" : "मज़दूर",
    )
        .where("isAvailable", isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {

      List<Map<String, dynamic>> nearbyWorkers = [];

      for (var doc in snapshot.docs) {

        if (doc.id == user.uid) continue;

        var data = doc.data();

        double workerLat = (data["latitude"] ?? 0).toDouble();
        double workerLng = (data["longitude"] ?? 0).toDouble();

        double distance = Geolocator.distanceBetween(
            userLat, userLng, workerLat, workerLng);

        data["distance"] = distance;
        data["id"] = doc.id;

        nearbyWorkers.add(data);
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
                        builder: (_) => const IncomingRequestsScreen(),
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

          String audioUrl = data["audioUrl"] ?? "";
          String name = data["name"] ?? "";
          String role = data["role"] ?? "";
          String dp = data["dp"] ?? "";
          int wallet = data["wallet"] ?? 0;

          return ListView(
            padding: EdgeInsets.zero,
            children: [

              // 🔥 HEADER
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),

                accountName: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                accountEmail: Text(role),

                currentAccountPicture: CircleAvatar(
                  backgroundImage:
                  dp.isNotEmpty ? NetworkImage(dp) : null,
                  child: dp.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),

              // 💰 REAL WALLET TILE
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                title: const Text("My Wallet"),
                subtitle: Text(
                  "Available: ₹$wallet",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletScreen(),
                    ),
                  );
                },
              ),



              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {},
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () async {

                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .set({
                      "isAvailable": false,
                    }, SetOptions(merge: true));
                  }

                  await FirebaseAuth.instance.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
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
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 16),
        const SizedBox(width: 6),
        const Text("Profile 60%", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 5,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        )
      ],
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
            .where("isAvailable", isEqualTo: true) // 🔥 ADD THIS
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
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await processHireWithCommission(
                                    user1Id:
                                    currentUserId,
                                    user2Id:
                                    workerId,
                                  );
                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "₹5 Platform Fee Paid")),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(
                                    SnackBar(
                                        content:
                                        Text(e.toString())),
                                  );
                                }
                              },
                              style:
                              ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                Colors.green,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                      25),
                                ),
                              ),
                              child: const Text(
                                "Hire ₹5",
                                style: TextStyle(
                                    fontWeight:
                                    FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
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

  await FirebaseFirestore.instance.runTransaction((transaction) async {

    DocumentReference senderRef =
    FirebaseFirestore.instance.collection("users").doc(senderId);

    DocumentReference requestRef =
    FirebaseFirestore.instance.collection("hireRequests").doc();

    DocumentSnapshot senderSnap = await transaction.get(senderRef);

    int wallet = senderSnap["wallet"] ?? 0;

    if (wallet < fee) {
      throw Exception("₹5 Balance Required");
    }

    // 🔻 Deduct ₹5 from sender
    transaction.update(senderRef, {
      "wallet": wallet - fee,
    });

    // 🔥 Create Hire Request
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

  required String currentUserId,
  required String workerId,
  required Map<String, dynamic> data,
  required Future<void> Function({
  required String user1Id,
  required String user2Id,
  }) processHireWithCommission,
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

                  const SizedBox(height: 4),

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

        const SizedBox(height: 16),

        /// Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {

                  if (audioUrl.isEmpty) {
                    ScaffoldMessenger.of(
                        navigatorKey.currentContext!
                    ).showSnackBar(
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
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await sendHireRequest(
                        senderId: currentUserId,
                        receiverId: workerId,
                      );

                      ScaffoldMessenger.of(
                          navigatorKey.currentContext!)
                          .showSnackBar(
                        const SnackBar(
                            content: Text("Request Sent Successfully")),
                      );

                    } catch (e) {

                      ScaffoldMessenger.of(
                          navigatorKey.currentContext!)
                          .showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Hire ₹5",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

      // 🔻 Deduct ₹5 from both
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
            .where("isAvailable", isEqualTo: true) // 🔥 ADD THIS
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
                currentUserId: currentUserId,
                workerId: thekedarId,
                data: data,
                processHireWithCommission: processHireWithCommission,
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
                      .orderBy("createdAt", descending: true)
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