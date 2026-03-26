import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//////////////////////////////////////////////////////
// 1. دالة إرسال الإشعارات
//////////////////////////////////////////////////////
Future<void> sendNotification({
  required String targetUserId,
  required String title,
  required String message,
}) async {
  await FirebaseFirestore.instance.collection("notifications").add({
    "userId": targetUserId,
    "title": title,
    "message": message,
    "time": FieldValue.serverTimestamp(),
    "isRead": false, // 🔴 مهم
  });
  var recipientId;
  var senderName;
  // بعد كود إضافة الرسالة لـ Firestore بنجاح، أضف هذا السطر:
  await sendNotification(
    targetUserId:
        recipientId, // معرف الشخص المستلم (الأدمن أو المزود أو العميل)
    title: "رسالة جديدة ✉️",
    message:
        "لديك رسالة جديدة من ${senderName}", // senderName هو اسم المرسل الحالي
  );
}

//////////////////////////////////////////////////////
// 2. صفحة الإشعارات
//////////////////////////////////////////////////////
class NotificationsPage extends StatefulWidget {
  final String role; // admin / provider / client
  const NotificationsPage({super.key, required this.role});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const Color navy = Color(0xFF0A2A43);

  @override
  void initState() {
    super.initState();
    _markAllAsRead(); // 🔴 تصفير عند الدخول
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String filterId = (widget.role == "admin") ? "admin" : user.uid;

    var snapshot = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: filterId)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({"isRead": true});
    }
  }

  Widget _getNotificationIcon(String title) {
    if (title.contains("رسالة"))
      return const Icon(Icons.mail, color: Colors.blue);
    if (title.contains("طلب خدمة"))
      return const Icon(Icons.shopping_bag, color: Colors.orange);
    if (title.contains("تقييم"))
      return const Icon(Icons.star, color: Colors.amber);
    if (title.contains("إعلان"))
      return const Icon(Icons.campaign, color: Colors.purple);
    if (title.contains("قبول") || title.contains("موافقة"))
      return const Icon(Icons.check_circle, color: Colors.green);

    return const Icon(Icons.notifications, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("يرجى تسجيل الدخول")),
      );
    }

    String filterId = (widget.role == "admin") ? "admin" : user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("الإشعارات",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: navy,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: filterId)
            .orderBy("time", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("خطأ في تحميل البيانات"));
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("لا توجد إشعارات"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              String title = data["title"] ?? "تنبيه";
              String message = data["message"] ?? "";
              bool isRead = data["isRead"] ?? false;
              Timestamp? time = data["time"];

              return Card(
                color: isRead ? Colors.white : Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: _getNotificationIcon(title),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      const SizedBox(height: 5),
                      Text(
                        time != null ? _formatDate(time.toDate()) : "",
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // 🔴 تحويل لمقروء عند الضغط
                    await docs[index].reference.update({"isRead": true});
                  },
                  onLongPress: () async {
                    await docs[index].reference.delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "اليوم - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }

    return "${date.year}/${date.month}/${date.day}";
  }
}

//////////////////////////////////////////////////////
// 3. زر الجرس مع العداد
//////////////////////////////////////////////////////
Widget notificationIcon(BuildContext context, String role) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const SizedBox();

  String filterId = (role == "admin") ? "admin" : user.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: filterId)
        .where("isRead", isEqualTo: false) // 🔴 غير المقروء فقط
        .snapshots(),
    builder: (context, snapshot) {
      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

      return Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(role: role),
                ),
              );
            },
          ),
          if (count > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 9 ? "+9" : count.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      );
    },
  );
}
