import 'package:flutter/material.dart';

/// Shows a dialog to create a new watchlist. Returns the entered name or null.
Future<String?> showCreateWatchlistDialog(BuildContext context) {
  return _showNameDialog(
    context: context,
    title: 'New Watchlist',
    confirmLabel: 'Create',
  );
}

/// Shows a dialog to rename an existing watchlist. Returns the new name or null.
Future<String?> showRenameWatchlistDialog(
  BuildContext context,
  String currentName,
) {
  return _showNameDialog(
    context: context,
    title: 'Rename Watchlist',
    confirmLabel: 'Rename',
    initialValue: currentName,
  );
}

/// Shows a confirmation dialog to delete a watchlist. Returns true if confirmed.
Future<bool> showDeleteWatchlistConfirmation(
  BuildContext context,
  String watchlistName,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Watchlist'),
      content: Text('Delete "$watchlistName"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> _showNameDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. My Picks',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name cannot be empty';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}
