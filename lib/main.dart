import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/theme_config.dart';
import 'halaman/login_page.dart';

// Fungsi utama - menjalankan aplikasi
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

// Widget utama aplikasi - mengatur tema dan halaman awal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulShoes Clean',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginPage(),
    );
  }
}
