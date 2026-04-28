import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/impresoras_repository.dart';
import '../domain/impresora.dart';

// Provider del repositorio
final impresorasRepositoryProvider = Provider<ImpresorasRepository>((ref) {
  throw UnimplementedError('ImpresorasRepository debe ser inicializado con SharedPreferences');
});

// Provider para obtener la lista de impresoras
final impresorasProvider = FutureProvider<List<Impresora>>((ref) async {
  final repository = ref.watch(impresorasRepositoryProvider);
  return repository.obtenerImpresoras();
});

// Provider para obtener la impresora de recibos
final impresoraRecibosProvider = FutureProvider<Impresora?>((ref) async {
  final repository = ref.watch(impresorasRepositoryProvider);
  return repository.obtenerImpresoraRecibos();
});

// StateProvider para el estado de búsqueda Bluetooth
final bluetoothScanningProvider = StateProvider<bool>((ref) => false);

// StateProvider para dispositivos Bluetooth encontrados
final bluetoothDevicesProvider = StateProvider<List<BluetoothDevice>>((ref) => []);

// Modelo simple para dispositivos Bluetooth
class BluetoothDevice {
  final String nombre;
  final String direccion;

  const BluetoothDevice({
    required this.nombre,
    required this.direccion,
  });
}