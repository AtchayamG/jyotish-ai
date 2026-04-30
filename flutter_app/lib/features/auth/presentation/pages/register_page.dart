// lib/features/auth/presentation/pages/register_page.dart
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";

import "../bloc/auth_bloc.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/router/app_router.dart";
import "../../../../core/utils/places_service.dart";

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form       = GlobalKey<FormState>();
  final _name       = TextEditingController();
  final _email      = TextEditingController();
  final _pass       = TextEditingController();
  final _placeCtrl  = TextEditingController();
  final _placeFocus = FocusNode();
  bool _obscure     = true;

  // ── Birth detail selections ───────────────────────────────────────────────
  DateTime?   _dob;
  TimeOfDay?  _tob;
  String?     _placeLabel;
  double?     _lat, _lng, _tz;

  // ── Places autocomplete ───────────────────────────────────────────────────
  final PlacesService     _places      = PlacesService();
  List<PlacePrediction>   _predictions = [];
  bool                    _loadingPlaces = false;
  Timer?                  _debounce;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _pass.dispose();
    _placeCtrl.dispose(); _placeFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 6, 15),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: "SELECT DATE OF BIRTH",
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

  // ── Time picker ───────────────────────────────────────────────────────────

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _tob ?? const TimeOfDay(hour: 6, minute: 0),
      helpText: "SELECT TIME OF BIRTH",
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

  // ── Google Places autocomplete ────────────────────────────────────────────

  void _onPlaceInput(String value) {
    _debounce?.cancel();
    if (_placeLabel != null) {
      setState(() { _placeLabel = null; _lat = null; _lng = null; _tz = null; });
    }
    if (value.trim().length < 3) {
      setState(() { _predictions = []; _loadingPlaces = false; });
      return;
    }
    setState(() => _loadingPlaces = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await _places.autocomplete(value);
      if (!mounted) return;
      setState(() { _predictions = results; _loadingPlaces = false; });
    });
  }

  Future<void> _selectPlace(PlacePrediction p) async {
    _placeFocus.unfocus();
    setState(() {
      _placeCtrl.text = p.description;
      _placeLabel     = p.description;
      _predictions    = [];
      _loadingPlaces  = true;
    });
    final details = await _places.getDetails(p.placeId);
    if (!mounted) return;
    setState(() {
      _loadingPlaces = false;
      if (details != null) {
        _lat = details.latitude;
        _lng = details.longitude;
        _tz  = details.timezone;
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_dob == null) { _showSnack("Please select your Date of Birth"); return; }

    final dob = "${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}";
    final tob = _tob != null
        ? "${_tob!.hour.toString().padLeft(2, '0')}:${_tob!.minute.toString().padLeft(2, '0')}"
        : null;

    context.read<AuthBloc>().add(RegisterRequested(
      _email.text.trim(),
      _pass.text,
      _name.text.trim(),
      dateOfBirth:  dob,
      timeOfBirth:  tob,
      placeOfBirth: _placeLabel,
      latitude:     _lat,
      longitude:    _lng,
      timezone:     _tz,
    ));
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating));

  // ── Display labels ────────────────────────────────────────────────────────

  String get _dobLabel => _dob == null
      ? "Select Date of Birth *"
      : "${_dob!.day.toString().padLeft(2, '0')} / "
        "${_dob!.month.toString().padLeft(2, '0')} / "
        "${_dob!.year}";

  String get _tobLabel => _tob == null
      ? "Select Time of Birth  (optional)"
      : "${_tob!.hour.toString().padLeft(2, '0')} : "
        "${_tob!.minute.toString().padLeft(2, '0')}";

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) =>
      BlocListener<AuthBloc, AuthState>(
        listener: (_, state) {
          if (state is AuthError) _showSnack(state.message);
        },
        child: Scaffold(
          backgroundColor: AppColors.inkDeep,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text("JYOTISH AI", style: AppTextStyles.sectionTag),
                    const SizedBox(height: 6),
                    const Text("Create Account", style: AppTextStyles.displayMd),
                    const SizedBox(height: 4),
                    Text(
                      "Your birth details power personalised cosmic predictions",
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // ── Account details ──────────────────────────────────
                    _sectionLabel("ACCOUNT DETAILS"),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _name,
                      style: AppTextStyles.bodyMd,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                      ),
                      validator: (v) => v != null && v.trim().length >= 2
                          ? null : "Enter your name",
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.bodyMd,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                      ),
                      validator: (v) => v != null && v.contains("@")
                          ? null : "Enter a valid email",
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18, color: AppColors.textHint,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 8
                          ? null : "Minimum 8 characters",
                    ),
                    const SizedBox(height: 32),

                    // ── Birth details ────────────────────────────────────
                    _sectionLabel("BIRTH DETAILS"),
                    Text(
                      "Needed for Kundli, Dasha, Horoscope & AI predictions",
                      style: AppTextStyles.bodyXs
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Date of birth
                    _PickerTile(
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppColors.gold,
                      label: _dobLabel,
                      isSet: _dob != null,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),

                    // Time of birth
                    _PickerTile(
                      icon: Icons.schedule_outlined,
                      iconColor: AppColors.violetLight,
                      label: _tobLabel,
                      isSet: _tob != null,
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 12),

                    // Place of birth — Google Places autocomplete
                    _PlaceField(
                      controller: _placeCtrl,
                      focusNode: _placeFocus,
                      predictions: _predictions,
                      isLoading: _loadingPlaces,
                      confirmedLat: _lat,
                      confirmedLng: _lng,
                      confirmedTz: _tz,
                      onChanged: _onPlaceInput,
                      onSelect: _selectPlace,
                    ),

                    const SizedBox(height: 36),

                    // Submit button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (_, state) => ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submit,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.ink))
                            : const Text("Create Account  ✦"),
                      ),
                    ),
                    const SizedBox(height: 14),

                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text("Already have an account?  Sign In"),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: AppTextStyles.sectionTag),
      );
}

