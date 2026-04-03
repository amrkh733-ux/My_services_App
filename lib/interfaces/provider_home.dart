import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

import '../messaging/provider_messaging_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_store_flutter/notifications/notifications.dart';
import '../login_screen.dart';
import 'edit_profile_page.dart';
import '../ai/faq_chat_page.dart';
//////////////////////////////////////////////////////
// صفحة مزود الخدمة الرئيسية
//////////////////////////////////////////////////////

class ProviderHome extends StatelessWidget {
  const ProviderHome({super.key});

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
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: const Text(
          "خدماتي",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
          // زر الإشعارات
          notificationIcon(context, "provider"),
          // قائمة الحساب والمزيد
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              DocumentSnapshot doc = await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get();
              Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

              switch (value) {
                case 0: // إنشاء إعلان
                  if (data != null) {
                    String profession = data["profession"] ?? "";
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateAdPage(profession: profession),
                      ),
                    );
                  }
                  break;

                case 1: // صفحتي
                  if (data != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          name: data["name"] ?? "",
                          role: data["role"] ?? "",
                          email: data["email"] ?? "",
                          phone: data["phone"] ?? "",
                          province: data["province"] ?? "",
                          district: data["district"] ?? "",
                          profession: data["profession"] ?? "",
                          age: data["age"] ?? "",
                          cvFile: data["cvFile"] ?? "",
                        ),
                      ),
                    );
                  }
                  break;

                case 2: // المراسلة مع الأدمن
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderMessagingPage(
                        userId: user.uid,
                        name: data?["name"] ?? "مزود خدمة",
                      ),
                    ),
                  );
                  break;

                case 4: // تسجيل الخروج
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                  break;

                case 5: // حذف الحساب مباشرة
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
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("إلغاء"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "حذف",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) return;

                  try {
                    // حذف بيانات المستخدم من Firestore
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .delete();

                    // حذف الحساب من FirebaseAuth
                    await user.delete();

                    // الانتقال إلى صفحة تسجيل الدخول
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

                  break;

                case 3: // فتح الدردشة الذكية
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FAQChatPage(
                          userType: UserType.provider), // مزود الخدمة
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text("صفحتي")),
              PopupMenuItem(value: 0, child: Text("إنشاء إعلان")),
              PopupMenuItem(value: 2, child: Text("المراسلة مع الادمن")),
              PopupMenuItem(value: 3, child: Text("الدردشة الذكية")),
              PopupMenuItem(value: 4, child: Text("تسجيل الخروج")),
              PopupMenuItem(
                value: 5,
                child: Text("حذف الحساب", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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
                        builder: (_) => ServiceCategoryPage(
                          categoryName: categories[index]["title"],
                          userId: user?.uid ?? "",
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
                        Icon(categories[index]["icon"], size: 40, color: navy),
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

//////////////////////////////////////////////////////
// صفحة الخدمات لكل قطاع
class CreateAdPage extends StatefulWidget {
  final String profession;

  const CreateAdPage({super.key, required this.profession});

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController professionController = TextEditingController();
  List<XFile> images = [];
  String providerName = "";
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    professionController.text = widget.profession;
    getProviderName();
  }

  Future<void> getProviderName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          providerName = doc["name"] ?? "";
        });
      }
    }
  }

  Future<void> pickImages() async {
    final List<XFile>? selectedImages = await picker.pickMultiImage();
    if (selectedImages != null) {
      setState(() {
        images.addAll(selectedImages);
      });
    }
  }

  // --- دالة إرسال الإعلان المحدثة (تم إصلاح الأقواس هنا) ---
  // --- دالة إرسال الإعلان (نسخة مشروع التخرج بدون رفع Storage) ---
  // --- دالة إرسال الإعلان المحدثة لاستخدام Cloudinary (الحل المجاني والدائم) ---
