import 'package:fl_anchor_scroll/fl_anchor_scroll.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(title: 'FlAnchorScroll', home: _App()));
}

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  List<int> list = List.generate(40000, (index) => index);
  List<bool> states = [];
  late AnchorScrollController anchorScrollController;

  @override
  void initState() {
    super.initState();
    states = list.map((item) => false).toList();
    anchorScrollController = AnchorScrollController(
        suggestedRowHeight: 100, keepScrollOffset: false);
    anchorScrollController.addListener(() {
      Future.delayed(const Duration(milliseconds: 200), () {
        logStates();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('FlAnchorScroll')),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.arrow_upward),
            onPressed: () {
              anchorScrollController.animateTo(0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.linear);
            }),
        body: CustomScrollView(controller: anchorScrollController, slivers: [
          SliverToBoxAdapter(child: header),
          SliverList(
              delegate: SliverChildBuilderDelegate(
            (_, int index) {
              final item = list[index];
              return AnchorScrollTag(
                  key: ValueKey(index),
                  highlightColor: Colors.red,
                  color: Colors.blue,
                  controller: anchorScrollController,
                  index: index,
                  child: VisibilityDetector(
                      key: ValueKey(index),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (index == 12) {
                          // log(info.visibleFraction);
                        }
                        if (info.visibleFraction > 0.5) {
                          // log('======${index}');
                        }
                        states[index] = info.visibleFraction > 0.5;
                      },
                      child: Container(
                          margin: const EdgeInsets.all(10),
                          width: double.infinity,
                          alignment: Alignment.center,
                          height: index.isEven ? 100 : 400,
                          child: Text(
                            '$index',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 19),
                          ))));
            },
            childCount: list.length,
          )),
        ]));
  }

  Widget get header {
    return Column(children: [
      Container(color: Colors.yellow, height: 300, width: double.infinity),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        ElevatedButton(
            onPressed: () {
              anchorScrollController.animateToIndex(100,
                  preferPosition: AnchorScrollPosition.begin);
            },
            child: const Text('jump100')),
        ElevatedButton(
            onPressed: () {
              anchorScrollController.highlight(10);
            },
            child: const Text('highlight')),
        // ElevatedButton(
        //     onPressed: () {
        //       anchorScrollController.animateToIndex(1000,
        //           duration: const Duration(milliseconds: 1),
        //           preferPosition: AnchorScrollPosition.begin);
        //     },
        //     child: const Text('jump1000')),
        ElevatedButton(
            onPressed: () {
              anchorScrollController.animateToIndex(3000,
                  duration: const Duration(milliseconds: 1),
                  preferPosition: AnchorScrollPosition.begin);
            },
            child: const Text('jump3000')),
      ]),
    ]);
  }

  List<int> lastIndex = [];

  void logStates() {
    List<int> index = [];
    for (int i = 0; i < states.length; i++) {
      if (states[i]) {
        index.add(i);
      }
    }
    if (lastIndex.toString() == index.toString()) return;
    lastIndex = index;
    print(index);
  }
}
