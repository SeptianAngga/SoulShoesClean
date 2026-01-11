import 'package:intl/intl.dart';
import '../config/supabase_config.dart';
import '../models/pengeluaran_model.dart';

// Service untuk mengelola data pengeluaran
class PengeluaranService {
  // Method untuk mengambil semua pengeluaran dari database
  Future<List<PengeluaranModel>> getAllPengeluaran() async {
    try {
      final response = await SupabaseConfig.client
          .from('pengeluaran')
          .select()
          .order('tanggal', ascending: false);

      return (response as List)
          .map((json) => PengeluaranModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pengeluaran: $e');
    }
  }

  // Method untuk menambah pengeluaran baru
  Future<PengeluaranModel> createPengeluaran(PengeluaranModel pengeluaran) async {
    try {
      final response = await SupabaseConfig.client
          .from('pengeluaran')
          .insert(pengeluaran.toJson())
          .select()
          .single();

      return PengeluaranModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah pengeluaran: $e');
    }
  }

  // Method untuk menghapus pengeluaran
  Future<void> deletePengeluaran(String id) async {
    try {
      await SupabaseConfig.client
          .from('pengeluaran')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus pengeluaran: $e');
    }
  }

  // Method untuk menghitung total pengeluaran bulan ini
  Future<Map<String, dynamic>> getPengeluaranStats() async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfMonthStr = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);

      final response = await SupabaseConfig.client
          .from('pengeluaran')
          .select('tanggal, jumlah');

      final pengeluaranList = response as List;

      int totalPengeluaran = 0;
      int pengeluaranHariIni = 0;
      int pengeluaranBulanIni = 0;
      int itemHariIni = 0;
      int itemBulanIni = 0;

      for (var item in pengeluaranList) {
        final jumlah = item['jumlah'] as int? ?? 0;
        final tanggalStr = item['tanggal'] as String?;

        totalPengeluaran += jumlah;

        if (tanggalStr != null) {
          if (tanggalStr == todayStr) {
            pengeluaranHariIni += jumlah;
            itemHariIni++;
          }

          if (tanggalStr.compareTo(firstDayOfMonthStr) >= 0) {
            pengeluaranBulanIni += jumlah;
            itemBulanIni++;
          }
        }
      }

      return {
        'totalPengeluaran': totalPengeluaran,
        'pengeluaranHariIni': pengeluaranHariIni,
        'pengeluaranBulanIni': pengeluaranBulanIni,
        'itemHariIni': itemHariIni,
        'itemBulanIni': itemBulanIni,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik pengeluaran: $e');
    }
  }
}
