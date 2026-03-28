import 'package:flutter/material.dart';

class ModernDrawer extends StatelessWidget {
  const ModernDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [

          // 🔹 HEADER WITH GRADIENT
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 25),
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
                const CircleAvatar(
                  radius: 45,
                  backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=3"),
                ),
                const SizedBox(height: 12),
                const Text(
                  "sudeer",
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "ठेकेदार",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Wallet ₹55",
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // 🔹 ACCOUNT SECTION
                sectionTitle("Account"),
                drawerCard([
                  drawerTile(Icons.account_balance_wallet, "My Wallet"),
                  drawerTile(Icons.edit, "Edit Profile"),
                  drawerTile(Icons.location_on, "Location Update"),
                ]),

                const SizedBox(height: 20),

                // 🔹 WORK SECTION
                sectionTitle("Work"),
                drawerCard([
                  drawerTile(Icons.work, "My Jobs"),
                  drawerTile(Icons.history, "Hire History"),
                  drawerTile(Icons.bar_chart, "Earnings Report"),
                ]),

                const SizedBox(height: 20),

                // 🔹 PERFORMANCE SECTION
                sectionTitle("Performance"),
                drawerCard([
                  drawerTile(Icons.star, "My Ratings"),
                  drawerTile(Icons.workspace_premium, "Premium Badge"),
                ]),

                const SizedBox(height: 20),

                drawerTile(Icons.settings, "Settings"),
                drawerTile(Icons.logout, "Logout", isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Section Title
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey),
      ),
    );
  }

  // 🔹 Card Style Container
  Widget drawerCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: children),
    );
  }

  // 🔹 Drawer Item
  Widget drawerTile(IconData icon, String title,
      {bool isLogout = false}) {
    return ListTile(
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}