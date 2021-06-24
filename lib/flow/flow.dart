import 'dart:async';

import 'package:flutter/material.dart';

abstract class FlowManager<T> extends StatefulWidget {
  final String title;

  const FlowManager({
    Key? key,
    required this.title,
  }) : super(key: key);

  FlowManagerArgs<T> flowArgs(BuildContext context) =>
      ModalRoute.of(context)!.settings.arguments as FlowManagerArgs<T>;

  static _FlowManagerState<T> of<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedFlowManager>()!
        .data as _FlowManagerState<T>;
  }

  FutureOr<bool> confirmDropFlow(BuildContext context) {
    return true;
  }

  FutureOr<bool> finishFlow(BuildContext context, T data);

  @override
  State<StatefulWidget> createState() => _FlowManagerState<T>();
}

class FlowManagerArgs<T> {
  final Map<String, FlowStep<T>> steps;
  final String initialStep;
  final T initialData;
  final String finishText;

  FlowManagerArgs(
    this.steps,
    this.initialStep,
    this.initialData, {
    this.finishText = 'FINISH',
  });
}

class FlowStep<T> {
  final Widget Function(BuildContext, GlobalKey<State>?) buildPage;
  final Function(T, BuildContext) setStateOnStart;
  final String Function(T, BuildContext)? generateNextStepName;
  final String? Function(T, BuildContext)? generateNextButtonText;
  final bool Function(T, BuildContext)? nextEnabled;
  final FutureOr<bool> Function(T, BuildContext) onFinish;

  FlowStep({
    required this.buildPage,
    this.generateNextStepName,
    this.generateNextButtonText,
    this.setStateOnStart = _doNothing,
    this.nextEnabled = _doNothing,
    this.onFinish = _doNothing,
  });

  static bool _doNothing(data, context) => true;
}

class InheritedFlowManager extends InheritedWidget {
  final _FlowManagerState data;

  InheritedFlowManager({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedFlowManager old) => old != this;
}

class _FlowManagerState<T> extends State<FlowManager> {
  final PageStorageBucket _bucket = PageStorageBucket();

  bool initialized = false;
  late List<FlowStep<T>> steps;
  late T data;

  FlowStep<T> get currentStep => steps[steps.length - 1];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      final args = widget.flowArgs(context);
      steps = [args.steps[args.initialStep] as FlowStep<T>];
      data = args.initialData;
      setState(() {
        currentStep.setStateOnStart(data, context);
      });
    }
  }

  void updateState(Function() fn) {
    setState(fn);
  }

  void nextStep() async {
    if ((currentStep.nextEnabled?.call(data, context) ?? true) &&
        (await currentStep.onFinish(data, context))) {
      if (currentStep.generateNextStepName == null) {
        if (await widget.finishFlow(context, data)) {
          debugPrint('[flow] Finish');
          Navigator.of(context).pop(data);
        }
      } else {
        final stepName = currentStep.generateNextStepName!(data, context);
        final step = widget.flowArgs(context).steps[stepName];
        debugPrint('[flow] Next to $stepName');
        if (step == null) throw "Unknown next state: $step";

        setState(() {
          steps.add(step as FlowStep<T>);
          currentStep.setStateOnStart(data, context);
        });
      }
    }
  }

  bool canPopStep() {
    return steps.length > 1;
  }

  Future<bool> _onBackPress() async {
    steps.removeLast();
    if (steps.isEmpty) {
      debugPrint('[flow] Back Out');
      if (await widget.confirmDropFlow(context)) Navigator.of(context).pop();
    } else {
      debugPrint('[flow] Back');
      setState(() {
        currentStep.setStateOnStart(data, context);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return InheritedFlowManager(
      data: this,
      child: WillPopScope(
        onWillPop: _onBackPress,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            leading: IconButton(
              icon: Icon(canPopStep() ? Icons.arrow_back : Icons.close),
              onPressed: _onBackPress,
            ),
            actions: <Widget>[
              if (currentStep.nextEnabled != null)
                TextButton(
                  child: Text(currentStep.generateNextStepName == null
                      ? widget.flowArgs(context).finishText
                      : currentStep.generateNextButtonText
                              ?.call(data, context) ??
                          'NEXT'),
                  style: TextButton.styleFrom(primary: Colors.white),
                  onPressed:
                      currentStep.nextEnabled!(data, context) ? nextStep : null,
                ),
            ],
          ),
          body: PageStorage(
            bucket: _bucket,
            child: Builder(
                builder: (context) => currentStep.buildPage(context, null)),
          ),
        ),
      ),
    );
  }
}
