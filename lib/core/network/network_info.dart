import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final results = await connectivity.checkConnectivity();
    return _checkConnection(results);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(_checkConnection);
  }

  bool _checkConnection(dynamic results) {
    if (results is List<ConnectivityResult>) {
      return results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi
      );
    } else if (results is ConnectivityResult) {
      return results == ConnectivityResult.mobile || 
             results == ConnectivityResult.wifi;
    }
    return false;
  }
}
