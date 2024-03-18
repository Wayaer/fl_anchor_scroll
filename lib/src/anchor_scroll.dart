part of '../fl_anchor_scroll.dart';

const _kDefaultScrollDistanceOffset = 100.0;
const _kDefaultDurationUnit = 40;

const _kMillisecond = Duration(milliseconds: 1);
const _kHighlightDuration = Duration(seconds: 3);
const _kScrollAnimationDuration = Duration(milliseconds: 250);

typedef ViewportBoundaryGetter = Rect Function();
typedef AxisValueGetter = double Function(Rect rect);

Rect defaultViewportBoundaryGetter() => Rect.zero;

enum AnchorScrollPosition { begin, middle, end }

abstract class FlAnchorScrollController implements ScrollController {
  /// used to quick scroll to a index if the row height is the same
  double? get suggestedRowHeight;

  /// used to make the additional boundary for viewport
  /// e.g. a sticky header which covers the real viewport of a list view
  ViewportBoundaryGetter get viewportBoundaryGetter;

  /// used to choose which direction you are using.
  /// e.g. axis == Axis.horizontal ? (r) => r.left : (r) => r.top
  AxisValueGetter get beginGetter;

  AxisValueGetter get endGetter;

  /// detect if it's in scrolling (scrolling is a async process)
  bool get isAnchorScrolling;

  /// all layout out states will be put into this map
  Map<int, AnchorScrollTagState> get tagMap;

  /// used to chaining parent scroll controller
  set parentController(ScrollController parentController);

  /// check if there is a parent controller
  bool get hasParentController;

  /// scroll to the giving index
  Future animateToIndex(int index,
      {Duration duration = _kScrollAnimationDuration,
      AnchorScrollPosition? preferPosition});

  /// highlight the item
  Future highlight(int index,
      {bool cancelExistHighlights = true,
      Duration highlightDuration = _kHighlightDuration,
      bool animated = true});

  /// cancel all highlight item immediately.
  void cancelAllHighlights();

  /// check if the state is created. that is, is the indexed widget is layout out.
  /// NOTE: state created doesn't mean it's in viewport. it could be a buffer range, depending on flutter's implementation.
  bool isIndexStateInLayoutRange(int index);
}

class AnchorScrollController extends ScrollController
    with AnchorScrollControllerMixin {
  AnchorScrollController(
      {super.initialScrollOffset = 0.0,
      super.keepScrollOffset = true,
      Axis? axis,
      this.suggestedRowHeight,
      this.viewportBoundaryGetter = defaultViewportBoundaryGetter,
      AnchorScrollController? copyTagsFrom,
      super.debugLabel})
      : beginGetter = (axis == Axis.horizontal ? (r) => r.left : (r) => r.top),
        endGetter =
            (axis == Axis.horizontal ? (r) => r.right : (r) => r.bottom) {
    if (copyTagsFrom != null) tagMap.addAll(copyTagsFrom.tagMap);
  }

  @override
  final double? suggestedRowHeight;
  @override
  final ViewportBoundaryGetter viewportBoundaryGetter;
  @override
  final AxisValueGetter beginGetter;
  @override
  final AxisValueGetter endGetter;
}

class PageAnchorScrollController extends PageController
    with AnchorScrollControllerMixin {
  @override
  final double? suggestedRowHeight;

  @override
  final ViewportBoundaryGetter viewportBoundaryGetter;

  @override
  final AxisValueGetter beginGetter;

  @override
  final AxisValueGetter endGetter;

  PageAnchorScrollController(
      {super.initialPage,
      super.keepPage,
      super.viewportFraction,
      this.suggestedRowHeight,
      this.viewportBoundaryGetter = defaultViewportBoundaryGetter,
      PageAnchorScrollController? copyTagsFrom,
      String? debugLabel})
      : beginGetter = ((Rect rect) => rect.left),
        endGetter = ((Rect rect) => rect.right) {
    if (copyTagsFrom != null) tagMap.addAll(copyTagsFrom.tagMap);
  }
}

