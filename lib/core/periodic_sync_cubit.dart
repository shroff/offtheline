import 'package:appcore/core/api.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

abstract class PeriodicSyncCubit extends Cubit<PeriodicSyncState> {
  final ApiCubit api;

  PeriodicSyncCubit(this.api) : super(PeriodicSyncState());

  UriBuilder createUriBuilder();

  void fetchUpdates() async {
    debugPrint('[api] Fetching Updates');

    if (api.state.session == null || state.fetching) {
      return;
    }

    emit(PeriodicSyncState(fetching: true));

    final uriBuilder = createUriBuilder();
    final httpRequest = Request('get', uriBuilder.build());

    final error = await api.sendRequest(httpRequest);
    emit(PeriodicSyncState(fetching: false, error: error));
  }
}

class PeriodicSyncState {
  final bool fetching;
  final String? error;

  PeriodicSyncState({this.fetching = false, this.error});
}
