import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../facturas/data/printer_service.dart';
import '../../configuracion/presentation/impresoras_provider.dart';
import '../../facturas/presentation/facturas_provider.dart';
import '../../facturas/domain/factura.dart';

class FacturaConfirmacionScreen extends ConsumerStatefulWidget {
  final int facturaId;
  final String numeroFactura;
  final double total;

  const FacturaConfirmacionScreen({
    Key? key,
    required this.facturaId,
    required this.numeroFactura,
    required this.total,
  }) : super(key: key);

  @override
  ConsumerState<FacturaConfirmacionScreen> createState() =>
      _FacturaConfirmacionScreenState();
}

class _FacturaConfirmacionScreenState
    extends ConsumerState<FacturaConfirmacionScreen>
    with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _imprimirFactura() async {
    try {
      // Obtener el valor de la impresora
      final impresoraAsync = ref.read(impresoraRecibosProvider);

      // Si está en loading, mostrar mensaje y esperar
      if (impresoraAsync.isLoading) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cargando configuración de impresora...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        // Esperar un momento y reintentar
        await Future.delayed(const Duration(milliseconds: 500));
        // Invalidar para forzar recarga
        ref.invalidate(impresoraRecibosProvider);
        return;
      }

      // Si hay error, mostrar mensaje
      if (impresoraAsync.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar impresora: ${impresoraAsync.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Obtener la impresora
      final impresora = impresoraAsync.value;

      if (impresora == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay impresora de recibos configurada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Imprimiendo factura...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Obtener la factura completa del backend
      final facturasRepo = ref.read(facturasRepositoryProvider);
      final facturaMap = await facturasRepo.obtenerDetalleFactura(widget.facturaId);
      final detalles = await facturasRepo.obtenerDetallesFactura(widget.facturaId);

      // Convertir Map a Factura
      final factura = Factura.fromJson(facturaMap);

      // Imprimir factura
      final printerService = PrinterService();
      final success = await printerService.imprimirFactura(
        printerAddress: impresora.direccionBluetooth!,
        factura: factura,
        detalles: detalles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura impresa exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Error al imprimir factura. Verifique la conexión con la impresora.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícono de éxito animado
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título
                      const Text(
                        'FACTURA FINALIZADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Número de factura
                      Text(
                        widget.numeroFactura,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currencyFormat.format(widget.total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Botón Imprimir
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _imprimirFactura,
                          icon: const Icon(Icons.print, size: 24),
                          label: const Text(
                            'IMPRIMIR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3460),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón Nueva Factura
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navegar a la pantalla principal (home)
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 24),
                          label: const Text(
                            'NUEVA FACTURA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}