import 'package:conectenis_app/core/theme/layout.dart';
import 'package:flutter/material.dart';

typedef ReportReasonOption = ({String value, String label});

Future<({String reason, String? details})?> showReportReasonSheet({
  required BuildContext context,
  required String title,
  required List<ReportReasonOption> reasons,
}) {
  return showModalBottomSheet<({String reason, String? details})>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ReportReasonSheetBody(title: title, reasons: reasons),
  );
}

class _ReportReasonSheetBody extends StatefulWidget {
  const _ReportReasonSheetBody({
    required this.title,
    required this.reasons,
  });

  final String title;
  final List<ReportReasonOption> reasons;

  @override
  State<_ReportReasonSheetBody> createState() => _ReportReasonSheetBodyState();
}

class _ReportReasonSheetBodyState extends State<_ReportReasonSheetBody> {
  String? _selected;
  final _detailsController = TextEditingController();

  bool get _needsDetails => _selected == 'other';

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == null) return;
    if (_needsDetails && _detailsController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o motivo com pelo menos 10 caracteres.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      (
        reason: _selected!,
        details: _needsDetails ? _detailsController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + screenBottomInset(context) + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.reasons
                  .map(
                    (r) => RadioListTile<String>(
                      title: Text(r.label, style: const TextStyle(fontSize: 14)),
                      value: r.value,
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_needsDetails) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalhes',
                hintText: 'Descreva o problema...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Enviar denúncia')),
        ],
      ),
    );
  }
}
