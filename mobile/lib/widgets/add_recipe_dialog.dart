import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/recipes_provider.dart';

class AddRecipeDialog extends ConsumerStatefulWidget {
  final String? initialUrl;
  const AddRecipeDialog({super.key, this.initialUrl});

  @override
  ConsumerState<AddRecipeDialog> createState() => _AddRecipeDialogState();
}

class _AddRecipeDialogState extends ConsumerState<AddRecipeDialog> {
  late TextEditingController _urlController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(recipeProcessorProvider.notifier).processUrl(_urlController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes to handle Side Effects (Close Dialog, Show Error)
    ref.listen(recipeProcessorProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        // Success
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receta "${next.value!.title}" añadida correctamente!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (next is AsyncError) {
        // Error
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final state = ref.watch(recipeProcessorProvider);
    final isLoading = state is AsyncLoading;

    return AlertDialog(
      title: const Text('Nueva Receta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pega el enlace de Instagram, YouTube o TikTok para analizar con IA.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL del video',
                hintText: 'https://www.instagram.com/reel/...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor introduce una URL';
                }
                if (!value.startsWith('http')) {
                  return 'Debe ser una URL válida';
                }
                return null;
              },
              enabled: !isLoading,
            ),
            if (isLoading) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              const Text("Analizando con Gemini AI...", style: TextStyle(fontSize: 12)),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: const Text('Procesar'),
        ),
      ],
    );
  }
}
