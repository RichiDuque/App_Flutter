import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bluetooth_service.dart';

class BluetoothSearchDialog extends ConsumerStatefulWidget {
  const BluetoothSearchDialog({super.key});

  @override
  ConsumerState<BluetoothSearchDialog> createState() => _BluetoothSearchDialogState();
}

class _BluetoothSearchDialogState extends ConsumerState<BluetoothSearchDialog> {
  final BluetoothService _bluetoothService = BluetoothService();
  final List<BluetoothDeviceInfo> _dispositivos = [];
  bool _isScanning = false;
  bool _isBluetoothEnabled = false;
  String _mensaje = 'Iniciando búsqueda...';

  @override
  void initState() {
    super.initState();
    _inicializarBluetooth();
  }

  @override
  void dispose() {
    _bluetoothService.cancelDiscovery();
    super.dispose();
  }

  Future<void> _inicializarBluetooth() async {
    // Verificar si Bluetooth está disponible
    final isAvailable = await _bluetoothService.isBluetoothAvailable();
    if (!isAvailable) {
      setState(() {
        _mensaje = 'Bluetooth no disponible en este dispositivo';
      });
      return;
    }

    // Verificar si Bluetooth está habilitado
    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      setState(() {
        _mensaje = 'Habilitando Bluetooth...';
      });

      final enabled = await _bluetoothService.requestEnable();
      if (!enabled) {
        setState(() {
          _mensaje = 'Por favor habilita Bluetooth para continuar';
        });
        return;
      }
    }

    setState(() {
      _isBluetoothEnabled = true;
    });

    // Solicitar permisos
    final hasPermissions = await _bluetoothService.requestPermissions();
    if (!hasPermissions) {
      setState(() {
        _mensaje = 'Se requieren permisos de Bluetooth y ubicación';
      });
      return;
    }

    // Cargar dispositivos vinculados primero
    await _cargarDispositivosVinculados();

    // Iniciar búsqueda
    await _iniciarBusqueda();
  }

  Future<void> _cargarDispositivosVinculados() async {
    final vinculados = await _bluetoothService.getBondedDevices();
    setState(() {
      _dispositivos.clear();
      _dispositivos.addAll(vinculados);
    });
  }

  Future<void> _iniciarBusqueda() async {
    setState(() {
      _isScanning = true;
      _mensaje = 'Buscando dispositivos...';
    });

    try {
      await for (BluetoothDeviceInfo device in _bluetoothService.startDiscovery()) {
        // Evitar duplicados
        final existe = _dispositivos.any((d) => d.direccion == device.direccion);
        if (!existe) {
          setState(() {
            _dispositivos.add(device);
          });
        }
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Error en la búsqueda: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isScanning = false;
        if (_dispositivos.isEmpty) {
          _mensaje = 'No se encontraron dispositivos';
        } else {
          _mensaje = 'Búsqueda completada';
        }
      });
    }
  }

  Future<void> _detenerBusqueda() async {
    await _bluetoothService.cancelDiscovery();
    setState(() {
      _isScanning = false;
      _mensaje = 'Búsqueda detenida';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_searching, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Buscar Impresoras Bluetooth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Estado de búsqueda
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[850]?.withValues(alpha: 0.5),
              child: Row(
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  else
                    Icon(
                      _dispositivos.isEmpty ? Icons.bluetooth_disabled : Icons.bluetooth,
                      size: 16,
                      color: _dispositivos.isEmpty ? Colors.grey : Colors.blue,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mensaje,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_isScanning)
                    TextButton(
                      onPressed: _detenerBusqueda,
                      child: const Text('Detener'),
                    )
                  else if (_isBluetoothEnabled)
                    TextButton(
                      onPressed: _iniciarBusqueda,
                      child: const Text('Buscar'),
                    ),
                ],
              ),
            ),

            // Lista de dispositivos
            Flexible(
              child: _dispositivos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isScanning
                                  ? 'Buscando dispositivos...'
                                  : 'No se encontraron dispositivos',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Asegúrate de que la impresora\nesté encendida y en modo visible',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _dispositivos.length,
                      itemBuilder: (context, index) {
                        final dispositivo = _dispositivos[index];
                        return _buildDispositivoItem(dispositivo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispositivoItem(BluetoothDeviceInfo dispositivo) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            dispositivo.isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
            color: dispositivo.isBonded ? Colors.blue : Colors.blueAccent,
            size: 24,
          ),
        ),
        title: Text(
          dispositivo.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dispositivo.direccion,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            if (dispositivo.isBonded) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Vinculado',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (dispositivo.signalStrength.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Señal: ${dispositivo.signalStrength}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          Navigator.of(context).pop(dispositivo);
        },
      ),
    );
  }
}