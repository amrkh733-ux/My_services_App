// lib/interfaces/admin_ratings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home.dart';

class AdminRatingsPage extends StatelessWidget {
  const AdminRatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("التقييمات"),
        backgroundColor: AdminHome.navy,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ratings")
            .orderBy("time", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("لا توجد تقييمات"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data["serviceName"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("المزود: ${data["providerName"] ?? ""}"),
                      Text("العميل: ${data["customerName"] ?? ""}"),
                      Text("التقييم: ${data["rating"] ?? ""}"),
                      Text("ملاحظة: ${data["comment"] ?? ""}"),
                    ],
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
