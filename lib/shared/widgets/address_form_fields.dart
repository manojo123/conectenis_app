import 'package:conectenis_app/features/address/data/address_repository.dart';
import 'package:conectenis_app/shared/models/address_form_data.dart';
import 'package:conectenis_app/shared/models/address_lookup.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';
import 'package:conectenis_app/shared/utils/postal_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressFormFields extends ConsumerStatefulWidget {
  const AddressFormFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.requireNumber = true,
  });

  final AddressFormData data;
  final ValueChanged<AddressFormData> onChanged;
  final bool requireNumber;

  @override
  ConsumerState<AddressFormFields> createState() => _AddressFormFieldsState();
}

class _AddressFormFieldsState extends ConsumerState<AddressFormFields> {
  late final TextEditingController _postalCodeController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _complementController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;

  bool _lookingUp = false;
  String? _lookupError;

  @override
  void initState() {
    super.initState();
    _postalCodeController = TextEditingController(text: widget.data.formattedPostalCode);
    _streetController = TextEditingController(text: widget.data.street);
    _numberController = TextEditingController(text: widget.data.number);
    _complementController = TextEditingController(text: widget.data.complement);
    _neighborhoodController = TextEditingController(text: widget.data.neighborhood);
    _cityController = TextEditingController(text: widget.data.city);
    _stateController = TextEditingController(text: widget.data.state);
  }

  @override
  void dispose() {
    _postalCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _emit(AddressFormData data) => widget.onChanged(data);

  AddressFormData _currentData({bool? locationLocked}) {
    return widget.data.copyWith(
      postalCode: _postalCodeController.text,
      street: _streetController.text,
      number: _numberController.text,
      complement: _complementController.text,
      neighborhood: _neighborhoodController.text,
      city: _cityController.text,
      state: _stateController.text,
      locationLocked: locationLocked ?? widget.data.locationLocked,
    );
  }

  void _applyLookup(AddressLookup lookup) {
    _streetController.text = lookup.street;
    _neighborhoodController.text = lookup.neighborhood;
    _cityController.text = lookup.city;
    _stateController.text = lookup.state;
    if (lookup.complementHint != null &&
        lookup.complementHint!.isNotEmpty &&
        _complementController.text.isEmpty) {
      _complementController.text = lookup.complementHint!;
    }
    _postalCodeController.text = lookup.postalCode;
    _emit(_currentData(locationLocked: true));
    setState(() => _lookupError = null);
  }

  Future<void> _lookupPostalCode() async {
    final digits = normalizePostalCode(_postalCodeController.text);
    if (digits.length != 8) {
      setState(() {
        _lookupError = null;
        _emit(_currentData(locationLocked: false));
      });
      return;
    }

    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });

    try {
      final lookup = await ref.read(addressRepositoryProvider).lookupPostalCode(digits);
      if (!mounted) return;
      _applyLookup(lookup);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupError = e.toString();
        _emit(_currentData(locationLocked: false));
      });
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  InputDecoration _lockedDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: widget.data.locationLocked,
      fillColor: widget.data.locationLocked
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: _postalCodeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: InputDecoration(
            labelText: 'CEP',
            hintText: '00000-000',
            suffixIcon: _lookingUp
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _lookupPostalCode,
                    tooltip: 'Buscar CEP',
                  ),
          ),
          onChanged: (value) {
            final formatted = formatPostalCode(value);
            if (formatted != value) {
              _postalCodeController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            _emit(_currentData(locationLocked: false));
            if (normalizePostalCode(value).length == 8) {
              _lookupPostalCode();
            }
          },
        ),
        if (_lookupError != null) ...[
          const SizedBox(height: 8),
          Text(
            _lookupError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _streetController,
          decoration: const InputDecoration(labelText: 'Logradouro'),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _emit(_currentData()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _numberController,
                decoration: InputDecoration(
                  labelText: widget.requireNumber ? 'Número' : 'Número (opcional)',
                ),
                onChanged: (_) => _emit(_currentData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _complementController,
                decoration: const InputDecoration(labelText: 'Complemento'),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _emit(_currentData()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _neighborhoodController,
          decoration: _lockedDecoration('Bairro'),
          textCapitalization: TextCapitalization.words,
          readOnly: widget.data.locationLocked,
          onChanged: (_) => _emit(_currentData()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityController,
          decoration: _lockedDecoration('Cidade'),
          textCapitalization: TextCapitalization.words,
          readOnly: widget.data.locationLocked,
          onChanged: (_) => _emit(_currentData()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stateController,
          decoration: _lockedDecoration('Estado (UF)'),
          textCapitalization: TextCapitalization.characters,
          readOnly: widget.data.locationLocked,
          maxLength: 2,
          onChanged: (_) => _emit(_currentData()),
        ),
      ],
    );
  }
}

AddressFormData initialAddressFormData(UserProfile? user) {
  if (user == null) return const AddressFormData();
  return AddressFormData.fromUser(user);
}
