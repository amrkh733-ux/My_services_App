import 'package:flutter/material.dart';

class ReviewsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const ReviewsScreen({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تقييمات المزود")),
      body: reviews.isEmpty
          ? const Center(child: Text("لا توجد تقييمات"))
          : ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                var review = reviews[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(review["customerName"] ?? "عميل"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review["review"] ?? ""),
                        Row(
                          children: List.generate(
                            (review["rating"] ?? 0).toInt(),
                            (i) => const Icon(Icons.star,
                                color: Colors.orange, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
