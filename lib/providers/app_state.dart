import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/algerie_telecom_api.dart';
import '../services/gemini_api.dart';
import '../services/my_idoom_api.dart';

class AppState extends ChangeNotifier {
  final api = AlgerieTelecomApi();
  final myIdoomApi = MyIdoomApi();
  final geminiApi = GeminiApi("AIzaSyAS6l7qi0RhVjzXR3u6sDdtNTHmESOQMzQ");

  Map<String, dynamic>? lineInfo;
  Map<String, dynamic>? line4gInfo;

  // MyIdoom State
  bool isLoggedIn = false;
  Map<String, dynamic>? userProfile;

  String? lastMessage;
  bool loading = false;

  AppState() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');
    if (cookie != null) {
      myIdoomApi.setSessionCookie(cookie);
      // Optionally try to fetch profile immediately to verify session
      await refreshProfile();
      if (userProfile != null) {
        isLoggedIn = true;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String nd, String password) async {
    loading = true;
    notifyListeners();

    final res = await myIdoomApi.login(nd, password);

    if (res['success'] == true) {
      final cookie = res['cookie'];
      if (cookie != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_cookie', cookie);
      }

      // Fetch profile after login
      await refreshProfile();
      isLoggedIn = true;
    } else {
      lastMessage = res['message'];
    }

    loading = false;
    notifyListeners();
    return isLoggedIn;
  }

  Future<void> logout() async {
    isLoggedIn = false;
    userProfile = null;
    myIdoomApi.setSessionCookie(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final res = await myIdoomApi.getAccountInfo();
    if (res['success'] == true) {
      userProfile = res['data'];
    } else {
      // If fetching profile fails (e.g. 401), we might consider logging out,
      // but for now just don't update the profile.
    }
    notifyListeners();
  }

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
}
