import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/core/theme/app_radii.dart';
import 'package:conectenis_app/shared/models/enums.dart';

IconData genderIcon(Gender gender) => switch (gender) {
      Gender.male => Icons.male,
      Gender.female => Icons.female,
    };

Color genderSelectedTint(Gender gender) => switch (gender) {
      Gender.male => AppColors.info.withValues(alpha: 0.25),
      Gender.female => AppColors.warning.withValues(alpha: 0.25),
    };

class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowEmpty = false,
  });

  final Gender? value;
  final ValueChanged<Gender?> onChanged;
  final bool allowEmpty;

  void _select(Gender gender) {
    if (allowEmpty && value == gender) {
      onChanged(null);
    } else {
      onChanged(gender);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: Gender.values.map((gender) {
        final isSelected = value == gender;
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
                onTap: () => _select(gender),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        genderIcon(gender),
                        size: 26,
                        color: scheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        gender.label,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
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