// --- دالة إرسال الإعلان المحدثة باستخدام Cloudinary ---
  Future<void> submitAd() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى تسجيل الدخول أولاً")));
      return;
    }

    if (experienceController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        professionController.text.trim().isEmpty ||
        images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تعبئة جميع الحقول واختيار صور")),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0A2A43)),
              SizedBox(height: 15),
              Text(
                "جاري رفع الصور لخدماتي...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // --- إعدادات Cloudinary الخاصة بحسابك (عمرو خالد) ---
      final cloudinary = CloudinaryPublic(
        'dlu9fxjc8', // الـ Cloud Name الخاص بك من الصورة
        'my_preset', // اسم الـ Preset الذي أنشأته (تأكد أنه Unsigned)
        cache: false,
      );

      List<String> uploadedImageUrls = [];

      for (var image in images) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            folder: 'khadamati_ads', // مجلد خاص بمشروع خدماتي
          ),
        );
        uploadedImageUrls.add(response.secureUrl);
      }

      // حفظ البيانات في Firestore مع الروابط الحقيقية (https)
      await FirebaseFirestore.instance.collection("ads").add({
        "providerId": user.uid,
        "providerName": providerName,
        "profession": professionController.text.trim(),
        "experience": experienceController.text.trim(),
        "description": descriptionController.text.trim(),
        "images": uploadedImageUrls,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // إغلاق التحميل

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم رفع الإعلان بنجاح بنظام Cloudinary!")),
      );

      experienceController.clear();
      descriptionController.clear();
      setState(() {
        images.clear();
      });
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("فشل الرفع: تأكد من إعداد الـ Preset كـ Unsigned")),
      );
    }
  }

  // --- دالة الـ Build ---
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0A2A43);

    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء إعلان", style: TextStyle(color: Colors.white)),
        backgroundColor: navy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "مزود الخدمة: $providerName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: professionController,
              decoration: const InputDecoration(
                labelText: "المهنة",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: experienceController,
              decoration: const InputDecoration(
                labelText: "سنوات الخبرة",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "وصف الإعلان",
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text(
                  "رفع صور",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: navy),
              ),
            ),
            const SizedBox(height: 10),
            // عرض الصور المختارة
            // بعد رفع الصور إلى Firebase Storage
