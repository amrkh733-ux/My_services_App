import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerReviewsPage extends StatelessWidget {
  final String customerId;

  const CustomerReviewsPage({super.key, required this.customerId});

  static const Color navy = Color(0xFF0A2A43);

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: const Text(
          "التقييمات",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: currentUser == null
          ? const Center(
              child: Text("يجب تسجيل الدخول لعرض التقييمات"),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: customerId.isEmpty
                  ? FirebaseFirestore.instance
                      .collection("reviews")
                      .orderBy("time", descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection("reviews")
                      .where("customerId", isEqualTo: customerId)
                      .orderBy("time", descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد تقييمات حتى الآن"));
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        docs[index].data() as Map<String, dynamic>;

                    String providerName = data["providerName"] ?? "مقدم الخدمة";
                    String reviewText = data["review"] ?? "";
                    int rating = data["rating"] ?? 0;

                    // 🔴 الحقل الجديد
                    bool isAvailable = data["isAvailable"] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              providerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),

                            // 🔴 هنا يظهر "محجوزة"
                            if (!isAvailable)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  "محجوزة",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 5),

                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              reviewText,
                              style: const TextStyle(fontSize: 14),
                            ),
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
