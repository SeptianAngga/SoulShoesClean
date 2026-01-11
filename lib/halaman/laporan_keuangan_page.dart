import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../services/order_service.dart';
import '../services/pengeluaran_service.dart';
import '../models/pengeluaran_model.dart';

// Halaman untuk melihat laporan keuangan dan pendapatan
class LaporanKeuanganPage extends StatefulWidget {
  const LaporanKeuanganPage({super.key});

  @override
  State<LaporanKeuanganPage> createState() => _LaporanKeuanganPageState();
}

class _LaporanKeuanganPageState extends State<LaporanKeuanganPage> {
  final _orderService = OrderService();
  final _pengeluaranService = PengeluaranService();
  
  Map<String, dynamic> _pendapatanStats = {};
  Map<String, dynamic> _pengeluaranStats = {};
  List<PengeluaranModel> _recentPengeluaran = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Method untuk memuat data statistik keuangan
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pendapatanStats = await _orderService.getFinancialStats();
      final pengeluaranStats = await _pengeluaranService.getPengeluaranStats();
      final recentPengeluaran = await _pengeluaranService.getAllPengeluaran();
      
      if (mounted) {
        setState(() {
          _pendapatanStats = pendapatanStats;
          _pengeluaranStats = pengeluaranStats;
          _recentPengeluaran = recentPengeluaran;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Gagal memuat data: $e');
      }
    }
  }

  // Method untuk menampilkan dialog tambah pengeluaran
  Future<void> _showTambahPengeluaranDialog() async {
    final namaController = TextEditingController();
    final jumlahController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Pengeluaran', style: TextStyle(fontWeight: FontWeight.w600)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Item',
                    hintText: 'Contoh: Sabun cuci',
                    prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama item tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    hintText: 'Contoh: 50000',
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harga harus berupa angka';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      setDialogState(() => isLoading = true);
                      
                      try {
                        final pengeluaran = PengeluaranModel(
                          id: '',
                          namaItem: namaController.text.trim(),
                          jumlah: int.parse(jumlahController.text.trim()),
                        );
                        await _pengeluaranService.createPengeluaran(pengeluaran);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _showSuccess('Pengeluaran berhasil ditambahkan');
                          _loadData();
                        }
                      } catch (e) {
                        _showError('Gagal menambah pengeluaran: $e');
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk menghapus pengeluaran
  Future<void> _deletePengeluaran(PengeluaranModel pengeluaran) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengeluaran', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('Yakin ingin menghapus "${pengeluaran.namaItem}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _pengeluaranService.deletePengeluaran(pengeluaran.id);
        _showSuccess('Pengeluaran berhasil dihapus');
        _loadData();
      } catch (e) {
        _showError('Gagal menghapus pengeluaran: $e');
      }
    }
  }

  // Method untuk format angka menjadi format rupiah
  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendapatanTotal = _pendapatanStats['totalPendapatan'] ?? 0;
    final pengeluaranTotal = _pengeluaranStats['totalPengeluaran'] ?? 0;
    final labaBersih = pendapatanTotal - pengeluaranTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ringkasan Keuangan
                    _buildRingkasanCard(pendapatanTotal, pengeluaranTotal, labaBersih),
                    const SizedBox(height: 24),
                    
                    // Detail Pendapatan & Pengeluaran
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(
                          'Total Pendapatan',
                          pendapatanTotal,
                          '${_pendapatanStats['totalOrderSelesai'] ?? 0} order',
                          Icons.trending_up,
                          AppColors.success,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(
                          'Total Pengeluaran',
                          pengeluaranTotal,
                          '${_recentPengeluaran.length} item',
                          Icons.trending_down,
                          AppColors.danger,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Pengeluaran Section
                    _buildPengeluaranSection(),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahPengeluaranDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Pengeluaran', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildRingkasanCard(int pendapatan, int pengeluaran, int laba) {
    final isProfit = laba >= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit 
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? AppColors.success : AppColors.danger).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Laba Bersih',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(laba.abs()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (!isProfit)
            const Text(
              '(Rugi)',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int amount, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title, 
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            subtitle, 
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPengeluaranSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semua Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentPengeluaran.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 40, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada pengeluaran',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_recentPengeluaran.length, (index) {
            final item = _recentPengeluaran[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaItem,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          item.tanggalFormatted,
                          style: TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.jumlahFormatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deletePengeluaran(item),
                    icon: Icon(Icons.delete_outline, color: AppColors.textLight, size: 20),
                    tooltip: 'Hapus',
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
