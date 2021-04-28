import 'package:appcore/api_details/api_status_page.dart';
import 'package:appcore/actions/actions.dart';
import 'package:appcore/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiStatusBannerFragment<T extends ApiCubit> extends StatelessWidget {
  final bool allowPause;

  const ApiStatusBannerFragment({
    Key? key,
    this.allowPause = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qState = context.select((ActionQueueCubit<T> queue) => queue.state);
    if (qState.actions.isEmpty) return Container();
    final pendingRequests = qState.actions.length == 1
        ? '1 entry pending'
        : '${qState.actions.length} entries pending';

    IconData icon;
    String statusText;
    if (!qState.ready) {
      icon = Icons.sync;
      statusText = 'Initializing';
    } else if (qState.submitting) {
      icon = Icons.sync;
      statusText = 'Submitting';
    } else if (qState.paused) {
      icon = Icons.pause_circle_outline;
      statusText = 'Paused';
    } else if (qState.error?.isNotEmpty ?? false) {
      icon = Icons.error_outline;
      statusText = 'Error: ${qState.error}';
    } else {
      icon = Icons.check_circle_outline;
      statusText = 'Ready';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ApiStatusPage(allowPause: allowPause),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(color: Colors.grey[600]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