mixin AnchorScrollControllerMixin on ScrollController
    implements FlAnchorScrollController {
  @override
  final Map<int, AnchorScrollTagState> tagMap = <int, AnchorScrollTagState>{};

  @override
  double? get suggestedRowHeight;

  @override
  ViewportBoundaryGetter get viewportBoundaryGetter;

  @override
  AxisValueGetter get beginGetter;

  @override
  AxisValueGetter get endGetter;

  bool __isAnchorScrolling = false;

  set _isAnchorScrolling(bool isAnchorScrolling) {
    __isAnchorScrolling = isAnchorScrolling;
    if (!isAnchorScrolling && hasClients) {
      notifyListeners();
    }
  }

  @override
  bool get isAnchorScrolling => __isAnchorScrolling;

  ScrollController? _parentController;

  @override
  set parentController(ScrollController parentController) {
    if (_parentController == parentController) return;

    final isNotEmpty = positions.isNotEmpty;
    if (isNotEmpty && _parentController != null) {
      for (final p in _parentController!.positions) {
        if (positions.contains(p)) _parentController!.detach(p);
      }
    }

    _parentController = parentController;

    if (isNotEmpty && _parentController != null) {
      for (final p in positions) {
        _parentController!.attach(p);
      }
    }
  }

  @override
  bool get hasParentController => _parentController != null;

  @override
  void attach(ScrollPosition position) {
    super.attach(position);

    _parentController?.attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    _parentController?.detach(position);

    super.detach(position);
  }

  static const maxBound = 30; // 0.5 second if 60fps
  @override
  Future<void> animateToIndex(int index,
      {Duration duration = _kScrollAnimationDuration,
      AnchorScrollPosition? preferPosition}) async {
    return _co(
        this,
        () => _scrollToIndex(index,
            duration: duration, preferPosition: preferPosition));
  }

  Future<void> _scrollToIndex(int index,
      {Duration duration = _kScrollAnimationDuration,
      AnchorScrollPosition? preferPosition}) async {
    assert(duration > Duration.zero);

    Future<void> makeSureStateIsReady() async {
      for (var count = 0; count < maxBound; count++) {
        if (_isEmptyStates) {
          await _waitForWidgetStateBuild();
        } else {
          return;
        }
      }
      return;
    }

    await makeSureStateIsReady();

    if (!hasClients) return;

    if (isIndexStateInLayoutRange(index)) {
      _isAnchorScrolling = true;

      await _bringIntoViewportIfNeed(index, preferPosition,
          (double offset) async {
        await animateTo(offset, duration: duration, curve: Curves.ease);
        await _waitForWidgetStateBuild();
        return null;
      });

      _isAnchorScrolling = false;
    } else {
      double prevOffset = offset - 1;
      double currentOffset = offset;
      bool contains = false;
      Duration spentDuration = const Duration();
      double lastScrollDirection = 0.5; // alignment, default center;
      final moveDuration = duration ~/ _kDefaultDurationUnit;

      _isAnchorScrolling = true;

      bool usedSuggestedRowHeightIfAny = true;
      while (prevOffset != currentOffset &&
          !(contains = isIndexStateInLayoutRange(index))) {
        prevOffset = currentOffset;
        final nearest = _getNearestIndex(index);

        if (tagMap[nearest ?? 0] == null) return;

        final moveTarget =
            _forecastMoveUnit(index, nearest, usedSuggestedRowHeightIfAny)!;

        final suggestedDuration =
            usedSuggestedRowHeightIfAny && suggestedRowHeight != null
                ? duration
                : null;
        usedSuggestedRowHeightIfAny = false; // just use once
        lastScrollDirection = moveTarget - prevOffset > 0 ? 1 : 0;
        currentOffset = moveTarget;
        spentDuration += suggestedDuration ?? moveDuration;
        final oldOffset = offset;
        await animateTo(currentOffset,
            duration: suggestedDuration ?? moveDuration, curve: Curves.ease);
        await _waitForWidgetStateBuild();
        if (!hasClients || offset == oldOffset) {
          contains = isIndexStateInLayoutRange(index);
          break;
        }
      }
      _isAnchorScrolling = false;

      if (contains && hasClients) {
        await _bringIntoViewportIfNeed(
            index, preferPosition ?? _alignmentToPosition(lastScrollDirection),
            (finalOffset) async {
          if (finalOffset != offset) {
            _isAnchorScrolling = true;
            final remaining = duration - spentDuration;
            await animateTo(finalOffset,
                duration:
                    remaining <= Duration.zero ? _kMillisecond : remaining,
                curve: Curves.ease);
            await _waitForWidgetStateBuild();

            if (hasClients && offset != finalOffset) {
              for (var i = 0;
                  i < 3 && hasClients && offset != finalOffset;
                  i++) {
                await animateTo(finalOffset,
                    duration: _kMillisecond, curve: Curves.ease);
                await _waitForWidgetStateBuild();
              }
            }
            _isAnchorScrolling = false;
          }
        });
      }
    }

    return;
  }

  @override
  Future highlight(int index,
      {bool cancelExistHighlights = true,
      Duration highlightDuration = _kHighlightDuration,
      bool animated = true}) async {
    final tag = tagMap[index];
    return tag == null
        ? null
        : await tag.highlight(
            cancelExisting: cancelExistHighlights,
            highlightDuration: highlightDuration,
            animated: animated);
  }

  @override
  void cancelAllHighlights() {
    _cancelAllHighlights();
  }

  @override
  bool isIndexStateInLayoutRange(int index) => tagMap[index] != null;

  /// this means there is no widget state existing, usually happened before build.
  /// we should wait for next frame.
  bool get _isEmptyStates => tagMap.isEmpty;

  /// wait until the [SchedulerPhase] in [SchedulerPhase.persistentCallbacks].
  /// it means if we do animation scrolling to a position, the Future call back will in [SchedulerPhase.midFrameMicrotasks].
  /// if we want to search viewport element depending on Widget State, we must delay it to [SchedulerPhase.persistentCallbacks].
  /// which is the phase widget build/layout/draw
  Future _waitForWidgetStateBuild() => SchedulerBinding.instance.endOfFrame;

  /// NOTE: this is used to forcase the nearestIndex. if the the index equals targetIndex,
  /// we will use the function, calling _directionalOffsetToRevealInViewport to get move unit.
  double? _forecastMoveUnit(
      int targetIndex, int? currentNearestIndex, bool useSuggested) {
    assert(targetIndex != currentNearestIndex);
    currentNearestIndex = currentNearestIndex ?? 0; //null as none of state

    final alignment = targetIndex > currentNearestIndex ? 1.0 : 0.0;
    double? absoluteOffsetToViewport;

    if (useSuggested && suggestedRowHeight != null) {
      final indexDiff = (targetIndex - currentNearestIndex);
      final offsetToLastState = _offsetToRevealInViewport(
          currentNearestIndex, indexDiff <= 0 ? 0 : 1)!;
      absoluteOffsetToViewport = math.max(
          offsetToLastState.offset + indexDiff * suggestedRowHeight!, 0);
    } else {
      final offsetToLastState =
          _offsetToRevealInViewport(currentNearestIndex, alignment);

      absoluteOffsetToViewport = offsetToLastState?.offset;
      absoluteOffsetToViewport ??= _kDefaultScrollDistanceOffset;
    }

    return absoluteOffsetToViewport;
  }

  int? _getNearestIndex(int index) {
    final list = tagMap.keys;
    if (list.isEmpty) return null;

    final sorted = list.toList()
      ..sort((int first, int second) => first.compareTo(second));
    final min = sorted.first;
    final max = sorted.last;
    return (index - min).abs() < (index - max).abs() ? min : max;
  }

  Future _bringIntoViewportIfNeed(
      int index,
      AnchorScrollPosition? preferPosition,
      Future Function(double offset) move) async {
    if (preferPosition != null) {
      double targetOffset = _directionalOffsetToRevealInViewport(
          index, _positionToAlignment(preferPosition));

      targetOffset = targetOffset.clamp(
          position.minScrollExtent, position.maxScrollExtent);

      await move(targetOffset);
    } else {
      final begin = _directionalOffsetToRevealInViewport(index, 0);
      final end = _directionalOffsetToRevealInViewport(index, 1);

      final alreadyInViewport = offset < begin && offset > end;
      if (!alreadyInViewport) {
        double value;
        if ((end - offset).abs() < (begin - offset).abs()) {
          value = end;
        } else {
          value = begin;
        }

        await move(value > 0 ? value : 0);
      }
    }
  }

  double _positionToAlignment(AnchorScrollPosition position) {
    return position == AnchorScrollPosition.begin
        ? 0
        : position == AnchorScrollPosition.end
            ? 1
            : 0.5;
  }

  AnchorScrollPosition _alignmentToPosition(double alignment) => alignment == 0
      ? AnchorScrollPosition.begin
      : alignment == 1
          ? AnchorScrollPosition.end
          : AnchorScrollPosition.middle;

  double _directionalOffsetToRevealInViewport(int index, double alignment) {
    assert(alignment == 0 || alignment == 0.5 || alignment == 1);
    // 1.0 bottom, 0.5 center, 0.0 begin if list is vertically from begin to end
    final tagOffsetInViewport = _offsetToRevealInViewport(index, alignment);

    if (tagOffsetInViewport == null) {
      return -1;
    } else {
      double absoluteOffsetToViewport = tagOffsetInViewport.offset;
      if (alignment == 0.5) {
        return absoluteOffsetToViewport;
      } else if (alignment == 0) {
        return absoluteOffsetToViewport - beginGetter(viewportBoundaryGetter());
      } else {
        return absoluteOffsetToViewport + endGetter(viewportBoundaryGetter());
      }
    }
  }

  /// return offset, which is a absolute offset to bring the target index object into the center of the viewport
  /// see also: _directionalOffsetToRevealInViewport()
  RevealedOffset? _offsetToRevealInViewport(int index, double alignment) {
    final ctx = tagMap[index]?.context;
    if (ctx == null) return null;

    final renderBox = ctx.findRenderObject()!;
    final RenderAbstractViewport viewport =
        RenderAbstractViewport.of(renderBox);
    final revealedOffset = viewport.getOffsetToReveal(renderBox, alignment);

    return revealedOffset;
  }
}

