import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsUpdatesScreen extends StatelessWidget {
  const RequestsUpdatesScreen({super.key});

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

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),

                child: ListTile(

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

                  subtitle: Text("Status: $status"),

                  trailing: status == "accepted"
                      ? const Icon(Icons.arrow_forward_ios)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}