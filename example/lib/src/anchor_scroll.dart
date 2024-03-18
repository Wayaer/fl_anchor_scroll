import 'package:fl_anchor_scroll/fl_anchor_scroll.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

class AnchorScrollPage extends StatefulWidget {
  const AnchorScrollPage({super.key});

  @override
  State<AnchorScrollPage> createState() => _AnchorScrollPageState();
}

class _AnchorScrollPageState extends State<AnchorScrollPage>
    with TickerProviderStateMixin {
  List<int> list = List.generate(100, (index) => index);
  late FlAnchorScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = FlAnchorScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('With AnchorScrollTag')),
        body: CustomScrollView(controller: scrollController, slivers: [
          SliverToBoxAdapter(child: header),
          ExtendedSliverPersistentHeader(
              child: Container(
            color: context.theme.cardColor,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        scrollController.animateToIndex(10);
                      },
                      child: const Text('animateToIndex 10')),
                  ElevatedButton(
                      onPressed: () {
                        scrollController.animateToIndex(80);
                      },
                      child: const Text('animateToIndex 80'))
                ]),
          )),
          SliverList(
              delegate: SliverChildBuilderDelegate((_, int index) {
            return AnchorScrollTag(
                key: ValueKey(index),
                controller: scrollController,
                index: index,
                child: Container(
                    margin: const EdgeInsets.all(10),
                    width: double.infinity,
                    color: index.isEven ? Colors.amber : Colors.blueAccent,
                    alignment: Alignment.center,
                    height: index.isEven ? 300 : 200,
                    child: Text(
                      '$index',
                      style: const TextStyle(color: Colors.black, fontSize: 19),
                    )));
          }, childCount: list.length)),
        ]));
  }

  Widget get header {
    return Column(children: [
      Container(color: Colors.yellow, height: 200, width: double.infinity),
    ]);
  }
}
