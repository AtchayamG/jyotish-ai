// lib/features/settings/presentation/pages/add_profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class AddProfilePage extends StatefulWidget {
  const AddProfilePage({super.key});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  String _relationship = 'Spouse';
  String _gender = 'male';
  DateTime? _dob;
  TimeOfDay? _tob;
  bool _saving = false;

  static const _relationships = [
    'Spouse', 'Child', 'Parent', 'Sibling', 'Grandparent',
    'Friend', 'Partner', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink2,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18,
              color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Personal Details'),
            const SizedBox(height: 12),

            // Full Name
            _Field(
              label: 'Full Name',
              child: TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('e.g. Priya Sharma'),
                validator: (v) => v == null || v.trim().length < 2
                    ? 'Enter a valid name' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Relationship
            _Field(
              label: 'Relationship',
              child: DropdownButtonFormField<String>(
                value: _relationship,
                dropdownColor: AppColors.surface2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(null),
                items: _relationships.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r, style: const TextStyle(color: AppColors.textPrimary)),
                )).toList(),
                onChanged: (v) => setState(() => _relationship = v!),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            _Field(
              label: 'Gender',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(children: ['male', 'female', 'other'].map((g) {
                  final selected = _gender == g;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.gold.withAlpha(30) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: selected
                            ? Border.all(color: AppColors.gold.withAlpha(100))
                            : null,
                      ),
                      child: Text(
                        g[0].toUpperCase() + g.substring(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: selected ? AppColors.gold : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ));
                }).toList()),
              ),
            ),

            const SizedBox(height: 24),
            _SectionLabel('Birth Details'),
            const SizedBox(height: 12),

            // Date of Birth
            _Field(
              label: 'Date of Birth',
              child: InkWell(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 16,
                        color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Text(
                      _dob == null
                          ? 'Select date of birth'
                          : '${_dob!.day.toString().padLeft(2, '0')} '
                            '${_monthName(_dob!.month)} ${_dob!.year}',
                      style: TextStyle(
                        color: _dob == null ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time of Birth
            _Field(
              label: 'Time of Birth',
              child: InkWell(
                onTap: _pickTob,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time_outlined, size: 16,
                        color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Text(
                      _tob == null
                          ? 'Select time of birth (optional)'
                          : _tob!.format(context),
                      style: TextStyle(
                        color: _tob == null ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Place of Birth
            _Field(
              label: 'Place of Birth',
              child: TextFormField(
                controller: _placeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('City, State, Country'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter place of birth' : null,
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('Save Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.black)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '✦ This profile will be used for Kundli, matchmaking,\n'
              '   and horoscope readings on behalf of this person.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surface2,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surface2,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tob = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a date of birth'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _saving = true);

    // TODO: call API to save profile
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✓ Profile saved successfully'),
        backgroundColor: AppColors.teal,
      ));
      context.pop();
    }
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderDefault),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderDefault),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      child,
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: AppColors.gold,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary)),
    ]);
  }
}
