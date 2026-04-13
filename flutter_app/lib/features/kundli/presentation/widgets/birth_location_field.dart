// lib/features/kundli/presentation/widgets/birth_location_field.dart
// Simplified — Google Places removed
import "package:flutter/material.dart";
import "../../../../core/theme/app_theme.dart";

class BirthLocationField extends StatelessWidget {
  final Function(String, double, double) onLocationSelected;
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  const BirthLocationField({super.key, required this.onLocationSelected,
    required this.latCtrl, required this.lngCtrl});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Birth Location", style: AppTextStyles.bodySm),
    const SizedBox(height: 6),
    Row(children: [
      Expanded(child: TextFormField(
        controller: latCtrl, style: AppTextStyles.bodyMd,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: const InputDecoration(labelText: "Latitude", hintText: "13.0827"),
        onChanged: (v) {
          final lat = double.tryParse(v) ?? 13.0827;
          final lng = double.tryParse(lngCtrl.text) ?? 80.2707;
          onLocationSelected("Custom", lat, lng);
        },
      )),
      const SizedBox(width: 10),
      Expanded(child: TextFormField(
        controller: lngCtrl, style: AppTextStyles.bodyMd,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: const InputDecoration(labelText: "Longitude", hintText: "80.2707"),
        onChanged: (v) {
          final lat = double.tryParse(latCtrl.text) ?? 13.0827;
          final lng = double.tryParse(v) ?? 80.2707;
          onLocationSelected("Custom", lat, lng);
        },
      )),
    ]),
    const SizedBox(height: 4),
    Text("Default: Chennai (13.0827, 80.2707)", style: AppTextStyles.bodyXs),
  ]);
}
