import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  final _connectionStatus = ConnectivityResult.none.obs;
  
  ConnectivityResult get connectionStatus => _connectionStatus.value;
  bool get isConnected => _connectionStatus.value != ConnectivityResult.none;

  Future<ConnectivityService> init() async {
    // Get initial connectivity status
    final connectivityResults = await _connectivity.checkConnectivity();
    _connectionStatus.value = _getConnectionStatus(connectivityResults);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    return this;
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResults) {
    _connectionStatus.value = _getConnectionStatus(connectivityResults);
  }

  // Helper method to determine the overall connection status from the list
  ConnectivityResult _getConnectionStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else if (results.contains(ConnectivityResult.vpn)) {
      return ConnectivityResult.vpn;
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      return ConnectivityResult.bluetooth;
    } else if (results.contains(ConnectivityResult.other)) {
      return ConnectivityResult.other;
    } else {
      return ConnectivityResult.none;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}