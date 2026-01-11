// Model untuk data paket cuci
class PaketModel {
  final String id;
  final String namaPaket;
  final int harga;
  final String? deskripsi;
  final int estimasiHari;
  final DateTime? createdAt;

  PaketModel({
    required this.id,
    required this.namaPaket,
    required this.harga,
    this.deskripsi,
    this.estimasiHari = 3,
    this.createdAt,
  });

  // Method untuk mengubah data JSON dari database menjadi object PaketModel
  factory PaketModel.fromJson(Map<String, dynamic> json) {
    return PaketModel(
      id: json['id'] ?? '',
      namaPaket: json['nama_paket'] ?? '',
      harga: json['harga'] ?? 0,
      deskripsi: json['deskripsi'],
      estimasiHari: json['estimasi_hari'] ?? 3,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // Method untuk mengubah object PaketModel menjadi JSON untuk disimpan ke database
  Map<String, dynamic> toJson() {
    return {
      'nama_paket': namaPaket,
      'harga': harga,
      'deskripsi': deskripsi,
      'estimasi_hari': estimasiHari,
    };
  }

  // Getter untuk format harga (contoh: Rp 50.000)
  String get hargaFormatted {
    return 'Rp ${harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Getter untuk format estimasi (contoh: 3 hari)
  String get estimasiFormatted {
    return '$estimasiHari hari';
  }
}
