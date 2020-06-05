import 'package:appcore/core/core.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/material.dart';

class ApiStatusPage extends StatelessWidget {
  final bool allowPause;

  const ApiStatusPage({Key key, this.allowPause = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final api = Core.api(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('API'),
      ),
      body: FixedPageBody(
        child: (!api.isInitialized || api.requestQueue == null)
            ? CircularProgressIndicator()
            : CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate.fixed(
                      [
                        ListTile(
                            title: Text("Status: ${api.status.statusString}"),
                            subtitle: api.statusDetails != null
                                ? Text(api.statusDetails)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (api.status == ApiStatus.PAUSED ||
                                    api.status == ApiStatus.ERROR ||
                                    api.status == ApiStatus.SERVER_UNREACHABLE)
                                  IconButton(
                                      icon: Icon(Icons.play_arrow),
                                      onPressed: () {
                                        api.resume();
                                      }),
                                if (allowPause &&
                                    api.status != ApiStatus.PAUSED)
                                  IconButton(
                                      icon: Icon(Icons.pause),
                                      onPressed: () {
                                        api.pause(persistent: true);
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
                        final request = api.requestQueue.getAt(i);
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
                                onPressed:
                                    (i == 0 && api.status == ApiStatus.SYNCING)
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
                                              api.deleteRequest(request);
                                            }
                                          },
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: api.requestQueue.length,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
