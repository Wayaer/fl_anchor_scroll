import 'package:fl_anchor_scroll/fl_anchor_scroll.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

class AnchorScrollSliverListPage extends StatefulWidget {
  const AnchorScrollSliverListPage({super.key});

  @override
  State<AnchorScrollSliverListPage> createState() =>
      _AnchorScrollSliverListPageState();
}

class _AnchorScrollSliverListPageState extends State<AnchorScrollSliverListPage>
    with TickerProviderStateMixin {
  List<int> list = List.generate(100, (index) => index);
  late FlAnchorScrollController scrollController;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: list.length, vsync: this);
    scrollController = FlAnchorScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('With SliverList')),
        body: FlAnchorScrollBuilder(
            controller: scrollController,
            itemCount: list.length,
            tabController: tabController,
            onIndexChanged: (List<int> index) {
              // log('onIndexChanged:$index');
            },
            builder: (_, itemBuilder) =>
                CustomScrollView(controller: scrollController, slivers: [
                  SliverToBoxAdapter(child: header),
                  ExtendedSliverPersistentHeader(
                      child: Container(
                          color: context.theme.cardColor,
                          child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              controller: tabController,
                              tabs: list
                                  .builder((item) => Tab(text: 'Tab$item'))))),
                  SliverList(
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
                  ),
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
