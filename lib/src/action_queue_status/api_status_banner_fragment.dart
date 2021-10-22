import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_status_page.dart';
import '/src/core/action_queue.dart';

class ApiStatusBannerFragment extends StatelessWidget {
  final bool allowPause;

  const ApiStatusBannerFragment({
    Key? key,
    this.allowPause = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<ApiActionQueue>();
    if (queue.actions.isEmpty) return Container();
    final pendingRequests = queue.actions.length == 1
        ? '1 entry pending'
        : '${queue.actions.length} entries pending';

    IconData icon;
    String statusText;
    if (queue.submitting) {
      icon = Icons.sync;
      statusText = 'Submitting';
    } else if (queue.paused) {
      icon = Icons.pause_circle_outline;
      statusText = 'Paused';
    } else if (queue.error?.isNotEmpty ?? false) {
      icon = Icons.error_outline;
      statusText = 'Error: ${queue.error}';
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
