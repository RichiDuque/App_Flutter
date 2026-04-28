import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Servicio para detectar y monitorear la conectividad a Internet
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetConnection = InternetConnection();

  StreamController<bool>? _connectionStatusController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  bool _isConnected = false;
  bool _hasInternetAccess = false;

  /// Estado actual de conexión
  bool get isConnected => _isConnected && _hasInternetAccess;

  /// Stream para escuchar cambios en el estado de conexión
  Stream<bool> get connectionStream {
    _connectionStatusController ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _connectionStatusController!.stream;
  }

  /// Inicializa el servicio y verifica la conectividad inicial
  Future<void> initialize() async {
    await _checkConnectivity();
    _startListening();
  }

  /// Verifica la conectividad actual
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return isConnected;
  }

  Future<void> _checkConnectivity() async {
    try {
      // Primero verificar conectividad de red
      final connectivityResults = await _connectivity.checkConnectivity();
      _isConnected = connectivityResults.isNotEmpty &&
          !connectivityResults.contains(ConnectivityResult.none);

      // Luego verificar acceso real a Internet
      if (_isConnected) {
        final internetStatus = await _internetConnection.internetStatus;
        _hasInternetAccess = internetStatus == InternetStatus.connected;
      } else {
        _hasInternetAccess = false;
      }

      _notifyListeners();
    } catch (e) {
      _isConnected = false;
      _hasInternetAccess = false;
      _notifyListeners();
    }
  }

  void _startListening() {
    // Escuchar cambios en la conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (_isConnected) {
        _checkInternetAccess();
      } else {
        _hasInternetAccess = false;
        _notifyListeners();
      }
    });

    // Escuchar cambios en el acceso a Internet
    _internetSubscription = _internetConnection.onStatusChange.listen((status) {
      _hasInternetAccess = status == InternetStatus.connected;
      _notifyListeners();
    });
  }

  void _stopListening() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _connectivitySubscription = null;
    _internetSubscription = null;
  }

  Future<void> _checkInternetAccess() async {
    try {
      final status = await _internetConnection.internetStatus;
      _hasInternetAccess = status == InternetStatus.connected;
      _notifyListeners();
    } catch (e) {
      _hasInternetAccess = false;
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    _connectionStatusController?.add(isConnected);
  }

  /// Libera recursos
  void dispose() {
    _stopListening();
    _connectionStatusController?.close();
    _connectionStatusController = null;
  }
}
