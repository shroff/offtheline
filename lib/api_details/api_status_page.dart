import 'package:appcore/core/action_queue_cubit.dart';
import 'package:appcore/core/api.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiStatusPage<S extends ApiSession, T extends ApiCubit<S, T>>
    extends StatelessWidget {
  final bool allowPause;

  const ApiStatusPage({Key? key, this.allowPause = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final api = context.read<T>();
    final queue = context.watch<ActionQueueCubit>();
    final qState = queue.state;

    String statusText;
    // TODO: qState.ready
    if (qState.submitting) {
      statusText = 'Submitting';
    } else if (qState.paused) {
      statusText = 'Paused';
    } else if (qState.error?.isNotEmpty ?? false) {
      statusText = 'Error';
    } else {
      statusText = 'Ready';
    }

    final actions = qState.actions.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('API'),
      ),
      body: FixedPageBody(
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  ListTile(
                    title: Text("Status: $statusText"),
                    subtitle: qState.error?.isNotEmpty ?? false
                        ? Text(qState.error!)
                        : null,
                    trailing:
                        (qState.paused || (qState.error?.isNotEmpty ?? false))
                            ? IconButton(
                                icon: Icon(Icons.play_arrow),
                                onPressed: () {
                                  queue.resume();
                                })
                            : (allowPause && !qState.paused)
                                ? IconButton(
                                    icon: Icon(Icons.pause),
                                    onPressed: () {
                                      queue.pause();
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
                            showAlertDialog(
                              context,
                              title: request.generateDescription(api),
                              message: request.generatePayloadDetails(api),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          onPressed: (i == 0 && qState.submitting)
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
                                    queue.deleteRequestAt(i);
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
      ),
    );
  }
}
