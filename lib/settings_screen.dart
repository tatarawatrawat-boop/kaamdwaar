import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔥 t() function
String t(BuildContext context, String en, String hi) {
  return Localizations.localeOf(context).languageCode == 'hi' ? hi : en;
}

class SettingsScreen extends StatefulWidget {
  final Function(String) onLanguageChange;

  const SettingsScreen({super.key, required this.onLanguageChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: Text(t(context, "Settings", "सेटिंग्स")),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========== PREFERENCES ==========
          _buildSectionHeader(t(context, "Preferences", "प्राथमिकताएँ")),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.language,
            title: t(context, "Language", "भाषा"),
            subtitle: _getCurrentLanguageName(),
            onTap: () => _showLanguageDialog(context),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          _buildSwitchTile(
            icon: Icons.notifications,
            title: t(context, "Notifications", "सूचनाएँ"),
            subtitle: t(context, "Receive job alerts and updates", "नौकरी के अलर्ट और अपडेट प्राप्त करें"),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
              _saveNotificationPreference(value);
            },
          ),

          const SizedBox(height: 20),

          // ========== SUPPORT ==========
          _buildSectionHeader(t(context, "Support", "सहायता")),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: t(context, "Privacy Policy", "गोपनीयता नीति"),
            onTap: () => _showPrivacyPolicy(context),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          _buildSettingsTile(
            icon: Icons.description,
            title: t(context, "Terms & Conditions", "नियम और शर्तें"),
            onTap: () => _showTermsConditions(context),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          // 🔥 SUPPORT OPTIONS
          _buildSettingsTile(
            icon: Icons.phone,
            title: t(context, "Call Support", "कॉल सपोर्ट"),
            subtitle: "+91 6261360602",
            onTap: () => _makePhoneCall("+916261360602"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          _buildSettingsTile(
            icon: Icons.email,
            title: t(context, "Email Support", "ईमेल सपोर्ट"),
            subtitle: "rozgaarpeetha.support@gmail.com",  // 🔥 यहाँ भी बदलें
            onTap: () => _sendEmail("rozgaarpeetha.support@gmail.com"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          _buildSettingsTile(
            icon: Icons.chat,
            title: t(context, "WhatsApp Support", "व्हाट्सएप सपोर्ट"),
            subtitle: t(context, "Chat with us", "हमसे चैट करें"),
            onTap: () => _openWhatsApp("+916261360602"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          _buildSettingsTile(
            icon: Icons.star,
            title: t(context, "Rate Us", "हमें रेटिंग दें"),
            subtitle: t(context, "Rate on Play Store", "प्ले स्टोर पर रेटिंग दें"),
            onTap: () => _rateUs(),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          _buildSettingsTile(
            icon: Icons.share,
            title: t(context, "Share App", "ऐप शेयर करें"),
            subtitle: t(context, "Share with friends", "दोस्तों के साथ शेयर करें"),
            onTap: () => _shareApp(),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const SizedBox(height: 20),

          // ========== ABOUT ==========
          _buildSectionHeader(t(context, "About", "के बारे में")),
          const SizedBox(height: 8),

          _buildSettingsTile(
            icon: Icons.info,
            title: t(context, "App Version", "ऐप वर्शन"),
            subtitle: "1.0.0",
            onTap: null,
            trailing: null,
          ),

          _buildSettingsTile(
            icon: Icons.app_registration,
            title: t(context, "About Rozgaar Peetha", "रोजगार पीठा के बारे में"),
            onTap: () => _showAboutDialog(context),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  String _getCurrentLanguageName() {
    String langCode = Localizations.localeOf(context).languageCode;
    return langCode == 'hi' ? "हिंदी (Hindi)" : "English";
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t(context, "Select Language", "भाषा चुनें")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("English"),
                trailing: _getCurrentLanguageName() == "English"
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(dialogContext);
                  widget.onLanguageChange('en');
                },
              ),
              ListTile(
                title: const Text("हिंदी (Hindi)"),
                trailing: _getCurrentLanguageName() == "हिंदी (Hindi)"
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(dialogContext);
                  widget.onLanguageChange('hi');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications_enabled", value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? t(context, "Notifications enabled", "सूचनाएँ चालू कर दी गईं")
              : t(context, "Notifications disabled", "सूचनाएँ बंद कर दी गईं"),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) async {
    final Uri url = Uri.parse("https://sites.google.com/view/rozgaarpeethaprivacypolicy/home");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            context,
            "Unable to open privacy policy",
            "गोपनीयता नीति नहीं खोल सके",
          )),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTermsConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, "Terms & Conditions", "नियम और शर्तें")),
        content: const SingleChildScrollView(
          child: Text(
            "By using Rozgaar Peetha, you agree to:\n\n"
                "1. Provide accurate information\n"
                "2. Pay applicable fees for premium services\n"
                "3. Not misuse the platform\n"
                "4. Follow community guidelines\n\n"
                "Violation may result in account suspension.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(context, "Close", "बंद करें")),
          ),
        ],
      ),
    );
  }

  // 📞 Phone call
  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw "Could not launch";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, "Unable to make call", "कॉल नहीं कर सकते")),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 📧 Email
  // 📧 Email
  void _sendEmail(String email) async {
    // 🔥 आपका सही email address
    final Uri url = Uri.parse("mailto:rozgaarpeetha.support@gmail.com?subject=Support Request&body=Hello, I need help with...");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw "Could not launch";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, "Unable to open email", "ईमेल नहीं खोल सकते")),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 💬 WhatsApp
  void _openWhatsApp(String phoneNumber) async {
    String number = phoneNumber.replaceAll("+", "");
    final Uri url = Uri.parse("https://wa.me/$number");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, "Unable to open WhatsApp", "व्हाट्सएप नहीं खोल सकते")),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _rateUs() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t(context, "Rate us on Play Store", "प्ले स्टोर पर रेटिंग दें")),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareApp() async {
    final String packageName = "com.kaamdwaar.app";
    final String appUrl = "https://play.google.com/store/apps/details?id=$packageName";

    final String shareMessage = t(
      context,
      "Check out Rozgaar Peetha app! Find workers and contractors easily.\nDownload now: $appUrl",
      "रोजगार पीठा ऐप देखें! आसानी से मजदूर और ठेकेदार ढूंढें।\nअभी डाउनलोड करें: $appUrl",
    );

    try {
      await Share.share(shareMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, "Could not share app", "ऐप शेयर नहीं कर सके")),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, "About Rozgaar Peetha", "रोजगार पीठा के बारे में")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Rozgaar Peetha",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Version 1.0.0",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              t(context, "Connecting workers and employers in your area.", "आपके क्षेत्र में मजदूरों और ठेकेदारों को जोड़ना।"),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "© 2024 Rozgaar Peetha",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(context, "Close", "बंद करें")),
          ),
        ],
      ),
    );
  }
}