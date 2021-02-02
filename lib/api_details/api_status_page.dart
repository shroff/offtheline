import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiStatusPage extends StatelessWidget {
  final bool allowPause;

  const ApiStatusPage({Key key, this.allowPause = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final qState = context.select((ApiCubit api) => api.state.actionQueueState);

    String statusText;
    if (qState.actions == null) {
      statusText = 'Initializing';
    } else if (qState.submitting) {
      statusText = 'Submitting';
    } else if (qState.error != null) {
      statusText = qState.error;
    } else if (qState.paused) {
      statusText = 'Paused';
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
                            subtitle: qState.error != null
                                ? Text(qState.error)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (qState.paused || qState.error != null)
                                  IconButton(
                                      icon: Icon(Icons.play_arrow),
                                      onPressed: () {
                                        context.read<ApiCubit>().resume();
                                      }),
                                if (allowPause && !qState.paused)
                                  IconButton(
                                      icon: Icon(Icons.pause),
                                      onPressed: () {
                                        context.read<ApiCubit>().pause();
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
                          title: Text(request.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.info_outline),
                                onPressed: () {
                                  showAlertDialog(
                                    context,
                                    title: request.description,
                                    message: request.dataString,
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
                                                '${request.description}\n\n'
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
                                          context
                                              .read<ApiCubit>()
                                              .deleteRequest(request);
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
