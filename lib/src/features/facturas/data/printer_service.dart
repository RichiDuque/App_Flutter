import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../domain/factura.dart';
import 'package:intl/intl.dart';

class PrinterService {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

  // Comandos ESC/POS
  static const ESC = 0x1B;
  static const GS = 0x1D;

  // Inicializar impresora
  List<int> _init() => [ESC, 0x40];

  // Alineación
  List<int> _alignLeft() => [ESC, 0x61, 0x00];
  List<int> _alignCenter() => [ESC, 0x61, 0x01];
  List<int> _alignRight() => [ESC, 0x61, 0x02];

  // Tamaño de texto
  List<int> _textNormal() => [ESC, 0x21, 0x00];
  List<int> _textLarge() => [ESC, 0x21, 0x30];
  List<int> _textBold() => [ESC, 0x45, 0x01];
  List<int> _textNoBold() => [ESC, 0x45, 0x00];

  // Salto de línea
  List<int> _newLine() => [0x0A];

  // Cortar papel
  List<int> _cut() => [GS, 0x56, 0x00];

  Future<bool> imprimirFactura({
    required String printerAddress,
    required Factura factura,
    required List<Map<String, dynamic>> detalles,
  }) async {
    try {
      // Conectar a la impresora
      BluetoothConnection? connection = await BluetoothConnection.toAddress(printerAddress);

      // Generar comandos de impresión
      List<int> bytes = [];

      // Inicializar
      bytes.addAll(_init());

      // Encabezado - Nombre de la distribuidora
      bytes.addAll(_alignCenter());
      bytes.addAll(_textBold());
      bytes.addAll(utf8.encode('Distribuidora Laura Andrea\n'));
      bytes.addAll(_textNoBold());

      // Sede
      bytes.addAll(_alignCenter());
      bytes.addAll(utf8.encode('Sede Principal en Istmina barrio\n'));
      bytes.addAll(utf8.encode('Cubia\n'));

      // Información de empleado
      bytes.addAll(_alignLeft());
      bytes.addAll(utf8.encode('Empleado: ${factura.usuarioNombre ?? 'Propietario'}\n'));

      // Información de cliente
      bytes.addAll(_alignLeft());
      bytes.addAll(utf8.encode('Cliente: ${factura.clienteNombre ?? 'N/A'}\n'));
      bytes.addAll(utf8.encode('--------------------------------\n'));

      // Productos
      bytes.addAll(_textBold());
      bytes.addAll(utf8.encode('PRODUCTOS\n'));
      bytes.addAll(_textNoBold());
      bytes.addAll(utf8.encode('--------------------------------\n'));

      for (var detalle in detalles) {
        final cantidad = detalle['cantidad'];
        final precioUnitarioRaw = detalle['precio_unitario'];
        final subtotalRaw = detalle['subtotal'];

        final precioUnitario = precioUnitarioRaw is String
            ? double.tryParse(precioUnitarioRaw) ?? 0.0
            : (precioUnitarioRaw is num ? precioUnitarioRaw.toDouble() : 0.0);

        final subtotal = subtotalRaw is String
            ? double.tryParse(subtotalRaw) ?? 0.0
            : (subtotalRaw is num ? subtotalRaw.toDouble() : 0.0);

        final producto = detalle['Producto'];
        final nombreProducto = producto != null ? producto['nombre'] ?? 'Producto' : 'Producto';

        // Nombre del producto
        bytes.addAll(utf8.encode('$nombreProducto\n'));

        // Cantidad x Precio = Subtotal
        final lineaCantidad = '$cantidad x ${_currencyFormat.format(precioUnitario)}';
        final lineaSubtotal = _currencyFormat.format(subtotal);

        // Alinear precio a la derecha
        final espacios = 32 - lineaCantidad.length - lineaSubtotal.length;
        final espaciosStr = ' ' * (espacios > 0 ? espacios : 1);

        bytes.addAll(utf8.encode('$lineaCantidad$espaciosStr$lineaSubtotal\n'));
      }

      bytes.addAll(utf8.encode('--------------------------------\n'));

      // Totales
      bytes.addAll(_alignLeft());
      bytes.addAll(utf8.encode(_formatLineTotales('Subtotal:', factura.subtotal)));

      if (factura.descuento > 0) {
        bytes.addAll(utf8.encode(_formatLineTotales('Descuento:', factura.descuento, isNegative: true)));
      }

      bytes.addAll(utf8.encode('--------------------------------\n'));
      bytes.addAll(_textBold());
      bytes.addAll(_textLarge());
      bytes.addAll(utf8.encode(_formatLineTotales('TOTAL:', factura.total)));
      bytes.addAll(_textNormal());
      bytes.addAll(_textNoBold());

      // Mensaje de agradecimiento
      bytes.addAll(_alignCenter());
      bytes.addAll(utf8.encode('Gracias por su compra\n'));

      bytes.addAll(_newLine());

      // Cortar papel
      bytes.addAll(_cut());

      // Enviar a la impresora
      connection.output.add(Uint8List.fromList(bytes));
      await connection.output.allSent;

      // Cerrar conexión
      await Future.delayed(const Duration(milliseconds: 500));
      connection.dispose();

      return true;
    } catch (e) {
      print('Error al imprimir: $e');
      return false;
    }
  }

