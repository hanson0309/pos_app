import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';

class EditPrinterDialog extends StatefulWidget {
  final PrinterConfig printer;

  const EditPrinterDialog({super.key, required this.printer});

  @override
  State<EditPrinterDialog> createState() => _EditPrinterDialogState();
}

class _EditPrinterDialogState extends State<EditPrinterDialog> {
  late final TextEditingController _nameController;
  late int _paperWidth;

  static const _paperWidths = [40, 58, 80];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.printer.name);
    _paperWidth = _paperWidths.contains(widget.printer.paperWidth)
        ? widget.printer.paperWidth
        : 80;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit printer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Printer name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Label / paper width',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _paperWidths.map((mm) {
                return ChoiceChip(
                  label: Text('${mm}mm'),
                  selected: _paperWidth == mm,
                  onSelected: (_) => setState(() => _paperWidth = mm),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              widget.printer.protocol == PrinterProtocol.tsplLabel
                  ? 'XP-320B: match your label roll (often 58mm or 80mm).'
                  : 'Receipt roll width for ESC/POS printers.',
              style: AppTheme.caption,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              widget.printer.copyWith(
                name: name,
                paperWidth: _paperWidth,
                updatedAt: DateTime.now(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