void _cancelAllHighlights([AnchorScrollTagState? state]) {
  for (final tag in _highlights.keys) {
    tag._cancelController(reset: tag != state);
  }

  _highlights.clear();
}

typedef TagHighlightBuilder = Widget Function(
    BuildContext context, Animation<double> highlight);

class AnchorScrollTag extends StatefulWidget {
  const AnchorScrollTag({
    required super.key,
    required this.controller,
    required this.index,
    this.child,
    this.builder,
    this.color,
    this.highlightColor,
    this.disabled = false,
    this.onVisibilityChanged,
    this.visibilityDetectorKey,
  }) : assert(child != null || builder != null);
  final FlAnchorScrollController controller;
  final int index;
  final Widget? child;
  final TagHighlightBuilder? builder;
  final Color? color;
  final Color? highlightColor;
  final bool disabled;

  /// The callback to invoke when this widget's visibility changes.
  final VisibilityChangedCallback? onVisibilityChanged;
  final Key? visibilityDetectorKey;

  @override
  AnchorScrollTagState createState() => AnchorScrollTagState<AnchorScrollTag>();
}

Map<AnchorScrollTagState, AnimationController?> _highlights =
    <AnchorScrollTagState, AnimationController?>{};

class AnchorScrollTagState<W extends AnchorScrollTag> extends State<W>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.disabled) {
      register(widget.index);
    }
  }

  @override
  void dispose() {
    _cancelController();
    if (!widget.disabled) {
      unregister(widget.index);
    }
    _controller = null;
    _highlights.remove(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.key != widget.key ||
        oldWidget.disabled != widget.disabled) {
      if (!oldWidget.disabled) unregister(oldWidget.index);
      if (!widget.disabled) register(widget.index);
    }
  }

  void register(int index) {
    widget.controller.tagMap[index] = this;
  }

  void unregister(int index) {
    _cancelController();
    _highlights.remove(this);
    if (widget.controller.tagMap[index] == this) {
      widget.controller.tagMap.remove(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = _controller ?? kAlwaysDismissedAnimation;

    final item = _HighlightTransition(
        context: context,
        highlight: animation,
        background: widget.color,
        highlightColor: widget.highlightColor,
        child: widget.child!);
    if (widget.onVisibilityChanged != null &&
        widget.visibilityDetectorKey != null) {
      return VisibilityDetector(
          key: widget.visibilityDetectorKey!,
          onVisibilityChanged: widget.onVisibilityChanged,
          child: item);
    }
    return item;
  }

  DateTime? _startKey;

  /// this function can be called multiple times. every call will reset the highlight style.
  Future highlight(
      {bool cancelExisting = true,
      Duration highlightDuration = _kHighlightDuration,
      bool animated = true}) async {
    if (!mounted) return null;

    if (cancelExisting) {
      _cancelAllHighlights(this);
    }

    if (_highlights.containsKey(this)) {
      assert(_controller != null);
      _controller!.stop();
    }

    if (_controller == null) {
      _controller = AnimationController(vsync: this);
      _highlights[this] = _controller;
    }

    final startKey0 = _startKey = DateTime.now();
    const animationShow = 1.0;
    setState(() {});
    if (animated) {
      await _catchAnimationCancel(_controller!
          .animateTo(animationShow, duration: _kScrollAnimationDuration));
    } else {
      _controller!.value = animationShow;
    }
    await Future.delayed(highlightDuration);

    if (startKey0 == _startKey) {
      if (mounted) {
        setState(() {});
        const animationHide = 0.0;
        if (animated) {
          await _catchAnimationCancel(_controller!
              .animateTo(animationHide, duration: _kScrollAnimationDuration));
        } else {
          _controller!.value = animationHide;
        }
      }

      if (startKey0 == _startKey) {
        _controller = null;
        _highlights.remove(this);
      }
    }
    return null;
  }

  void _cancelController({bool reset = true}) {
    if (_controller != null) {
      if (_controller!.isAnimating) _controller!.stop();
      if (reset && _controller!.value != 0.0) _controller!.value = 0.0;
    }
  }
}

class _HighlightTransition extends StatelessWidget {
  const _HighlightTransition(
      {required this.context,
      required this.highlight,
      required this.child,
      this.background,
      this.highlightColor});

  final BuildContext context;
  final Animation<double> highlight;
  final Widget child;
  final Color? background;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBoxTransition(
        decoration: DecorationTween(
                begin: background != null
                    ? BoxDecoration(color: background)
                    : const BoxDecoration(),
                end: background != null
                    ? BoxDecoration(color: background)
                    : BoxDecoration(color: highlightColor))
            .animate(highlight),
        child: child);
  }
}
