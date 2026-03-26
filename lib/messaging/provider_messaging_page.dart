import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_store_flutter/notifications/notifications.dart';

class ProviderMessagingPage extends StatefulWidget {
  final String userId;
  final String name;

  const ProviderMessagingPage({
    super.key,
    required this.userId,
    required this.name,
  });

  @override
  State<ProviderMessagingPage> createState() => _ProviderMessagingPageState();
}

class _ProviderMessagingPageState extends State<ProviderMessagingPage> {
  final TextEditingController message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color navyDark = Color(0xFF062147);
  void sendMessage() async {
    if (message.text.trim().isEmpty) return;

    // حفظ النص قبل المسح لضمان عدم إرسال إشعار فارغ
    String textToSend = message.text.trim();
    message.clear();

    // 1. إرسال الرسالة إلى سجل الدردشة في Firestore
    await _firestore
        .collection("messages")
        .doc(widget.userId)
        .collection("chat")
        .add({
      "text": textToSend,
      "sender": "provider",
      "time": FieldValue.serverTimestamp(),
    });

    // 2. تحديث بيانات المحادثة الرئيسية لظهورها عند الأدمن
    await _firestore.collection("messages").doc(widget.userId).set({
      "name": widget.name,
      "userId": widget.userId,
      "role": "provider",
      "lastMessage": textToSend,
      "time": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. إرسال الإشعار للأدمن فوراً
    await sendNotification(
      targetUserId: "admin", // المستلم هو الأدمن
      title: "رسالة جديدة من مزود خدمة 🛠️",
      message: "أرسل لك ${widget.name}: $textToSend",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyDark,
        title: const Text(
          "المراسلة مع الأدمن", // عنوان ثابت مثل صفحة العميل
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("messages")
                  .doc(widget.userId)
                  .collection("chat")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView(
                  reverse: false,
                  children: docs.map((doc) {
                    bool isMe = doc["sender"] == "provider";

                    return Container(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? navyDark : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doc["text"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
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
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: message,
                    decoration: const InputDecoration(
                      hintText: "اكتب رسالة...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: navyDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
