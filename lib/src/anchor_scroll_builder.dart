import 'package:fl_anchor_scroll/fl_anchor_scroll.dart';
import 'package:flutter/material.dart';

typedef AnchorScrollBuilderIndexChanged = void Function(List<int> index);

typedef AnchorScrollBuilderScrollView = Widget Function(
    BuildContext context, AnchorScrollBuilderAnchorScrollTag itemBuilder);

typedef AnchorScrollBuilderAnchorScrollTag = Widget Function(
    int index, Widget itemBuilder);

typedef AnchorScrollBuilderVisibilityStateBuilder = bool Function(
    VisibilityInfo info);
typedef AnchorScrollBuilderTabController = void Function(int index);

class FlAnchorScrollBuilder extends StatefulWidget {
  const FlAnchorScrollBuilder({
    super.key,
    required this.controller,
    required this.builder,
    required this.itemCount,
    this.onIndexChanged,
    this.visibilityStateBuilder,
    this.delayDuration = const Duration(milliseconds: 100),
    this.tabController,
    this.preferPosition,
    this.tabControllerChanged,
  });

  /// build ScrollView
  final AnchorScrollBuilderScrollView builder;

  /// FlAnchorScrollController
  final FlAnchorScrollController controller;
  final AnchorScrollPosition? preferPosition;

  /// item 长度
  final int itemCount;

  /// 下标变化回调
  final AnchorScrollBuilderIndexChanged? onIndexChanged;

  /// delay 获取组件状态
  final Duration delayDuration;

  /// visibility State Builder
  final AnchorScrollBuilderVisibilityStateBuilder? visibilityStateBuilder;

  /// link TabController
  final TabController? tabController;

  /// tab controller changed callback
  final AnchorScrollBuilderTabController? tabControllerChanged;

  @override
  State<FlAnchorScrollBuilder> createState() => _AnchorScrollBuilderState();
}

class _AnchorScrollBuilderState extends State<FlAnchorScrollBuilder> {
  List<bool> itemStates = [];
  String lastIndex = '';
  bool isTabBarScrolling = false;

  int lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void didUpdateWidget(covariant FlAnchorScrollBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    initialize();
  }

  void initialize() {
    removeListener();
    widget.tabController?.addListener(tabListener);
    itemStates = List.generate(widget.itemCount, (index) => false);
  }

  void tabListener() {
    final tabController = widget.tabController!;
    if (lastTabIndex == tabController.index) return;
    lastTabIndex = tabController.index;
    isTabBarScrolling = true;
    if (itemStates.length > lastTabIndex && !itemStates[lastTabIndex]) {
      widget.controller
          .animateToIndex(lastTabIndex, preferPosition: widget.preferPosition);
    }
  }

  void getItemState() {
    bool isAnimate = isTabBarScrolling;
    if (widget.tabController != null && !isAnimate) {
      final controller = widget.controller;
      if (controller.offset == controller.position.maxScrollExtent) {
        animateToTabIndex(widget.itemCount - 1);
        isAnimate = true;
      }
      if (controller.offset == 0) {
        animateToTabIndex(0);
        isAnimate = true;
      }
    }

    List<int> index = [];
    for (int i = 0; i < itemStates.length; i++) {
      if (itemStates[i]) {
        index.add(i);
      }
    }
    if (lastIndex == index.toString()) return;
    lastIndex = index.toString();
    widget.onIndexChanged?.call(index);
    final i = index.firstOrNull;
    if (i == null) return;
    if (!isAnimate) animateToTabIndex(i);
  }

  void animateToTabIndex(int i) {
    if (isTabBarScrolling || widget.tabController == null) return;
    if (widget.tabControllerChanged == null) {
      widget.tabController!.animateTo(i);
    } else {
      widget.tabControllerChanged?.call(i);
    }
  }

  @override
  Widget build(BuildContext context) => NotificationListener(
      onNotification: (notifier) {
        if (notifier is ScrollEndNotification ||
            notifier is ScrollUpdateNotification) {
          if (notifier is ScrollEndNotification &&
              isTabBarScrolling &&
              !widget.controller.isAnchorScrolling) {
            isTabBarScrolling = false;
          }
          Future.delayed(widget.delayDuration, getItemState);
        }
        return true;
      },
      child: widget.builder(context, (int index, Widget itemBuilder) {
        final key = ValueKey(index);
        return AnchorScrollTag(
            key: key,
            controller: widget.controller,
            index: index,
            visibilityDetectorKey: key,
            onVisibilityChanged: (VisibilityInfo info) {
              itemStates[index] = widget.visibilityStateBuilder?.call(info) ??
                  info.visibleFraction == 1;
            },
            child: itemBuilder);
      }));

  void removeListener() {
    widget.tabController?.removeListener(tabListener);
  }

  @override
  void dispose() {
    removeListener();
    super.dispose();
  }
}
