import 'package:supabase_flutter/supabase_flutter.dart';

// Class untuk konfigurasi koneksi database Supabase
class SupabaseConfig {
  static const String supabaseUrl = 'https://bdjpzeflyffohmlghdin.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Ln-3Oes_OwurAIALoTbBKA_rJvcpsQ5';

  // Method untuk menghubungkan aplikasi ke Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Getter untuk mengakses client Supabase
  static SupabaseClient get client => Supabase.instance.client;
}
