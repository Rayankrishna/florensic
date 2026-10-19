import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/provider/species.provider.dart';
import '../../locator.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/scanning_store.dart';
import '../../theme.dart';

/// `Pick the species` — the correction search for a scan the keeper
/// disagrees with.
///
/// Scientific and common names both work. A tapped row is resolved to a
/// catalogue species and becomes what the plant is kept as; the add then
/// sends `species_id`, which records the correction. Resolving answers in
/// well under a second, so there is no long wait to dress up.
class SpeciesSearchScreen extends StatefulWidget {
  const SpeciesSearchScreen({super.key});

  @override
  State<SpeciesSearchScreen> createState() => _SpeciesSearchScreenState();
}

class _SpeciesSearchScreenState extends State<SpeciesSearchScreen> {
  final ScanningStore _store = locator<ScanningStore>();
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _store.clearSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _store.suggestSpecies(value),
    );
  }

  Future<void> _pick(SpeciesSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    final ok = await _store.correctSpecies(suggestion);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.selectionClick();
      Navigator.of(context).pop(true);
    } else if (_store.correctionError != null) {
      AppToast.show(context, message: _store.correctionError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  0,
                ),
                child: NavHeader(
                  title: 'Pick the species',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xl,
                  AppSpacing.gutter,
                  0,
                ),
                child: AppTextField(
                  hint: 'Scientific or common name',
                  controller: _query,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                ),
              ),
              Observer(
                builder: (context) => SizedBox(
                  height: AppSpacing.md,
                  child: _store.isSuggesting || _store.isCorrecting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.gutter,
                            vertical: 5,
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.leaf,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Observer(
                  builder: (context) {
                    if (_store.suggestionQuery.length < 2) {
                      return const _Hint(
                        'Type two letters or more — "monst", "swiss cheese" '
                        'and "money plant" all work.',
                      );
                    }
                    final rows = _store.suggestions;
                    if (rows.isEmpty) {
                      return _store.isSuggesting
                          ? const SizedBox.shrink()
                          : const _Hint(
                              'No species matches that yet. Try the '
                              'scientific name.',
                            );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        AppSpacing.xxxl,
                      ),
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return TileRow(
                          icon: PgIcons.leaf,
                          title: row.scientificName,
                          detail: row.commonName.isNotEmpty
                              ? row.commonName
                              : row.matchedTerm.isNotEmpty
                              ? 'Matched "${row.matchedTerm}"'
                              : null,
                          trailing: const PgIcon(
                            PgIcons.chevronRight,
                            size: 20,
                            color: AppColors.inkMuted,
                          ),
                          onTap: _store.isCorrecting ? null : () => _pick(row),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        0,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.body15.copyWith(fontSize: 15),
      ),
    );
  }
}
