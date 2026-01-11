import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme_config.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'tambah_order_page.dart';

// Halaman untuk melihat dan mengelola antrian order
class AntrianStatusPage extends StatefulWidget {
  const AntrianStatusPage({super.key});

  @override
  State<AntrianStatusPage> createState() => _AntrianStatusPageState();
}

class _AntrianStatusPageState extends State<AntrianStatusPage> {
  final _orderService = OrderService();
  List<OrderModel> _antrianList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAntrian();
  }

  // Method untuk memuat daftar antrian dari database
  Future<void> _loadAntrian() async {
    setState(() => _isLoading = true);
    try {
      final antrian = await _orderService.getOrdersForQueue();
      if (mounted) {
        setState(() {
          _antrianList = antrian;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Gagal memuat antrian: $e');
      }
    }
  }

  // Method untuk membuka halaman edit order
  Future<void> _editOrder(OrderModel order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahOrderPage(order: order),
      ),
    );
    if (result == true) {
      _loadAntrian();
    }
  }

  // Method untuk mengubah status order (Pending -> Proses -> Selesai)
  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    // Tampilkan dialog konfirmasi
    final confirm = await _showStatusConfirmDialog(order, newStatus);
    
    if (confirm != true) return;
    
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      _showSuccess('Status diubah ke $newStatus');
      
      // Jika selesai, kirim notifikasi WhatsApp
      if (newStatus == 'Selesai') {
        _sendWhatsAppNotification(order);
      }
      
      _loadAntrian();
    } catch (e) {
      _showError('Gagal mengubah status: $e');
    }
  }

  // Dialog konfirmasi perubahan status
  Future<bool?> _showStatusConfirmDialog(OrderModel order, String newStatus) {
    String title;
    String message;
    IconData icon;
    Color iconColor;
    String confirmText;

    switch (newStatus) {
      case 'Proses':
        title = 'Mulai Kerjakan?';
        message = 'Yakin ingin mengerjakan order "${order.namaPelanggan}"?\n\nSepatu: ${order.jenisSepatu}';
        icon = Icons.play_arrow;
        iconColor = AppColors.info;
        confirmText = 'Ya, Kerjakan';
        break;
      case 'Selesai':
        title = 'Tandai Selesai?';
        message = 'Yakin order "${order.namaPelanggan}" sudah selesai?\n\nSepatu: ${order.jenisSepatu}\n\nPelanggan akan diberitahu via WhatsApp.';
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        confirmText = 'Ya, Selesai';
        break;
      case 'Pending':
        title = 'Batalkan Proses?';
        message = 'Yakin ingin membatalkan proses order "${order.namaPelanggan}"?\n\nSepatu: ${order.jenisSepatu}\n\nStatus akan kembali ke Pending.';
        icon = Icons.undo;
        iconColor = AppColors.warning;
        confirmText = 'Ya, Batalkan';
        break;
      default:
        title = 'Ubah Status?';
        message = 'Yakin ingin mengubah status order?';
        icon = Icons.help_outline;
        iconColor = AppColors.textSecondary;
        confirmText = 'Ya';
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: iconColor),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Method untuk mengirim notifikasi WhatsApp ke pelanggan
  Future<void> _sendWhatsAppNotification(OrderModel order) async {
    // Format nomor WhatsApp (hapus karakter non-digit dan tambah kode negara)
    String phone = order.noWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}'; // Ganti 0 dengan 62 untuk Indonesia
    }
    
    // Buat pesan nota
    final message = '''
*NOTA SOULSHOES CLEAN*
================================

Halo ${order.namaPelanggan}!

Sepatu Anda sudah selesai dicuci dan *siap diambil*!

*Detail Order:*
- Tanggal Masuk: ${order.tanggalMasukFormatted}
- Sepatu: ${order.jenisSepatu}
- Paket: ${order.namaPaket ?? '-'}
- Harga: ${order.hargaFormatted}

*Status:* SELESAI

Silakan datang ke outlet kami untuk mengambil sepatu Anda.

Terima kasih telah mempercayakan sepatu Anda kepada *SoulShoes Clean*!

================================
''';
    
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    
    // Tanya user apakah mau kirim WhatsApp
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.chat, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Kirim WhatsApp?'),
          ],
        ),
        content: Text('Kirim notifikasi ke ${order.namaPelanggan} bahwa sepatu sudah siap diambil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Nanti', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Kirim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        // Coba buka WhatsApp app
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: buka di browser
          await launchUrl(url, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        _showError('Tidak dapat membuka WhatsApp: $e');
      }
    }
  }

  // Method untuk menghapus order dengan konfirmasi
  Future<void> _deleteOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Order', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('Yakin ingin menghapus order "${order.namaPelanggan}"?\n\nSepatu: ${order.jenisSepatu}'),
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
        await _orderService.deleteOrder(order.id);
        _showSuccess('Order berhasil dihapus');
        _loadAntrian();
      } catch (e) {
        _showError('Gagal menghapus order: $e');
      }
    }
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

  Color _getPriorityColor(String prioritas) {
    switch (prioritas) {
      case 'urgent':
        return AppColors.danger;
      case 'normal':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  IconData _getPriorityIcon(String prioritas) {
    switch (prioritas) {
      case 'urgent':
        return Icons.priority_high;
      case 'normal':
        return Icons.schedule;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getPriorityLabel(String prioritas) {
    switch (prioritas) {
      case 'urgent':
        return 'URGENT';
      case 'normal':
        return 'NORMAL';
      default:
        return 'RENDAH';
    }
  }

  String _getSisaHariText(int sisaHari) {
    if (sisaHari < 0) {
      return 'Terlambat ${-sisaHari} hari!';
    } else if (sisaHari == 0) {
      return 'Deadline HARI INI!';
    } else if (sisaHari == 1) {
      return 'Deadline BESOK!';
    } else {
      return 'Sisa $sisaHari hari';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Antrian & Status'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _antrianList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAntrian,
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      _buildSummary(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _antrianList.length,
                          itemBuilder: (context, index) {
                            final order = _antrianList[index];
                            return _buildAntrianCard(order, index + 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummary() {
    int urgent = _antrianList.where((o) => o.prioritas == 'urgent').length;
    int normal = _antrianList.where((o) => o.prioritas == 'normal').length;
    int rendah = _antrianList.where((o) => o.prioritas == 'rendah').length;
    int pending = _antrianList.where((o) => o.status == 'Pending').length;
    int proses = _antrianList.where((o) => o.status == 'Proses').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Prioritas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Urgent', urgent, AppColors.danger),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              _buildSummaryItem('Normal', normal, AppColors.warning),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              _buildSummaryItem('Rendah', rendah, AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Pending', pending, AppColors.pending),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              _buildSummaryItem('Proses', proses, AppColors.proses),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAntrianCard(OrderModel order, int nomorAntrian) {
    final priorityColor = _getPriorityColor(order.prioritas);
    final sisaHari = order.sisaHari;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sisaHari <= 0 ? AppColors.danger.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Nomor antrian
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#$nomorAntrian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                    Icon(
                      _getPriorityIcon(order.prioritas),
                      color: priorityColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
              // Detail order
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama pelanggan + Badge prioritas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.namaPelanggan,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPriorityLabel(order.prioritas),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // No WhatsApp
                      if (order.noWhatsapp.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              order.noWhatsapp,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Jenis sepatu
                      Row(
                        children: [
                          Icon(Icons.sports_gymnastics, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.jenisSepatu,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Paket + Status
                      Row(
                        children: [
                          Icon(Icons.local_laundry_service, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            order.namaPaket ?? '-',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: order.status == 'Proses' 
                                  ? AppColors.info.withValues(alpha: 0.1) 
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: order.status == 'Proses' ? AppColors.info : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Catatan (jika ada)
                      if (order.catatan != null && order.catatan!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note_alt_outlined, size: 12, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.catatan!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Tanggal Masuk dan Deadline
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            'Masuk: ${order.tanggalMasukFormatted}',
                            style: TextStyle(fontSize: 10, color: AppColors.textLight),
                          ),
                          Text(
                            'Deadline: ${order.deadlineFormatted}',
                            style: TextStyle(fontSize: 10, color: AppColors.textLight),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sisaHari <= 1 
                                  ? AppColors.danger.withValues(alpha: 0.1) 
                                  : AppColors.textLight.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getSisaHariText(sisaHari),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: sisaHari <= 1 ? AppColors.danger : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Tombol Aksi
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Edit button
                IconButton(
                  onPressed: () => _editOrder(order),
                  icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.info),
                  tooltip: 'Edit Order',
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteOrder(order),
                  icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                  tooltip: 'Hapus Order',
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                // Status buttons
                if (order.status == 'Pending')
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateStatus(order, 'Proses'),
                      icon: Icon(Icons.play_arrow, size: 18, color: AppColors.info),
                      label: Text(
                        'KERJAKAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ),
                if (order.status == 'Proses')
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateStatus(order, 'Selesai'),
                      icon: Icon(Icons.check_circle, size: 18, color: AppColors.success),
                      label: Text(
                        'SELESAI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                if (order.status == 'Proses')
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                if (order.status == 'Proses')
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateStatus(order, 'Pending'),
                      icon: Icon(Icons.undo, size: 18, color: AppColors.textSecondary),
                      label: Text(
                        'BATAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada antrian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua order sudah selesai 🎉',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
