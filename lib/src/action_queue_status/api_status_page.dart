import 'package:appcore/src/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiStatusPage<A extends ApiClient> extends StatelessWidget {
  final bool allowPause;

  const ApiStatusPage({Key? key, this.allowPause = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final api = context.watch<A>();

    String statusText;
    if (api.submitting) {
      statusText = 'Submitting';
    } else if (api.paused) {
      statusText = 'Paused';
    } else if (api.error?.isNotEmpty ?? false) {
      statusText = 'Error';
    } else {
      statusText = 'Ready';
    }

    final actions = api.actions.toList(growable: false);

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
                  subtitle:
                      api.error?.isNotEmpty ?? false ? Text(api.error!) : null,
                  trailing: (api.paused || (api.error?.isNotEmpty ?? false))
                      ? IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            api.resumeActionQueue();
                          })
                      : (allowPause && !api.paused)
                          ? IconButton(
                              icon: Icon(Icons.pause),
                              onPressed: () {
                                api.pauseActionQueue();
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
                  title: Text(request.generateDescription(api)),
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
                              title: Text(request.generateDescription(api)),
                              content: Text(
                                request.generatePayloadDetails(api),
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
                        onPressed: (i == 0 && api.submitting)
                            ? null
                            : () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Record'),
                                    content: Text(
                                        'You are about to delete the following record:\n\n'
                                        '${request.generateDescription(api)}\n\n'
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
                                  api.removeActionAt(i);
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