// ── Picker tile ───────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon, required this.iconColor,
    required this.label, required this.isSet, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSet
                  ? AppColors.gold.withOpacity(0.5)
                  : AppColors.borderSubtle,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isSet ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            Icon(
              isSet ? Icons.check_circle_outline : Icons.chevron_right,
              size: 18,
              color: isSet ? AppColors.gold : AppColors.textHint,
            ),
          ]),
        ),
      );
}

// ── Place autocomplete field ──────────────────────────────────────────────────

class _PlaceField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<PlacePrediction> predictions;
  final bool isLoading;
  final double? confirmedLat, confirmedLng, confirmedTz;
  final ValueChanged<String> onChanged;
  final Future<void> Function(PlacePrediction) onSelect;

  const _PlaceField({
    required this.controller, required this.focusNode,
    required this.predictions, required this.isLoading,
    required this.confirmedLat, required this.confirmedLng,
    required this.confirmedTz,
    required this.onChanged, required this.onSelect,
  });

  bool get _confirmed => confirmedLat != null;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              labelText: "Place of Birth",
              hintText: "Type a city name…",
              prefixIcon: const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.rose),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.gold),
                      ),
                    )
                  : _confirmed
                      ? const Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.gold)
                      : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _confirmed
                      ? AppColors.gold.withOpacity(0.5)
                      : AppColors.borderSubtle,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: onChanged,
          ),

          // Suggestions dropdown
          if (predictions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.ink2,
              child: Column(
                children: predictions.map((p) => InkWell(
                  onTap: () => onSelect(p),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    child: Row(children: [
                      const Icon(Icons.place_outlined,
                          size: 16, color: AppColors.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.description,
                            style: AppTextStyles.bodySm),
                      ),
                    ]),
                  ),
                )).toList(),
              ),
            ),
          ],

          // Confirmed location pill
          if (_confirmed) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.goldDim.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.my_location, size: 13, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Lat ${confirmedLat!.toStringAsFixed(4)}  "
                    "Lng ${confirmedLng!.toStringAsFixed(4)}  "
                    "UTC${confirmedTz! >= 0 ? '+' : ''}${confirmedTz!.toStringAsFixed(1)}",
                    style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                ),
              ]),
            ),
          ],
        ],
      );
}
