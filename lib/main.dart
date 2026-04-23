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
  import 'package:firebase_auth/firebase_auth.dart';
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
  import 'package:flutter_localizations/flutter_localizations.dart';
  import 'package:geocoding/geocoding.dart';
  import 'admin_dashboard_screen.dart';
  import 'package:razorpay_flutter/razorpay_flutter.dart';
  import 'package:flutter/material.dart';
  import 'package:vibration/vibration.dart';
  import 'settings_screen.dart';
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import 'dart:typed_data';
  import 'dart:convert';
  import 'package:http/http.dart' as http;


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<String> getAreaName(double lat, double lng) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(lat, lng);

      Placemark place = placemarks[0];

      String area =
          place.subLocality ??
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              "Unknown";

      return area;

    } catch (e) {
      print("Area detect error: $e");
      return "Unknown";
    }
  }

  String t(BuildContext context, String en, String hi) {
    return Localizations.localeOf(context).languageCode == 'hi'
        ? hi
        : en;
  }


  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'hire_call_popup',
      'Hire Requests',
      channelDescription: 'Notifications for hire requests',

      importance: Importance.max,
      priority: Priority.high,

      // 🔥 NEW
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,

      sound: RawResourceAndroidNotificationSound('ringtone'),
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      "KaamDwaar Incoming Hire",
      message.notification?.body ?? "Someone wants to hire you",
      platformChannelSpecifics,
    );
  }

  // 🔥 YAHAN ADD KARO
  void setupFCMListeners() {

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      final ctx = navigatorKey.currentContext;

      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              message.notification?.title ?? "New Notification",
            ),
          ),
        );
      }

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

    // 🔥 Initialize local notifications (यहाँ add करें)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    setupFCMListeners();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();


    // 🔥 ADD THIS (MOST IMPORTANT)
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    runApp(MyApp(initialMessage: initialMessage));
  }




  class MyApp extends StatefulWidget {
    final RemoteMessage? initialMessage;

    const MyApp({super.key, this.initialMessage});

    // 🔥 GLOBAL ACCESS (VERY IMPORTANT)
    static _MyAppState? of(BuildContext context) =>
        context.findAncestorStateOfType<_MyAppState>();

    @override
    State<MyApp> createState() => _MyAppState();
  }

  class _MyAppState extends State<MyApp> {

    Locale _locale = const Locale('en');

    void changeAppLanguage(String langCode) {
      changeLanguage(langCode);
    }

    @override
    void initState() {
      super.initState();
      loadSavedLanguage(); // 🔥 load on start
    }

    // 🔥 CHANGE LANGUAGE
    void changeLanguage(String langCode) async {
      setState(() {
        _locale = Locale(langCode);
      });

      // 🔥 SAVE LANGUAGE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("app_lang", langCode);
    }

    // 🔥 LOAD SAVED LANGUAGE
    Future<void> loadSavedLanguage() async {
      final prefs = await SharedPreferences.getInstance();
      String lang = prefs.getString("app_lang") ?? "en";

      setState(() {
        _locale = Locale(lang);
      });
    }

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,

        locale: _locale,

        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: AuthCheckScreen(initialMessage: widget.initialMessage),
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

                  Text(
                    Localizations.localeOf(context).languageCode == 'hi'
                        ? "रोजगार पीठा में आपका स्वागत है"
                        : "Welcome to Rozgaar Peetha",
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
                      hintText: t(context, "Enter mobile number", "मोबाइल नंबर दर्ज करें"),
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

                        if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phoneController.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t(
                                  context,
                                  "Enter valid 10 digit number",
                                  "कृपया 10 अंकों का सही मोबाइल नंबर दर्ज करें",
                                ),
                              ),
                            ),
                          );
                          return; // 🔥 VERY IMPORTANT
                        }
                        await FirebaseAuth.instance.verifyPhoneNumber(
                          phoneNumber: "+91${phoneController.text.trim()}",

                          verificationCompleted: (PhoneAuthCredential credential) async {
                            await FirebaseAuth.instance.signInWithCredential(credential);
                          },

                          verificationFailed: (FirebaseAuthException e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message ?? "Verification Failed")),
                            );
                          },

                          codeSent: (String verificationId, int? resendToken) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtpScreen(
                                  verificationId: verificationId,
                                  phoneNumber: "+91${phoneController.text.trim()}",  // 🔥 यह line add करें
                                ),
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
                      child: Text(
                        t(context, "Login", "लॉगिन करें"),
                        style: const TextStyle(fontSize: 18),
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
    final String phoneNumber;

    const OtpScreen({super.key, required this.verificationId, required this.phoneNumber});

    @override
    State<OtpScreen> createState() => _OtpScreenState();
  }

  class _OtpScreenState extends State<OtpScreen> {

    final TextEditingController otpController = TextEditingController();

    // 🔥 Resend OTP ke liye variables
    int _remainingSeconds = 60;
    Timer? _timer;
    bool _canResend = false;

    @override
    void initState() {
      super.initState();
      _startTimer();
    }

    @override
    void dispose() {
      _timer?.cancel();
      otpController.dispose();
      super.dispose();
    }

    void _startTimer() {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_remainingSeconds > 0) {
              _remainingSeconds--;
            } else {
              _canResend = true;
              _timer?.cancel();
            }
          });
        }
      });
    }

    void _resendOTP() async {
      setState(() {
        _canResend = false;
        _remainingSeconds = 60;
      });

      _startTimer();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Verification Failed")),
          );
          setState(() {
            _canResend = true;
            _remainingSeconds = 0;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }

    void verifyOTP() async {
      if (otpController.text.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(context, "Enter valid 6 digit OTP", "कृपया 6 अंकों का सही OTP दर्ज करें"),
            ),
          ),
        );
        return;
      }

      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otpController.text.trim(),
        );

        await FirebaseAuth.instance.signInWithCredential(credential);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthCheckScreen(),
          ),
        );

      } catch (e) {
        String errorMessage = t(
            context,
            "Invalid OTP. Please try again.",
            "गलत OTP है, कृपया फिर से कोशिश करें"
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
              Text(
                t(context, "Verify OTP", "OTP Verify करें"),
                style: const TextStyle(
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

              // 🔥 RESEND OTP BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _canResend
                        ? t(context, "Didn't receive OTP?", "OTP नहीं मिला?")
                        : t(context, "Resend OTP in", "OTP भेजने में बचा समय"),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (!_canResend) ...[
                    const SizedBox(width: 5),
                    Text(
                      "00:${_remainingSeconds.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                  if (_canResend) ...[
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: _resendOTP,
                      child: Text(
                        t(context, " Resend", "पुनः भेजें"),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: verifyOTP,
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

                  Text(
                    t(context, "What work do you do?", "आप क्या काम करते हैं?"),
                    style: const TextStyle(
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
                    child: Text(
                      t(context, "Continue", "आगे बढ़ें"),
                      style: const TextStyle(fontSize: 18),
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
      return Scaffold(
        body: Center(
          child: Text(
            t(context, "Next Screen", "अगली स्क्रीन"),
          ),
        ),
      );
    }
  }


  // ===== ProfileSetupScreen (with Edit Profile) =====

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
    final pinController = TextEditingController();

    File? selectedImage;
    String? imageUrl;

    // 🔥 Edit mode ke liye new variables
    String? existingImageUrl;
    String? existingAudioUrl;
    String? existingState;
    String? existingDistrict;
    bool isEditMode = false;

    final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
    String? audioPath;
    bool isRecording = false;
    int recordingSeconds = 0;
    Timer? recordingTimer;

    bool isLoading = false;

    String? selectedState;
    String? selectedDistrict;

    bool _isValidDistrict(String? district) {
      if (district == null) return false;
      if (selectedState == null) return false;
      if (!stateDistrictMap.containsKey(selectedState)) return false;

      return stateDistrictMap[selectedState]!.any((d) =>
      d["en"] == district || d["hi"] == district);
    }

    // 🔵 STATE - DISTRICT DATA
    final Map<String, List<Map<String, String>>> stateDistrictMap = {
      "mp": [
        {"en": "Bhopal", "hi": "भोपाल"},
        {"en": "Indore", "hi": "इंदौर"},
        {"en": "Raisen", "hi": "रायसेन"},
      ],
    };

    @override
    void initState() {
      super.initState();
      _loadExistingData(); // 🔥 Load existing data for edit
    }

    // 🔥 LOAD EXISTING USER DATA
    // 🔥 LOAD EXISTING USER DATA
    Future<void> _loadExistingData() async {
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

      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        // Fill controllers with existing data
        nameController.text = data["name"] ?? "";
        workTypeController.text = data["workType"] ?? "";
        pinController.text = data["pin"] ?? "";

        existingImageUrl = data["dp"];
        existingAudioUrl = data["audioUrl"];
        existingState = data["state"];
        existingDistrict = data["district"];

        // 🔥 IMPORTANT: Check if state exists in map, otherwise set null
        String? loadedState = existingState;
        String? loadedDistrict = existingDistrict;

        // Verify state exists in our map
        if (loadedState != null && stateDistrictMap.containsKey(loadedState)) {
          setState(() {
            selectedState = loadedState;
          });

          // Verify district exists in this state's districts
          if (loadedDistrict != null) {
            bool districtExists = stateDistrictMap[loadedState]!.any((d) =>
            d["en"] == loadedDistrict || d["hi"] == loadedDistrict);

            if (districtExists) {
              setState(() {
                selectedDistrict = loadedDistrict;
              });
            } else {
              setState(() {
                selectedDistrict = null;
              });
            }
          }
        } else {
          // Agar state map mein nahi hai to null set karo
          setState(() {
            selectedState = null;
            selectedDistrict = null;
          });
        }
      }

      setState(() {
        isLoading = false;
      });
    }

    // ================= AUDIO RECORD =================
    Future<void> startRecording() async {
      await _recorder.openRecorder();

      final dir = await getTemporaryDirectory();
      String path = "${dir.path}/intro_${DateTime.now().millisecondsSinceEpoch}.aac";

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
          if (mounted) {
            setState(() {
              recordingSeconds++;
            });
          }
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
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 60,
        );

        if (pickedFile != null) {
          setState(() {
            selectedImage = File(pickedFile.path);
          });
        }
      } catch (e) {
        print("Image Picker Error: $e");
      }
    }

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
        await Geolocator.openLocationSettings();
        return Future.error("Location off");
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return Future.error("Location permission denied");
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    // 🔥 UPDATE PROFILE (for edit mode)
    Future<void> updateProfile() async {
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

        Position position = await getUserLocation();
        String areaName = await getAreaName(
          position.latitude,
          position.longitude,
        );

        String? finalImageUrl = existingImageUrl;
        String? finalAudioUrl = existingAudioUrl;

        if (audioPath != null) {
          finalAudioUrl = await uploadAudio(File(audioPath!));
        }

        if (selectedImage != null) {
          finalImageUrl = await uploadImage(selectedImage!);
        }

        // 🔥 UPDATE user data (not create new)
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({
          "name": nameController.text.trim(),
          "workType": workTypeController.text.trim(),
          "state": selectedState,
          "district": selectedDistrict,
          "pin": pinController.text.trim(),
          "dp": finalImageUrl ?? existingImageUrl ?? "",
          "latitude": position.latitude,
          "longitude": position.longitude,
          "area": areaName,
          "audioUrl": finalAudioUrl ?? existingAudioUrl ?? "",
          "hasIntro": (finalAudioUrl != null || (existingAudioUrl != null && existingAudioUrl!.isNotEmpty)),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(context, "Profile updated successfully", "प्रोफाइल सफलतापूर्वक अपडेट हो गया"),
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);

      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    // 🔥 SAVE PROFILE (for new user)
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

        Position position = await getUserLocation();
        String areaName = await getAreaName(
          position.latitude,
          position.longitude,
        );

        String? finalImageUrl;
        String? finalAudioUrl;

        if (audioPath != null) {
          finalAudioUrl = await uploadAudio(File(audioPath!));
        }

        if (selectedImage != null) {
          finalImageUrl = await uploadImage(selectedImage!);
        }

        WriteBatch batch = FirebaseFirestore.instance.batch();

        DocumentReference userRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
        DocumentReference txnRef = FirebaseFirestore.instance.collection("transactions").doc();

        batch.set(userRef, {
          "name": nameController.text.trim(),
          "phone": user.phoneNumber ?? "",
          "role": widget.role,
          "workType": workTypeController.text.trim(),
          "state": selectedState,
          "district": selectedDistrict,
          "pin": pinController.text.trim(),
          "dp": finalImageUrl ?? "",
          "wallet": 20,
          "welcomeBonusGiven": true,
          "isFirstJobFreeUsed": false,
          "totalJobs": 0,
          "totalEarned": 0,
          "isAvailable": true,
          "rating": 0.0,
          "totalRatings": 0,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "area": areaName,
          "createdAt": FieldValue.serverTimestamp(),
          "audioUrl": finalAudioUrl ?? "",
          "hasIntro": finalAudioUrl != null,
        });

        batch.set(txnRef, {
          "userId": user.uid,
          "amount": 20,
          "type": "credit",
          "reason": "Welcome Bonus",
          "createdAt": FieldValue.serverTimestamp(),
        });

        await batch.commit();
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
      // Agar edit mode mein data load ho raha hai to loading show karo
      if (isEditMode && isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: Text(t(context, "Edit Profile", "प्रोफाइल संपादित करें")),
            backgroundColor: Colors.green,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(
            isEditMode
                ? t(context, "Edit Profile", "प्रोफाइल संपादित करें")
                : t(context, "Profile Setup", "प्रोफाइल सेटअप"),
          ),
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
                    "Role: ${widget.role == 'worker' ? 'मज़दूर' : 'ठेकेदार'}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📸 DP with existing image support
                  // 📸 DP with existing image support
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!) as ImageProvider
                          : (existingImageUrl != null && existingImageUrl!.isNotEmpty
                          ? NetworkImage(existingImageUrl!) as ImageProvider
                          : null),
                      child: (selectedImage == null && (existingImageUrl == null || existingImageUrl!.isEmpty))
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    t(context, "Tap to change photo", "फोटो बदलने के लिए टैप करें"),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // 🎤 Audio Record
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
                          t(context, "Recording... $recordingSeconds s", "रिकॉर्डिंग... $recordingSeconds सेकंड"),
                          style: const TextStyle(color: Colors.white),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              existingAudioUrl != null && existingAudioUrl!.isNotEmpty
                                  ? t(context, "Hold to re-record Intro", "इंट्रो री-रिकॉर्ड करें")
                                  : t(context, "Hold to Record Intro", "इंट्रो रिकॉर्ड करने के लिए दबाकर रखें"),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 🎵 Play existing audio button
                  if (existingAudioUrl != null && existingAudioUrl!.isNotEmpty && !isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () async {
                          final player = AudioPlayer();
                          await player.setUrl(existingAudioUrl!);
                          player.play();
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(t(context, "Play existing intro", "पुराना इंट्रो सुनें")),
                      ),
                    ),

                  const SizedBox(height: 20),

                  buildField(t(context, "Full Name", "पूरा नाम"), nameController),

                  buildField(
                    widget.role == "worker"
                        ? t(context, "What work do you do?", "आप कौन सा काम करते हैं?")
                        : t(context, "What type of work do you provide?", "आप किस प्रकार का काम देते हैं?"),
                    workTypeController,
                  ),

                  // 🔽 STATE DROPDOWN
                  // 🔽 STATE DROPDOWN
                  // 🔽 DISTRICT DROPDOWN (FIXED)
                  DropdownButtonFormField<String>(
                    value: selectedDistrict != null && _isValidDistrict(selectedDistrict)
                        ? selectedDistrict
                        : null,
                    hint: Text(t(context, "Select District", "जिला चुनें")),
                    items: (selectedState != null && stateDistrictMap.containsKey(selectedState)
                        ? stateDistrictMap[selectedState] ?? []
                        : [])
                        .map<DropdownMenuItem<String>>((districtMap) {
                      // 🔥 VALUE = ENGLISH (hamesha)
                      String districtValue = districtMap["en"]!;
                      // 🔥 DISPLAY = Hindi ya English
                      String displayName = Localizations.localeOf(context).languageCode == 'hi'
                          ? districtMap["hi"]!
                          : districtMap["en"]!;
                      return DropdownMenuItem<String>(
                        value: districtValue,  // 🔥 IMPORTANT: English value
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: selectedState == null
                        ? null
                        : (value) {
                      setState(() {
                        selectedDistrict = value;  // 🔥 value English mein store hoga
                      });
                    },
                    validator: (value) => value == null
                        ? t(context, "District is required", "जिला चुनना आवश्यक है")
                        : null,
                  ),
                  const SizedBox(height: 20),

                  buildField(
                    t(context, "PIN Code", "पिन कोड"),
                    pinController,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 30),

                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: isEditMode ? updateProfile : saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      isEditMode
                          ? t(context, "Update Profile", "प्रोफाइल अपडेट करें")
                          : t(context, "Save & Continue", "सेव करें और आगे बढ़ें"),
                    ),
                  ),
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
              return t(context, "This field cannot be empty", "यह फील्ड खाली नहीं हो सकता");
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
      pinController.dispose();
      _recorder.closeRecorder();
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

    final PageController _bannerController = PageController();
    int _currentBanner = 0;
    Timer? _bannerTimer;


    bool isProcessing = false;

    final FlutterSoundRecorder dashboardRecorder = FlutterSoundRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();

    String? dashboardAudioPath;

    String audioUrl = "";

    bool isRecordingDashboard = false;
    int recordSeconds = 0;
    Timer? recordTimer;

    late StreamSubscription<Position> _positionStream;
    bool _isLocationTracking = false;

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

    void startBannerAutoSlide() {
      _bannerTimer = Timer.periodic(
        const Duration(seconds: 3),
            (timer) {
          if (!_bannerController.hasClients) return;

          _currentBanner++;

          if (_currentBanner > 2) {
            _currentBanner = 0;
          }

          _bannerController.animateToPage(
            _currentBanner,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      );
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

    @override
    void dispose() {
      _bannerTimer?.cancel();
      _bannerController.dispose();

      requestTimer?.cancel();
      recordTimer?.cancel();

      ringtonePlayer.dispose();
      audioPlayer.dispose();

      super.dispose();
    }

    // 🔥 यह पूरा function copy-paste करें
    void _startLocationTracking() {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 100,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        if (!_isLocationTracking) {
          _isLocationTracking = true;

          String uid = FirebaseAuth.instance.currentUser!.uid;
          String areaName = await getAreaName(position.latitude, position.longitude);

          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .update({
            "latitude": position.latitude,
            "longitude": position.longitude,
            "area": areaName,
            "lastLocationUpdate": FieldValue.serverTimestamp(),
          });

          if (mounted) {
            setState(() {
              area = areaName;
            });
          }

          print("📍 Location updated: $areaName");
          _isLocationTracking = false;
        }
      }, onError: (error) {  // 🔥 यहाँ onError डालें (listen के अंदर)
        print("❌ Location stream error: $error");
      });
    }


    Future<void> startDashboardRecording() async {
      try {
        var status = await Permission.microphone.request();

        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t(context, "Microphone permission denied", "माइक की अनुमति नहीं मिली"),
              ),
            ),
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
          SnackBar(
            content: Text(
              t(
                context,
                "Recording too short",
                "रिकॉर्डिंग बहुत छोटी है",
              ),
            ),
          ),
        );
        return;
      }

      // 🎧 PREVIEW DIALOG ///// yeha kaam kar rahe hai
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              "${t(context, "Preview Intro", "इंट्रो सुनें")} 🎧",
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ⏱ Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "$recordSeconds sec",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  t(context, "Play and check before saving",
                      "सेव करने से पहले सुन लें"),
                ),
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
                child: Text(t(context, "Play", "चलाएँ")),
              ),

              // ❌ DISCARD
              TextButton(
                onPressed: () async {
                  await audioPlayer.stop();
                  Navigator.pop(dialogContext);
                },
                child: Text(t(context, "Discard", "हटाएँ")),
              ),

              // ✅ SAVE
              TextButton(
                onPressed: () async {
                  await audioPlayer.stop();
                  Navigator.pop(dialogContext);

                  try {
                    if (dashboardAudioPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t(context, "Audio not found", "ऑडियो नहीं मिला"),
                          ),
                        ),
                      );
                      return;
                    }

                    File file = File(dashboardAudioPath!);

                    String? url = await uploadDashboardAudio(file);

                    if (url == null || url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t(context, "Upload failed", "अपलोड विफल"),
                          ),
                        ),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .set({
                      "audioUrl": url,
                      "hasIntro": true,
                    }, SetOptions(merge: true));

                    setState(() {
                      audioUrl = url;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t(context, "Intro saved", "इंट्रो सेव हो गया"),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t(context, "Something went wrong", "कुछ गलत हो गया"),
                        ),
                      ),
                    );
                  }
                },
                child: Text(t(context, "Save", "सेव करें")),
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

      startBannerAutoSlide();

      _startLocationTracking();

      getUserData();
      loadAudioUrl();


      saveFCMToken();
      checkActiveRequest();

      listenIncomingRequests();
      listenReceiverPayment();
      listenBothPaymentComplete();
      listenSenderUpdates();
    }

    Future<void> addMoneyToWallet(int amount) async {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DocumentReference userRef =
      FirebaseFirestore.instance.collection("users").doc(uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        int currentWallet =
            (snapshot.data() as Map<String, dynamic>)["wallet"] ?? 0;

        transaction.update(userRef, {
          "wallet": currentWallet + amount,
        });
      });

      setState(() {
        wallet += amount; // 🔥 UI update
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("₹$amount added successfully")),
      );
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

              final ctx = navigatorKey.currentContext;

              if (ctx != null) {
                Navigator.push(
                  ctx,
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

              final ctx = navigatorKey.currentContext;

              if (ctx != null) {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => const WorkerAcceptedScreen(),
                  ),
                );
              }

            }

            if (status == "rejected") {

              if (navigatorKey.currentContext == null) return;

              final ctx = navigatorKey.currentContext;

              if (ctx != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      t(
                        ctx,
                        "Worker rejected your request",
                        "मज़दूर ने आपकी रिक्वेस्ट अस्वीकार कर दी",
                      ),
                    ),
                  ),
                );
              }

            }

            if (status == "expired") {

              final ctx = navigatorKey.currentContext;
              if (ctx == null) return;

              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    t(
                      ctx,
                      "Request expired",
                      "रिक्वेस्ट की समय सीमा समाप्त हो गई",
                    ),
                  ),
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
                              isAvailable
                                  ? t(context, "Available", "उपलब्ध")
                                  : t(context, "Offline", "ऑफलाइन"),
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





    // DATA FETCH KARNE KA FUNCTION
    void getUserData() async {

      print("CHECK RUNNING");
      print("MY NUMBER: ${FirebaseAuth.instance.currentUser?.phoneNumber}");

      print(FirebaseAuth.instance.currentUser?.phoneNumber);
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

      bool hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(pattern: [500, 500, 500, 500, 500], repeat: 0);
      }

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

      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      showGeneralDialog(
        context: ctx,
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
                    Vibration.cancel();

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
                                  Vibration.cancel();

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
                                  Vibration.cancel();

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

                    Text(
                      "🔒 ${t(context, "Direct Connection Unlock", "सीधा संपर्क अनलॉक")}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      t(
                        context,
                        "You can contact this worker directly (Free for limited time)",
                        "आप इस मज़दूर से सीधे संपर्क कर सकते हैं (फिलहाल मुफ्त)",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          t(
                            context,
                            "Valid for next 10 minutes",
                            "अगले 10 मिनट तक मान्य",
                          ),
                          style: const TextStyle(
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

                            onPressed: isProcessing ? null : () async {

                              setState(() {
                                isProcessing = true;
                              });

                              try {

                                // ✅ SAFE USER FETCH
                                final user = FirebaseAuth.instance.currentUser;

                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("User not logged in")),
                                  );
                                  return;
                                }

                                String currentUserId = user.uid;

                                // 🔥 USER DATA FETCH
                                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(currentUserId)
                                    .get();

                                Map<String, dynamic> userData =
                                (userDoc.data() ?? {}) as Map<String, dynamic>;

                                // 🔥 REQUEST CHECK (duplicate payment stop)
                                DocumentSnapshot requestDoc = await FirebaseFirestore.instance
                                    .collection("hireRequests")
                                    .doc(data["id"])
                                    .get();

                                bool alreadyPaid = requestDoc["receiverPaid"] ?? false;

                                if (alreadyPaid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Payment already done")),
                                  );
                                  return;
                                }

                                // 🔥 WALLET + COMMISSION



                                await processHireWithCommission(
                                  user1Id: data["senderId"],
                                  user2Id: currentUserId,
                                );

                                // 🔥 REQUEST UPDATE
                                await FirebaseFirestore.instance
                                    .collection("hireRequests")
                                    .doc(data["id"])
                                    .update({
                                  "receiverPaid": true,
                                });

                                Navigator.of(dialogContext).pop();
                                isDialogOpen = false;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t(context, "Connection successful", "संपर्क सफल हुआ"),
                                    ),
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

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t(context, "Something went wrong", "कुछ गलत हो गया"),
                                    ),
                                  ),
                                );

                              }

                              setState(() {
                                isProcessing = false;
                              });
                            },

                            child: Text(
                              t(
                                context,
                                "Continue",
                                "आगे बढ़ें",
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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

            final ctx = navigatorKey.currentContext;

            if (ctx != null) {
              Navigator.push(
                ctx,
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

        }

      });

    }

    Future<void> updateUserLocation() async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        String uid = FirebaseAuth.instance.currentUser!.uid;

        // 🔥 ADD THIS
        String areaName = await getAreaName(
          position.latitude,
          position.longitude,
        );

        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .update({
          "latitude": position.latitude,
          "longitude": position.longitude,
          "area": areaName// 🔥 IMPORTANT
        });

        print("✅ Location + Area updated");
      } catch (e) {
        print("❌ Location error: $e");
      }
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
            return Center(
              child: Text(
                t(
                  context,
                  "No nearby workers found",
                  "कोई नजदीकी मज़दूर नहीं मिला",
                ),
              ),
            );
          }

          var workers = snapshot.data!;

          return SizedBox(
            height: 280, // Mazdoor list card height
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

      await FirebaseFirestore.instance.runTransaction((transaction) async {

        const int commission = 5;

        DocumentReference user1Ref =
        FirebaseFirestore.instance.collection("users").doc(user1Id);

        DocumentReference user2Ref =
        FirebaseFirestore.instance.collection("users").doc(user2Id);

        DocumentReference adminRef =
        FirebaseFirestore.instance.collection("admin").doc("main");

        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot user2Snap = await transaction.get(user2Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);

        // ✅ USER 1
        Map<String, dynamic> user1Data =
            user1Snap.data() as Map<String, dynamic>? ?? {};
        int user1Wallet = user1Data["wallet"] ?? 0;

        // ✅ USER 2
        Map<String, dynamic> user2Data =
            user2Snap.data() as Map<String, dynamic>? ?? {};
        int user2Wallet = user2Data["wallet"] ?? 0;

        // ✅ ADMIN
        Map<String, dynamic> adminData =
            adminSnap.data() as Map<String, dynamic>? ?? {};
        int adminWallet = adminData["wallet"] ?? 0;

        // 🔥 CHECK BOTH
        if (user1Wallet < commission) {
          throw Exception("Recharge Required");
        }

        if (user2Wallet < commission) {
          throw Exception("Recharge Required");
        }

        // 💰 CUT BOTH
        transaction.update(user1Ref, {
          "wallet": user1Wallet - commission,
        });

        transaction.update(user2Ref, {
          "wallet": user2Wallet - commission,
        });

        // 🔥 TRANSACTION LOG USER 1
        transaction.set(
          FirebaseFirestore.instance.collection("transactions").doc(),
          {
            "userId": user1Id,
            "amount": commission,
            "type": "debit",
            "reason": "Hire Commission",
            "createdAt": FieldValue.serverTimestamp(),
          },
        );

// 🔥 TRANSACTION LOG USER 2
        transaction.set(
          FirebaseFirestore.instance.collection("transactions").doc(),
          {
            "userId": user2Id,
            "amount": commission,
            "type": "debit",
            "reason": "Hire Commission",
            "createdAt": FieldValue.serverTimestamp(),
          },
        );

// 🔥 ADMIN LOG
        transaction.set(
          FirebaseFirestore.instance.collection("transactions").doc(),
          {
            "userId": "admin",
            "amount": commission * 2,
            "type": "credit",
            "reason": "Commission Earned",
            "createdAt": FieldValue.serverTimestamp(),
          },
        );

        // 🔥 ADMIN ADD
        transaction.set(adminRef, {
          "wallet": adminWallet + (commission * 2),
          "totalEarning": FieldValue.increment(commission * 2),
        }, SetOptions(merge: true));
      });
    }



    Stream<List<Map<String, dynamic>>> _getNearbyJobsStream() async* {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // 🔥 USER DATA FETCH
      var userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        yield [];
        return;
      }

      String userDistrict = userDoc["district"] ?? "";
      String userState = userDoc["state"] ?? "";

      // 🔥 CURRENT LOCATION
      Position currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (e) {
        print("Location error: $e");
        yield [];
        return;
      }

      double userLat = currentPosition.latitude;
      double userLng = currentPosition.longitude;

      // 🔥 ROLE LOGIC
      String role = widget.role.toString().trim();

      String targetRole =
      (role == "worker")
          ? "employer"
          : "worker";

      // 🔥 FIREBASE STREAM
      yield* FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: targetRole)
          .where("isAvailable", isEqualTo: true)
          .where("state", isEqualTo: userState)       // 🔥 NEW (IMPORTANT)
          .where("district", isEqualTo: userDistrict) // 🔥 KEEP
          .snapshots()
          .asyncMap((snapshot) async {

        List<Map<String, dynamic>> nearbyWorkers = [];

        for (var doc in snapshot.docs) {

          // ❌ खुद को skip करो
          if (doc.id == user.uid) continue;

          var data = doc.data() as Map<String, dynamic>;

          data["id"] = doc.id;

          double workerLat = (data["latitude"] ?? 0).toDouble();
          double workerLng = (data["longitude"] ?? 0).toDouble();

          // ❌ अगर location missing है तो skip
          if (workerLat == 0 || workerLng == 0) continue;

          double distance = Geolocator.distanceBetween(
            userLat,
            userLng,
            workerLat,
            workerLng,
          );

          // 🔥 MAIN FILTER (10 KM)
          if (distance <= 10000) {
            data["distance"] = distance;
            nearbyWorkers.add(data);
          }
        }

        // 🔥 SORT (nearest first)
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
          title: Text(
            t(context, "Dashboard", "डैशबोर्ड"),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
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
                    _smallNavButton(
                      Icons.people_alt,
                      t(context, "Worker List", "मज़दूर लिस्ट"),
                      Colors.blue,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MajdoorListScreen()),
                        );
                      },
                    ),



                    _smallNavButton(
                      Icons.business,
                      t(context, "Contractor List", "ठेकेदार लिस्ट"),
                      Colors.purple,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ThekedarListScreen()),
                        );
                      },
                    ),

                    _smallNavButton(
                      Icons.notifications,
                      t(context, "Requests", "रिक्वेस्ट्स"),
                      Colors.orange,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestsUpdatesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),


                const SizedBox(height: 18),


                // ================= NEARBY JOBS =================
                _smallSectionHeader(
                  t(context, "Nearby Jobs", "नज़दीकी काम"),
                ),
                const SizedBox(height: 8),

                _buildNearbyJobs(),

                const SizedBox(height: 18),

