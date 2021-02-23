import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiStatusPage<T extends ApiCubit> extends StatelessWidget {
  final bool allowPause;

  const ApiStatusPage({Key key, this.allowPause = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final qState = context.select((T api) => api.state.actionQueueState);
    final api = context.read<T>();

    String statusText;
    if (qState.actions == null) {
      statusText = 'Initializing';
    } else if (qState.submitting) {
      statusText = 'Submitting';
    } else if (qState.paused) {
      statusText = 'Paused';
    } else if (qState.error?.isNotEmpty ?? false ) {
      statusText = 'Error';
    } else {
      statusText = 'Ready';
    }

    final actions = qState.actions?.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('API'),
      ),
      body: FixedPageBody(
        child: (actions == null)
            ? CircularProgressIndicator()
            : CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate.fixed(
                      [
                        ListTile(
                            title: Text("Status: $statusText"),
                            subtitle: qState.error?.isNotEmpty ?? false
                                ? Text(qState.error)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (qState.paused || (qState.error?.isNotEmpty ?? false))
                                  IconButton(
                                      icon: Icon(Icons.play_arrow),
                                      onPressed: () {
                                        api.resume();
                                      }),
                                if (allowPause && !qState.paused)
                                  IconButton(
                                      icon: Icon(Icons.pause),
                                      onPressed: () {
                                        api.pause();
                                      }),
                              ],
                            )),
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
                                    // TODO: show props
                                    // message: request.dataString,
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
                                              FlatButton(
                                                child: Text('YES'),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(true);
                                                },
                                              ),
                                              FlatButton(
                                                child: Text('NO'),
                                                textTheme:
                                                    ButtonTextTheme.primary,
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(false);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm ?? false) {
                                          api.deleteRequestAt(i);
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
