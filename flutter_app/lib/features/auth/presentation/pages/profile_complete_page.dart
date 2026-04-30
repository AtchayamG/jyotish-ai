// lib/features/auth/presentation/pages/profile_complete_page.dart
//
// Shown to users who were created via the admin portal and have no birth
// details yet. They must fill DOB, TOB and Place before using the app.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/utils/places_service.dart';

class ProfileCompletePage extends StatefulWidget {
  const ProfileCompletePage({super.key});
  @override
  State<ProfileCompletePage> createState() => _ProfileCompletePageState();
}

class _ProfileCompletePageState extends State<ProfileCompletePage> {
  final _formKey = GlobalKey<FormState>();

  // Birth date / time
  DateTime? _dob;
  TimeOfDay? _tob;

  // Place
  final _placeController = TextEditingController();
  double? _lat, _lng, _tz;
  List<PlacePrediction> _suggestions = [];
  bool _loadingSuggestions = false;
  final _placesService = PlacesService();

  bool _submitting = false;

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'SELECT DATE OF BIRTH',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.ink,
            surface: AppColors.ink2,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogTheme(backgroundColor: AppColors.ink2),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── Time picker ─────────────────────────────────────────────────────────────

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _tob ?? const TimeOfDay(hour: 6, minute: 0),
      helpText: 'SELECT TIME OF BIRTH',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.ink,
            surface: AppColors.ink2,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogTheme(backgroundColor: AppColors.ink2),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tob = picked);
  }

  // ── Places autocomplete ──────────────────────────────────────────────────────

  Future<void> _onPlaceInput(String value) async {
    if (value.length < 3) { setState(() => _suggestions = []); return; }
    setState(() => _loadingSuggestions = true);
    final results = await _placesService.autocomplete(value);
    if (mounted) setState(() { _suggestions = results; _loadingSuggestions = false; });
  }

  Future<void> _selectPlace(PlacePrediction p) async {
    _placeController.text = p.description;
    setState(() => _suggestions = []);
    final details = await _placesService.getDetails(p.placeId);
    if (details != null && mounted) {
      setState(() { _lat = details.latitude; _lng = details.longitude; _tz = details.timezone; });
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _snack('Please select your date of birth');
      return;
    }
    if (_tob == null) {
      _snack('Please select your time of birth');
      return;
    }
    if (_lat == null || _lng == null) {
      _snack('Please select a place from the suggestions');
      return;
    }

    final dobStr = DateFormat('yyyy-MM-dd').format(_dob!);
    final tobStr =
        '${_tob!.hour.toString().padLeft(2, '0')}:${_tob!.minute.toString().padLeft(2, '0')}';

    context.read<AuthBloc>().add(UpdateBirthDetailsRequested(
      dateOfBirth:  dobStr,
      timeOfBirth:  tobStr,
      placeOfBirth: _placeController.text.trim(),
      latitude:     _lat!,
      longitude:    _lng!,
      timezone:     _tz ?? 5.5,
    ));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _snack(state.message);
          setState(() => _submitting = false);
        }
        if (state is AuthLoading) setState(() => _submitting = true);
        if (state is AuthAuthenticated) setState(() => _submitting = false);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.ink,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // Header
                    const Text('✦', style: TextStyle(color: AppColors.gold, fontSize: 28)),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Complete Your Profile',
                        style: AppTextStyles.displaySm),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enter your birth details to unlock personalised '
                      'horoscopes, kundli and AI predictions.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary, height: 1.6),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    Text('BIRTH DATE', style: AppTextStyles.sectionTag),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: AppColors.gold, size: 18),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            _dob == null
                                ? 'Tap to select date'
                                : DateFormat('d MMMM yyyy').format(_dob!),
                            style: _dob == null
                                ? AppTextStyles.bodySm
                                    .copyWith(color: AppColors.textHint)
                                : AppTextStyles.bodySm,
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    Text('TIME OF BIRTH', style: AppTextStyles.sectionTag),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _pickTime,
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: Row(children: [
                          const Icon(Icons.access_time_outlined,
                              color: AppColors.teal, size: 18),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            _tob == null
                                ? 'Tap to select time'
                                : _tob!.format(context),
                            style: _tob == null
                                ? AppTextStyles.bodySm
                                    .copyWith(color: AppColors.textHint)
                                : AppTextStyles.bodySm,
                          ),
                          const Spacer(),
                          Text('(24-hr)',
                              style: AppTextStyles.bodyXs
                                  .copyWith(color: AppColors.textHint)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    Text('PLACE OF BIRTH', style: AppTextStyles.sectionTag),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _placeController,
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        hintText: 'City, State, Country',
                        hintStyle:
                            AppTextStyles.bodySm.copyWith(color: AppColors.textHint),
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: AppColors.rose, size: 18),
                        suffixIcon: _loadingSuggestions
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.gold),
                                ),
                              )
                            : null,
                      ),
                      onChanged: _onPlaceInput,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),

                    // Suggestions
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.ink2,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: _suggestions
                              .map((p) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.place_outlined,
                                        color: AppColors.textHint, size: 16),
                                    title: Text(p.description,
                                        style: AppTextStyles.bodySm),
                                    onTap: () => _selectPlace(p),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    // Coords confirmed
                    if (_lat != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.teal, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Lat: ${_lat!.toStringAsFixed(4)}  '
                          'Lng: ${_lng!.toStringAsFixed(4)}  '
                          'UTC${_tz! >= 0 ? '+' : ''}${_tz!.toStringAsFixed(1)}',
                          style: AppTextStyles.monoSm
                              .copyWith(color: AppColors.teal),
                        ),
                      ]),
                    ],

                    const SizedBox(height: AppSpacing.x3l),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.ink),
                              )
                            : const Text('Save & Continue  ✦'),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            context.read<AuthBloc>().add(const LogoutRequested()),
                        child: Text('Sign out',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textHint)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
