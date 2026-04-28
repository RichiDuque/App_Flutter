import 'package:flutter/material.dart';
import '../../../clientes/domain/cliente.dart';

class ClienteSelectorDialog extends StatefulWidget {
  final List<Cliente> clientes;
  final int? clienteIdSeleccionado;
  final Function(int) onClienteSelected;

  const ClienteSelectorDialog({
    super.key,
    required this.clientes,
    required this.clienteIdSeleccionado,
    required this.onClienteSelected,
  });

  @override
  State<ClienteSelectorDialog> createState() => _ClienteSelectorDialogState();
}

class _ClienteSelectorDialogState extends State<ClienteSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> _clientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _clientesFiltrados = widget.clientes;
    _searchController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarClientes);
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _clientesFiltrados = widget.clientes;
      } else {
        _clientesFiltrados = widget.clientes.where((cliente) {
          final nombreMatch = cliente.nombreEstablecimiento.toLowerCase().contains(query);
          final propietarioMatch =
              cliente.propietario?.toLowerCase().contains(query) ?? false;
          final telefonoMatch =
              cliente.telefono?.toLowerCase().contains(query) ?? false;
          final emailMatch =
              cliente.email?.toLowerCase().contains(query) ?? false;
          return nombreMatch || propietarioMatch || telefonoMatch || emailMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Seleccionar Cliente',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            // Lista de clientes filtrados
            Expanded(
              child: _clientesFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron clientes',
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
                      itemCount: _clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = _clientesFiltrados[index];
                        final isSelected =
                            cliente.id == widget.clienteIdSeleccionado;

                        return ListTile(
                          title: Text(
                            cliente.nombreEstablecimiento,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: cliente.propietario != null && cliente.propietario!.isNotEmpty
                              ? Text(
                                  'Propietario: ${cliente.propietario}',
                                  style: TextStyle(color: Colors.grey[400]),
                                )
                              : cliente.telefono != null
                                  ? Text(
                                      cliente.telefono!,
                                      style: TextStyle(color: Colors.grey[400]),
                                    )
                                  : cliente.email != null
                                      ? Text(
                                          cliente.email!,
                                          style: TextStyle(color: Colors.grey[400]),
                                        )
                                      : null,
                          selected: isSelected,
                          selectedTileColor: Colors.green[900],
                          leading: CircleAvatar(
                            backgroundColor:
                                isSelected ? Colors.green[600] : Colors.grey[700],
                            child: Text(
                              cliente.iniciales,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            widget.onClienteSelected(cliente.id);
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