  String _formatLineTotales(String label, double monto, {bool isNegative = false}) {
    final montoStr = '${isNegative ? '-' : ''}${_currencyFormat.format(monto)}';
    final espacios = 32 - label.length - montoStr.length;
    final espaciosStr = ' ' * (espacios > 0 ? espacios : 1);
    return '$label$espaciosStr$montoStr\n';
  }

  Future<bool> imprimirReciboPrueba({
    required String printerAddress,
  }) async {
    try {
      // Conectar a la impresora
      BluetoothConnection? connection = await BluetoothConnection.toAddress(printerAddress);

      // Generar comandos de impresión
      List<int> bytes = [];

      // Inicializar
      bytes.addAll(_init());

      // Encabezado - Nombre de la distribuidora
      bytes.addAll(_alignCenter());
      bytes.addAll(_textBold());
      bytes.addAll(utf8.encode('Distribuidora Laura Andrea\n'));
      bytes.addAll(_textNoBold());

      // Sede
      bytes.addAll(_alignCenter());
      bytes.addAll(utf8.encode('Sede Principal en Istmina barrio\n'));
      bytes.addAll(utf8.encode('Cubia\n'));

      // Información de empleado
      bytes.addAll(_alignLeft());
      bytes.addAll(utf8.encode('Empleado: Propietario\n'));

      // Línea separadora
      bytes.addAll(utf8.encode('--------------------------------\n'));
      bytes.addAll(_newLine());

      // Título del recibo en negrita
      bytes.addAll(_alignCenter());
      bytes.addAll(_textBold());
      bytes.addAll(_textLarge());
      bytes.addAll(utf8.encode('RECIBO DE PRUEBA\n'));
      bytes.addAll(_textNormal());
      bytes.addAll(_textNoBold());
      bytes.addAll(_newLine());

      // Mensaje de prueba
      bytes.addAll(_alignCenter());
      bytes.addAll(utf8.encode('Impresora configurada\n'));
      bytes.addAll(utf8.encode('correctamente\n'));
      bytes.addAll(_newLine());

      // Fecha de prueba
      bytes.addAll(_alignCenter());
      bytes.addAll(utf8.encode('${_dateFormat.format(DateTime.now())}\n'));
      bytes.addAll(_newLine());

      // Línea separadora
      bytes.addAll(_alignLeft());
      bytes.addAll(utf8.encode('--------------------------------\n'));

      // Mensaje de agradecimiento
      bytes.addAll(_alignCenter());
      bytes.addAll(utf8.encode('Gracias por su compra\n'));

      bytes.addAll(_newLine());

      // Cortar papel
      bytes.addAll(_cut());

      // Enviar a la impresora
      connection.output.add(Uint8List.fromList(bytes));
      await connection.output.allSent;

      // Cerrar conexión
      await Future.delayed(const Duration(milliseconds: 500));
      connection.dispose();

      return true;
    } catch (e) {
      print('Error al imprimir recibo de prueba: $e');
      return false;
    }
  }
}