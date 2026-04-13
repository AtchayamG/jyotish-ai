// lib/features/home/presentation/pages/kundli_input_widget.dart
// Birth location field with Google Places autocomplete

import "package:flutter/material.dart";
import "package:google_places_flutter/google_places_flutter.dart";
import "package:google_places_flutter/model/prediction.dart";
import "../../../../core/theme/app_theme.dart";

class BirthLocationField extends StatefulWidget {
  final Function(String placeName, double lat, double lng) onLocationSelected;
  const BirthLocationField({super.key, required this.onLocationSelected});
  @override State<BirthLocationField> createState() => _BirthLocationFieldState();
}

class _BirthLocationFieldState extends State<BirthLocationField> {
  final _ctrl = TextEditingController();

  // Replace with your Google Maps API Key
  static const _googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Birth Location *", style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      GooglePlaceAutoCompleteTextField(
        textEditingController: _ctrl,
        googleAPIKey: _googleApiKey,
        inputDecoration: InputDecoration(
          hintText: "e.g. Chennai, Tamil Nadu",
          hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        debounceTime: 400,
        countries: const ["in"],  // Prioritise India results
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          final lat = double.tryParse(prediction.lat ?? "13.0827") ?? 13.0827;
          final lng = double.tryParse(prediction.lng ?? "80.2707") ?? 80.2707;
          final name = prediction.description ?? "";
          widget.onLocationSelected(name, lat, lng);
        },
        itemClick: (Prediction prediction) {
          _ctrl.text = prediction.description ?? "";
          _ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _ctrl.text.length));
        },
        seperatedBuilder: const Divider(color: AppColors.borderSubtle, height: 1),
        containerHorizontalPadding: 0,
        itemBuilder: (context, index, Prediction prediction) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface2,
          child: Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gold),
            const SizedBox(width: 10),
            Expanded(child: Text(
              prediction.description ?? "",
              style: AppTextStyles.bodyMd,
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        isCrossBtnShown: true,
      ),
    ],
  );
}
