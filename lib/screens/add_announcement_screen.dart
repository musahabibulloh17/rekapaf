import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/school_news.dart';
import '../data/rekap_repository.dart';
import '../theme/rekap_theme.dart';

/// Screen untuk menambah/edit pengumuman sekolah
class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({super.key, this.announcement});

  final SchoolNews? announcement;


  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late NewsCategory _selectedCategory;
  File? _selectedImage;
  double _focalX = 0.0;
  double _focalY = 0.0;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.announcement?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.announcement?.description ?? '',
    );
    _selectedCategory =
        widget.announcement?.category ?? NewsCategory.pengumuman;
    _focalX = widget.announcement?.focalX ?? 0.0;
    _focalY = widget.announcement?.focalY ?? 0.0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan deskripsi harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.announcement != null) {
        // Edit mode
        await RekapRepository.instance.updateNews(
          id: widget.announcement!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory.name,
          date: widget.announcement!.date.toIso8601String(),
          imageFile: _selectedImage,
          focalX: _focalX,
          focalY: _focalY,
        );
      } else {
        // Add mode
        await RekapRepository.instance.addNews(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory.name,
          date: DateTime.now().toIso8601String(),
          imageFile: _selectedImage,
          focalX: _focalX,
          focalY: _focalY,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan pengumuman')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.announcement == null ? 'Tambah Pengumuman' : 'Edit Pengumuman',
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title field
              Text(
                'Judul Pengumuman',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Masukkan judul pengumuman...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 24),

              /// Description field
              Text(
                'Deskripsi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Masukkan deskripsi lengkap...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 6,
              ),
              const SizedBox(height: 24),

              /// Category dropdown
              Text(
                'Kategori',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<NewsCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: NewsCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(),
                  onChanged: (category) {
                    if (category != null) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              /// Image Picker
              Text(
                'Gambar (Opsional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                FocalPointPicker(
                  imageProvider: FileImage(_selectedImage!),
                  initialAlignment: Alignment(_focalX, _focalY),
                  onAlignmentChanged: (align) {
                    _focalX = align.x;
                    _focalY = align.y;
                  },
                )
              else if (widget.announcement?.imageUrl != null && widget.announcement!.imageUrl!.isNotEmpty)
                FocalPointPicker(
                  imageProvider: NetworkImage(widget.announcement!.fullImageUrl),
                  initialAlignment: Alignment(_focalX, _focalY),
                  onAlignmentChanged: (align) {
                    _focalX = align.x;
                    _focalY = align.y;
                  },
                )
              else
                GestureDetector(
                  onTap: () async {
                    final picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() {
                        _selectedImage = File(picked.path);
                        _focalX = 0.0;
                        _focalY = 0.0;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Pilih Gambar', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              if (_selectedImage != null || (widget.announcement?.imageUrl != null && widget.announcement!.imageUrl!.isNotEmpty))
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() {
                              _selectedImage = File(picked.path);
                              _focalX = 0.0;
                              _focalY = 0.0;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Ganti Gambar'),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _selectedImage = null;
                            _focalX = widget.announcement?.focalX ?? 0.0;
                            _focalY = widget.announcement?.focalY ?? 0.0;
                          }),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Batal Ganti', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 32),

              /// Action buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading 
                      ? const SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Simpan Pengumuman'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FocalPointPicker extends StatefulWidget {
  final ImageProvider imageProvider;
  final Alignment initialAlignment;
  final ValueChanged<Alignment> onAlignmentChanged;

  const FocalPointPicker({
    super.key,
    required this.imageProvider,
    this.initialAlignment = Alignment.center,
    required this.onAlignmentChanged,
  });

  @override
  State<FocalPointPicker> createState() => _FocalPointPickerState();
}

class _FocalPointPickerState extends State<FocalPointPicker> {
  late Alignment _alignment;

  @override
  void initState() {
    super.initState();
    _alignment = widget.initialAlignment;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _alignment += Alignment(-details.delta.dx * 0.01, -details.delta.dy * 0.01);
          _alignment = Alignment(
            _alignment.x.clamp(-1.0, 1.0),
            _alignment.y.clamp(-1.0, 1.0),
          );
        });
        widget.onAlignmentChanged(_alignment);
      },
      child: AspectRatio(
        aspectRatio: 2.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: widget.imageProvider,
                fit: BoxFit.cover,
                alignment: _alignment,
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.control_camera, color: Colors.white, size: 24),
                ),
              ),
              const Positioned(
                bottom: 8, left: 8, right: 8,
                child: Text(
                  'Geser gambar untuk menyesuaikan titik fokus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
