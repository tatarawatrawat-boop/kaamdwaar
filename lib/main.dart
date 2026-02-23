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
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
      home: AuthCheckScreen(), // 🔥 YE IMPORTANT HAI
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
          builder: (_) => DashboardScreen(role: role),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
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

        /// 🔥 NEW FIELDS
        "latitude": position.latitude,
        "longitude": position.longitude,

        "createdAt": Timestamp.now(),
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

class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String name = "";
  String area = "";
  String dpUrl = "";
  int walletBalance = 0;
  bool isLoading = true;

  late Razorpay _razorpay;
  int rechargeAmount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          name = doc["name"] ?? "";
          area = doc["area"] ?? "";
          dpUrl = doc["dp"] ?? "";
          walletBalance = doc["wallet"] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// 🔥 OPEN RAZORPAY
  void openRazorpay(int amount) {
    rechargeAmount = amount;

    var options = {
      'key': 'rzp_test_SJeW8zM6X7fQQI',
      'amount': amount * 100,
      'name': 'KaamDwaar Wallet',
      'description': 'Wallet Recharge',
      'timeout': 60,
      'prefill': {
        'contact': '9999999999',
        'email': 'test@test.com'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Razorpay Error: $e");
    }
  }

  /// ✅ PAYMENT SUCCESS
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({
      "wallet": FieldValue.increment(rechargeAmount),
    });

    fetchUserData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("₹$rechargeAmount Added Successfully")),
    );
  }

  /// ❌ PAYMENT FAILED
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed ❌")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  /// 💰 WALLET DIALOG
  void showWalletDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Wallet"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Available Balance: ₹$walletBalance"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openRazorpay(50); // 🔥 Recharge ₹50
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Add ₹50"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openRazorpay(100); // 🔥 Recharge ₹100
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Add ₹100"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Dashboard"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green,
                    backgroundImage:
                    dpUrl.isNotEmpty ? NetworkImage(dpUrl) : null,
                    child: dpUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(widget.role,
                          style: const TextStyle(color: Colors.black54)),
                      Text(area),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                dashboardCard(
                  Icons.account_balance_wallet,
                  "₹$walletBalance",
                  Colors.green,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletScreen(),
                      ),
                    );
                  },
                ),

                dashboardCard(
                  Icons.people,
                  "मजदूर लिस्ट",
                  Colors.blue,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const MazdoorListScreen(),
                      ),
                    );
                  },
                ),

                dashboardCard(
                  Icons.business,
                  "ठेकेदार लिस्ट",
                  Colors.purple,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const ThekedaarListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(
      IconData icon,
      String title,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// =====PaymentSuccess); =====

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  int walletBalance = 0;
  bool isLoading = true;
  late Razorpay _razorpay;
  int rechargeAmount = 0;

  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWallet();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    amountController.dispose();
    super.dispose();
  }

  Future<void> fetchWallet() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          walletBalance = doc.data()?["wallet"] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          walletBalance = 0;
          isLoading = false;
        });
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Wallet Error: $e");
    }
  }

  void openRazorpay(int amount) {
    rechargeAmount = amount;

    var options = {
      'key': 'rzp_test_SJeW8zM6X7fQQI',
      'amount': amount * 100,
      'name': 'KaamDwaar Wallet',
      'description': 'Wallet Recharge',
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1️⃣ Wallet Update
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({
      "wallet": FieldValue.increment(rechargeAmount),
    });

    // 2️⃣ Transaction Save
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("transactions")
        .add({
      "amount": rechargeAmount,
      "type": "credit",
      "paymentId": response.paymentId,
      "status": "success",
      "createdAt": Timestamp.now(),
    });

    fetchWallet();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("₹$rechargeAmount Added Successfully")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed ❌")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("मेरा वॉलेट"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 Balance Card
            Container(
              width: 220,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "कुल बैलेंस",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "₹$walletBalance.00",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "रिचार्ज करें",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),

            const SizedBox(height: 20),

            /// 💰 Amount Field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "राशि डालें (जैसे 100)",
                prefixText: "₹ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 Recharge Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  int amount = int.tryParse(amountController.text) ?? 0;
                  if (amount < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("कम से कम ₹10 डालें")),
                    );
                    return;
                  }
                  openRazorpay(amount);
                },
                child: const Text(
                  "रिचार्ज करें",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "ट्रांजेक्शन हिस्ट्री",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection("transactions")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("कोई ट्रांजेक्शन नहीं");
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {

                      var data = snapshot.data!.docs[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text("₹${data['amount']} Added"),
                          subtitle: Text(
                            (data['createdAt'] as Timestamp)
                                .toDate()
                                .toString(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ===== MazdoorListScreen =====

class MazdoorListScreen extends StatefulWidget {
  const MazdoorListScreen({super.key});

  @override
  State<MazdoorListScreen> createState() => _MazdoorListScreenState();
}

class _MazdoorListScreenState extends State<MazdoorListScreen> {

  List<QueryDocumentSnapshot> nearbyMazdoor = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNearbyMazdoor();
  }

  Future<Position> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> fetchNearbyMazdoor() async {

    Position myPosition = await getCurrentLocation();

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "मज़दूर")
        .get();

    List<QueryDocumentSnapshot> filtered = [];

    for (var doc in snapshot.docs) {

      double lat = doc["latitude"];
      double lng = doc["longitude"];

      double distanceInMeters = Geolocator.distanceBetween(
        myPosition.latitude,
        myPosition.longitude,
        lat,
        lng,
      );

      double distanceInKm = distanceInMeters / 1000;

      if (distanceInKm <= 3) {
        filtered.add(doc);
      }
    }

    setState(() {
      nearbyMazdoor = filtered;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("3KM के अंदर मज़दूर"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : nearbyMazdoor.isEmpty
          ? const Center(child: Text("कोई मज़दूर पास में नहीं मिला"))
          : ListView.builder(
        itemCount: nearbyMazdoor.length,
        itemBuilder: (context, index) {

          var data = nearbyMazdoor[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: data["dp"] != ""
                    ? NetworkImage(data["dp"])
                    : null,
                child: data["dp"] == ""
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(data["name"]),
              subtitle: Text(data["workType"]),
            ),
          );
        },
      ),
    );
  }
}
// ===== ThekedaarListScreen =====

class ThekedaarListScreen extends StatelessWidget {
  const ThekedaarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ठेकेदार लिस्ट"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("role", isEqualTo: "ठेकेदार")
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("कोई ठेकेदार उपलब्ध नहीं"),
            );
          }

          final thekedaarList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: thekedaarList.length,
            itemBuilder: (context, index) {

              final data = thekedaarList[index];

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: data["dp"] != ""
                        ? NetworkImage(data["dp"])
                        : null,
                    child: data["dp"] == ""
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    data["name"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["workType"] ?? ""),
                      Text(data["area"] ?? ""),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}