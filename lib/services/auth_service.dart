import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

// Service untuk mengelola autentikasi user
class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _namaLengkapKey = 'nama_lengkap';
  static const String _roleKey = 'role';

  // Method untuk login dengan username dan password
  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        final user = UserModel.fromJson(response);
        await _saveSession(user);
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Login gagal: $e');
    }
  }

  // Method untuk menyimpan session user ke penyimpanan lokal
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_namaLengkapKey, user.namaLengkap);
    await prefs.setString(_roleKey, user.role);
  }

  // Method untuk mengambil data user yang sedang login
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    
    if (userId == null) return null;
    
    return UserModel(
      id: userId,
      username: prefs.getString(_usernameKey) ?? '',
      namaLengkap: prefs.getString(_namaLengkapKey) ?? '',
      role: prefs.getString(_roleKey) ?? 'admin',
    );
  }

  // Method untuk register user baru
  Future<UserModel?> register(String username, String password, String namaLengkap) async {
    try {
      // Cek apakah username sudah digunakan
      final existingUser = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Username sudah digunakan');
      }

      // Insert user baru ke database
      final response = await SupabaseConfig.client
          .from('users')
          .insert({
            'username': username,
            'password': password,
            'nama_lengkap': namaLengkap,
            'role': 'admin',
          })
          .select()
          .single();

      final user = UserModel.fromJson(response);
      await _saveSession(user);
      return user;
    } catch (e) {
      throw Exception('Register gagal: $e');
    }
  }

  // Method untuk register user baru (tanpa auto-login)
  Future<UserModel?> registerOnly(String username, String password, String namaLengkap) async {
    try {
      // Cek apakah username sudah digunakan
      final existingUser = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Username sudah digunakan');
      }

      // Insert user baru ke database
      final response = await SupabaseConfig.client
          .from('users')
          .insert({
            'username': username,
            'password': password,
            'nama_lengkap': namaLengkap,
            'role': 'admin',
          })
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Register gagal: $e');
    }
  }

  // Method untuk logout dan menghapus session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_namaLengkapKey);
    await prefs.remove(_roleKey);
  }
}
