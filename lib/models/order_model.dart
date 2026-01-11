import 'package:intl/intl.dart';

// Model untuk data order/pesanan
class OrderModel {
  final String id;
  final String namaPelanggan;
  final String noWhatsapp;
  final String jenisSepatu;
  final String? paketId;
  final String status;
  final String statusPembayaran;
  final String? metodePembayaran;
  final String? catatan;
  final DateTime tanggalMasuk;
  final DateTime? tanggalSelesai;
  final DateTime? tanggalPembayaran;
  final DateTime? createdAt;
  
  // Data dari tabel paket_cuci (join)
  final String? namaPaket;
  final int? hargaPaket;
  final int? estimasiHari;

  OrderModel({
    required this.id,
    required this.namaPelanggan,
    this.noWhatsapp = '',
    required this.jenisSepatu,
    this.paketId,
    required this.status,
    this.statusPembayaran = 'Belum Dibayar',
    this.metodePembayaran,
    this.catatan,
    DateTime? tanggalMasuk,
    this.tanggalSelesai,
    this.tanggalPembayaran,
    DateTime? createdAt,
    this.namaPaket,
    this.hargaPaket,
    this.estimasiHari,
  }) : tanggalMasuk = tanggalMasuk ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  // Method untuk mengubah data JSON dari database menjadi object OrderModel
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      namaPelanggan: json['nama_pelanggan'] ?? '',
      noWhatsapp: json['no_whatsapp'] ?? '',
      jenisSepatu: json['jenis_sepatu'] ?? '',
      paketId: json['paket_id'],
      status: json['status'] ?? 'Pending',
      statusPembayaran: json['status_pembayaran'] ?? 'Belum Dibayar',
      metodePembayaran: json['metode_pembayaran'],
      catatan: json['catatan'],
      tanggalMasuk: json['tanggal_masuk'] != null 
          ? DateTime.parse(json['tanggal_masuk']) 
          : DateTime.now(),
      tanggalSelesai: json['tanggal_selesai'] != null 
          ? DateTime.parse(json['tanggal_selesai']) 
          : null,
      tanggalPembayaran: json['tanggal_pembayaran'] != null 
          ? DateTime.parse(json['tanggal_pembayaran']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      namaPaket: json['paket_cuci']?['nama_paket'],
      hargaPaket: json['paket_cuci']?['harga'],
      estimasiHari: json['paket_cuci']?['estimasi_hari'],
    );
  }

  // Method untuk mengubah object OrderModel menjadi JSON untuk disimpan ke database
  Map<String, dynamic> toJson() {
    return {
      'nama_pelanggan': namaPelanggan,
      'no_whatsapp': noWhatsapp,
      'jenis_sepatu': jenisSepatu,
      'paket_id': paketId,
      'status': status,
      'status_pembayaran': statusPembayaran,
      'metode_pembayaran': metodePembayaran,
      'catatan': catatan,
      'tanggal_masuk': DateFormat('yyyy-MM-dd').format(tanggalMasuk),
      'tanggal_selesai': tanggalSelesai != null 
          ? DateFormat('yyyy-MM-dd').format(tanggalSelesai!) 
          : null,
    };
  }

  // Getter untuk format tanggal masuk (contoh: 28 Des 2024)
  String get tanggalMasukFormatted {
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggalMasuk);
  }

  // Getter untuk format harga (contoh: Rp 50.000)
  String get hargaFormatted {
    if (hargaPaket == null) return '-';
    return 'Rp ${hargaPaket.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Getter untuk menghitung tanggal deadline
  DateTime get deadline {
    return tanggalMasuk.add(Duration(days: estimasiHari ?? 3));
  }

  // Getter untuk format tanggal deadline
  String get deadlineFormatted {
    return DateFormat('dd MMM yyyy', 'id_ID').format(deadline);
  }

  // Getter untuk menghitung sisa hari sampai deadline
  int get sisaHari {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDate.difference(today).inDays;
  }

  // Getter untuk menentukan prioritas berdasarkan sisa hari
  String get prioritas {
    if (sisaHari <= 1) return 'urgent';
    if (sisaHari <= 3) return 'normal';
    return 'rendah';
  }

  // Method untuk membuat salinan OrderModel dengan data yang diubah
  OrderModel copyWith({
    String? id,
    String? namaPelanggan,
    String? noWhatsapp,
    String? jenisSepatu,
    String? paketId,
    String? status,
    String? statusPembayaran,
    String? metodePembayaran,
    String? catatan,
    DateTime? tanggalMasuk,
    DateTime? tanggalSelesai,
    DateTime? tanggalPembayaran,
    DateTime? createdAt,
    String? namaPaket,
    int? hargaPaket,
    int? estimasiHari,
  }) {
    return OrderModel(
      id: id ?? this.id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      noWhatsapp: noWhatsapp ?? this.noWhatsapp,
      jenisSepatu: jenisSepatu ?? this.jenisSepatu,
      paketId: paketId ?? this.paketId,
      status: status ?? this.status,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      catatan: catatan ?? this.catatan,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      tanggalPembayaran: tanggalPembayaran ?? this.tanggalPembayaran,
      createdAt: createdAt ?? this.createdAt,
      namaPaket: namaPaket ?? this.namaPaket,
      hargaPaket: hargaPaket ?? this.hargaPaket,
      estimasiHari: estimasiHari ?? this.estimasiHari,
    );
  }
}
