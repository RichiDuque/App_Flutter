import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Verificar si Bluetooth está disponible
  Future<bool> isBluetoothAvailable() async {
    try {
      return await _bluetooth.isAvailable ?? false;
    } catch (e) {
      return false;
    }
  }

  // Verificar si Bluetooth está habilitado
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isEnabled ?? false;
    } catch (e) {
      return false;
    }
  }

  // Solicitar habilitar Bluetooth
  Future<bool> requestEnable() async {
    try {
      final result = await _bluetooth.requestEnable();
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Solicitar permisos necesarios
  Future<bool> requestPermissions() async {
    try {
      // Para Android 12+ se necesitan permisos especiales
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      // Si falla (probablemente Android < 12), intentar con permisos legacy
      try {
        final status = await Permission.bluetooth.request();
        final locationStatus = await Permission.location.request();
        return status.isGranted && locationStatus.isGranted;
      } catch (e) {
        return false;
      }
    }
  }

  // Obtener dispositivos vinculados
  Future<List<BluetoothDeviceInfo>> getBondedDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return devices
          .map((device) => BluetoothDeviceInfo(
                nombre: device.name ?? 'Dispositivo desconocido',
                direccion: device.address,
                isBonded: true,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Descubrir nuevos dispositivos
  Stream<BluetoothDeviceInfo> startDiscovery() async* {
    try {
      await for (BluetoothDiscoveryResult result in _bluetooth.startDiscovery()) {
        yield BluetoothDeviceInfo(
          nombre: result.device.name ?? 'Dispositivo desconocido',
          direccion: result.device.address,
          isBonded: result.device.isBonded,
          rssi: result.rssi,
        );
      }
    } catch (e) {
      // Error en el descubrimiento
    }
  }

  // Cancelar descubrimiento
  Future<void> cancelDiscovery() async {
    try {
      await _bluetooth.cancelDiscovery();
    } catch (e) {
      // Error al cancelar
    }
  }

  // Verificar si se está descubriendo
  Future<bool> get isDiscovering async {
    try {
      return await _bluetooth.isDiscovering ?? false;
    } catch (e) {
      return false;
    }
  }
}

// Modelo para información de dispositivo Bluetooth
class BluetoothDeviceInfo {
  final String nombre;
  final String direccion;
  final bool isBonded;
  final int? rssi; // Intensidad de señal

  BluetoothDeviceInfo({
    required this.nombre,
    required this.direccion,
    this.isBonded = false,
    this.rssi,
  });

  String get displayName {
    if (nombre == 'Dispositivo desconocido') {
      return direccion;
    }
    return nombre;
  }

  String get signalStrength {
    if (rssi == null) return '';
    if (rssi! > -60) return 'Excelente';
    if (rssi! > -70) return 'Buena';
    if (rssi! > -80) return 'Regular';
    return 'Débil';
  }
}