import 'package:appcore/core/core.dart';
import 'package:flutter/material.dart';

class ApiStatusBannerFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final api = Core.api(context);
    if (api.status == ApiStatus.DONE && (api.requestQueue?.isEmpty ?? true)) return Container();
    final pendingRequests = api.requestQueue == null
        ? ''
        : api.requestQueue.length == 1
            ? '1 entry pending'
            : '${api.requestQueue.length} entries pending';

    IconData icon;
    switch (api.status) {
      case ApiStatus.INITIALIZING:
        icon = Icons.power_settings_new;
        break;
      case ApiStatus.DONE:
        icon = Icons.check_circle_outline;
        break;
      case ApiStatus.PAUSED:
        icon = Icons.pause_circle_outline;
        break;
      case ApiStatus.SYNCING:
        icon = Icons.sync;
        break;
      case ApiStatus.ERROR:
        icon = Icons.error_outline;
        break;
      case ApiStatus.SERVER_UNREACHABLE:
        icon = Icons.cloud_off;
        break;
      default:
        icon = null;
        break;
    }

    return Container(
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
                  api.status.statusString,
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
    );
  }
}
