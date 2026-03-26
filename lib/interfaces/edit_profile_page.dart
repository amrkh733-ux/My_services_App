import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String province;
  final String district;
  final String profession;
  final String age;
  final String cvFile;

  const EditProfilePage({
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
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color navy = Color(0xFF0A2A43);

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final provinceController = TextEditingController();
  final districtController = TextEditingController();
  final professionController = TextEditingController();
  final ageController = TextEditingController();
  final cvController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() {
    // تحميل البيانات من widget
    nameController.text = widget.name;
    phoneController.text = widget.phone;
    emailController.text = widget.email;
    provinceController.text = widget.province;
    districtController.text = widget.district;
    professionController.text = widget.profession;
    ageController.text = widget.age;
    cvController.text = widget.cvFile;

    setState(() {
      loading = false;
    });
  }

  Future updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "name": nameController.text,
      "phone": phoneController.text,
      "email": emailController.text,
      "province": provinceController.text,
      "district": districtController.text,
      "role": professionController.text, // يمكن التعديل إذا أردنا نوع الدور
      "profession": professionController.text,
      "age": ageController.text,
      "cvFile": cvController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم تحديث البيانات بنجاح")),
    );

    Navigator.pop(context);
  }

  Widget buildField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType keyboard = TextInputType.text}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            icon: Icon(icon, color: navy),
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("تعديل البيانات"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            buildField(
              controller: nameController,
              label: "الاسم",
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            buildField(
              controller: phoneController,
              label: "رقم الهاتف",
              icon: Icons.phone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            buildField(
              controller: emailController,
              label: "البريد الإلكتروني",
              icon: Icons.email,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            buildField(
              controller: provinceController,
              label: "المحافظة",
              icon: Icons.location_city,
            ),
            const SizedBox(height: 15),
            buildField(
              controller: districtController,
              label: "المديرية",
              icon: Icons.location_on,
            ),
            const SizedBox(height: 15),
            buildField(
              controller: professionController,
              label: "المهنة",
              icon: Icons.work,
            ),
            const SizedBox(height: 15),
            buildField(
              controller: ageController,
              label: "العمر",
              icon: Icons.cake,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: updateProfile,
                icon: const Icon(Icons.save),
                label: const Text(
                  "حفظ التعديل",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