// الكود الجديد لعرض الصور المختارة قبل إرسالها
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: images.map((img) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // نستخدم kIsWeb لعرض الصورة بشكل صحيح حسب المنصة
                        child: kIsWeb
                            ? Image.network(img.path, fit: BoxFit.cover)
                            : Image.file(File(img.path), fit: BoxFit.cover),
                      ),
                    ),
                    // زر صغير لحذف الصورة إذا تراجع المستخدم عن اختيارها
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => images.remove(img)),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitAd,
                style: ElevatedButton.styleFrom(backgroundColor: navy),
                child: const Text(
                  "إرسال الإعلان",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
// صفحة الخدمات لكل قطاع (النسخة المعدلة بالكامل)
//////////////////////////////////////////////////////
class ServiceCategoryPage extends StatefulWidget {
  final String categoryName;
  final String userId;

  const ServiceCategoryPage({
    super.key,
    required this.categoryName,
    required this.userId,
  });

  @override
  State<ServiceCategoryPage> createState() => _ServiceCategoryPageState();
}

class _ServiceCategoryPageState extends State<ServiceCategoryPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  String selectedCurrency = "ريال يمني";
  final List<String> currencies = ["ريال يمني", "ريال سعودي", "دولار أمريكي"];
  String providerName = "";
  bool isProcessing = false; // لمنع تكرار الإشعارات عند الضغط المتعدد

  @override
  void initState() {
    super.initState();
    getProviderName();
  }

  Future<void> getProviderName() async {
    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();
    if (doc.exists) {
      setState(() {
        providerName = doc["name"] ?? "";
      });
    }
  }

  Future<void> addService() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        experienceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("الرجاء تعبئة جميع الحقول")));
      return;
    }
    await FirebaseFirestore.instance.collection("services").add({
      "name": nameController.text.trim(),
      "price": priceController.text.trim(),
      "currency": selectedCurrency,
      "category": widget.categoryName,
      "providerId": widget.userId,
      "providerName": providerName,
      "experience": experienceController.text.trim(),
      "status": "متاح", // الحالة الافتراضية
      "customerId": null,
      "bookedAt": null,
    });
    nameController.clear();
    priceController.clear();
    experienceController.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم إضافة الخدمة بنجاح")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF0A2A43),
      ),
      body: Column(
        children: [
          // الجزء الخاص بإضافة خدمة جديدة
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "اسم الخدمة"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: "السعر"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCurrency,
                        items: currencies
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCurrency = value!),
                        decoration: const InputDecoration(labelText: "العملة"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(labelText: "سنوات الخبرة"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: addService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2A43),
                    ),
                    child: const Text("إضافة الخدمة",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),

          // عرض قائمة الخدمات والطلبات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("services")
                  .where("providerId", isEqualTo: widget.userId)
                  .where("category", isEqualTo: widget.categoryName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text("لا توجد خدمات مضافة"));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    // 1. معالجة البيانات وتجنب الـ Null
                    String currentStatus = data["status"]?.toString() ?? "متاح";
                    String? customerId = data["customerId"]?.toString();
                    String serviceName = data["name"]?.toString() ?? "خدمة";

                    // 2. شرط ظهور الأزرار (تظهر فقط عند "محجوز")
                    bool showActions =
                        (currentStatus == "محجوز" && customerId != null);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(serviceName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17)),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      docs[index].reference.delete(),
                                ),
                              ],
                            ),
                            Text(
                                "السعر: ${data["price"] ?? "0"} ${data["currency"] ?? ""}"),
                            const SizedBox(height: 5),

                            // عرض الحالة بشكل ملون
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentStatus == "محجوز"
                                    ? Colors.orange.withOpacity(0.1)
                                    : currentStatus == "مقبول"
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "الحالة: ${currentStatus == "محجوز" ? "طلب جديد ⭐" : currentStatus}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: currentStatus == "محجوز"
                                      ? Colors.orange
                                      : currentStatus == "مقبول"
                                          ? Colors.green
                                          : Colors.blueGrey,
                                ),
                              ),
                            ),

                            // 3. أزرار القبول والرفض (تظهر فقط عند الطلب الجديد)
                            if (showActions) ...[
                              const Divider(height: 25),
                              const Text("هناك طلب جديد بانتظار موافقتك:",
                                  style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      onPressed: isProcessing
                                          ? null
                                          : () async {
                                              setState(
                                                  () => isProcessing = true);
                                              try {
                                                await docs[index]
                                                    .reference
                                                    .update(
                                                        {"status": "مقبول"});
                                                var orders =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection("orders")
                                                        .where(
                                                            "serviceId",
                                                            isEqualTo:
                                                                docs[index].id)
                                                        .where("status",
                                                            isEqualTo:
                                                                "pending")
                                                        .get();
                                                for (var doc in orders.docs) {
                                                  await doc.reference.update(
                                                      {"status": "accepted"});
                                                }
                                                await sendNotification(
                                                    targetUserId: customerId,
                                                    title: "تم قبول طلبك ✅",
                                                    message:
                                                        "وافق $providerName على طلبك لخدمة $serviceName.");
                                              } finally {
                                                if (mounted)
                                                  setState(() =>
                                                      isProcessing = false);
                                              }
                                            },
                                      child: const Text("قبول",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      onPressed: isProcessing
                                          ? null
                                          : () async {
                                              setState(
                                                  () => isProcessing = true);
                                              try {
                                                await docs[index]
                                                    .reference
                                                    .update({
                                                  "status": "متاح",
                                                  "customerId": null,
                                                  "bookedAt": null
                                                });
                                                var orders =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection("orders")
                                                        .where(
                                                            "serviceId",
                                                            isEqualTo:
                                                                docs[index].id)
                                                        .get();
                                                for (var doc in orders.docs) {
                                                  await doc.reference.update(
                                                      {"status": "rejected"});
                                                }
                                                await sendNotification(
                                                    targetUserId: customerId,
                                                    title:
                                                        "نعتذر، تم رفض الطلب ❌",
                                                    message:
                                                        "لم يتم قبول طلبك لخدمة $serviceName.");
                                              } finally {
                                                if (mounted)
                                                  setState(() =>
                                                      isProcessing = false);
                                              }
                                            },
                                      child: const Text("رفض",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ]
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
      ),
    );
  }
}

//////////////////////////////////////////////////////
// زر دائري
//////////////////////////////////////////////////////
class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const CircularActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF0A2A43),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

//////////////////////////////////////////////////////
// صفحة الملف الشخصي
//////////////////////////////////////////////////////
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
                  if (profession.isNotEmpty)
                    infoCard(Icons.work, "المهنة", profession),
                  if (age.isNotEmpty) infoCard(Icons.cake, "العمر", age),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(
                              name: name,
                              role: role,
                              email: email,
                              phone: phone,
                              province: province,
                              district: district,
                              profession: profession,
                              age: age,
                              cvFile: cvFile,
                            ),
                          ),
                        );
                      },
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

//////////////////////////////////////////////////////
// صفحة محادثة الادمن
//////////////////////////////////////////////////////
