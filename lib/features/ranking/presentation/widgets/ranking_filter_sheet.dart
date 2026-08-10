import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/ranking/presentation/widgets/city_picker_sheet.dart';
import 'package:conectenis_app/features/ranking/presentation/widgets/ranking_filters.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/utils/ntrp_labels.dart';
import 'package:conectenis_app/shared/widgets/chip_row.dart';
import 'package:conectenis_app/shared/widgets/segmented_tabs.dart';

void showRankingFilterSheet({
  required BuildContext context,
  required RankingFilters filters,
  required ValueChanged<RankingFilters> onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) =>
        _RankingFilterSheet(filters: filters, onChanged: onChanged),
  );
}

class _RankingFilterSheet extends StatefulWidget {
  const _RankingFilterSheet({required this.filters, required this.onChanged});

  final RankingFilters filters;
  final ValueChanged<RankingFilters> onChanged;

  @override
  State<_RankingFilterSheet> createState() => _RankingFilterSheetState();
}

class _RankingFilterSheetState extends State<_RankingFilterSheet> {
  late RankingFilters _local = widget.filters;

  static const _ntrpOptions = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0];

  // Prototype scope order: Cidade · Estado · Brasil.
  static const _geoOrder = [
    RankingGeoScope.city,
    RankingGeoScope.state,
    RankingGeoScope.country,
  ];

  void _update(RankingFilters next) {
    setState(() => _local = next);
    widget.onChanged(next);
  }

  Future<void> _pickCity() async {
    final city = await showCityPicker(context);
    if (city == null || !mounted) return;
    _update(_local.copyWith(cityId: city.id, cityLabel: city.label));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: t.text,
                    ),
                  ),
                ),
                if (_local.hasActiveFilters)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _update(const RankingFilters()),
                    child: Text(
                      'Limpar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: t.accentText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label(t, 'ABRANGÊNCIA'),
            const SizedBox(height: 8),
            SegmentedTabs(
              labels: _geoOrder.map((g) => g.label).toList(),
              index: _geoOrder.indexOf(_local.geo),
              onChanged: (i) => _update(_local.copyWith(geo: _geoOrder[i])),
            ),
            if (_local.geo == RankingGeoScope.city) ...[
              const SizedBox(height: 14),
              _label(t, 'CIDADE'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickCity,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.surface2,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.location_city_rounded,
                          size: 18, color: t.muted),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _local.cityLabel ?? 'Minha cidade',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color:
                                _local.cityLabel != null ? t.text : t.muted,
                          ),
                        ),
                      ),
                      if (_local.cityLabel != null)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _update(_local.copyWith(clearCity: true)),
                          child: Icon(Symbols.close_rounded,
                              size: 16, color: t.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _label(t, 'FORMATO'),
            const SizedBox(height: 8),
            ChoiceChipRow(
              options: ['Todos', ...ChallengeFormat.values.map((f) => f.label)],
              selectedIndex: _local.format == null
                  ? 0
                  : ChallengeFormat.values.indexOf(_local.format!) + 1,
              dense: true,
              scrollable: true,
              onSelected: (i) => _update(
                i == 0
                    ? _local.copyWith(clearFormat: true)
                    : _local.copyWith(format: ChallengeFormat.values[i - 1]),
              ),
            ),
            const SizedBox(height: 14),
            _label(t, 'GÊNERO'),
            const SizedBox(height: 8),
            ChoiceChipRow(
              options: RankingGenderFilter.values.map((g) => g.label).toList(),
              selectedIndex: RankingGenderFilter.values.indexOf(_local.gender),
              dense: true,
              scrollable: true,
              onSelected: (i) =>
                  _update(_local.copyWith(gender: RankingGenderFilter.values[i])),
            ),
            const SizedBox(height: 14),
            _label(t, 'NÍVEL'),
            const SizedBox(height: 8),
            ChoiceChipRow(
              options: ['Todos', ..._ntrpOptions.map(ntrpValueLabel)],
              selectedIndex: _local.ntrpLevel == null
                  ? 0
                  : _ntrpOptions.indexOf(_local.ntrpLevel!) + 1,
              dense: true,
              scrollable: true,
              onSelected: (i) => _update(
                i == 0
                    ? _local.copyWith(clearNtrp: true)
                    : _local.copyWith(ntrpLevel: _ntrpOptions[i - 1]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(AppTokens t, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: t.disabled,
        ),
      );
}
