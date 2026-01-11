import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../widgets/stat_card.dart';
import 'login_page.dart';
import 'tambah_order_page.dart';
import 'paket_cuci_page.dart';
import 'riwayat_page.dart';
import 'laporan_keuangan_page.dart';
import 'antrian_status_page.dart';
import 'pembayaran_page.dart';

// Halaman utama dashboard admin
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  final _orderService = OrderService();
  
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'proses': 0,
    'selesai': 0,
  };
  bool _isLoading = true;
  String _namaUser = '';
  String _role = 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Method untuk memuat data user dan statistik order
  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      final stats = await _orderService.getAllStats();
      
      if (mounted) {
        setState(() {
          _namaUser = user?.namaLengkap ?? 'Admin';
          _role = user?.role ?? 'admin';
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method untuk logout dengan konfirmasi
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),
                
                // Stats
                Text(
                  'Statistik Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStats(),
                const SizedBox(height: 32),
                
                // Menu
                Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row - Logo and App Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SoulShoes Clean',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Shoes Cleaning Service',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          // Bottom row - Welcome with Role
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selamat datang, $_namaUser',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _role == 'admin' ? 'Admin' : 'Pelanggan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Pending',
            value: _stats['pending'].toString(),
            icon: Icons.pending_outlined,
            color: AppColors.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Proses',
            value: _stats['proses'].toString(),
            icon: Icons.autorenew,
            color: AppColors.proses,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Selesai',
            value: _stats['selesai'].toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.selesai,
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    final menuItems = [
      // 1. Tambah order baru
      {
        'title': 'Tambah Order',
        'subtitle': 'Terima order baru dari pelanggan',
        'icon': Icons.add_box_outlined,
        'color': AppColors.success,
        'page': const TambahOrderPage(),
      },
      // 2. Lihat antrian & kerjakan
      {
        'title': 'Antrian & Status',
        'subtitle': 'Lihat urutan, update status & hapus',
        'icon': Icons.queue,
        'color': AppColors.info,
        'page': const AntrianStatusPage(),
      },
      // 3. Pembayaran
      {
        'title': 'Pembayaran',
        'subtitle': 'Proses bayar saat pelanggan ambil',
        'icon': Icons.payment,
        'color': AppColors.primary,
        'page': const PembayaranPage(),
      },
      // 4. Riwayat order selesai & lunas
      {
        'title': 'Riwayat',
        'subtitle': 'Order yang sudah selesai & dibayar',
        'icon': Icons.history,
        'color': AppColors.textSecondary,
        'page': const RiwayatPage(),
      },
      // 4. Laporan keuangan
      {
        'title': 'Laporan Keuangan',
        'subtitle': 'Rekap pendapatan',
        'icon': Icons.attach_money,
        'color': AppColors.success,
        'page': const LaporanKeuanganPage(),
      },
      // 5. Pengaturan paket
      {
        'title': 'Paket Cuci',
        'subtitle': 'Kelola paket & estimasi hari',
        'icon': Icons.local_laundry_service_outlined,
        'color': AppColors.primaryLight,
        'page': const PaketCuciPage(),
      },
    ];

    return Column(
      children: menuItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (item['color'] as Color).withValues(alpha:  0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => item['page'] as Widget),
                ).then((_) => _loadData());
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha:  0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
