import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_store_flutter/notifications/notifications.dart';

class CustomerMessagingPage extends StatefulWidget {
  final String userId;
  final String name;

  const CustomerMessagingPage(
      {super.key, required this.userId, required this.name});

  @override
  State<CustomerMessagingPage> createState() => _CustomerMessagingPageState();
}

class _CustomerMessagingPageState extends State<CustomerMessagingPage> {
  final TextEditingController message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color navyDark = Color(0xFF062147);
  void sendMessage() async {
    if (message.text.trim().isEmpty) return;

    // حفظ النص في متغير قبل مسح الحقل
    String textToSend = message.text.trim();
    message.clear();

    // 1. إرسال الرسالة إلى سجل الدردشة
    await _firestore
        .collection("messages")
        .doc(widget.userId)
        .collection("chat")
        .add({
      "text": textToSend,
      "sender": "customer",
      "time": FieldValue.serverTimestamp()
    });

    // 2. تحديث بيانات المحادثة الرئيسية (لتظهر في قائمة الرسائل عند الأدمن)
    await _firestore.collection("messages").doc(widget.userId).set({
      "name": widget.name,
      "userId": widget.userId,
      "role": "customer",
      "lastMessage": textToSend,
      "time": FieldValue.serverTimestamp()
    }, SetOptions(merge: true));

    // 3. إرسال الإشعار للأدمن
    await sendNotification(
      targetUserId: "admin", // الهدف هو الأدمن دائماً هنا
      title: "رسالة جديدة من عميل 📩",
      message: "أرسل لك ${widget.name}: $textToSend",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyDark,
        title: const Text(
          "المراسلة مع الأدمن",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
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

                final docs = snapshot.data!.docs;

                return ListView(
                  reverse: false, // الرسائل الأحدث أسفل
                  children: docs.map((e) {
                    bool isMe = e["sender"] == "customer";

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
                          e["text"],
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
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
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
