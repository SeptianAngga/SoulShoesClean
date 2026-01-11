// Model untuk data user/admin
class UserModel {
  final String id;
  final String username;
  final String namaLengkap;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.namaLengkap,
    this.role = 'admin',
    this.createdAt,
  });

  // Method untuk mengubah data JSON dari database menjadi object UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      role: json['role'] ?? 'admin',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
}
