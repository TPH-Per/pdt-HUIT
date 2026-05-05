import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}

class ConnectivityUndetermined extends ConnectivityState {
  const ConnectivityUndetermined();
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityUndetermined()) {
    _initConnectivityStream();
  }

  void _initConnectivityStream() {
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        emit(const ConnectivityOffline());
      } else {
        emit(const ConnectivityOnline());
      }
    });
  }

  Future<void> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        emit(const ConnectivityOffline());
      } else {
        emit(const ConnectivityOnline());
      }
    } catch (e) {
      emit(const ConnectivityUndetermined());
    }
  }

  bool get isOnline => state is ConnectivityOnline;
}
