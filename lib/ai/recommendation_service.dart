import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔹 Model
class ProviderModel {
  final String id;
  final String name;
  final String category;
  final String profession;
  double stars;
  int reviewsCount;
  int ordersCount;
  int clientsCount;
  bool isTop;

  ProviderModel({
    required this.id,
    required this.name,
    required this.category,
    required this.profession,
    this.stars = 0.0,
    this.reviewsCount = 0,
    this.ordersCount = 0,
    this.clientsCount = 0,
    this.isTop = false,
  });
}

// 🔹 Service
class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ خفيف (بدون نجوم)
  Future<List<ProviderModel>> getAllProvidersSimple() async {
    var snapshot = await _db.collection("users").get();

    return snapshot.docs.map((doc) {
      var data = doc.data();

      return ProviderModel(
        id: doc.id,
        name: data['name'] ?? 'بدون اسم',
        category: data['category'] ?? 'عام',
        profession: data['profession'] ?? '',
      );
    }).toList();
  }

  // ❗ ثقيل (يستخدم فقط عند الحاجة)
  Future<List<ProviderModel>> getAllProvidersFull() async {
    var snapshot = await _db.collection("users").get();
    List<ProviderModel> providers = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();

      var provider = ProviderModel(
        id: doc.id,
        name: data['name'] ?? 'بدون اسم',
        category: data['category'] ?? 'عام',
        profession: data['profession'] ?? '',
      );

      // ⭐ التقييم
      var reviews = await _db
          .collection("reviews")
          .where("providerId", isEqualTo: provider.id)
          .get();

      provider.reviewsCount = reviews.docs.length;

      double total = 0;
      for (var r in reviews.docs) {
        total += (r['rating'] ?? 0);
      }

      provider.stars =
          provider.reviewsCount > 0 ? total / provider.reviewsCount : 0;

      // 📦 الطلبات
      var orders = await _db
          .collection("orders")
          .where("providerId", isEqualTo: provider.id)
          .get();

      provider.ordersCount = orders.docs.length;

      // 👥 العملاء
      Set clients = {};
      for (var o in orders.docs) {
        clients.add(o['clientId']);
      }

      provider.clientsCount = clients.length;

      providers.add(provider);
    }

    return providers;
  }

  // 🔥 الأفضل
  Future<List<ProviderModel>> getTopProviders() async {
    var providers = await getAllProvidersFull();

    providers = providers.where((p) => p.reviewsCount > 0).toList();

    providers.sort((a, b) {
      double scoreA = (a.stars * 2) + a.reviewsCount + (a.ordersCount * 0.5);
      double scoreB = (b.stars * 2) + b.reviewsCount + (b.ordersCount * 0.5);
      return scoreB.compareTo(scoreA);
    });

    var top = providers.take(10).toList();

    for (var p in top) {
      p.isTop = true;
    }

    return top;
  }

  // 🔥 الأكثر طلباً
  Future<List<ProviderModel>> getMostRequestedProviders() async {
    var providers = await getAllProvidersFull();

    providers.sort((a, b) => b.ordersCount.compareTo(a.ordersCount));

    return providers;
  }
}

// 🔹 UI
class ProvidersListPage extends StatelessWidget {
  final RecommendationService recommendationService = RecommendationService();

  ProvidersListPage({super.key});

  // ⭐ كرت فيه تفاصيل
  Widget buildProviderCard(ProviderModel p) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: SizedBox(
        width: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(p.profession),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < p.stars.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
                Text("${p.reviewsCount}"),
              ],
            ),
            Text("📦 ${p.ordersCount} طلب"),
          ],
        ),
      ),
    );
  }

  // ✅ كرت بسيط بدون نجوم
  Widget buildSimpleCard(ProviderModel p) {
    return Container(
      width: 140,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 40),
          const SizedBox(height: 5),
          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            p.profession,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 🔥 قسم موحد
  Widget buildSection({
    required String title,
    required Future<List<ProviderModel>> future,
    bool simple = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<ProviderModel>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("لا يوجد بيانات"));
              }

              var providers = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: providers.length,
                itemBuilder: (context, index) {
                  return simple
                      ? buildSimpleCard(providers[index])
                      : buildProviderCard(providers[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مزودي الخدمة")),
      body: ListView(
        children: [
          // 🔥 الأفضل
          buildSection(
            title: "أفضل مزودي الخدمة",
            future: recommendationService.getTopProviders(),
          ),

          // 🔥 الأكثر طلباً
          buildSection(
            title: "الأكثر طلباً",
            future: recommendationService.getMostRequestedProviders(),
          ),

          // 🔥 الجميع (بدون نجوم ✔️)
          buildSection(
            title: "جميع مزودي الخدمة",
            future: recommendationService.getAllProvidersSimple(),
            simple: true,
          ),
        ],
      ),
    );
  }
}
