import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBW5GqRrFFSgTajlrodHCbosJn9zZf-zvU",
      authDomain: "khadamati-ac182.firebaseapp.com",
      projectId: "khadamati-ac182",
      storageBucket: "khadamati-ac182.firebasestorage.app",
      messagingSenderId: "508735672791",
      appId: "1:508735672791:web:96879f07c018d563893b92",
      measurementId: "G-DMNH41LVMH",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RegisterScreen(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final districtController = TextEditingController();
  final professionController = TextEditingController();
  final experienceController = TextEditingController();

  String? selectedProvince;
  String? selectedRole;

  static const Color navyColor = Color(0xFF0A2A43);

  final List<String> yemenProvinces = [
    "أبين",
    "حضرموت",
    "تعز",
    "صنعاء",
    "عدن",
    "المهرة",
    "الحديدة",
    "شبوة",
    "لحج",
    "المحويت",
    "ريمة",
    "ذمار",
    "إب",
    "صعدة",
    "البيضاء",
    "الضالع",
    "الجوف",
    "حجة",
    "سقطرى"
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    districtController.dispose();
    professionController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: navyColor, content: Text(msg)),
    );
  }

  void clearFields() {
    setState(() {
      nameController.text = "";
      phoneController.text = "";
      emailController.text = "";
      passwordController.text = "";
      districtController.text = "";
      professionController.text = "";
      experienceController.text = "";

      selectedProvince = null;
      selectedRole = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.reset();
    });
  }

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedProvince == null) {
      showSnack("الرجاء اختيار المحافظة");
      return;
    }

    if (selectedRole == null) {
      showSnack("الرجاء اختيار الدور");
      return;
    }

    if (!emailController.text.contains('@')) {
      showSnack("البريد الإلكتروني غير صالح");
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "name": nameController.text,
        "phone": phoneController.text,
        "email": emailController.text,
        "province": selectedProvince,
        "district": districtController.text,
        "role": selectedRole,
        "profession":
            selectedRole == "مزود خدمة" ? professionController.text : "",
        "experience":
            selectedRole == "مزود خدمة" ? experienceController.text : "",
        "createdAt": Timestamp.now(),
      });

      clearFields();
      showSnack("تم إنشاء الحساب بنجاح");
    } on FirebaseAuthException catch (e) {
      showSnack(e.message ?? "حدث خطأ");
    } catch (e) {
      showSnack("حدث خطأ غير متوقع");
    }
  }

  Widget inputField(TextEditingController controller, String hint,
      {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navyColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: (value) {
          if (value == null || value.isEmpty) return "الحقل مطلوب";
          return null;
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }

  Widget dropdownField({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navyColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navyColor,
        title: const Text("إنشاء حساب"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "إنشاء حساب جديد",
                  style: TextStyle(
                    color: navyColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                dropdownField(
                  value: selectedRole,
                  items: const ["عميل", "مزود خدمة"],
                  hint: "اختر الدور",
                  onChanged: (val) {
                    setState(() {
                      selectedRole = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
                inputField(nameController, "الاسم"),
                const SizedBox(height: 20),
                inputField(phoneController, "رقم الهاتف",
                    keyboard: TextInputType.phone),
                const SizedBox(height: 20),
                inputField(emailController, "البريد الإلكتروني",
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 20),
                inputField(passwordController, "كلمة المرور", obscure: true),
                const SizedBox(height: 20),
                dropdownField(
                  value: selectedProvince,
                  items: yemenProvinces,
                  hint: "اختر المحافظة",
                  onChanged: (val) {
                    setState(() {
                      selectedProvince = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
                inputField(districtController, "المديرية"),
                if (selectedRole == "مزود خدمة") ...[
                  const SizedBox(height: 20),
                  inputField(professionController, "المهنة"),
                  const SizedBox(height: 20),
                  inputField(experienceController, "سنوات الخبرة",
                      keyboard: TextInputType.number),
                ],
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                    ),
                    child: const Text(
                      "إنشاء حساب",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
