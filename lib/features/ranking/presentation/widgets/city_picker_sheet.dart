import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:conectenis_app/core/theme/app_tokens.dart';
import 'package:conectenis_app/features/ranking/data/cities_repository.dart';
import 'package:conectenis_app/shared/models/city.dart';
import 'package:conectenis_app/shared/utils/debounce.dart';
import 'package:conectenis_app/shared/widgets/empty_state.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';
import 'package:conectenis_app/shared/widgets/pressable.dart';

Future<City?> showCityPicker(BuildContext context) {
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _CityPickerSheet(),
  );
}

class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet();

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 400));
  AsyncValue<List<City>> _cities = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _debouncer.run(_search));
    _search();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _cities = const AsyncLoading());
    try {
      final list =
          await ref.read(citiesRepositoryProvider).search(_controller.text);
      if (mounted) setState(() => _cities = AsyncData(list));
    } catch (e, st) {
      if (mounted) setState(() => _cities = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Text(
                  'Escolher cidade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: t.text,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.inputBg,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Symbols.search_rounded, size: 19, color: t.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Buscar cidade…',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            hintStyle: TextStyle(fontSize: 14.5, color: t.muted),
                          ),
                          style: TextStyle(fontSize: 14.5, color: t.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _cities.when(
                  loading: () => const LoadingView(),
                  error: (e, _) =>
                      ErrorView(message: e.toString(), onRetry: _search),
                  data: (list) => list.isEmpty
                      ? const EmptyState(
                          icon: Symbols.location_city_rounded,
                          title: 'Nenhuma cidade encontrada',
                          subtitle: 'Tente outro nome.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final city = list[i];
                            return PressableScale(
                              scale: 0.985,
                              onTap: () => Navigator.pop(context, city),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Symbols.location_city_rounded,
                                        size: 18, color: t.muted),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        city.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: t.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
