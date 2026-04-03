import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountControlPage extends StatelessWidget {
  const AccountControlPage({super.key});

  String getRoleName(String role) {
    if (role == "provider") return "مزود خدمة";
    if (role == "client") return "عميل";
    return "أدمن";
  }

  String fixRoleValue(dynamic role) {
    if (role == "مزود خدمة") return "provider";
    if (role == "عميل") return "client";
    if (role == "provider" || role == "client") return role;
    return "client";
  }

  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void showCV(BuildContext context, String url) {
    bool isImage =
        url.endsWith(".jpg") || url.endsWith(".png") || url.endsWith(".jpeg");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("السيفي"),
          content: SizedBox(
            width: 300,
            height: 400,
            child: isImage
                ? Image.network(url, fit: BoxFit.contain)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 60),
                      const SizedBox(height: 10),
                      const Text("ملف PDF"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => openLink(url),
                        child: const Text("فتح السيفي"),
                      )
                    ],
                  ),
          ),
          actions: [
            TextButton(
              child: const Text("إغلاق"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة الحسابات"),
        backgroundColor: AdminHome.navy,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("لا يوجد مستخدمين"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              bool isDisabled = data["disabled"] ?? false;
              String roleFixed = fixRoleValue(data["role"]);
              String? cvUrl = data["cv"];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data["name"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الدور: ${getRoleName(roleFixed)}"),
                      Text(
                        isDisabled ? "الحالة: معطل" : "الحالة: نشط",
                        style: TextStyle(
                          color: isDisabled ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("تفاصيل المستخدم"),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("👤 الاسم: ${data["name"] ?? ""}"),
                                      Text("📞 الهاتف: ${data["phone"] ?? ""}"),
                                      Text(
                                          "📧 الإيميل: ${data["email"] ?? ""}"),
                                      Text(
                                          "💼 المهنة: ${data["profession"] ?? ""}"),
                                      Text(
                                          "⭐ الخبرة: ${data["experience"] ?? ""}"),
                                    ],
                                  ),
                                ),
                                actions: [
                                  if (roleFixed == "provider" &&
                                      cvUrl != null &&
                                      cvUrl.isNotEmpty)
                                    ElevatedButton(
                                      onPressed: () => showCV(context, cvUrl),
                                      child: const Text("عرض السيفي"),
                                    ),
                                  TextButton(
                                    child: const Text("إغلاق"),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          TextEditingController nameController =
                              TextEditingController(text: data["name"]);

                          TextEditingController phoneController =
                              TextEditingController(text: data["phone"]);

                          TextEditingController emailController =
                              TextEditingController(text: data["email"]);

                          TextEditingController jobController =
                              TextEditingController(text: data["profession"]);

                          TextEditingController expController =
                              TextEditingController(
                                  text: data["experience"]?.toString());

                          String selectedRole = roleFixed;

                          showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: const Text("تعديل المستخدم"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: const InputDecoration(
                                              labelText: "اسم المستخدم",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          DropdownButtonFormField<String>(
                                            initialValue: selectedRole,
                                            items: const [
                                              DropdownMenuItem(
                                                value: "client",
                                                child: Text("عميل"),
                                              ),
                                              DropdownMenuItem(
                                                value: "provider",
                                                child: Text("مزود خدمة"),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                selectedRole = value!;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              labelText: "الدور",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: phoneController,
                                            decoration: const InputDecoration(
                                              labelText: "رقم الهاتف",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: emailController,
                                            decoration: const InputDecoration(
                                              labelText: "البريد الإلكتروني",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: jobController,
                                            decoration: const InputDecoration(
                                              labelText: "المهنة",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: expController,
                                            decoration: const InputDecoration(
                                              labelText: "سنوات الخبرة",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text("إلغاء"),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      ElevatedButton(
                                        child: const Text("حفظ"),
                                        onPressed: () async {
                                          await docs[index].reference.update({
                                            "name": nameController.text,
                                            "role": selectedRole,
                                            "phone": phoneController.text,
                                            "email": emailController.text,
                                            "profession": jobController.text,
                                            "experience": expController.text,
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isDisabled ? Icons.check_circle : Icons.block,
                          color: isDisabled ? Colors.green : Colors.red,
                        ),
                        onPressed: () async {
                          await docs[index].reference.update({
                            "disabled": !isDisabled,
                          });
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
}
