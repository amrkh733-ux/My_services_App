// lib/interfaces/services_management.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesManagementPage extends StatelessWidget {
  const ServicesManagementPage({super.key});

  static const Color navy = Color(0xFF0A2A43);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("إدارة الخدمات"),
        backgroundColor: navy,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("services").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "لا توجد خدمات",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// اسم المزود + الأزرار
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data["providerName"] ?? "بدون اسم",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              /// زر التعديل
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  TextEditingController nameController =
                                      TextEditingController(text: data["name"]);

                                  TextEditingController categoryController =
                                      TextEditingController(
                                          text: data["category"]);

                                  TextEditingController priceController =
                                      TextEditingController(
                                          text: data["price"].toString());

                                  TextEditingController currencyController =
                                      TextEditingController(
                                          text: data["currency"]);

                                  TextEditingController experienceController =
                                      TextEditingController(
                                          text: data["experience"].toString());

                                  TextEditingController statusController =
                                      TextEditingController(
                                          text: data["status"]);

                                  TextEditingController descriptionController =
                                      TextEditingController(
                                          text: data["description"]);

                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("تعديل الخدمة"),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              TextField(
                                                controller: nameController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "اسم الخدمة",
                                                ),
                                              ),
                                              TextField(
                                                controller: categoryController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "القسم",
                                                ),
                                              ),
                                              TextField(
                                                controller: priceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "السعر",
                                                ),
                                              ),
                                              TextField(
                                                controller: currencyController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "العملة",
                                                ),
                                              ),
                                              TextField(
                                                controller:
                                                    experienceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "سنوات الخبرة",
                                                ),
                                              ),
                                              TextField(
                                                controller: statusController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "الحالة",
                                                ),
                                              ),
                                              TextField(
                                                controller:
                                                    descriptionController,
                                                maxLines: 3,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "الوصف",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("إلغاء"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await docs[index]
                                                  .reference
                                                  .update({
                                                "name": nameController.text,
                                                "category":
                                                    categoryController.text,
                                                "price": double.tryParse(
                                                        priceController.text) ??
                                                    0,
                                                "currency":
                                                    currencyController.text,
                                                "experience": int.tryParse(
                                                        experienceController
                                                            .text) ??
                                                    0,
                                                "status": statusController.text,
                                                "description":
                                                    descriptionController.text,
                                              });

                                              Navigator.pop(context);

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text("تم تعديل الخدمة"),
                                                ),
                                              );
                                            },
                                            child: const Text("حفظ"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),

                              /// زر الحذف
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("حذف الخدمة"),
                                        content: const Text(
                                            "هل تريد حذف هذه الخدمة؟"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("إلغاء"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () async {
                                              await docs[index]
                                                  .reference
                                                  .delete();

                                              Navigator.pop(context);

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text("تم حذف الخدمة"),
                                                ),
                                              );
                                            },
                                            child: const Text("حذف"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "الخدمة: ${data["name"] ?? ""}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text("القسم: ${data["category"] ?? ""}"),
                      Text("السعر: ${data["price"] ?? ""}"),
                      Text("العملة: ${data["currency"] ?? ""}"),
                      Text("الخبرة: ${data["experience"] ?? ""}"),

                      const SizedBox(height: 8),

                      Text(data["description"] ?? ""),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data["status"] ?? "متاح",
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
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
