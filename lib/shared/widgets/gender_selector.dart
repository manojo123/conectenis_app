import 'package:flutter/material.dart';
import 'package:conectenis_app/core/theme/app_colors.dart';
import 'package:conectenis_app/shared/models/enums.dart';

IconData genderIcon(Gender gender) => switch (gender) {
      Gender.male => Icons.male,
      Gender.female => Icons.female,
    };

const genderMaleColor = Color(0xFFB3D9FF);
const genderFemaleColor = Color(0xFFFFCCE5);

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
    return Row(
      children: Gender.values.map((gender) {
        final isSelected = value == gender;
        final bg = gender == Gender.male ? genderMaleColor : genderFemaleColor;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: gender == Gender.male ? 8 : 0),
            child: Material(
              color: isSelected ? bg : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _select(gender),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        genderIcon(gender),
                        size: 26,
                        color: isSelected ? Colors.black87 : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        gender.label,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : AppColors.textPrimary,
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
