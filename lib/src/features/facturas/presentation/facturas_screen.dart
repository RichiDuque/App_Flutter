import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:facturacion_app/src/features/auth/presentation/auth_controller.dart';
import 'package:facturacion_app/src/features/home/presentation/widgets/app_drawer.dart';
import 'package:facturacion_app/src/features/equipos/presentation/equipos_provider.dart';
import 'package:facturacion_app/src/core/widgets/connectivity_indicator.dart';
import 'package:facturacion_app/src/config/env.dart';
import 'facturas_provider.dart';
import '../domain/factura.dart';
import '../domain/devolucion.dart';
import 'widgets/filtro_usuarios_dialog.dart';
import 'widgets/selector_fechas_dialog.dart';
import 'factura_detalle_screen.dart';
import 'devolucion_detalle_screen.dart';

class FacturasScreen extends ConsumerWidget {
  const FacturasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final facturasAsync = ref.watch(facturasProvider);
    final busqueda = ref.watch(busquedaFacturasProvider);
    final usuariosSeleccionados = ref.watch(usuariosSeleccionadosProvider);
    final fechaSeleccionada = ref.watch(fechaSeleccionadaProvider);
    final isAdmin = authState.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'Facturas',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Botón de selector de fecha
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: fechaSeleccionada != null ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () async {
              final nuevaFecha = await showDialog<DateTime?>(
                context: context,
                builder: (context) => SelectorFechasDialog(
                  fechaSeleccionada: fechaSeleccionada,
                ),
              );
              if (nuevaFecha != null || nuevaFecha != fechaSeleccionada) {
                ref.read(fechaSeleccionadaProvider.notifier).state = nuevaFecha;
              }
            },
          ),
          // Botón de filtro de usuarios (solo para admin)
          if (isAdmin)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  if (usuariosSeleccionados.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${usuariosSeleccionados.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const FiltroUsuariosDialog(),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: () async {
              // Botón de debug temporal - PETICIÓN HTTP DIRECTA
              try {
                // Hacer petición HTTP directa usando la URL de Env
                final dio = Dio(BaseOptions(
                  baseUrl: Env.apiBaseUrl,
                  connectTimeout: const Duration(seconds: 8),
                  receiveTimeout: const Duration(seconds: 8),
                  headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer ${authState.token}",
                  },
                ));

                final response = await dio.get('/facturas');

                if (context.mounted) {
                  final data = response.data;
                  final facturasList = data is List ? data : [];

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[850],
                      title: Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.orange[400]),
                          const SizedBox(width: 8),
                          const Text('Debug: HTTP Directo', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Status: ${response.statusCode}', style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text('Data type: ${data.runtimeType}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                            const SizedBox(height: 8),
                            Text('Es lista: ${data is List}', style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text('Facturas en JSON: ${facturasList.length}',
                              style: TextStyle(color: facturasList.isEmpty ? Colors.red[300] : Colors.green[300])),
                            if (facturasList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Primera factura ID: ${facturasList[0]['id']}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                              const SizedBox(height: 4),
                              Text('Numero: ${facturasList[0]['numero_factura']}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK', style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[850],
                      title: const Text('Debug: Error HTTP', style: TextStyle(color: Colors.white)),
                      content: SingleChildScrollView(
                        child: Text('Error: $e', style: TextStyle(color: Colors.red[300], fontSize: 10)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK', style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(facturasProvider);
            },
          ),
          // Icono de conectividad
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: ConnectivityIcon(),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'facturas'),
      body: Column(
        children: [
          // Indicador de conectividad
          const ConnectivityIndicator(),
          // Banner con información del usuario y rol
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[850]!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Vista de Administrador' : 'Vista de Vendedor',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authState.user ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (fechaSeleccionada != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatFechaHeader(fechaSeleccionada),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ref.read(fechaSeleccionadaProvider.notifier).state =
                              null;
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isAdmin && usuariosSeleccionados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Filtrando ${usuariosSeleccionados.length} usuario(s)',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Barra de búsqueda
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o número...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[500]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  ref.read(busquedaFacturasProvider.notifier).state = value;
                },
              ),
            ),
          ),
          // Lista de facturas
          Expanded(
            child: facturasAsync.when(
              data: (facturas) {
                // Filtrar por búsqueda
                var facturasFiltradas = facturas;
                if (busqueda.isNotEmpty) {
                  final busquedaLower = busqueda.toLowerCase();
                  facturasFiltradas = facturas.where((f) {
                    return f.clienteNombre
                            ?.toLowerCase()
                            .contains(busquedaLower) ==
                        true ||
                        f.numeroFormateado.toLowerCase().contains(busquedaLower);
                  }).toList();
                }

                // Filtrar por fecha seleccionada
                if (fechaSeleccionada != null) {
                  facturasFiltradas = facturasFiltradas.where((f) {
                    return _isSameDay(f.fechaCreacion, fechaSeleccionada);
                  }).toList();
                }

                if (facturasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          busqueda.isNotEmpty || fechaSeleccionada != null
                              ? Icons.search_off
                              : Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getMensajeVacio(
                              busqueda, fechaSeleccionada, isAdmin, usuariosSeleccionados),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (fechaSeleccionada != null ||
                            usuariosSeleccionados.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(fechaSeleccionadaProvider.notifier).state =
                                  null;
                              ref
                                  .read(usuariosSeleccionadosProvider.notifier)
                                  .state = [];
                            },
                            icon: const Icon(Icons.clear_all,
                                color: Colors.greenAccent),
                            label: const Text(
                              'Limpiar filtros',
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Obtener compañeros de equipo ANTES del loop (para vendedores)
                final misCompanerosAsync =
                    !isAdmin ? ref.watch(misCompanerosProvider) : null;
                final companerosIds = <int>{};

                if (!isAdmin && misCompanerosAsync != null) {
                  misCompanerosAsync.whenData((companeros) {
                    companerosIds.addAll(companeros.map((c) => c.id));
                  });
                }

                // Agrupar facturas por día
                final facturasAgrupadas = _agruparPorDia(facturasFiltradas);
                final fechasOrdenadas = facturasAgrupadas.keys.toList()
                  ..sort((a, b) => b.compareTo(a)); // Más recientes primero

                return ListView.builder(
                  itemCount: fechasOrdenadas.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final fecha = fechasOrdenadas[index];
                    final facturasDelDia = facturasAgrupadas[fecha]!;

                    // Calcular el total del día y total de reembolsos
                    final totalFacturasDia = facturasDelDia.fold<double>(
                      0.0,
                      (sum, factura) => sum + factura.total,
                    );

                    final totalReembolsosDia = facturasDelDia.fold<double>(
                      0.0,
                      (sum, factura) {
                        // Sumar todos los reembolsos de esta factura
                        return sum + factura.devoluciones.fold<double>(
                          0.0,
                          (devSum, devolucion) => devSum + devolucion.total,
                        );
                      },
                    );

                    final totalNeto = totalFacturasDia - totalReembolsosDia;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header del día
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.greenAccent, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            color: Colors.greenAccent, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatFechaDia(fecha),
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${facturasDelDia.length} factura${facturasDelDia.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Totales del día
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Total facturas
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.receipt, color: Colors.green[300], size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Total Facturas:',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '\$${totalFacturasDia.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.green[300],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (totalReembolsosDia > 0) ...[
                                      const SizedBox(height: 6),
                                      // Total reembolsos
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.remove_circle, color: Colors.red[300], size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Total Reembolsos:',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '-\$${totalReembolsosDia.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.red[300],
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Divider(color: Colors.grey[700], height: 1),
                                      const SizedBox(height: 6),
                                      // Total neto
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 16),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Total Neto:',
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '\$${totalNeto.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else
                                      // Si no hay reembolsos, mostrar solo el total
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 16),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Total Neto:',
                                                  style: TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '\$${totalNeto.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Facturas del día
                        ...facturasDelDia.expand((factura) {
                          final widgets = <Widget>[
                            _buildFacturaCard(
                              context,
                              ref,
                              factura,
                              isAdmin,
                              authState.userId,
                              companerosIds,
                            ),
                          ];

                          // Agregar devoluciones si existen
                          if (factura.devoluciones.isNotEmpty) {
                            widgets.addAll(
                              factura.devoluciones.map((devolucion) =>
                                _buildDevolucionCard(context, factura, devolucion)
                              )
                            );
                          }

                          return widgets;
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar facturas',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(facturasProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Agrupar facturas por día
  Map<DateTime, List<Factura>> _agruparPorDia(List<Factura> facturas) {
    final Map<DateTime, List<Factura>> agrupadas = {};

    for (final factura in facturas) {
      final fecha = DateTime(
        factura.fechaCreacion.year,
        factura.fechaCreacion.month,
        factura.fechaCreacion.day,
      );

      if (!agrupadas.containsKey(fecha)) {
        agrupadas[fecha] = [];
      }
      agrupadas[fecha]!.add(factura);
    }

    return agrupadas;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMensajeVacio(String busqueda, DateTime? fechaSeleccionada,
      bool isAdmin, List<int> usuariosSeleccionados) {
    if (busqueda.isNotEmpty) {
      return 'No se encontraron facturas con "$busqueda"';
    }
    if (fechaSeleccionada != null) {
      return 'No hay facturas para ${_formatFechaHeader(fechaSeleccionada)}';
    }
    if (isAdmin && usuariosSeleccionados.isEmpty) {
      return 'No hay facturas registradas';
    }
    return 'No hay facturas para mostrar';
  }

  String _formatFechaHeader(DateTime fecha) {
    final now = DateTime.now();
    if (_isSameDay(fecha, now)) {
      return 'Hoy';
    } else if (_isSameDay(fecha, now.subtract(const Duration(days: 1)))) {
      return 'Ayer';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  String _formatFechaDia(DateTime fecha) {
    final now = DateTime.now();
    if (_isSameDay(fecha, now)) {
      return 'Hoy';
    } else if (_isSameDay(fecha, now.subtract(const Duration(days: 1)))) {
      return 'Ayer';
    } else {
      final dias = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final meses = [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${dias[fecha.weekday]} ${fecha.day} ${meses[fecha.month]}';
    }
  }

  Widget _buildFacturaCard(
    BuildContext context,
    WidgetRef ref,
    Factura factura,
    bool isAdmin,
    int? currentUserId,
    Set<int> companerosIds,
  ) {
    // Determinar si es una factura propia o de un compañero
    final bool isOwnInvoice = currentUserId != null && factura.usuarioId == currentUserId;
    final bool isTeammateInvoice = !isAdmin && companerosIds.contains(factura.usuarioId);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => FacturaDetalleScreen(factura: factura),
            ),
          );

          // Si se hizo un reembolso, refrescar la lista
          if (resultado == true && context.mounted) {
            ref.invalidate(facturasProvider);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            // Borde sutil para facturas de compañeros
            border: isTeammateInvoice && !isOwnInvoice
                ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Número de factura y estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Indicador de equipo para facturas de compañeros
                          if (isTeammateInvoice && !isOwnInvoice) ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.group,
                                size: 16,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              factura.numeroFormateado,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildEstadoBadge(factura.estado),
                  ],
                ),
                const SizedBox(height: 12),
                // Cliente
                Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey[500], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        factura.clienteNombre ?? 'Cliente #${factura.clienteId}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                // Usuario - visible para admin O para vendedores con facturas de compañeros
                if ((isAdmin || isTeammateInvoice) && factura.usuarioNombre != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isTeammateInvoice && !isOwnInvoice
                            ? Icons.group
                            : Icons.badge_outlined,
                        color: isTeammateInvoice && !isOwnInvoice
                            ? Colors.blueAccent
                            : Colors.grey[500],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOwnInvoice
                              ? 'Vendedor: ${factura.usuarioNombre} (Tú)'
                              : isTeammateInvoice
                                  ? 'Compañero: ${factura.usuarioNombre}'
                                  : 'Vendedor: ${factura.usuarioNombre}',
                          style: TextStyle(
                            color: isTeammateInvoice && !isOwnInvoice
                                ? Colors.blueAccent
                                : Colors.grey[400],
                            fontSize: 13,
                            fontWeight: isTeammateInvoice && !isOwnInvoice
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Hora y total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.grey[500], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _formatHora(factura.fechaCreacion),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${factura.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Mostrar descuento si existe
                if (factura.descuento > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Subtotal: \$${factura.subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Desc: -\$${factura.descuento.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    String label;

    switch (estado.toLowerCase()) {
      case 'completada':
      case 'finalizada':
        color = Colors.green;
        label = 'COMPLETADA';
        break;
      case 'pendiente':
        color = Colors.orange;
        label = 'PENDIENTE';
        break;
      case 'cancelada':
        color = Colors.red;
        label = 'CANCELADA';
        break;
      default:
        color = Colors.grey;
        label = estado.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatHora(DateTime fecha) {
    final hour = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    final minute = fecha.minute.toString().padLeft(2, '0');
    final period = fecha.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }

  Widget _buildDevolucionCard(BuildContext context, Factura factura, Devolucion devolucion) {
    return Container(
      margin: const EdgeInsets.only(left: 40, right: 8, top: 4, bottom: 4),
      child: Card(
        color: Colors.orange[900]?.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DevolucionDetalleScreen(
                  devolucionId: devolucion.id,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_return,
                  color: Colors.orange[300],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVOLUCIÓN',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatHora(devolucion.fecha),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-\$${devolucion.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}