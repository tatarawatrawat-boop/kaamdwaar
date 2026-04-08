import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  int totalUsers = 0;
  int totalJobs = 0;
  int totalEarning = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    try {

      // 👤 Total Users
      var usersSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .get();

      // 📦 Total Jobs
      var jobsSnapshot = await FirebaseFirestore.instance
          .collection("hireRequests")
          .get();

      // 💰 Total Earning
      var adminDoc = await FirebaseFirestore.instance
          .collection("admin")
          .doc("main")
          .get();

      setState(() {
        totalUsers = usersSnapshot.docs.length;
        totalJobs = jobsSnapshot.docs.length;
        totalEarning = adminDoc["totalEarning"] ?? 0;
        isLoading = false;
      });

    } catch (e) {
      print("Admin load error: $e");
    }
  }

  Widget buildCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 35, color: Colors.green),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            buildCard(
              "Total Users",
              totalUsers.toString(),
              Icons.people,
            ),

            buildCard(
              "Total Jobs",
              totalJobs.toString(),
              Icons.work,
            ),

            buildCard(
              "Total Earnings",
              "₹$totalEarning",
              Icons.account_balance_wallet,
            ),

          ],
        ),
      ),
    );
  }
}