import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'facturacion_controller.dart';

class ComentarioScreen extends ConsumerStatefulWidget {
  final int productoId;
  final String? comentarioInicial;

  const ComentarioScreen({
    super.key,
    required this.productoId,
    this.comentarioInicial,
  });

  @override
  ConsumerState<ComentarioScreen> createState() => _ComentarioScreenState();
}

class _ComentarioScreenState extends ConsumerState<ComentarioScreen> {
  late TextEditingController _comentarioController;

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController(text: widget.comentarioInicial ?? '');
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  void _guardarComentario() {
    ref.read(facturacionControllerProvider.notifier).actualizarComentario(
          widget.productoId,
          _comentarioController.text,
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Agregar Comentario',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner informativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[800]!, Colors.grey[850]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.note_add,
                      color: Colors.greenAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instrucciones Especiales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Agrega notas o comentarios para este producto',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Campo de texto para el comentario
            TextField(
              controller: _comentarioController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Comentario',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Ej: Sin cebolla, extra queso...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              maxLines: 5,
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              onPressed: _guardarComentario,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'GUARDAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}