import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/order_model.dart';
import '../models/paket_model.dart';
import '../services/order_service.dart';
import '../services/paket_service.dart';

// Halaman untuk menambah atau mengedit order
class TambahOrderPage extends StatefulWidget {
  final OrderModel? order; // Optional for edit mode
  
  const TambahOrderPage({super.key, this.order});

  @override
  State<TambahOrderPage> createState() => _TambahOrderPageState();
}

class _TambahOrderPageState extends State<TambahOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaPelangganController = TextEditingController();
  final _noWhatsappController = TextEditingController();
  final _jenisSepatuController = TextEditingController();
  final _catatanController = TextEditingController();
  
  final _orderService = OrderService();
  final _paketService = PaketService();
  
  List<PaketModel> _paketList = [];
  PaketModel? _selectedPaket;
  bool _isLoading = false;
  bool _isLoadingPaket = true;

  bool get isEditMode => widget.order != null;

  @override
  void initState() {
    super.initState();
    _loadPaket();
    
    // Populate fields if edit mode
    if (widget.order != null) {
      _namaPelangganController.text = widget.order!.namaPelanggan;
      _noWhatsappController.text = widget.order!.noWhatsapp;
      _jenisSepatuController.text = widget.order!.jenisSepatu;
      _catatanController.text = widget.order!.catatan ?? '';
    }
  }

  // Method untuk memuat daftar paket cuci
  Future<void> _loadPaket() async {
    try {
      final paketList = await _paketService.getAllPaket();
      if (mounted) {
        setState(() {
          _paketList = paketList;
          _isLoadingPaket = false;
          
          // Set selected paket if edit mode
          if (widget.order != null && widget.order!.paketId != null) {
            _selectedPaket = _paketList.where((p) => p.id == widget.order!.paketId).firstOrNull;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPaket = false);
        _showError('Gagal memuat paket: $e');
      }
    }
  }

  // Method untuk menyimpan order (tambah baru atau update)
  Future<void> _simpanOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaket == null) {
      _showError('Pilih paket cuci terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditMode) {
        // Update existing order
        final updatedOrder = widget.order!.copyWith(
          namaPelanggan: _namaPelangganController.text.trim(),
          noWhatsapp: _noWhatsappController.text.trim(),
          jenisSepatu: _jenisSepatuController.text.trim(),
          paketId: _selectedPaket!.id,
          catatan: _catatanController.text.trim().isEmpty 
              ? null 
              : _catatanController.text.trim(),
        );
        await _orderService.updateOrder(updatedOrder);
          
        if (mounted) {
          _showSuccess('Order berhasil diperbarui');
          Navigator.pop(context, true);
        }
      } else {
        // Create new order
        final order = OrderModel(
          id: '',
          namaPelanggan: _namaPelangganController.text.trim(),
          noWhatsapp: _noWhatsappController.text.trim(),
          jenisSepatu: _jenisSepatuController.text.trim(),
          paketId: _selectedPaket!.id,
          status: 'Pending',
          catatan: _catatanController.text.trim().isEmpty 
              ? null 
              : _catatanController.text.trim(),
          tanggalMasuk: DateTime.now(),
        );
        await _orderService.createOrder(order);
        
        if (mounted) {
          _showSuccess('Order berhasil ditambahkan');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError('Gagal menyimpan order: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
  void dispose() {
    _namaPelangganController.dispose();
    _noWhatsappController.dispose();
    _jenisSepatuController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Order' : 'Tambah Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Isi data pelanggan dan pilih paket cuci',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Nama Pelanggan
              _buildLabel('Nama Pelanggan'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaPelangganController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama pelanggan',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pelanggan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // No WhatsApp
              _buildLabel('No. WhatsApp'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noWhatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Contoh: 08123456789',
                  prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No. WhatsApp tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Jenis Sepatu
              _buildLabel('Jenis Sepatu'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _jenisSepatuController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Nike Air Max, Adidas Ultraboost',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jenis sepatu tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Paket Cuci
              _buildLabel('Paket Cuci'),
              const SizedBox(height: 8),
              _isLoadingPaket
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<PaketModel>(
                        value: _selectedPaket,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        hint: Row(
                          children: [
                            Icon(Icons.local_laundry_service_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Pilih paket cuci',
                              style: TextStyle(color: AppColors.textLight),
                            ),
                          ],
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return _paketList.map<Widget>((paket) {
                            return Row(
                              children: [
                                const Icon(Icons.local_laundry_service_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${paket.namaPaket} - ${paket.hargaFormatted}',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        items: _paketList.map((paket) {
                          return DropdownMenuItem<PaketModel>(
                            value: paket,
                            child: Text(
                              '${paket.namaPaket} - ${paket.hargaFormatted}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPaket = value);
                        },
                      ),
                    ),
              const SizedBox(height: 20),
              
              // Catatan
              _buildLabel('Catatan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan khusus jika ada',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Simpan Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
