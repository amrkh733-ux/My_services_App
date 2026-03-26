// lib/interfaces/admin_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_store_flutter/messaging/admin_messaging_page.dart'
    as messaging;

import 'package:phone_store_flutter/reviews/customer_reviews.dart';
import 'account_control.dart' as account;
import '../login_screen.dart';
// أعلى الملف: استيراد صفحة الإشعارات من المجلد الصحيح

import 'services_management.dart';
import 'package:phone_store_flutter/notifications/notifications.dart';

//////////////////////////////////////////////////////
// صفحة الادمن الرئيسية
//////////////////////////////////////////////////////
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  static Color? get navy => null;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static const Color navy = Color(0xFF0A2A43);

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
  void initState() {
    super.initState();
    _listenForMessages(); // تشغيل المستمع عند فتح التطبيق
  }

  void _listenForMessages() {
    FirebaseFirestore.instance
        .collection("chats")
        .where("receiverId", isEqualTo: "admin")
        .where("isRead", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges
          .any((change) => change.type == DocumentChangeType.added)) {
        // 1. إظهار الـ SnackBar (التنبيه المؤقت)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("وصلت رسالة جديدة للأدمن! ✉️"),
            backgroundColor: navy,
          ),
        );

        // 2. تسجيل إشعار في قاعدة البيانات ليظهر تحت أيقونة الجرس
        sendNotification(
          targetUserId: "admin",
          title: "رسالة جديدة ✉️",
          message: "لديك رسائل غير مقروءة في قسم المراسلة.",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // باقي كود الـ build كما هو لديك تماماً
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: const Text(
          "لوحة التحكم",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset("assets/logo.png", fit: BoxFit.cover),
            ),
          ),
        ),
        actions: [
          // زر الإشعارات
          // زر الإشعارات المخصص للأدمن
          notificationIcon(context, "admin"),
          // قائمة الخيارات المنسدلة
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) async {
              User? user = FirebaseAuth.instance.currentUser;

              if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerReviewsPage(
                      customerId: '', // نص فارغ ليعرض كل التقييمات لكل العملاء
                    ),
                  ),
                );
              }

              if (value == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => messaging.AdminMessagingPage()),
                );
              }

              if (value == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminAdsApprovalPage()),
                );
              }

              if (value == 6) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const account.AccountControlPage()),
                );
              }

              if (value == 7) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ServicesManagementPage()),
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
              // فتح صفحة طلبات حذف الحساب

