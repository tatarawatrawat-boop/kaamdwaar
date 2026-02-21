import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
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

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Already logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      } else {
        // Not logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }

    });;
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
  bool isLoading = false;

  String? selectedState;
  String? selectedDistrict;

  // 🔵 STATE - DISTRICT DATA
  final Map<String, List<String>> stateDistrictMap = {
    "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur", "Kota"],
    "Uttar Pradesh": ["Lucknow", "Kanpur", "Agra"],
    "Madhya Pradesh": ["Bhopal", "Indore", "Gwalior"],
  };

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

  // 💾 SAVE PROFILE
  Future<void> saveProfile() async {
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
    if (user == null) return;

    String? finalImageUrl = imageUrl;

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
      "createdAt": Timestamp.now(),
    });

    setState(() {
      isLoading = false;
    });

    print("Profile Saved Successfully");
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
}