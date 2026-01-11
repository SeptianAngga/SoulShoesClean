import '../config/supabase_config.dart';
import '../models/paket_model.dart';

// Service untuk mengelola data paket cuci
class PaketService {
  // Method untuk mengambil semua paket dari database
  Future<List<PaketModel>> getAllPaket() async {
    try {
      final response = await SupabaseConfig.client
          .from('paket_cuci')
          .select()
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => PaketModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data paket: $e');
    }
  }

  // Method untuk menambah paket baru ke database
  Future<PaketModel> createPaket(PaketModel paket) async {
    try {
      final response = await SupabaseConfig.client
          .from('paket_cuci')
          .insert(paket.toJson())
          .select()
          .single();

      return PaketModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah paket: $e');
    }
  }

  // Method untuk mengupdate data paket di database
  Future<PaketModel> updatePaket(String id, PaketModel paket) async {
    try {
      final response = await SupabaseConfig.client
          .from('paket_cuci')
          .update(paket.toJson())
          .eq('id', id)
          .select()
          .single();

      return PaketModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengupdate paket: $e');
    }
  }

  // Method untuk menghapus paket dari database
  Future<void> deletePaket(String id) async {
    try {
      await SupabaseConfig.client
          .from('paket_cuci')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus paket: $e');
    }
  }
}
