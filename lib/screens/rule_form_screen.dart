import 'package:flutter/material.dart';
import '../models/rule_model.dart';
import '../db/db_helper.dart';
import '/services/notification_service.dart';

class RuleFormScreen extends StatefulWidget {
  final Rule? rule;

  const RuleFormScreen({super.key, this.rule});

  @override
  State<RuleFormScreen> createState() => _RuleFormScreenState();
}

class _RuleFormScreenState extends State<RuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final dbHelper = DBHelper();
  bool _isLoading = false;
  int _selectedDuration = 30;

  final List<int> _presetDurations = [5, 15, 30, 60, 120, 240];

  final List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  List<int> _selectedDays = []; // Ubah ke List<int>

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _nameController.text = widget.rule!.name;
      _durationController.text = widget.rule!.durationMinutes.toString();
      _selectedDuration = widget.rule!.durationMinutes;
      _selectedDays = widget.rule!.activeDays; // Sudah List<int>
    } else {
      _durationController.text = _selectedDuration.toString();
      _selectedDays = List.generate(
        7,
        (index) => index,
      ); // Default semua hari aktif (0-6)
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 5,
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes menit';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes == 0
          ? '$hours jam'
          : '$hours jam $remainingMinutes menit';
    }
  }

  Future<void> saveRule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu hari aktif.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final name = _nameController.text.trim();
        final duration =
            int.tryParse(_durationController.text) ?? _selectedDuration;

        final rule = Rule(
          id: widget.rule?.id,
          name: name,
          durationMinutes: duration,
          createdAt: widget.rule?.createdAt ?? DateTime.now(),
          isCompleted: widget.rule?.isCompleted ?? false,
          isViolated: widget.rule?.isViolated ?? false,
          activeDays: _selectedDays, // Sudah benar List<int>
        );

        if (widget.rule == null) {
          final id = await dbHelper.insertRule(rule);

          await scheduleRuleNotification(
            id: id,
            title: name,
            duration: Duration(minutes: duration),
          );
          await schedulePreEndNotification(
            id: id + 100000,
            title: name,
            duration: Duration(minutes: duration),
          );

          _showSuccessMessage('Aturan berhasil ditambahkan!');
        } else {
          await dbHelper.updateRule(rule);

          await scheduleRuleNotification(
            id: rule.id!,
            title: name,
            duration: Duration(minutes: duration),
          );
          await schedulePreEndNotification(
            id: rule.id! + 100000,
            title: name,
            duration: Duration(minutes: duration),
          );

          _showSuccessMessage('Perubahan disimpan!');
        }

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
      _durationController.text = duration.toString();
    });
  }

  void _toggleDay(int index) {
    setState(() {
      if (_selectedDays.contains(index)) {
        _selectedDays.remove(index);
      } else {
        _selectedDays.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = widget.rule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Aturan' : 'Tambah Aturan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => Navigator.pushNamed(context, '/stat'),
            tooltip: 'Statistik',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Icon(
                      isEditMode ? Icons.edit_note : Icons.add_task,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Nama Aturan
                _buildLabel('Nama Aturan', theme),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Contoh: Mengerjakan PR Matematika',
                  icon: Icons.label,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Nama aturan wajib diisi'
                              : null,
                ),
                const SizedBox(height: 24),

                // Durasi
                _buildLabel('Durasi', theme),
                const SizedBox(height: 8),
                _buildPresetDurationList(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _durationController,
                  hint: 'Masukkan durasi (menit)',
                  icon: Icons.timer,
                  suffixText: 'menit',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Durasi wajib diisi';
                    }
                    final intValue = int.tryParse(value);
                    if (intValue == null) {
                      return 'Masukkan angka yang valid';
                    }
                    if (intValue < 3) {
                      return 'Minimal durasi adalah 3 menit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Pilih Hari Aktif
                _buildLabel('Hari Aktif', theme),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final selected = _selectedDays.contains(index);
                    return FilterChip(
                      label: Text(_days[index]),
                      selected: selected,
                      onSelected: (_) => _toggleDay(index),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : theme.colorScheme.primary,
                      ),
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                if (!isEditMode)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aturan ini berlaku selama ${_formatDuration(_selectedDuration)} '
                            'dan akan aktif pada hari-hari yang dipilih.',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : saveRule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    icon:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Icon(isEditMode ? Icons.save : Icons.add),
                    label: Text(
                      isEditMode ? 'Simpan Perubahan' : 'Tambah Aturan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                if (isEditMode) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixText: suffixText,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildPresetDurationList() {
    final theme = Theme.of(context);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _presetDurations.length,
        itemBuilder: (context, index) {
          final duration = _presetDurations[index];
          final isSelected = _selectedDuration == duration;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_formatDuration(duration)),
              selected: isSelected,
              onSelected: (_) => _selectDuration(duration),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              elevation: isSelected ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected
                          ? Colors.transparent
                          : theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
