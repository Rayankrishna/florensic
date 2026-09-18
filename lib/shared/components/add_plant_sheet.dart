import 'package:flutter/material.dart';

import '../../domain/models/plant_species.dart';
import '../../theme.dart';
import '../widgets/plant_artwork.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Asks what the keeper wants to call this plant before it joins the
/// collection.
///
/// The name is optional — leaving it alone keeps the species' common name,
/// which is what every card and dashboard then shows.
class AddPlantSheet extends StatefulWidget {
  const AddPlantSheet({super.key, required this.species});

  final PlantSpecies species;

  /// Returns the chosen nickname, or `null` if the keeper backed out.
  static Future<String?> show(BuildContext context, PlantSpecies species) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C232B24),
      builder: (context) => AddPlantSheet(species: species),
    );
  }

  @override
  State<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<AddPlantSheet> {
  late final TextEditingController _nickname =
      TextEditingController(text: widget.species.commonName);

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_nickname.text.trim());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.ground,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.track,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: PlantArtwork(
                          glyph: widget.species.glyph,
                          ground: widget.species.ground,
                          inset: 0.16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name your plant',
                              style: AppText.title28.copyWith(fontSize: 23)),
                          const SizedBox(height: 3),
                          Text(
                            widget.species.latinName,
                            style: AppText.body15.copyWith(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Nickname',
                  hint: widget.species.commonName,
                  controller: _nickname,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Optional — leave it as it is to use the species name. You '
                  'can rename it at any time.',
                  style: AppText.body13.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(
                  label: 'Add to My Plants',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
