import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'api_status_page.dart';
import '/src/api/api.dart';

class ApiStatusBannerFragment<A extends ApiClient> extends StatelessWidget {
  final bool allowPause;

  const ApiStatusBannerFragment({
    Key? key,
    this.allowPause = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final api = context.watch<A>();
    if (api.actions.isEmpty) return Container();
    final pendingRequests = api.actions.length == 1
        ? '1 entry pending'
        : '${api.actions.length} entries pending';

    IconData icon;
    String statusText;
    if (api.submitting) {
      icon = Icons.sync;
      statusText = 'Submitting';
    } else if (api.paused) {
      icon = Icons.pause_circle_outline;
      statusText = 'Paused';
    } else if (api.error?.isNotEmpty ?? false) {
      icon = Icons.error_outline;
      statusText = 'Error: ${api.error}';
    } else {
      icon = Icons.check_circle_outline;
      statusText = 'Ready';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ApiStatusPage<A>(allowPause: allowPause),
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
