import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_store_flutter/notifications/notifications.dart';

class AdminMessagingPage extends StatefulWidget {
  const AdminMessagingPage({super.key});

  @override
  State<AdminMessagingPage> createState() => _AdminMessagingPageState();
}

class _AdminMessagingPageState extends State<AdminMessagingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color navyDark = Color(0xFF062147);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navyDark,
        title: const Text(
          "المراسلات",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection("messages")
            .orderBy("time", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("لا توجد رسائل"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  title: Text(
                    data["name"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        data["role"] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data["lastMessage"] ?? "",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: navyDark,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          userId: data["userId"],
                          name: data["name"],
                          role: data["role"],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String userId;
  final String name;
  final String role;

  const ChatPage({
    super.key,
    required this.userId,
    required this.name,
    required this.role,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController message = TextEditingController();
  static const Color navyDark = Color(0xFF062147);
  void sendMessage() async {
    if (message.text.trim().isEmpty) return;

    String textToSend = message.text.trim(); // حفظ النص قبل المسح
    message.clear(); // مسح الحقل فوراً لتجربة مستخدم أفضل

    // 1. إضافة الرسالة إلى سجل المحادثة بين الأدمن وهذا المستخدم
    await _firestore
        .collection("messages")
        .doc(widget.userId)
        .collection("chat")
        .add({
      "text": textToSend,
      "sender": "admin",
      "time": FieldValue.serverTimestamp()
    });
    await sendNotification(
      targetUserId: widget.userId, // معرف المستخدم المستلم
      title: "رسالة من الإدارة ✉️",
      message: textToSend,
    );
    // 2. تحديث الوثيقة الرئيسية (لتظهر آخر رسالة في قائمة المراسلات)
    await _firestore.collection("messages").doc(widget.userId).set({
      "lastMessage": textToSend,
      "time": FieldValue.serverTimestamp(),
      "userId": widget.userId,
      "name": widget.name,
      "role": widget.role,
    }, SetOptions(merge: true));

    // 3. إرسال الإشعار للمستخدم (العميل أو المزود)
  }

  void showUserDetails() async {
    var doc = await _firestore.collection("users").doc(widget.userId).get();
    if (doc.exists) {
      var data = doc.data()!;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // تمت إزالة CircleAvatar و الصور
              Text("الاسم: ${data["name"] ?? ""}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("الدور: ${data["role"] ?? ""}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("البريد: ${data["email"] ?? ""}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("الهاتف: ${data["phone"] ?? ""}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("المحافظة: ${data["province"] ?? ""}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("المديرية: ${data["district"] ?? ""}",
                  style: const TextStyle(fontSize: 16)),
              if ((data["profession"] ?? "").isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("المهنة: ${data["profession"]}",
                      style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: navyDark),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إغلاق"),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyDark,
        title: GestureDetector(
          onTap: showUserDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.name, style: const TextStyle(color: Colors.white)),
              Text(
                widget.role,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection("messages")
                  .doc(widget.userId)
                  .collection("chat")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((e) {
                    bool isAdmin = e["sender"] == "admin";

                    return Container(
                      alignment: isAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isAdmin ? navyDark : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          e["text"],
                          style: TextStyle(
                            color: isAdmin ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: message,
                    decoration: const InputDecoration(
                      hintText: "اكتب رسالة",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: navyDark),
                  onPressed: sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
