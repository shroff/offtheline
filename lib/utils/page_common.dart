import 'package:flutter/material.dart';

class FixedPageBody extends StatelessWidget {
  final Widget child;

  const FixedPageBody({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540),
          child: child,
        ),
      );
}

class ScrollingPageBody extends StatelessWidget {
  final Widget child;

  const ScrollingPageBody({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FixedPageBody(child: child),
        ),
      );
}
