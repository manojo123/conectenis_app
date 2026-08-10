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

  // NTRP goes 0.0-5.0 - the full span means "no filter."
  static const _ntrpFloor = 0.0;
  static const _ntrpCeil = 5.0;
  late RangeValues _ntrpRange = RangeValues(
    _local.ntrpMin ?? _ntrpFloor,
    _local.ntrpMax ?? _ntrpCeil,
  );

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

  void _commitNtrpRange() {
    final isFullRange =
        _ntrpRange.start <= _ntrpFloor && _ntrpRange.end >= _ntrpCeil;
    _update(
      isFullRange
          ? _local.copyWith(clearNtrp: true)
          : _local.copyWith(ntrpMin: _ntrpRange.start, ntrpMax: _ntrpRange.end),
    );
  }

  SliderThemeData _sliderTheme(AppTokens t) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: t.accent,
      inactiveTrackColor: t.surface2,
      thumbColor: t.accent,
      overlayColor: t.tintAcc,
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
      trackHeight: 4,
    );
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
                    onTap: () {
                      setState(() => _ntrpRange = const RangeValues(_ntrpFloor, _ntrpCeil));
                      _update(const RankingFilters());
                    },
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
            Row(
              children: [
                _label(t, 'NÍVEL'),
                const Spacer(),
                Text(
                  _ntrpRange.start <= _ntrpFloor && _ntrpRange.end >= _ntrpCeil
                      ? 'Todos os níveis'
                      : '${ntrpValueLabel(_ntrpRange.start)} - ${ntrpValueLabel(_ntrpRange.end)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: _sliderTheme(t),
              child: RangeSlider(
                min: _ntrpFloor,
                max: _ntrpCeil,
                divisions: 10,
                values: _ntrpRange,
                onChanged: (v) => setState(() => _ntrpRange = v),
                onChangeEnd: (_) => _commitNtrpRange(),
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
