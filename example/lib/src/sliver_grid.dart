import 'package:fl_anchor_scroll/fl_anchor_scroll.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

class AnchorScrollSliverGridPage extends StatefulWidget {
  const AnchorScrollSliverGridPage({super.key});

  @override
  State<AnchorScrollSliverGridPage> createState() =>
      _AnchorScrollSliverGridPageState();
}

class _AnchorScrollSliverGridPageState extends State<AnchorScrollSliverGridPage>
    with TickerProviderStateMixin {
  List<int> list = List.generate(100, (index) => index);
  late FlAnchorScrollController anchorScrollController;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: list.length, vsync: this);
    anchorScrollController = FlAnchorScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('With SliverGrid')),
        body: FlAnchorScrollBuilder(
            controller: anchorScrollController,
            itemCount: list.length,
            tabController: tabController,
            onIndexChanged: (List<int> index) {
              // log('onIndexChanged:$index');
            },
            builder: (_, itemBuilder) =>
                CustomScrollView(controller: anchorScrollController, slivers: [
                  SliverToBoxAdapter(child: header),
                  ExtendedSliverPersistentHeader(
                      child: Container(
                    color: context.theme.cardColor,
                    child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        controller: tabController,
                        tabs: list.builder((item) => Tab(text: 'Tab$item'))),
                  )),
                  SliverGrid(
                      delegate: SliverChildBuilderDelegate((_, int index) {
                        return itemBuilder(
                            index,
                            Container(
                                margin: const EdgeInsets.all(10),
                                width: double.infinity,
                                color: index.isEven
                                    ? Colors.amber
                                    : Colors.blueAccent,
                                alignment: Alignment.center,
                                height: index.isEven ? 300 : 200,
                                child: Text(
                                  '$index',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 19),
                                )));
                      }, childCount: list.length),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 100)),
                ])));
  }

  Widget get header {
    return Column(children: [
      Container(
          color: Colors.yellow,
          height: context.height * 0.6,
          width: double.infinity),
    ]);
  }
}
