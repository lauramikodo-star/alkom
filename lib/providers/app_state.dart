import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/algerie_telecom_api.dart';
import '../services/my_idoom_api.dart';
import '../services/gemini_api.dart';

class AppState extends ChangeNotifier {
  final api = AlgerieTelecomApi();
  final myIdoomApi = MyIdoomApi();
  final geminiApi = GeminiApi("AIzaSyAS6l7qi0RhVjzXR3u6sDdtNTHmESOQMzQ"); // Ideally should be in .env

  // Anonymous State
  Map<String, dynamic>? lineInfo;
  Map<String, dynamic>? line4gInfo;
  String? lastMessage;
  bool loading = false;

  // Authenticated State
  String? userToken;
  Map<String, dynamic>? userInfo; // Basic info from login
  Map<String, dynamic>? accountInfo; // Detailed info from /api/compte

  AppState() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    userToken = prefs.getString('user_token');
    if (userToken != null) {
      // Optionally verify token or refresh info
      fetchAccountInfo();
    }
    notifyListeners();
  }

  bool get isLoggedIn => userToken != null;

  // --- Anonymous Actions ---

  Future<void> fetchInfo(String number) async {
    loading = true;
    notifyListeners();
    lineInfo = await api.getLineInfo(number);
    loading = false;
    notifyListeners();
  }

  Future<void> fetch4gInfo(String number) async {
    loading = true;
    notifyListeners();
    line4gInfo = await api.get4gLineInfo(number);
    loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> pay(String number, String voucher) async {
    loading = true;
    notifyListeners();
    final res = await api.recharge(number: number, voucher: voucher);
    loading = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> debt(String number) async {
    loading = true;
    notifyListeners();
    final res = await api.checkDebt(number);
    loading = false;
    notifyListeners();
    return res;
  }

  // --- Authenticated Actions ---

  Future<Map<String, dynamic>> login(String nd, String password) async {
    loading = true;
    notifyListeners();

    final res = await myIdoomApi.login(nd, password);

    if (res.containsKey('meta_data')) {
        final token = res['meta_data']['original']['token'];
        final data = res['data']['original'];

        if (token != null) {
            userToken = token;
            userInfo = data;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_token', token);

            // Auto fetch detailed info
            await fetchAccountInfo();
        }
    } else if (res.containsKey('token')) {
         // Handling varied response structures just in case
         userToken = res['token'];
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('user_token', userToken!);
    }

    loading = false;
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    userToken = null;
    userInfo = null;
    accountInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    loading = true;
    notifyListeners();
    final res = await myIdoomApi.register(data);
    loading = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> confirmRegister(String nd, String otp) async {
    loading = true;
    notifyListeners();
    final res = await myIdoomApi.confirmRegister(nd, otp);
    loading = false;
    notifyListeners();
    return res;
  }

  Future<void> fetchAccountInfo() async {
    if (userToken == null) return;

    // Don't show full screen loading for background fetch if possible,
    // but here we might want to indicate it.
    // loading = true;
    // notifyListeners();

    final res = await myIdoomApi.getAccountInfo(userToken!);
    if (res['error'] != true) {
       // Adjust based on actual structure.
       // Python code says data -> original
       if (res.containsKey('data') && res['data'] is Map && res['data'].containsKey('original')) {
          accountInfo = res['data']['original'];
       } else {
          accountInfo = res;
       }
    } else if (res['statusCode'] == 401) {
      // Token expired
      logout();
    }

    // loading = false;
    notifyListeners();
  }
}
