// part of '../fl_anchor_scroll.dart';
//
// class AnchorScrollBuilder extends StatefulWidget {
//   const AnchorScrollBuilder({required this.controller});
//
//   final AnchorScrollController controller;
//
//   @override
//   State<AnchorScrollBuilder> createState() => AnchorScrollBuilderState();
// }
//
// class AnchorScrollBuilderState extends State<AnchorScrollBuilder> {
//   List<Color> list = Colors.primaries;
//   List<bool> states = [];
//   late AnchorScrollController anchorScrollController;
//
//   @override
//   void initState() {
//     super.initState();
//     states = list.map((item) => false).toList();
//     anchorScrollController = AnchorScrollController();
//     anchorScrollController.addListener(() {
//       Future.delayed(const Duration(milliseconds: 200), () {
//         logStates();
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomScrollView(controller: anchorScrollController, slivers: [
//       SliverToBoxAdapter(child: header),
//       SliverList(
//           delegate: SliverChildBuilderDelegate(
//         (_, int index) {
//           final item = list[index];
//           return AnchorScrollTag(
//               key: ValueKey(index),
//               controller: anchorScrollController,
//               index: index,
//               child: VisibilityDetector(
//                   key: ValueKey(index),
//                   onVisibilityChanged: (VisibilityInfo info) {
//                     if (index == 12) {
//                       // log(info.visibleFraction);
//                     }
//                     if (info.visibleFraction > 0.5) {
//                       // log('======${index}');
//                     }
//                     states[index] = info.visibleFraction > 0.5;
//                   },
//                   child: Container(
//                       color: item,
//                       width: double.infinity,
//                       alignment: Alignment.center,
//                       height: index.isEven ? 100 : 400,
//                       child: Text(
//                         '$index',
//                         style:
//                             const TextStyle(color: Colors.black, fontSize: 19),
//                       ))));
//         },
//         childCount: list.length,
//       )),
//     ]);
//   }
//
//   List<int> lastIndex = [];
//
//   void logStates() {
//     List<int> index = [];
//     for (int i = 0; i < states.length; i++) {
//       if (states[i]) {
//         index.add(i);
//       }
//     }
//     if (lastIndex.toString() == index.toString()) return;
//     lastIndex = index;
//   }
// }
