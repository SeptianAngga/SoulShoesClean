import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/paket_model.dart';
import '../services/paket_service.dart';
import '../widgets/paket_card.dart';

// Halaman untuk mengelola paket cuci (CRUD)
class PaketCuciPage extends StatefulWidget {
  const PaketCuciPage({super.key});

  @override
  State<PaketCuciPage> createState() => _PaketCuciPageState();
}

class _PaketCuciPageState extends State<PaketCuciPage> {
  final _paketService = PaketService();
  List<PaketModel> _paketList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaket();
  }

  // Method untuk memuat daftar paket dari database
  Future<void> _loadPaket() async {
    try {
      final paketList = await _paketService.getAllPaket();
      if (mounted) {
        setState(() {
          _paketList = paketList;
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

  // Method untuk menampilkan dialog tambah/edit paket
  Future<void> _showPaketDialog({PaketModel? paket}) async {
    final namaController = TextEditingController(text: paket?.namaPaket ?? '');
    final hargaController = TextEditingController(
      text: paket?.harga.toString() ?? '',
    );
    final deskripsiController = TextEditingController(text: paket?.deskripsi ?? '');
    final estimasiController = TextEditingController(
      text: paket?.estimasiHari.toString() ?? '3',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            paket == null ? 'Tambah Paket' : 'Edit Paket',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Paket',
                      hintText: 'Contoh: Deep Clean',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama paket tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: hargaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga',
                      hintText: 'Contoh: 30000',
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: estimasiController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estimasi Hari',
                      hintText: 'Contoh: 3',
                      suffixText: 'hari',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Estimasi hari tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Estimasi harus berupa angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Deskripsi paket cuci',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      setDialogState(() => isLoading = true);
                      
                      try {
                        final newPaket = PaketModel(
                          id: paket?.id ?? '',
                          namaPaket: namaController.text.trim(),
                          harga: int.parse(hargaController.text.trim()),
                          estimasiHari: int.parse(estimasiController.text.trim()),
                          deskripsi: deskripsiController.text.trim().isEmpty
                              ? null
                              : deskripsiController.text.trim(),
                        );

                        if (paket == null) {
                          await _paketService.createPaket(newPaket);
                        } else {
                          await _paketService.updatePaket(paket.id, newPaket);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          _showSuccess(paket == null
                              ? 'Paket berhasil ditambahkan'
                              : 'Paket berhasil diperbarui');
                          _loadPaket();
                        }
                      } catch (e) {
                        _showError('Gagal menyimpan paket: $e');
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk menghapus paket dengan konfirmasi
  Future<void> _deletePaket(PaketModel paket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Paket',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Yakin ingin menghapus paket "${paket.namaPaket}"?',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paketService.deletePaket(paket.id);
        _showSuccess('Paket berhasil dihapus');
        _loadPaket();
      } catch (e) {
        _showError('Gagal menghapus paket: $e');
      }
    }
  }

  // Method untuk menampilkan pesan error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Method untuk menampilkan pesan sukses
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paket Cuci'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paketList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPaket,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _paketList.length,
                    itemBuilder: (context, index) {
                      final paket = _paketList[index];
                      return PaketCard(
                        paket: paket,
                        onEdit: () => _showPaketDialog(paket: paket),
                        onDelete: () => _deletePaket(paket),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaketDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Paket',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_laundry_service_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada paket cuci',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan paket baru dengan tombol di bawah',
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
