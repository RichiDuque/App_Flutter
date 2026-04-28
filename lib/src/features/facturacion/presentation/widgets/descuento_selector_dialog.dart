import 'package:flutter/material.dart';
import '../../../descuentos/domain/descuento.dart';

class DescuentoSelectorDialog extends StatelessWidget {
  final List<Descuento> descuentos;
  final int? descuentoIdSeleccionado;
  final Function(int?) onDescuentoSelected;

  const DescuentoSelectorDialog({
    super.key,
    required this.descuentos,
    required this.descuentoIdSeleccionado,
    required this.onDescuentoSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Seleccionar Descuento',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            // Opción "Sin descuento"
            ListTile(
              title: const Text(
                'Sin descuento',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '0% de descuento',
                style: TextStyle(color: Colors.grey[400]),
              ),
              selected: descuentoIdSeleccionado == null,
              selectedTileColor: Colors.green[900],
              leading: CircleAvatar(
                backgroundColor: descuentoIdSeleccionado == null
                    ? Colors.green[600]
                    : Colors.grey[700],
                child: const Icon(
                  Icons.block,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onTap: () {
                onDescuentoSelected(null);
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.grey, height: 1),
            // Lista de descuentos
            Expanded(
              child: descuentos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.discount_outlined,
                              size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay descuentos disponibles',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: descuentos.length,
                      itemBuilder: (context, index) {
                        final descuento = descuentos[index];
                        final isSelected =
                            descuento.id == descuentoIdSeleccionado;

                        return ListTile(
                          title: Text(
                            descuento.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${descuento.porcentaje.toStringAsFixed(0)}% de descuento',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.green[900],
                          leading: CircleAvatar(
                            backgroundColor:
                                isSelected ? Colors.green[600] : Colors.grey[700],
                            child: Text(
                              '${descuento.porcentaje.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            onDescuentoSelected(descuento.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}