// حذف حساب الأدمن نفسه
              else if (value == 5 && user != null) {
                bool confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("حذف الحساب"),
                    content: const Text("هل أنت متأكد من حذف حسابك نهائياً؟"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("إلغاء")),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("حذف",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed) {
                  // حذف إشعارات هذا الأدمن أولاً لضمان نظافة البيانات
                  var notes = await FirebaseFirestore.instance
                      .collection("notifications")
                      .where("userId", isEqualTo: "admin")
                      .get();
                  for (var doc in notes.docs) {
                    await doc.reference.delete();
                  }

                  // حذف البيانات من Firestore ثم حذف الحساب من Firebase Auth
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .delete();
                  await user.delete();

                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text("التقييمات")),
              PopupMenuItem(value: 2, child: Text("المراسلة")),
              PopupMenuItem(value: 3, child: Text("الموافقة على الإعلانات")),
              PopupMenuItem(value: 6, child: Text("إدارة الحسابات")),
              PopupMenuItem(value: 7, child: Text("إدارة الخدمات")),
              PopupMenuItem(value: 4, child: Text("تسجيل الخروج")),
              PopupMenuItem(
                  value: 5,
                  child:
                      Text("حذف الحساب", style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
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
                        builder: (_) => AdminCategoryServicesPage(
                          categoryName: categories[index]["title"],
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
                        Icon(
                          categories[index]["icon"],
                          size: 40,
                          color: navy,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          categories[index]["title"],
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAdsApprovalPage extends StatelessWidget {
  const AdminAdsApprovalPage({super.key});

  static const Color navy = Color(0xFF0A2A43);

  get serviceName => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("جميع الإعلانات"),
        backgroundColor: navy,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب كل الإعلانات بغض النظر عن الحالة
        stream: FirebaseFirestore.instance.collection("ads").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("لا توجد إعلانات"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["providerName"] ?? "",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text("المهنة: ${data["profession"] ?? ""}"),
                      Text("سنوات الخبرة: ${data["experience"] ?? ""}"),
                      const SizedBox(height: 5),
                      Text(data["description"] ?? ""),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. زر الموافقة: يظهر إذا كان الإعلان قيد الانتظار
                          if ((data["status"] ?? "") != "approved")
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                // تحديث الحالة في قاعدة البيانات
                                await docs[index].reference.update({
                                  "status": "approved",
                                });
                                Future<void> sendNotification({
                                  required String targetUserId,
                                  required String title,
                                  required String message,
                                  required String senderType,
                                  required String senderId,
                                }) async {
                                  await FirebaseFirestore.instance
                                      .collection("notifications")
                                      .add({
                                    "targetUserId": targetUserId,
                                    "title": title,
                                    "message": message,
                                    "senderType": senderType,
                                    "senderId": senderId,
                                    "timestamp": FieldValue.serverTimestamp(),
                                    "isRead": false,
                                  });
                                }

                                final TextEditingController messageController =
                                    TextEditingController();

                                await sendNotification(
                                  targetUserId: "admin",
                                  title: "رسالة جديدة ✉️",
                                  message: messageController.text.trim(),
                                  senderType: "customer", // أو "provider"
                                  senderId:
                                      FirebaseAuth.instance.currentUser!.uid,
                                );

                                var providerId;
                                await sendNotification(
                                  targetUserId:
                                      providerId, // هنا يذهب الإشعار للمزود
                                  title: "طلب خدمة جديد 🔔",
                                  message:
                                      "قام عميل بطلب خدمتك ($serviceName).",
                                  senderType: '',
                                  senderId: '',
                                );
                                // إرسال إشعار للمزود فوراً
                                await sendNotification(
                                  targetUserId:
                                      data["providerId"] ?? "", // معرف المزود
                                  title: "تم قبول إعلانك 🎉",
                                  message:
                                      "وافق الأدمن على إعلانك (${data['profession']}) وهو متاح الآن.",
                                  senderType: '',
                                  senderId: '',
                                );
                              },
                              child: const Text("موافقة",
                                  style: TextStyle(color: Colors.white)),
                            ),

                          const SizedBox(width: 10),

                          // 2. زر الحذف: يحذف ويرسل إشعار تنبيه
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              bool confirmed = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("حذف الإعلان"),
                                  content: const Text(
                                      "هل أنت متأكد من حذف هذا الإعلان نهائيًا؟"),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("إلغاء")),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("حذف",
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed) {
                                String pId = data["providerId"] ?? "";
                                String prof = data["profession"] ?? "";

                                // حذف الإعلان
                                await docs[index].reference.delete();

                                // إرسال إشعار للمزود يخبره بسبب الحذف
                                await sendNotification(
                                  targetUserId: pId,
                                  title: "تنبيه بخصوص إعلانك ⚠️",
                                  message:
                                      "نأسف، تم حذف إعلانك ($prof) من قبل الإدارة.",
                                );
                              }
                            },
                            child: const Text("حذف",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
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

//////////////////////////////////////////////////////
// صفحة الخدمات لكل قطاع (Admin View)
//////////////////////////////////////////////////////
class AdminCategoryServicesPage extends StatelessWidget {
  final String categoryName;

  const AdminCategoryServicesPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: AdminHome.navy,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("services")
            .where("category", isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("لا توجد خدمات حتى الآن"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["providerName"] ?? "",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(data["name"] ?? "",
                          style: const TextStyle(
                              fontSize: 15, color: Colors.blueGrey)),
                      const SizedBox(height: 4),
                      Text("السعر: ${data["price"]}"),
                      Text("العملة: ${data["currency"]}"),
                      Text("سنوات الخبرة: ${data["experience"] ?? ""}"),
                      Text("الحالة: ${data["status"] ?? "متاح"}",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.green)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController name =
                                  TextEditingController(text: data["name"]);
                              TextEditingController price =
                                  TextEditingController(
                                      text: data["price"].toString());
                              TextEditingController experience =
                                  TextEditingController(
                                      text: data["experience"]);

                              return AlertDialog(
                                title: const Text("تعديل الخدمة"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: name,
                                      decoration: const InputDecoration(
                                          labelText: "اسم الخدمة"),
                                    ),
                                    TextField(
                                      controller: price,
                                      decoration: const InputDecoration(
                                          labelText: "السعر"),
                                    ),
                                    TextField(
                                      controller: experience,
                                      decoration: const InputDecoration(
                                          labelText: "سنوات الخبرة"),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("إلغاء"),
                                    // زر الموافقة داخل AdminAdsApprovalPage
                                    // داخل زر الموافقة في AdminAdsApprovalPage
                                    onPressed: () async {
                                      // 1. تحديث حالة الإعلان في Firebase
                                      await docs[index].reference.update({
                                        "status": "approved",
                                      });

                                      // 2. إرسال إشعار للمزود فوراً (باستخدام الدالة العالمية)
                                      await sendNotification(
                                        targetUserId: data["providerId"] ??
                                            "", // معرف المزود
                                        title: "تم قبول إعلانك 🎉",
                                        message:
                                            "وافق الأدمن على إعلانك (${data['profession']}) وهو متاح الآن للعملاء.",
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "تمت الموافقة وإرسال إشعار للمزود")),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            docs[index].reference.delete();
                          }),
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

//////////////////////////////////////////////////////
// صفحة الإشعارات للادمن
//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// صفحة طلبات حذف الحساب
//////////////////////////////////////////////////////
class DeletionRequestsPage extends StatelessWidget {
  const DeletionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("طلبات الحذف"),
          backgroundColor: const Color(0xFF0A2A43)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("deletion_requests")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['email']),
                subtitle: const Text("طلب حذف الحساب نهائياً"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    // منطق الحذف النهائي
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
