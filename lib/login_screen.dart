import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart';
import 'interfaces/provider_home.dart';
import 'interfaces/customer.dart';
import 'interfaces/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Color navyColor = Color(0xFF0A2A43);

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showSnack("الرجاء إدخال البريد وكلمة المرور");
      return;
    }

    setState(() => isLoading = true);

    try {
      // تسجيل الدخول
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        showSnack("فشل تسجيل الدخول");
        return;
      }

      // جلب بيانات المستخدم من Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      /// ✅ إذا المستخدم غير موجود → اعتبره Admin
      if (!doc.exists) {
        if (!mounted) return;

        showSnack("تم تسجيل الدخول كأدمن");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      /// 🔴 التحقق من التعطيل
      bool isDisabled = data["disabled"] ?? false;

      if (isDisabled) {
        await _auth.signOut();
        showSnack("تم تعطيل حسابك، تواصل مع الإدارة");
        return;
      }

      /// تحديد الدور بشكل مرن
      String role = data["role"] ?? "client";

      if (!mounted) return;

      showSnack("تم تسجيل الدخول بنجاح");

      /// التوجيه حسب الدور
      if (role == "مزود خدمة" || role == "provider") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProviderHome()),
        );
      } else if (role == "عميل" || role == "client") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      }
    } on FirebaseAuthException catch (e) {
      showSnack(e.message ?? "حدث خطأ");
    } catch (e) {
      showSnack("حدث خطأ غير متوقع");
      print(e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: navyColor,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget inputField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navyColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: navyColor),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget passwordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navyColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: hidePassword,
        style: const TextStyle(color: navyColor),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "كلمة المرور",
          hintStyle: const TextStyle(color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              hidePassword ? Icons.visibility_off : Icons.visibility,
              color: navyColor,
            ),
            onPressed: () => setState(() => hidePassword = !hidePassword),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: navyColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/logo.png"),
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "تسجيل الدخول",
                style: TextStyle(
                  color: navyColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              inputField(
                emailController,
                "البريد الإلكتروني",
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              passwordField(),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "دخول",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  "إنشاء حساب جديد",
                  style: TextStyle(
                    color: navyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
