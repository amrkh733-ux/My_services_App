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

  // ✅ خفيف (يجلب من لديهم مهنة فقط لضمان عدم ظهور الشاشة فارغة)
  Future<List<ProviderModel>> getAllProvidersSimple() async {
    try {
      var snapshot = await _db.collection("users").get();

      // 🔥 التصفية برمجياً: نأخذ فقط المستخدمين الذين لديهم حقل "مهنة"
      var providersDocs = snapshot.docs.where((doc) {
        var data = doc.data();
        String prof = data['profession']?.toString().trim() ?? '';
        return prof.isNotEmpty;
      }).toList();

      return providersDocs.map((doc) {
        var data = doc.data();
        return ProviderModel(
          id: doc.id,
          name: data['name'] ?? 'بدون اسم',
          category: data['category'] ?? 'عام',
          profession: data['profession'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint("Error in getAllProvidersSimple: $e");
      return [];
    }
  }

  // ⚡ ثقيل ومحسن (يجلب التقييمات والطلبات بشكل صحيح)
  Future<List<ProviderModel>> getAllProvidersFull() async {
    try {
      var snapshot = await _db.collection("users").get();

      // 🔥 التصفية برمجياً هنا أيضاً
      var providersDocs = snapshot.docs.where((doc) {
        var data = doc.data();
        String prof = data['profession']?.toString().trim() ?? '';
        return prof.isNotEmpty;
      }).toList();

      List<ProviderModel> providers = [];

      for (var doc in providersDocs) {
        var data = doc.data();

        var provider = ProviderModel(
          id: doc.id,
          name: data['name'] ?? 'بدون اسم',
          category: data['category'] ?? 'عام',
          profession: data['profession'] ?? '',
        );

        // ⭐ جلب التقييمات وحساب النجوم
        var reviews = await _db
            .collection("reviews")
            .where("providerId", isEqualTo: provider.id)
            .get();

        provider.reviewsCount = reviews.docs.length;

        double total = 0;
        for (var r in reviews.docs) {
          total += (r['rating'] ?? 0.0).toDouble();
        }

        provider.stars =
            provider.reviewsCount > 0 ? total / provider.reviewsCount : 0.0;

        // 📦 جلب الطلبات
        var orders = await _db
            .collection("orders")
            .where("providerId", isEqualTo: provider.id)
            .get();

        provider.ordersCount = orders.docs.length;

        // 👥 حساب العملاء الفريدين
        Set clients = {};
        for (var o in orders.docs) {
          clients.add(o['clientId']);
        }
        provider.clientsCount = clients.length;

        providers.add(provider);
      }

      return providers;
    } catch (e) {
      debugPrint("Error in getAllProvidersFull: $e");
      return [];
    }
  }

  // 🔥 الأفضل (الترتيب الذكي الخالي من الأخطاء)
  Future<List<ProviderModel>> getTopProviders() async {
    var providers = await getAllProvidersFull();

    // استبعاد من ليس لديهم تقييمات
    providers = providers.where((p) => p.reviewsCount > 0).toList();

    // الترتيب الرياضي العادل لفرز الأفضل
    providers.sort((a, b) {
      double scoreA =
          (a.stars * 3) + (a.reviewsCount * 1.5) + (a.ordersCount * 0.5);
      double scoreB =
          (b.stars * 3) + (b.reviewsCount * 1.5) + (b.ordersCount * 0.5);
      return scoreB.compareTo(scoreA); // ترتيب تنازلي (الأعلى أولاً)
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
    // ترتيب تنازلي حسب عدد الطلبات
    providers.sort((a, b) => b.ordersCount.compareTo(a.ordersCount));
    return providers.take(10).toList();
  }
}

// 🔹 UI
class ProvidersListPage extends StatelessWidget {
  final RecommendationService recommendationService = RecommendationService();

  ProvidersListPage({super.key});

  // ⭐ كرت فيه تفاصيل للـ "أفضل" والـ "أكثر طلباً"
  Widget buildProviderCard(ProviderModel p) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 40, color: Color(0xFF0A2A43)),
            const SizedBox(height: 5),
            Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              p.profession.isNotEmpty ? p.profession : "مزود خدمة",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < p.stars.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "(${p.reviewsCount})",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "📦 ${p.ordersCount} طلب",
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ كرت بسيط لجميع مزودي الخدمة
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
          const Icon(Icons.person, size: 40, color: Colors.grey),
          const SizedBox(height: 5),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            p.profession.isNotEmpty ? p.profession : "مقدم خدمة",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🔥 قسم موحد لعرض المجموعات المختلفة
  Widget buildSection({
    required String title,
    required Future<List<ProviderModel>> future,
    bool simple = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<ProviderModel>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "لا يوجد بيانات حالياً",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
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
      appBar: AppBar(
        title: const Text("مزودي الخدمة"),
        backgroundColor: const Color(0xFF0A2A43),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // 🔥 أفضل مزودي الخدمة (مرتبين تنازلياً بأقوى نظام تقييم ذكي)
          buildSection(
            title: "أفضل مزودي الخدمة (المقترحة لك)",
            future: recommendationService.getTopProviders(),
          ),

          // 🔥 الأكثر طلباً
          buildSection(
            title: "الخدمات الأكثر طلباً",
            future: recommendationService.getMostRequestedProviders(),
          ),

          // 🔥 الجميع (بدون حسابات ثقيلة)
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
