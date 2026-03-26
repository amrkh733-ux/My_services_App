import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_store_flutter/notifications/notifications.dart';

import '../login_screen.dart';
import '../messaging/customer_messaging_page.dart';
import 'edit_customer.dart';
import '../reviews/customer_reviews.dart'; // مسار الملف الصحيح
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../ai/faq_chat_page.dart';
import '../ai/recommendation_service.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  static const Color navy = Color(0xFF0A2A43);

  final PageController pageController = PageController();
  final RecommendationService recommendationService = RecommendationService();
  final List<Map<String, dynamic>> categories = const [
    {"title": "البرمجة وتطوير المواقع", "icon": Icons.computer},
    {"title": "التصميم الجرافيكي", "icon": Icons.design_services},
    {"title": "إدارة وسائل التواصل الاجتماعي", "icon": Icons.campaign},
    {"title": "كتابة المحتوى والتحرير", "icon": Icons.edit},
    {"title": "التصوير والمونتاج", "icon": Icons.video_camera_back},
    {"title": "التسويق الرقمي", "icon": Icons.trending_up},
    {"title": "الواجهة الإعلامية", "icon": Icons.mic},
    {"title": "خدمات الكهرباء", "icon": Icons.electrical_services},
    {"title": "أعمال السباكة", "icon": Icons.plumbing},
    {"title": "أعمال البناء والتشطيبات", "icon": Icons.home_repair_service},
    {"title": "الميكانيكا", "icon": Icons.build},
  ];

  @override
  @override
  void initState() {
    super.initState();

    // تشغيل التمرير التلقائي بعد 3 ثوانٍ لأول مرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 3), autoScroll);
      }
    });
  }

  Widget buildSection({
    required String title,
    required Future<List<ProviderModel>> future,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: FutureBuilder<List<ProviderModel>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var list = snapshot.data!;

              if (list.isEmpty) {
                return const Center(child: Text("لا توجد بيانات"));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  var item = list[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderServicesPage(
                            providerId: item.id,
                            providerName: item.name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
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
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.profession, // 🔥 هذا سيظهر مهنة المزود (مبرمج، سباك، مصمم، الخ)
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // عرض النجوم بصرياً
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    index < item.stars.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text("(${item.reviewsCount})"), // عدد المراجعات
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future markNotificationsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: user.uid) // تغيير الحقل لـ userId
        .where("isRead", isEqualTo: false) // تغيير الحقل لـ isRead
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({"isRead": true});
    }
  }

  void autoScroll() {
    if (!pageController.hasClients || !mounted) return;

    // الحصول على الصفحة الحالية وزيادتها بواحد دائماً
    int nextPage = (pageController.page?.round() ?? 0) + 1;

    pageController
        .animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    )
        .then((_) {
      // إعادة التشغيل بعد 3 ثوانٍ من اكتمال الحركة
      Future.delayed(const Duration(seconds: 3), autoScroll);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: const Text(
          "الخدمات",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(child: Image.asset("assets/logo.png")),
          ),
        ),
        actions: [
          // زر الإشعارات
          // استخدام الويدجت الموحدة التي برمجتها أنت

          // داخل actions في AppBar
          // هذا السطر سيقوم بكل العمل: جلب العدد، عرض الجرس، وفتح صفحة الإشعارات
          notificationIcon(context, "client"),

          // قائمة الحساب
          PopupMenuButton<int>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) async {
              User? user = FirebaseAuth.instance.currentUser;

              if (value == 1 && user != null) {
                DocumentSnapshot doc = await FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .get();

                Map<String, dynamic>? data =
                    doc.data() as Map<String, dynamic>?;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      name: data?["name"] ?? "",
                      role: data?["role"] ?? "",
                      email: data?["email"] ?? "",
                      phone: data?["phone"] ?? "",
                      province: data?["province"] ?? "",
                      district: data?["district"] ?? "",
                      profession: data?["profession"] ?? "",
                      age: data?["age"] ?? "",
                      cvFile: data?["cvFile"] ?? "",
                    ),
                  ),
                );
              }

              if (value == 2 && user != null) {
                FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .get()
                    .then((doc) {
                  var data = doc.data();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerMessagingPage(
                        userId: user.uid,
                        name: data?["name"] ?? "عميل",
                      ),
                    ),
                  );
                });
              }

              if (value == 3 && user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerReviewsPage(
                      customerId: '',
                    ),
                  ),
                );
              }

              if (value == 4) {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
              if (value == 5) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FAQChatPage(userType: UserType.customer),
                  ),
                );
              }
              if (value == 6 && user != null) {
                // تأكيد الحذف
                bool? confirm = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("حذف الحساب"),
                      content: const Text(
                        "هل أنت متأكد من حذف الحساب نهائياً؟",
                      ),
                      actions: [
                        TextButton(
                          child: const Text("إلغاء"),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        TextButton(
                          child: const Text(
                            "حذف",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    );
                  },
                );

                if (confirm != true) return;

                try {
                  // حذف بيانات المستخدم من قاعدة البيانات
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .delete();

                  // حذف الحساب من FirebaseAuth
                  await user.delete();

                  // العودة لصفحة تسجيل الدخول
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حذف الحساب نهائياً")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text("صفحتي")),
              PopupMenuItem(value: 2, child: Text("مراسلة الأدمن")),
              PopupMenuItem(value: 3, child: Text("التقييمات")),
              PopupMenuItem(
                  value: 5,
                  child: Text("الأسئلة الشائعة (AI)")), // تم وضعها هنا
              PopupMenuItem(value: 4, child: Text("تسجيل الخروج")),
              PopupMenuItem(
                value: 6,
                child: Text(
                  "حذف الحساب",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("ads")
                  .where("status", isEqualTo: "approved")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const SizedBox();
                }

                return PageView.builder(
                  controller: pageController,
                  // جعل العدد كبير جداً لضمان عدم توقف التمرير
                  itemCount: 10000,
                  itemBuilder: (context, index) {
                    // هذه المعادلة تضمن العودة للإعلان الأول بعد انتهاء القائمة
                    var realIndex = index % docs.length;
                    var data = docs[realIndex].data() as Map<String, dynamic>;

                    List<String> images =
                        List<String>.from(data["images"] ?? []);

                    if (images.isEmpty) return const SizedBox();

                    return Container(
                      // إضافة مارجن بسيط لتحسين المظهر أثناء التمرير
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              images[0],
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data["providerName"] ?? "",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "خبرة ${data["experience"]}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    data["description"] ?? "",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // 🔥 الأفضل
                buildSection(
                  title: "أفضل مزودي الخدمة (المقترحة لك)",
                  future: recommendationService.getTopProviders(),
                ),

// 🔥 الأكثر طلباً
                buildSection(
                  title: "الخدمات الأكثر طلباً",
                  future: recommendationService.getMostRequestedProviders(),
                ),

// 🔥 الجميع
                buildSection(
                  title: "جميع مزودي الخدمة",
                  future: recommendationService.getAllProvidersSimple(),
                ),

                const SizedBox(height: 20),
                // 🔻 نفس الكود القديم (التصنيفات)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServicesPage(
                              category: categories[index]["title"] ?? "",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(categories[index]["icon"]),
                            Text(categories[index]["title"]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServicesPage extends StatelessWidget {
  final String category;
  // حذفنا الـ RecommendationService من هنا لأننا سنعرض الخدمات مباشرة

  ServicesPage({super.key, required this.category});

  static const Color navy = Color(0xFF0A2A43);

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // العودة لاستخدام StreamBuilder لضمان ظهور الخدمات فوراً
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("services")
            .where("category", isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("لا توجد خدمات متوفرة في هذا القسم حالياً"),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  docs[index].data() as Map<String, dynamic>;
              String serviceId = docs[index].id;

              // منطق تحديد حالة الحجز
              bool isBookedByOthers =
                  (data["status"] == "محجوز" || data["status"] == "مقبول") &&
                      data["customerId"] != currentUser?.uid;

              bool isBookedByMe =
                  (data["status"] == "محجوز" || data["status"] == "مقبول") &&
                      data["customerId"] == currentUser?.uid;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          data["name"] ?? "خدمة غير مسمى",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: navy,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("السعر: ${data["price"]} ${data["currency"]}"),
                            Text("مقدم الخدمة: ${data["providerName"]}"),

// --- إضافة عرض المحافظة والمديرية ---
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(data["providerId"])
                                  .get(),
                              builder: (context, userSnap) {
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  var uData = userSnap.data!.data()
                                      as Map<String, dynamic>;
                                  String province =
                                      uData["province"] ?? "غير محدد";
                                  String district =
                                      uData["district"] ?? "غير محدد";
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2, bottom: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14, color: Colors.redAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$province - $district",
                                          style: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox(
                                    height: 5); // مسافة مؤقتة لحين التحميل
                              },
                            ),
// ---------------------------------

                            Text("سنوات الخبرة: ${data["experience"]}"),
                            if (isBookedByMe)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  data["status"] == "مقبول"
                                      ? "✅ تم قبول طلبك"
                                      : "⏳ طلبك قيد الانتظار",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (isBookedByOthers)
                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text(
                                  "🚫 هذه الخدمة محجوزة حالياً",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // منطق الأزرار (طلب، إلغاء، تقييم)
                      if (!isBookedByOthers)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("orders")
                              .where("serviceId", isEqualTo: serviceId)
                              .where("clientId", isEqualTo: currentUser?.uid)
                              .where("status",
                                  whereIn: ["pending", "accepted"]).snapshots(),
                          builder: (context, orderSnap) {
                            if (orderSnap.hasData &&
                                orderSnap.data!.docs.isNotEmpty) {
                              var orderDoc = orderSnap.data!.docs.first;
                              return Wrap(
                                spacing: 10,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cancel,
                                        size: 18, color: Colors.white),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    label: const Text("إلغاء الحجز",
                                        style: TextStyle(color: Colors.white)),
                                    onPressed: () => _cancelBooking(
                                        context, serviceId, orderDoc.id),
                                  ),
                                  if (orderDoc["status"] == "accepted")
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.star,
                                          size: 18, color: Colors.white),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange),
                                      label: const Text(
                                        "تقييم",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        // استدعاء الديالوج مع تمرير providerId و providerName
                                        _showRatingDialog(
                                          context,
                                          serviceId,
                                          orderDoc,
                                          currentUser,
                                          providerName: data["providerName"] ??
                                              "غير معروف",
                                          providerId: '',
                                        );
                                      },
                                    ),
                                ],
                              );
                            }

                            if (data["status"] == "متاح") {
                              return SizedBox(
                                width: double.infinity,
                                child: _buildRequestButton(
                                    context,
                                    serviceId,
                                    currentUser,
                                    null,
                                    data["providerId"] ?? "",
                                    data["name"] ?? ""),
                              );
                            }
                            return const SizedBox.shrink();
                          },
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

  // --- الدوال المساعدة (نفس التي لديك ولكن تم استدعاؤها بشكل صحيح داخل الكلاس) ---

  Future<void> _cancelBooking(
      BuildContext context, String serviceId, String orderId) async {
    await FirebaseFirestore.instance.collection("orders").doc(orderId).delete();
    await FirebaseFirestore.instance
        .collection("services")
        .doc(serviceId)
        .update({
      "status": "متاح",
      "customerId": null,
      "bookedAt": null,
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم إلغاء الحجز")));
  }

  Widget _buildRequestButton(BuildContext context, String serviceId,
      User? currentUser, String? oldOrderId, String providerId, String sName) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: navy),
      child:
          const Text("طلب الخدمة الآن", style: TextStyle(color: Colors.white)),
      onPressed: () async {
        if (currentUser == null) return;
        try {
          var userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(currentUser.uid)
              .get();
          String clientName = userDoc.data()?["name"]?.toString() ?? "عميل";

          await FirebaseFirestore.instance.collection("orders").add({
            "serviceId": serviceId,
            "clientId": currentUser.uid,
            "clientName": clientName,
            "providerId": providerId,
            "serviceName": sName,
            "status": "pending",
            "time": FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection("services")
              .doc(serviceId)
              .update({
            "status": "محجوز",
            "customerId": currentUser.uid,
            "bookedAt": FieldValue.serverTimestamp(),
          });

          await sendNotification(
            targetUserId: providerId,
            title: "طلب خدمة جديد 🔔",
            message: "قام العميل ($clientName) بطلب خدمتك ($sName).",
          );

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم إرسال الطلب بنجاح")));
        } catch (e) {
          print(e);
        }
      },
    );
  }

  // أضف المتغيرات المطلوبة في توقيع الدالة (Signature)
  void _showRatingDialog(BuildContext context, String serviceId,
      QueryDocumentSnapshot orderDoc, User? currentUser,
      {required String providerId, required String providerName}) {
    // أضفنا هذه السطر
    showDialog(
      context: context,
      builder: (context) {
        int selectedRating = 5;
        TextEditingController reviewController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("تقييم الخدمة"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () => setState(() => selectedRating = i + 1),
                      ),
                    ),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration:
                        const InputDecoration(hintText: "اكتب رأيك هنا"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("إلغاء"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                    child: const Text("حفظ التقييم"),
                    onPressed: () async {
                      try {
                        if (currentUser == null) return;

                        // 🔥 جلب اسم المستخدم (لحل مشكلة "غير معروف")
                        var userDoc = await FirebaseFirestore.instance
                            .collection("users")
                            .doc(currentUser.uid)
                            .get();

                        String customerName =
                            userDoc.data()?["name"]?.toString() ?? "عميل";

                        // 🔥 حفظ التقييم مع الاسم والبيانات الممررة
                        await FirebaseFirestore.instance
                            .collection("reviews")
                            .add({
                          "serviceId": serviceId,
                          "providerId": providerId,
                          "providerName": providerName,
                          "customerId": currentUser.uid,
                          "customerName": customerName, // الاسم الذي جلبناه
                          "rating": selectedRating,
                          "review": reviewController.text.trim(),
                          "time": Timestamp.now(),
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم حفظ التقييم بنجاح")),
                        );
                      } catch (e) {
                        print("ERROR: $e");
                      }
                    }),
              ],
            );
          },
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String province;
  final String district;
  final String profession;
  final String age;
  final String cvFile;

  const ProfilePage({
    super.key,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.province,
    required this.district,
    required this.profession,
    required this.age,
    required this.cvFile,
  });

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A2A43);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: navy, title: const Text("صفحتي")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    role,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  infoCard(Icons.email, "البريد الإلكتروني", email),
                  infoCard(Icons.phone, "رقم الهاتف", phone),
                  infoCard(Icons.location_city, "المحافظة", province),
                  infoCard(Icons.location_on, "المديرية", district),
                  if (profession.trim().isNotEmpty)
                    infoCard(Icons.work, "المهنة", profession),
                  if (age.trim().isNotEmpty) infoCard(Icons.cake, "العمر", age),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("تعديل البيانات"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditCustomerPage(
                              name: name,
                              email: email,
                              phone: phone,
                              province: province,
                              district: district,
                              age: age,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A2A43)),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class CreateAdPage extends StatefulWidget {
  const CreateAdPage({super.key});

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController expController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  List<File> images = [];

  final ImagePicker picker = ImagePicker();

  Future pickImages() async {
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        images = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  Future sendAd() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> imageUrls = [];

    for (var image in images) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      Reference ref = FirebaseStorage.instance
          .ref()
          .child("ads_images")
          .child("$fileName.jpg");

      UploadTask uploadTask = ref.putFile(image);

      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      imageUrls.add(downloadUrl);
    }

    await FirebaseFirestore.instance.collection("ads").add({
      "providerId": user.uid,
      "providerName": nameController.text.trim(),
      "experience": expController.text,
      "description": descController.text,
      "images": imageUrls,
      "status": "pending",
      "time": Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("تم إرسال الإعلان للأدمن")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0A2A43);

    return Scaffold(
      appBar: AppBar(backgroundColor: navy, title: const Text("إنشاء إعلان")),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "الاسم"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: expController,
              decoration: const InputDecoration(labelText: "سنوات الخبرة"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "وصف الإعلان"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("إضافة صور الأعمال"),
              onPressed: pickImages,
            ),
            const SizedBox(height: 15),
            if (images.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.file(
                        images[i],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: navy),
              onPressed: sendAd,
              child: const Text("إرسال الإعلان"),
            ),
          ],
        ),
      ),
    );
  }
}
// 1. أضف هذا الاستيراد في أعلى الملف

// 2. داخل كلاس _CustomerHomeState أضف هذه الدالة لإظهار الشات
class ProviderServicesPage extends StatelessWidget {
  final String providerId;
  final String providerName;

  const ProviderServicesPage({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  static const Color navy = Color(0xFF0A2A43);

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: Text("خدمات $providerName"),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب الخدمات الخاصة بهذا المزود فقط
        stream: FirebaseFirestore.instance
            .collection("services")
            .where("providerId", isEqualTo: providerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("لا توجد خدمات متاحة لهذا المزود حالياً"));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  docs[index].data() as Map<String, dynamic>;
              String serviceId = docs[index].id;

              // منطق تحديد حالة الحجز (نفس القديم)
              bool isBookedByOthers =
                  (data["status"] == "محجوز" || data["status"] == "مقبول") &&
                      data["customerId"] != currentUser?.uid;

              bool isBookedByMe =
                  (data["status"] == "محجوز" || data["status"] == "مقبول") &&
                      data["customerId"] == currentUser?.uid;

              String currentServiceName =
                  data["name"]?.toString() ?? "خدمة غير مسمى";
              String currentPrice = data["price"]?.toString() ?? "0";
              String currentCurrency = data["currency"]?.toString() ?? "";
              String currentExperience = data["experience"]?.toString() ?? "0";

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          currentServiceName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: navy),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("السعر: $currentPrice $currentCurrency"),
                            Text("سنوات الخبرة: $currentExperience"),

                            // عرض الحالة للعميل
                            if (isBookedByMe)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  data["status"] == "مقبول"
                                      ? "✅ تم قبول طلبك"
                                      : "⏳ طلبك قيد الانتظار",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (isBookedByOthers)
                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text(
                                  "🚫 هذه الخدمة محجوزة حالياً",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // أزرار التحكم (الطلب، الإلغاء، التقييم)
                      if (!isBookedByOthers)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("orders")
                              .where("serviceId", isEqualTo: serviceId)
                              .where("clientId", isEqualTo: currentUser?.uid)
                              .where("status",
                                  whereIn: ["pending", "accepted"]).snapshots(),
                          builder: (context, orderSnap) {
                            if (orderSnap.hasData &&
                                orderSnap.data!.docs.isNotEmpty) {
                              var orderDoc = orderSnap.data!.docs.first;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cancel,
                                        size: 18, color: Colors.white),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700),
                                    label: const Text("إلغاء الحجز",
                                        style: TextStyle(color: Colors.white)),
                                    onPressed: () => _cancelBooking(
                                        context, serviceId, orderDoc.id),
                                  ),
                                  if (orderDoc["status"] == "accepted")
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.star,
                                          size: 18, color: Colors.white),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange),
                                      label: const Text("تقييم",
                                          style:
                                              TextStyle(color: Colors.white)),
                                      onPressed: () => _showRatingDialog(
                                          context,
                                          serviceId,
                                          orderDoc,
                                          currentUser),
                                    ),
                                ],
                              );
                            }

                            // إذا كانت الخدمة متاحة ولم يطلبها العميل بعد
                            if (data["status"] == "متاح") {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: navy),
                                  onPressed: () => _requestService(
                                      context,
                                      serviceId,
                                      currentUser,
                                      providerId,
                                      currentServiceName),
                                  child: const Text("طلب الخدمة الآن",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
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

  // --- الدوال المساعدة (نفس منطق الكود القديم) ---

  Future<void> _cancelBooking(
      BuildContext context, String serviceId, String orderId) async {
    await FirebaseFirestore.instance.collection("orders").doc(orderId).delete();
    await FirebaseFirestore.instance
        .collection("services")
        .doc(serviceId)
        .update({
      "status": "متاح",
      "customerId": null,
      "bookedAt": null,
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم إلغاء الحجز")));
  }

  Future<void> _requestService(BuildContext context, String serviceId,
      User? currentUser, String pId, String sName) async {
    if (currentUser == null) return;
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();
      String clientName = userDoc.data()?["name"]?.toString() ?? "عميل";

      await FirebaseFirestore.instance.collection("orders").add({
        "serviceId": serviceId,
        "clientId": currentUser.uid,
        "clientName": clientName,
        "providerId": pId,
        "providerName": providerName,
        "serviceName": sName,
        "status": "pending",
        "time": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("services")
          .doc(serviceId)
          .update({
        "status": "محجوز",
        "customerId": currentUser.uid,
        "bookedAt": FieldValue.serverTimestamp(),
      });

      await sendNotification(
        targetUserId: pId,
        title: "طلب خدمة جديد 🔔",
        message: "قام العميل ($clientName) بطلب خدمتك ($sName).",
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  void _showRatingDialog(BuildContext context, String serviceId,
      QueryDocumentSnapshot orderDoc, User? currentUser) async {
    // 1. جلب بيانات العميل (الذي يقيم) قبل فتح الديالوج لضمان السرعة
    String customerName = "عميل";
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser?.uid)
          .get();
      if (userDoc.exists) {
        customerName = userDoc.data()?["name"]?.toString() ?? "عميل";
      }
    } catch (e) {
      debugPrint("Error fetching customer name: $e");
    }

    showDialog(
      context: context,
      builder: (context) {
        int selectedRating = 5;
        TextEditingController reviewController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("تقييم الخدمة"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () => setState(() => selectedRating = i + 1),
                      ),
                    ),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration:
                        const InputDecoration(hintText: "اكتب رأيك هنا"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("إلغاء"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("حفظ التقييم"),
                  onPressed: () async {
                    try {
                      // استخدام providerId الممرر للكلاس نفسه
                      // ملاحظة: إذا كنت في Stateless استخدم providerId مباشرة
                      // إذا كنت في Stateful استخدم widget.providerId

                      await FirebaseFirestore.instance
                          .collection("reviews")
                          .add({
                        "serviceId": serviceId,
                        "providerId": providerId, // المعرف الممرر للصفحة
                        "providerName": providerName, // الاسم الممرر للصفحة
                        "customerId": currentUser?.uid,
                        "customerName":
                            customerName, // الاسم الذي جلبناه في الأعلى
                        "rating": selectedRating,
                        "review": reviewController.text.trim(),
                        "time": Timestamp.now(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم حفظ التقييم بنجاح")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("فشل الحفظ: $e")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ChatWithAdminPage extends StatelessWidget {
  const ChatWithAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("محادثة مع الأدمن"),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Text(
          "هنا سيظهر المحادثة الخاصة بالعميل مع الأدمن",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
