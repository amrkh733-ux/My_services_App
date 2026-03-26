import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart';

class AuthService {
  static const String usersKey = 'users';
  static const String currentUserKey = 'current_user';

  static Future<List<UserModel>> _getStoredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(usersKey);
    if (raw == null) return [];
    final List decoded = json.decode(raw);
    return decoded
        .map((e) => UserModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> _saveUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(users.map((u) => u.toMap()).toList());
    await prefs.setString(usersKey, encoded);
  }

  static Future<bool> register(UserModel user) async {
    final users = await _getStoredUsers();
    final exists = users.any((u) => u.email == user.email);
    if (exists) return false;
    users.add(user);
    await _saveUsers(users);
    await _setCurrentUser(user);
    return true;
  }

  static Future<bool> login(String email, String password) async {
    final users = await _getStoredUsers();
    final match = users.firstWhere(
      (u) => u.email == email && u.password == password,
      orElse: () => UserModel(name: '', email: '', password: ''),
    );
    if (match.email == '') return false;
    await _setCurrentUser(match);
    return true;
  }

  static Future<void> _setCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentUserKey, json.encode(user.toMap()));
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(currentUserKey);
    if (raw == null) return null;
    final map = json.decode(raw);
    return UserModel.fromMap(Map<String, dynamic>.from(map));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentUserKey);
  }
}
