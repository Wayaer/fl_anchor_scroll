part of '../fl_anchor_scroll.dart';

typedef AnchorScrollBuilderIndexChanged = void Function(List<int> index);

class AnchorScrollBuilder extends StatefulWidget {
  const AnchorScrollBuilder(
      {super.key,
      required this.controller,
      required this.child,
      this.onIndexChanged,
      required this.itemCount});

  final AnchorScrollController controller;
  final Widget child;
  final int itemCount;
  final AnchorScrollBuilderIndexChanged? onIndexChanged;

  @override
  State<AnchorScrollBuilder> createState() => AnchorScrollBuilderState();
}

class AnchorScrollBuilderState extends State<AnchorScrollBuilder> {
  List<bool> states = [];

  @override
  void initState() {
    super.initState();
    initialize();
    if (widget.onIndexChanged != null) widget.controller.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant AnchorScrollBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    initialize();
  }

  void initialize() {
    states = List.generate(widget.itemCount, (index) => false);
  }

  void listener() {
    Future.delayed(const Duration(milliseconds: 200), () {
      getStates();
    });
  }

  List<int> lastIndex = [];

  void getStates() {
    List<int> index = [];
    for (int i = 0; i < states.length; i++) {
      if (states[i]) {
        index.add(i);
      }
    }
    if (lastIndex.toString() == index.toString()) return;
    lastIndex = index;
    widget.onIndexChanged?.call(lastIndex);
  }

  void removeListener() {
    if (widget.onIndexChanged != null) {
      widget.controller.removeListener(listener);
    }
  }

  @override
  void dispose() {
    removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
