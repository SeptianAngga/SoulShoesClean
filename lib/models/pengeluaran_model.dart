import 'package:intl/intl.dart';

// Model untuk data pengeluaran
class PengeluaranModel {
  final String id;
  final String namaItem;
  final int jumlah;
  final DateTime tanggal;
  final DateTime? createdAt;

  PengeluaranModel({
    required this.id,
    required this.namaItem,
    required this.jumlah,
    DateTime? tanggal,
    this.createdAt,
  }) : tanggal = tanggal ?? DateTime.now();

  // Method untuk mengubah data JSON dari database menjadi object PengeluaranModel
  factory PengeluaranModel.fromJson(Map<String, dynamic> json) {
    return PengeluaranModel(
      id: json['id'] ?? '',
      namaItem: json['nama_item'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      tanggal: json['tanggal'] != null 
          ? DateTime.parse(json['tanggal']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // Method untuk mengubah object PengeluaranModel menjadi JSON untuk disimpan ke database
  Map<String, dynamic> toJson() {
    return {
      'nama_item': namaItem,
      'jumlah': jumlah,
      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
    };
  }

  // Getter untuk format tanggal (contoh: 28 Des 2024)
  String get tanggalFormatted {
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal);
  }

  // Getter untuk format jumlah (contoh: Rp 50.000)
  String get jumlahFormatted {
    return 'Rp ${jumlah.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
