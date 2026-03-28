import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HireListener {

  static void listenSenderUpdates(BuildContext context) {

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

          if (data["status"] == "accepted") {

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Worker accepted your request"),
              ),
            );
          }

          if (data["receiverPaid"] == true) {

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Connection unlocked"),
              ),
            );
          }
        }
      }
    });
  }
}