import 'package:intl/intl.dart';
import '../config/supabase_config.dart';
import '../models/order_model.dart';

// Service untuk mengelola data order
class OrderService {
  // Method untuk mengambil semua order dari database
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data order: $e');
    }
  }

  // Method untuk mengambil order yang sedang dikerjakan (untuk halaman antrian)
  Future<List<OrderModel>> getOrdersForQueue() async {
    try {
      // Hanya ambil order Pending dan Proses
      final response = await SupabaseConfig.client
          .from('orders')
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .neq('status', 'Selesai')
          .order('tanggal_masuk', ascending: true);

      final orders = (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      orders.sort((a, b) => a.deadline.compareTo(b.deadline));

      return orders;
    } catch (e) {
      throw Exception('Gagal mengambil data antrian: $e');
    }
  }

  // Method untuk mengambil order siap bayar (untuk halaman pembayaran)
  Future<List<OrderModel>> getOrdersForPayment() async {
    try {
      // Order yang Selesai tapi Belum Dibayar
      final response = await SupabaseConfig.client
          .from('orders')
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .eq('status', 'Selesai')
          .eq('status_pembayaran', 'Belum Dibayar')
          .order('tanggal_selesai', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pembayaran: $e');
    }
  }

  // Method untuk mengambil order yang sudah selesai dan lunas (untuk halaman riwayat)
  Future<List<OrderModel>> getCompletedOrders({DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = SupabaseConfig.client
          .from('orders')
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .eq('status', 'Selesai')
          .eq('status_pembayaran', 'Lunas');

      if (startDate != null) {
        query = query.gte('tanggal_masuk', DateFormat('yyyy-MM-dd').format(startDate));
      }
      if (endDate != null) {
        query = query.lte('tanggal_masuk', DateFormat('yyyy-MM-dd').format(endDate));
      }

      final response = await query.order('tanggal_pembayaran', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil riwayat order: $e');
    }
  }

  // Method untuk menambah order baru ke database
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .insert(order.toJson())
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah order: $e');
    }
  }

  // Method untuk mengupdate data order di database
  Future<OrderModel> updateOrder(OrderModel order) async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .update(order.toJson())
          .eq('id', order.id)
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengupdate order: $e');
    }
  }

  // Method untuk mengupdate status order (Pending -> Proses -> Selesai)
  Future<OrderModel> updateOrderStatus(String id, String status) async {
    try {
      Map<String, dynamic> updateData = {'status': status};
      
      if (status == 'Selesai') {
        updateData['tanggal_selesai'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }

      final response = await SupabaseConfig.client
          .from('orders')
          .update(updateData)
          .eq('id', id)
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengupdate status order: $e');
    }
  }

  // Method untuk memproses pembayaran order
  Future<OrderModel> processPayment(String id, String metodePembayaran) async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .update({
            'status_pembayaran': 'Lunas',
            'metode_pembayaran': metodePembayaran,
            'tanggal_pembayaran': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memproses pembayaran: $e');
    }
  }

  // Method untuk menghapus order dari database
  Future<void> deleteOrder(String id) async {
    try {
      await SupabaseConfig.client
          .from('orders')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus order: $e');
    }
  }

  // Method untuk mengambil statistik order (pending, proses, selesai)
  Future<Map<String, int>> getAllStats() async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select('status');

      final orders = response as List;
      
      int pending = 0;
      int proses = 0;
      int selesai = 0;

      for (var order in orders) {
        switch (order['status']) {
          case 'Pending':
            pending++;
            break;
          case 'Proses':
            proses++;
            break;
          case 'Selesai':
            selesai++;
            break;
        }
      }

      return {
        'total': orders.length,
        'pending': pending,
        'proses': proses,
        'selesai': selesai,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }

  // Method untuk mengambil statistik keuangan (pendapatan)
  Future<Map<String, dynamic>> getFinancialStats() async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfMonthStr = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);

      final response = await SupabaseConfig.client
          .from('orders')
          .select('tanggal_selesai, paket_cuci(harga)')
          .eq('status', 'Selesai');

      final orders = response as List;

      int totalPendapatan = 0;
      int pendapatanHariIni = 0;
      int pendapatanBulanIni = 0;
      int totalOrderSelesai = 0;
      int orderHariIni = 0;
      int orderBulanIni = 0;

      for (var order in orders) {
        final harga = order['paket_cuci']?['harga'] as int? ?? 0;
        final tanggalSelesaiStr = order['tanggal_selesai'] as String?;

        totalPendapatan += harga;
        totalOrderSelesai++;

        if (tanggalSelesaiStr != null) {
          if (tanggalSelesaiStr == todayStr) {
            pendapatanHariIni += harga;
            orderHariIni++;
          }

          if (tanggalSelesaiStr.compareTo(firstDayOfMonthStr) >= 0) {
            pendapatanBulanIni += harga;
            orderBulanIni++;
          }
        }
      }

      return {
        'totalPendapatan': totalPendapatan,
        'pendapatanHariIni': pendapatanHariIni,
        'pendapatanBulanIni': pendapatanBulanIni,
        'totalOrderSelesai': totalOrderSelesai,
        'orderHariIni': orderHariIni,
        'orderBulanIni': orderBulanIni,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik keuangan: $e');
    }
  }

  // Method untuk mengambil order selesai terbaru (untuk laporan keuangan)
  Future<List<OrderModel>> getRecentCompletedOrders({int limit = 10}) async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select('*, paket_cuci(nama_paket, harga, estimasi_hari)')
          .eq('status', 'Selesai')
          .order('tanggal_selesai', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil order selesai: $e');
    }
  }
}