// ================= WORK HISTORY =================
                _smallSectionHeader(
                  t(context, "My Work History", "मेरा कार्य इतिहास"),
                ),
                const SizedBox(height: 8),

                _compactJobScroll([
                  _compactJobItem(
                    t(context, "Brickwork", "ईंट का काम"),
                    t(context, "Civil Lines", "सिविल लाइंस"),
                    "₹800 / day",
                    4,
                  ),
                  _compactJobItem(
                    t(context, "Unloading Cement", "सीमेंट उतारना"),
                    t(context, "Sahadatganj", "सहादतगंज"),
                    "₹200",
                    4,
                  ),
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
                    title: Text(
                      t(context, "My Wallet", "मेरा वॉलेट"),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      "₹$wallet",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // 🔥 MUST

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WalletScreen()),
                      );
                    },
                  ),
                ),

                // 🔽 MENU SECTION
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [

                      _drawerTile(
                        Icons.edit,
                        t(context, "Edit Profile", "प्रोफाइल संपादित करें"),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileSetupScreen(role: role),
                            ),
                          );
                        },
                      ),

                      if (FirebaseAuth.instance.currentUser?.phoneNumber == "+916261360602")
                        _drawerTile(
                          Icons.admin_panel_settings,
                          "Admin Dashboard",
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminDashboardScreen(),
                              ),
                            );
                          },
                        ),


                      _drawerTile(
                        Icons.history,
                        t(context, "Hire History", "भर्ती इतिहास"),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HireHistoryScreen(),
                            ),
                          );
                        },
                      ),

                      const Divider(),

                      _drawerTile(
                        Icons.settings,
                        t(context, "Settings", "सेटिंग्स"),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                onLanguageChange: (langCode) {
                                  // 🔥 यहाँ language change करो
                                  (context.findAncestorStateOfType<_MyAppState>())
                                      ?.changeLanguage(langCode);
                                },
                              ),
                            ),
                          );
                        },
                      ),


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

                // 🇮🇳 HINDI
                ListTile(
                  title: const Text("Hindi (हिंदी)"),
                  onTap: () {
                    Navigator.pop(context);

                    // 🔥 YAHAN ADD KARNA HAI
                    (context.findAncestorStateOfType<_MyAppState>())
                        ?.changeLanguage('hi');
                  },
                ),

                // 🇬🇧 ENGLISH
                ListTile(
                  title: const Text("English"),
                  onTap: () {
                    Navigator.pop(context);

                    // 🔥 YAHAN ADD KARNA HAI
                    (context.findAncestorStateOfType<_MyAppState>())
                        ?.changeLanguage('en');
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
          controller: _bannerController,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 DP
            CircleAvatar(
              radius: 28,
              backgroundImage: dp.isNotEmpty ? NetworkImage(dp) : null,
              child: dp.isEmpty ? const Icon(Icons.person) : null,
            ),

            const SizedBox(width: 10),

            // 🔥 LEFT SIDE (Name + Role + Area)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    widget.role,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
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

            // 🔥 RIGHT SIDE (Available + Record SAME COLUMN)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                _buildAvailabilityToggle(),

                const SizedBox(height: 4), // 🔥 gap control

                _smallProfileProgress(),
              ],
            ),
          ],
        ),
      );
    }



    Widget _buildAvailabilityToggle() {
      return GestureDetector(
        onTap: () async {

          String uid = FirebaseAuth.instance.currentUser!.uid;

          bool newValue = !isAvailable;

          setState(() {
            isAvailable = newValue;
          });

          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .update({
            "isAvailable": newValue,
          });

        },
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                isAvailable
                    ? t(context, "Available", "उपलब्ध")
                    : t(context, "Offline", "ऑफलाइन"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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

    // Ye naya code hai jo click karne par dusri screen par le jayega

    Widget _smallProfileProgress() {
      return GestureDetector(
        onLongPressStart: (_) => startDashboardRecording(),
        onLongPressEnd: (_) => stopDashboardRecording(),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🔥 SAME
          decoration: BoxDecoration(
            color: isRecordingDashboard ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                isRecordingDashboard
                    ? "$recordSeconds s"
                    : "Record",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11, // 🔥 SAME
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
        ),
      );
    }
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

    final AudioPlayer audioPlayer = AudioPlayer();

    // 🔥 नया function: सिर्फ 10 KM के अंदर वाले मजदूर लाने के लिए
    Stream<List<QueryDocumentSnapshot>> _getNearbyWorkersStream() async* {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // अपनी current location लो
      Position currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (e) {
        print("Location error: $e");
        yield [];
        return;
      }

      double userLat = currentPosition.latitude;
      double userLng = currentPosition.longitude;

      // सारे available मजदूर लो
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "worker")
          .where("isAvailable", isEqualTo: true)
          .get();

      List<QueryDocumentSnapshot> nearbyWorkers = [];

      for (var doc in snapshot.docs) {
        // अपने आप को skip करो
        if (doc.id == user.uid) continue;

        var data = doc.data() as Map<String, dynamic>;
        double workerLat = (data["latitude"] ?? 0).toDouble();
        double workerLng = (data["longitude"] ?? 0).toDouble();

        // अगर location missing है तो skip
        if (workerLat == 0 || workerLng == 0) continue;

        double distance = Geolocator.distanceBetween(
          userLat,
          userLng,
          workerLat,
          workerLng,
        );

        // 🔥 MAIN FILTER: सिर्फ 10 KM के अंदर वाले
        if (distance <= 10000) {
          // दूरी data में add करो (UI में दिखाने के लिए)
          data["distance"] = distance;
          nearbyWorkers.add(doc);
        }
      }

      // नजदीक वाले पहले दिखें
      nearbyWorkers.sort((a, b) {
        double distA = (a.data() as Map<String, dynamic>)["distance"] ?? 0;
        double distB = (b.data() as Map<String, dynamic>)["distance"] ?? 0;
        return distA.compareTo(distB);
      });

      yield nearbyWorkers;
    }

    Future<void> playAudio(String url) async {
      try {
        await audioPlayer.setUrl(url);
        audioPlayer.play();
      } catch (e) {
        print("Audio error: $e");
      }
    }

    // 🔥 ₹5 Commission System (आपका original code)
    Future<void> processHireWithCommission({
      required String user1Id,
      required String user2Id,
    }) async {
      const int commission = 5;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference user1Ref = FirebaseFirestore.instance.collection("users").doc(user1Id);
        DocumentReference adminRef = FirebaseFirestore.instance.collection("admin").doc("main");
        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);
        int user1Wallet = (user1Snap.data() as Map<String, dynamic>?)?["wallet"] ?? 0;
        bool user1FreeUsed = (user1Snap.data() as Map<String, dynamic>?)?["isFirstJobFreeUsed"] ?? false;
        int adminWallet = adminSnap["wallet"] ?? 0;
        int totalCommission = 0;
        if (!user1FreeUsed) {
          transaction.update(user1Ref, {
            "isFirstJobFreeUsed": true,
          });
        } else {
          if (user1Wallet < commission) {
            throw Exception("₹5 Balance Required");
          }
          transaction.update(user1Ref, {
            "wallet": user1Wallet - commission,
          });
          totalCommission += commission;
        }
        if (totalCommission > 0) {
          transaction.update(adminRef, {
            "wallet": adminWallet + totalCommission,
            "totalEarning": FieldValue.increment(totalCommission),
          });
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          title: const Text("मजदूर लिस्ट",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: StreamBuilder<List<QueryDocumentSnapshot>>(
          // 🔥 यहाँ नया stream use करो
          stream: _getNearbyWorkersStream(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("10 KM के अंदर कोई मजदूर उपलब्ध नहीं है"),
              );
            }

            var docs = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                var data = doc.data() as Map<String, dynamic>;
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
                double distance = (data["distance"] ?? 0).toDouble();
                bool isAvailable = data["isAvailable"] ?? false;
                double rating = (data["rating"] ?? 0.0).toDouble();
                int totalRatings = (data["totalRatings"] ?? 0);
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
                              backgroundImage: dp.isNotEmpty ? NetworkImage(dp) : null,
                              child: dp.isEmpty
                                  ? Text(
                                name.isNotEmpty ? name[0] : "",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              )
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
                                  bool isPending = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
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
                                      backgroundColor: isPending ? Colors.grey : Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: Text(
                                      isPending ? "Pending" : "Hire ₹5",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
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


  Future<void> sendPushNotification(String token) async {
    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=YOUR_SERVER_KEY"
      },
      body: jsonEncode({
        "to": token,
        "priority": "high",
        "notification": {
          "title": "New Hire Request",
          "body": "Someone wants to hire you"
        },
        "data": {
          "type": "hire_request"
        }
      }),
    );
  }

  Future<void> sendHireRequest({
    required String senderId,
    required String receiverId,
  }) async {

    const int fee = 5;

    DocumentSnapshot senderDoc =
    await FirebaseFirestore.instance
        .collection("users")
        .doc(senderId)
        .get();

    bool senderAvailable =
        senderDoc["isAvailable"] ?? false;

    if (!senderAvailable) {
      throw Exception("You are offline. Go online first.");
    }

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

      DocumentSnapshot senderSnap =
      await transaction.get(senderRef);

      int wallet = senderSnap["wallet"] ?? 0;

      if (wallet < fee) {

        final ctx = navigatorKey.currentContext;

        if (ctx != null) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => const WalletScreen(),
            ),
          );
        }

        throw Exception("Please recharge wallet");
      }

      transaction.set(requestRef, {
        "senderId": senderId,
        "receiverId": receiverId,
        "senderPaid": true,
        "receiverPaid": false,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });
    });

    // 🔥 Transaction ke baad Push Notification bhejo
    String token = receiverDoc["fcmToken"] ?? "";

    if (token.isNotEmpty) {
      await sendPushNotification(token);
    }
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

                            String currentUserId = FirebaseAuth.instance.currentUser!.uid;

                            // 🔥 USER DATA FETCH
                            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                .collection("users")
                                .doc(currentUserId)
                                .get();

                            bool isFirstFreeUsed = userDoc["isFirstJobFreeUsed"] ?? false;

                            /// 🎁 FIRST JOB FREE
                            if (!isFirstFreeUsed) {

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(currentUserId)
                                  .update({
                                "isFirstJobFreeUsed": true,
                              });

                              // 👉 Direct request send (no balance check)
                              await sendHireRequest(
                                senderId: currentUserId,
                                receiverId: workerId,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t(context, "First Job Free 🎉", "पहला काम फ्री 🎉"),
                                  ),
                                ),
                              );

                            } else {

                              /// 🔥 NORMAL FLOW (₹5 REQUIRED)
                              await sendHireRequest(
                                senderId: currentUserId,
                                receiverId: workerId,
                              );

                            }

                          } catch (e) {

                            String error = e.toString();

                            if (error.toString().contains("BALANCE_REQUIRED")) {

                              // 🔔 Message दिखाओ
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t(
                                      context,
                                      "Insufficient balance. Please recharge first",
                                      "वॉलेट में ₹5 नहीं है, पहले रिचार्ज करें",
                                    ),
                                  ),
                                ),
                              );

                              // 🚀 Wallet Screen खोलो
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WalletScreen(),
                                ),
                              );

                            } else {

                              // ❌ Other Error
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t(
                                      context,
                                      "Something went wrong",
                                      "कुछ गलत हो गया",
                                    ),
                                  ),
                                ),
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

    // 🔥 नया function: सिर्फ 10 KM के अंदर वाले ठेकेदार लाने के लिए
    Stream<List<QueryDocumentSnapshot>> _getNearbyEmployersStream() async* {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // अपनी current location लो
      Position currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (e) {
        print("Location error: $e");
        yield [];
        return;
      }

      double userLat = currentPosition.latitude;
      double userLng = currentPosition.longitude;

      // सारे available ठेकेदार लो
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "employer")
          .where("isAvailable", isEqualTo: true)
          .get();

      List<QueryDocumentSnapshot> nearbyEmployers = [];

      for (var doc in snapshot.docs) {
        // अपने आप को skip करो
        if (doc.id == user.uid) continue;

        var data = doc.data() as Map<String, dynamic>;
        double employerLat = (data["latitude"] ?? 0).toDouble();
        double employerLng = (data["longitude"] ?? 0).toDouble();

        // अगर location missing है तो skip
        if (employerLat == 0 || employerLng == 0) continue;

        double distance = Geolocator.distanceBetween(
          userLat,
          userLng,
          employerLat,
          employerLng,
        );

        // 🔥 MAIN FILTER: सिर्फ 10 KM के अंदर वाले
        if (distance <= 10000) {
          // दूरी data में add करो (UI में दिखाने के लिए)
          data["distance"] = distance;
          nearbyEmployers.add(doc);
        }
      }

      // नजदीक वाले पहले दिखें
      nearbyEmployers.sort((a, b) {
        double distA = (a.data() as Map<String, dynamic>)["distance"] ?? 0;
        double distB = (b.data() as Map<String, dynamic>)["distance"] ?? 0;
        return distA.compareTo(distB);
      });

      yield nearbyEmployers;
    }

    // 🔥 ₹5 Commission System
    Future<void> processHireWithCommission({
      required String user1Id,
      required String user2Id,
    }) async {
      const int commission = 5;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference user1Ref = FirebaseFirestore.instance.collection("users").doc(user1Id);
        DocumentReference adminRef = FirebaseFirestore.instance.collection("admin").doc("main");

        DocumentSnapshot user1Snap = await transaction.get(user1Ref);
        DocumentSnapshot adminSnap = await transaction.get(adminRef);

        Map<String, dynamic> user1Data = user1Snap.data() as Map<String, dynamic>? ?? {};
        Map<String, dynamic> adminData = adminSnap.data() as Map<String, dynamic>? ?? {};

        int user1Wallet = user1Data["wallet"] ?? 0;
        bool user1FreeUsed = user1Data["isFirstJobFreeUsed"] ?? false;
        int adminWallet = adminData["wallet"] ?? 0;

        int totalCommission = 0;

        // ================= USER 1 =================
        if (!user1FreeUsed) {
          transaction.update(user1Ref, {
            "isFirstJobFreeUsed": true,
          });

          transaction.set(
            user1Ref.collection("transactions").doc(),
            {
              "amount": 0,
              "type": "info",
              "message": "First Job Free",
              "createdAt": FieldValue.serverTimestamp(),
            },
          );
        } else {
          if (user1Wallet < commission) {
            throw Exception("₹5 Balance Required");
          }

          transaction.update(user1Ref, {
            "wallet": user1Wallet - commission,
          });

          transaction.set(
            user1Ref.collection("transactions").doc(),
            {
              "amount": commission,
              "type": "debit",
              "message": "Platform Fee",
              "createdAt": FieldValue.serverTimestamp(),
            },
          );

          totalCommission += commission;
        }

        // ================= ADMIN =================
        if (totalCommission > 0) {
          if (!adminSnap.exists) {
            transaction.set(adminRef, {
              "wallet": totalCommission,
              "totalEarning": totalCommission,
            });
          } else {
            transaction.update(adminRef, {
              "wallet": adminWallet + totalCommission,
              "totalEarning": FieldValue.increment(totalCommission),
            });
          }

          transaction.set(
            adminRef.collection("transactions").doc(),
            {
              "amount": totalCommission,
              "type": "credit",
              "message": "Platform Commission",
              "createdAt": FieldValue.serverTimestamp(),
            },
          );
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          title: const Text("ठेकेदार लिस्ट",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: StreamBuilder<List<QueryDocumentSnapshot>>(
          // 🔥 यहाँ नया stream use करो
          stream: _getNearbyEmployersStream(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("10 KM के अंदर कोई ठेकेदार उपलब्ध नहीं है"),
              );
            }

            var docs = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                var data = doc.data() as Map<String, dynamic>;
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
                  playAudio: playAudio,
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

    late Razorpay _razorpay;

    int selectedAmount = 50;
    TextEditingController amountController = TextEditingController();

    @override
    void initState() {
      super.initState();

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

    // 🔥 Razorpay open
    void openCheckout(int amount) {
      var options = {
        'key': 'rzp_live_SYYQBs3VQNeGTX',
        'amount': amount * 100,
        'name': 'KaamDwaar',
        'description': 'Wallet Recharge',
      };

      _razorpay.open(options);
    }

    // ✅ SUCCESS
    void _handlePaymentSuccess(PaymentSuccessResponse response) async {
      int amount = amountController.text.isNotEmpty
          ? int.parse(amountController.text)
          : selectedAmount;

      await addMoneyToWallet(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("₹$amount added successfully")),
      );
    }

    // ❌ ERROR
    void _handlePaymentError(PaymentFailureResponse response) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Failed")),
      );
    }

    // 💰 FIRESTORE UPDATE
    Future<void> addMoneyToWallet(int amount) async {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "wallet": FieldValue.increment(amount),
      });
    }

    // 🔥 AMOUNT BUTTON
    Widget _amountButton(int amount) {
      bool isSelected = selectedAmount == amount;

      return GestureDetector(
        onTap: () {
          setState(() {
            selectedAmount = amount;
            amountController.clear();
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "₹$amount",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {

      String uid = FirebaseAuth.instance.currentUser!.uid;

      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),

        appBar: AppBar(
          title: Text("My Wallet"),
          backgroundColor: Colors.green,
        ),

        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var userData =
            snapshot.data!.data() as Map<String, dynamic>;

            int wallet = userData["wallet"] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 💰 BALANCE
                  Container(
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
                        Text("Total Balance",
                            style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 10),
                        Text(
                          "₹$wallet",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text("Recharge",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    children: [
                      _amountButton(30),
                      _amountButton(50),
                      _amountButton(100),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 💵 CUSTOM INPUT
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter custom amount",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔋 BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        int finalAmount = amountController.text.isNotEmpty
                            ? int.parse(amountController.text)
                            : selectedAmount;

                        openCheckout(finalAmount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text("Recharge"),
                    ),
                  ),

                  SizedBox(height: 20),

                  // 🔥 TITLE
                  Text(
                    "Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 10),

                  // 🔥 TRANSACTION LIST
                  SizedBox(
                    height: 300,
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection("transactions")
                          .orderBy("createdAt", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {

                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return Center(child: Text("No transactions yet"));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {

                            var data = docs[index].data() as Map<String, dynamic>;

                            bool isDebit = data["type"] == "debit";

                            return ListTile(
                              leading: Icon(
                                isDebit ? Icons.arrow_downward: Icons.arrow_upward,
                                color: isDebit ? Colors.red : Colors.green,
                              ),
                              title: Text(
                                "₹${data["amount"]}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDebit ? Colors.red : Colors.green,
                                ),
                              ),
                              subtitle: Text(
                                data["reason"] ?? data["message"] ?? "No info",
                              ),
                              trailing: Text(data["type"]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
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
          "createdAt": FieldValue.serverTimestamp(),
        },
      );

      // 🔥 Worker Transaction
      transaction.set(
        workerRef.collection("transactions").doc(),
        {
          "amount": amount,
          "type": "credit",
          "message": "Job Payment Received",
          "createdAt": FieldValue.serverTimestamp(),
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
                  title: Text(
                    t(context, "New Hire Request", "नई रिक्वेस्ट"),
                  ),
                  subtitle: Text(
                    t(context, "Tap to Accept", "स्वीकार करने के लिए टैप करें"),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {

                      await FirebaseFirestore.instance
                          .collection("hireRequests")
                          .doc(request.id)
                          .update({
                        "status": "accepted"
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t(context, "Accepted", "स्वीकार किया गया"),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      t(context, "Accept", "स्वीकार करें"),
                    ),
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
        appBar: AppBar(
          title: Text(
            t(context, "My Ratings", "मेरी रेटिंग्स"),
          ),
        ),
        body: Center(
          child: Text(
            t(
              context,
              "Ratings Coming Soon",
              "रेटिंग्स जल्द आ रही हैं",
            ),
          ),
        ),
      );
    }
  }

  class MyJobsScreen extends StatelessWidget {
    const MyJobsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            t(context, "My Jobs", "मेरे काम"),
          ),
        ),
        body: Center(
          child: Text(
            t(
              context,
              "Jobs Coming Soon",
              "काम जल्द आ रहे हैं",
            ),
          ),
        ),
      );
    }
  }

  class EditProfileScreen extends StatelessWidget {
    const EditProfileScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            t(context, "Edit Profile", "प्रोफाइल संपादित करें"),
          ),
        ),
        body: Center(
          child: Text(
            t(
              context,
              "Edit Profile Coming Soon",
              "प्रोफाइल संपादन जल्द उपलब्ध होगा",
            ),
          ),
        ),
      );
    }
  }

  class HireHistoryScreen extends StatefulWidget {
    const HireHistoryScreen({super.key});

    @override
    State<HireHistoryScreen> createState() => _HireHistoryScreenState();
  }

  class _HireHistoryScreenState extends State<HireHistoryScreen> {

    @override
    Widget build(BuildContext context) {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            t(context, "Hire History", "भर्ती इतिहास"),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                  tabs: [
                    Tab(text: t(context, "Sent", "भेजी गई")),
                    Tab(text: t(context, "Received", "प्राप्त हुई")),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Sent Requests Tab
                    _buildHistoryList(
                      stream: FirebaseFirestore.instance
                          .collection("hireRequests")
                          .where("senderId", isEqualTo: uid)
                          .where("status", whereIn: ["accepted", "rejected", "expired"])
                          .orderBy("createdAt", descending: true)
                          .snapshots(),
                      isSender: true,
                    ),
                    // Received Requests Tab
                    _buildHistoryList(
                      stream: FirebaseFirestore.instance
                          .collection("hireRequests")
                          .where("receiverId", isEqualTo: uid)
                          .where("status", whereIn: ["accepted", "rejected", "expired"])
                          .orderBy("createdAt", descending: true)
                          .snapshots(),
                      isSender: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildHistoryList({
      required Stream<QuerySnapshot> stream,
      required bool isSender,
    }) {
      return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t(context, "No history found", "कोई इतिहास नहीं मिला"),
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(context, data, isSender);
            },
          );
        },
      );
    }

    Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data, bool isSender) {
      String otherUserId = isSender ? data["receiverId"] : data["senderId"];
      String status = data["status"] ?? "pending";
      Timestamp createdAt = data["createdAt"];

      DateTime dateTime = createdAt.toDate();

      // Status ke hisaab se color aur icon
      Color statusColor;
      IconData statusIcon;
      String statusText;

      switch (status) {
        case "accepted":
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = t(context, "Accepted", "स्वीकृत");
          break;
        case "rejected":
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
          statusText = t(context, "Rejected", "अस्वीकृत");
          break;
        case "expired":
          statusColor = Colors.orange;
          statusIcon = Icons.timer_off;
          statusText = t(context, "Expired", "समाप्त");
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.hourglass_empty;
          statusText = status;
      }

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(otherUserId)
            .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text("Loading..."),
              ),
            );
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          String name = userData["name"] ?? "Unknown User";
          String work = userData["workType"] ?? "";
          String dp = userData["dp"] ?? "";
          String area = userData["area"] ?? "";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: dp.isNotEmpty ? NetworkImage(dp) : null,
                child: dp.isEmpty ? const Icon(Icons.person, size: 28) : null,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (work.isNotEmpty)
                    Text(work, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        area.isNotEmpty ? area : "Location not set",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${_formatDate(dateTime)} • ${_formatTime(dateTime)}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              onTap: () {
                // अगर accepted है तो worker details देख सकता है
                if (status == "accepted") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerDetailScreen(
                        name: name,
                        work: work,
                        area: area,
                        phone: userData["phone"] ?? "",
                        lat: (userData["latitude"] ?? 0).toDouble(),
                        lng: (userData["longitude"] ?? 0).toDouble(),
                        rating: (userData["rating"] ?? 0).toDouble(),
                        introAudio: userData["audioUrl"] ?? "",
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      );
    }

    String _formatDate(DateTime date) {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }

    String _formatTime(DateTime date) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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

      // 🔥 FREE MODE CONTROL (बस यही add किया है)


      const int commission = 5;

      await FirebaseFirestore.instance.runTransaction((transaction) async {

        const int commission = 5;

        final user1Ref =
        FirebaseFirestore.instance.collection("users").doc(user1Id);

        final user2Ref =
        FirebaseFirestore.instance.collection("users").doc(user2Id);

        final adminRef =
        FirebaseFirestore.instance.collection("admin").doc("main");

        final user1Snap = await transaction.get(user1Ref);
        final user2Snap = await transaction.get(user2Ref);
        final adminSnap = await transaction.get(adminRef);

        final user1Data =
            user1Snap.data() as Map<String, dynamic>? ?? {};

        final user2Data =
            user2Snap.data() as Map<String, dynamic>? ?? {};

        final adminData =
            adminSnap.data() as Map<String, dynamic>? ?? {};

        int user1Wallet = user1Data["wallet"] ?? 0;
        int user2Wallet = user2Data["wallet"] ?? 0;
        int adminWallet = adminData["wallet"] ?? 0;

        int totalCommission = 0;

        // 💰 CHECK BOTH USERS
        if (user1Wallet < commission) {
          throw Exception("User1 ₹5 Balance Required");
        }

        if (user2Wallet < commission) {
          throw Exception("User2 ₹5 Balance Required");
        }

        // 🔥 CUT BOTH
        transaction.update(user1Ref, {
          "wallet": user1Wallet - commission,
        });

        transaction.update(user2Ref, {
          "wallet": user2Wallet - commission,
        });

        totalCommission = commission * 2;

        // 🔥 ADMIN ADD
        transaction.set(adminRef, {
          "wallet": adminWallet + totalCommission,
          "totalEarning": FieldValue.increment(totalCommission),
        }, SetOptions(merge: true));

        // 🔥 SAVE TRANSACTIONS (VERY IMPORTANT)
        final txRef = FirebaseFirestore.instance.collection("transactions");

        transaction.set(txRef.doc(), {
          "userId": user1Id,
          "amount": commission,
          "type": "debit",
          "reason": "Hire Commission",
          "createdAt": FieldValue.serverTimestamp(),
        });

        transaction.set(txRef.doc(), {
          "userId": user2Id,
          "amount": commission,
          "type": "debit",
          "reason": "Hire Commission",
          "createdAt": FieldValue.serverTimestamp(),
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

                    Text(
                      t(context, "Direct Connection Unlock", "सीधा संपर्क अनलॉक"),
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

                    Text(
                      t(
                        context,
                        "Valid for next 10 minutes",
                        "अगले 10 मिनट तक मान्य",
                      ),
                      style: const TextStyle(
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

                        // ❌ PAYMENT REMOVE (FREE MODE)

                        await FirebaseFirestore.instance
                            .collection("hireRequests")
                            .doc(data["id"])
                            .update({
                          "receiverPaid": true,
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
          title: Text(
            t(context, "My Requests", "मेरी रिक्वेस्ट्स"),
          ),
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
              return Center(
                child: Text(
                  t(context, "No requests yet", "अभी तक कोई रिक्वेस्ट नहीं"),
                ),
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
                        ? t(
                      context,
                      "Worker accepted your request",
                      "मज़दूर ने आपकी रिक्वेस्ट स्वीकार कर ली",
                    )
                        : t(
                      context,
                      "Waiting for worker response",
                      "मज़दूर के जवाब का इंतजार",
                    ),
                  ),

                  subtitle: status == "accepted"
                      ? Text(
                    t(
                      context,
                      "Tap to unlock connection",
                      "कनेक्शन खोलने के लिए टैप करें",
                    ),
                  )
                      : Text(
                    t(
                      context,
                      "Status: $status",
                      "स्थिति: $status",
                    ),
                  ),

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

              Text(
                t(
                  context,
                  "Worker accepted your request",
                  "मज़दूर ने आपकी रिक्वेस्ट स्वीकार कर ली",
                ),
                style: const TextStyle(
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