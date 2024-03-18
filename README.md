# fl_anchor_scroll

## 锚点定位

### 简单的使用定位跳转

```dart

Widget build() {
  return CustomScrollView(controller: anchorScrollController, slivers: [
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
        }, childCount: list.length))
  ]);
}


```

### 配合tabBar使用的定位跳转

```dart
Widget build() {
  return FlAnchorScrollBuilder(
      controller: scrollController,
      itemCount: list.length,
      tabController: tabController,
      onIndexChanged: (List<int> index) {
        // log('onIndexChanged:$index');
      },
      builder: (_, itemBuilder) =>
          CustomScrollView(controller: scrollController, slivers: [
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
          ]));
}
```