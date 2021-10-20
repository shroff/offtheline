import 'package:appcore/src/api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ApiStatusPage extends StatelessWidget {
  final bool allowPause;

  const ApiStatusPage({Key? key, this.allowPause = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final queue = context.watch<ApiActionQueue>();

    String statusText;
    if (queue.submitting) {
      statusText = 'Submitting';
    } else if (queue.paused) {
      statusText = 'Paused';
    } else if (queue.error?.isNotEmpty ?? false) {
      statusText = 'Error';
    } else {
      statusText = 'Ready';
    }

    final actions = queue.actions.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('API'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                ListTile(
                  title: Text("Status: $statusText"),
                  subtitle: queue.error?.isNotEmpty ?? false
                      ? Text(queue.error!)
                      : null,
                  trailing: (queue.paused || (queue.error?.isNotEmpty ?? false))
                      ? IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            queue.resumeActionQueue();
                          })
                      : (allowPause && !queue.paused)
                          ? IconButton(
                              icon: Icon(Icons.pause),
                              onPressed: () {
                                queue.pauseActionQueue();
                              })
                          : null,
                ),
                Divider(),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final request = actions[i];
                return ListTile(
                  title: Text(request.generateDescription(queue.api)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title:
                                  Text(request.generateDescription(queue.api)),
                              content: Text(
                                request.generatePayloadDetails(queue.api),
                                softWrap: true,
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: (i == 0 && queue.submitting)
                            ? null
                            : () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Record'),
                                    content: Text(
                                        'You are about to delete the following record:\n\n'
                                        '${request.generateDescription(queue.api)}\n\n'
                                        'It will not be submitted to the server, and you will not be able to recover it.\n\n'
                                        'Are you sure you want to do this?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('YES'),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                      ElevatedButton(
                                        child: Text('NO'),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm ?? false) {
                                  queue.removeActionAt(i);
                                }
                              },
                      ),
                    ],
                  ),
                );
              },
              childCount: actions.length,
            ),
          ),
        ],
      ),
    );
  }
}
