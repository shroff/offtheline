import 'package:appcore/api_details/api_status_page.dart';
import 'package:appcore/core/api_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiStatusBannerFragment<T extends ApiCubit> extends StatelessWidget {
  final bool allowPause;

  const ApiStatusBannerFragment({
    Key key,
    this.allowPause = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qState = context.select((T api) => api.state.actionQueueState);
    if (qState.actions?.isEmpty ?? true) return Container();
    final pendingRequests = qState.actions == null
        ? ''
        : qState.actions.length == 1
            ? '1 entry pending'
            : '${qState.actions.length} entries pending';

    IconData icon;
    String statusText;
    if (qState.actions == null) {
      icon = Icons.power_settings_new;
      statusText = 'Initializing';
    } else if (qState.submitting) {
      icon = Icons.sync;
      statusText = 'Submitting';
    } else if (qState.error != null) {
      icon = Icons.error_outline;
      statusText = qState.error;
    } else if (qState.paused) {
      icon = Icons.pause_circle_outline;
      statusText = 'Paused';
    } else {
      icon = Icons.check_circle_outline;
      statusText = 'Ready';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ApiStatusPage<T>(allowPause: allowPause),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(color: Colors.grey[600]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (icon != null)
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (pendingRequests != null)
                    Text(
                      pendingRequests,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
