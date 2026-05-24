import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
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
    return Row(
      children: Gender.values.map((gender) {
        final isSelected = selected.contains(gender);
        final bg = gender == Gender.male ? genderMaleColor : genderFemaleColor;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: gender == Gender.male ? 8 : 0),
            child: Material(
              color: isSelected ? bg : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _toggle(gender),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        genderIcon(gender),
                        size: 22,
                        color: isSelected ? Colors.black87 : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gender.label,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, size: 18, color: Colors.black87.withValues(alpha: 0.7)),
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
