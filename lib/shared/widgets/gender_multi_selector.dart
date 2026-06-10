import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/shared/models/enums.dart';
import 'package:conectenis_app/shared/widgets/gender_selector.dart';

class GenderMultiSelector extends StatelessWidget {
  const GenderMultiSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<Gender> selected;
  final ValueChanged<Set<Gender>> onChanged;

  void _toggle(Gender gender) {
    final next = Set<Gender>.from(selected);
    if (next.contains(gender)) {
      next.remove(gender);
    } else {
      next.add(gender);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: Gender.values.map((gender) {
        final isSelected = selected.contains(gender);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: gender == Gender.male ? 8 : 0),
            child: Material(
              color: isSelected ? genderSelectedTint(gender) : scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : scheme.outline,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => _toggle(gender),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        genderIcon(gender),
                        size: 22,
                        color: scheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gender.label,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Gender? genderPreferenceFromSet(Set<Gender> selected) {
  if (selected.length == 1) return selected.first;
  return null;
}
