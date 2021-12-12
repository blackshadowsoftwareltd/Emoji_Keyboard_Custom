import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'constraints.dart';

void main() =>

    /// KeyboardVisibilityProvider
    runApp(const MaterialApp(home: Home()));

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  bool isEmojiVisible = false;
  bool isKeyboardVisible = false;
  int _selectedTab = 0;
  late TextEditingController _textController;
  late StreamSubscription<bool> keyboardSubscription;
  late TabController _tabController;
  late ScrollController _scrollController;
  final focusNode = FocusNode();
  bool isPortrait = false;
  double width = 0, height = 0;
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _tabController = TabController(vsync: this, length: emojis.length);
    _scrollController = ScrollController();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible && isEmojiVisible) {
        isEmojiVisible = false;
        setState(() {});
      } else {}
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    isPortrait = height > width ? true : false;
    _tabController.addListener(() {
      _selectedTab = _tabController.index;
      if (!isPortrait) {
        _scrollController.jumpTo(_selectedTab * height * .075);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cross = (MediaQuery.of(context).size.width * .025).round();
    List<String> textMessage = List.of(messages.reversed);
    return WillPopScope(
        onWillPop: () async {
          if (isEmojiVisible) {
            isEmojiVisible = !isEmojiVisible;
            setState(() {});
            return false;
          }
          return true;
        },
        child: Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(),
            body: SizedBox(
                height: isPortrait ? height : width,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: ListView.builder(
                              reverse: true,
                              itemCount: textMessage.length,
                              itemBuilder: (context, index) => Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      alignment: Alignment.centerRight,
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.all(8),
                                      child: Text(textMessage[index]),
                                    ),
                                  ))),
                      Container(
                          margin: const EdgeInsets.all(5),
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Row(children: [
                            IconButton(
                                onPressed: () async {
                                  if (isEmojiVisible) {
                                    focusNode.requestFocus();
                                  } else if (!isEmojiVisible) {
                                    await SystemChannels.textInput
                                        .invokeMethod('TextInput.hide');
                                    await Future.delayed(
                                        const Duration(milliseconds: 100));
                                    FocusScope.of(context).unfocus();
                                  }
                                  isEmojiVisible = !isEmojiVisible;
                                  setState(() {});
                                },
                                icon: isEmojiVisible
                                    ? const Icon(Icons.keyboard,
                                        color: Colors.black54)
                                    : const Icon(Icons.emoji_emotions,
                                        color: Colors.black54)),
                            Flexible(
                                child: TextField(
                                    focusNode: focusNode,
                                    controller: _textController,
                                    decoration: const InputDecoration(
                                        hintText: 'Message...'))),
                            IconButton(
                                onPressed: () {
                                  messages.add(_textController.text);
                                  _textController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.send,
                                    color: Colors.black54))
                          ])),
                      Offstage(
                          offstage: !isEmojiVisible,
                          child: Container(
                              height: height * .4,
                              width: double.infinity,
                              margin: const EdgeInsets.all(5),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Colors.black54, width: .5),
                                  borderRadius: BorderRadius.circular(10)),
                              child: DefaultTabController(
                                  length: emojis.length,
                                  child: isPortrait
                                      ? Column(children: [
                                          Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 2),
                                              child: ImojiTabBar(
                                                  tabController:
                                                      _tabController)),
                                          const Divider(
                                              color: Colors.black45,
                                              height: 5,
                                              thickness: .5),
                                          ImojisList(
                                              cross: cross,
                                              textController: _textController,
                                              tabController: _tabController)
                                        ])
                                      : Row(children: [
                                          emojiSideBar(),
                                          ImojisList(
                                              cross: cross,
                                              textController: _textController,
                                              tabController: _tabController)
                                        ]))))
                    ]))));
  }

  SizedBox emojiSideBar() {
    return SizedBox(
        width: 50,
        child: ListView.builder(
            controller: _scrollController,
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              final x = emojis[index].split(' ');
              return GestureDetector(
                  onTap: () {
                    _selectedTab = index;
                    _tabController.animateTo(index);
                    setState(() {});
                  },
                  child: Container(
                      padding: const EdgeInsets.all(2),
                      margin: const EdgeInsets.all(2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _selectedTab == index
                              ? Colors.grey.shade300
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(x[0], style: const TextStyle(fontSize: 25))));
            }));
  }
}

class ImojiTabBar extends StatelessWidget {
  const ImojiTabBar({
    Key? key,
    required this.tabController,
  }) : super(key: key);
  final TabController tabController;
  @override
  Widget build(BuildContext context) {
    return TabBar(
        controller: tabController,
        isScrollable: true,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.blue[700],
        labelStyle: const TextStyle(fontSize: 25),
        unselectedLabelStyle: const TextStyle(fontSize: 20),
        labelPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 1),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
            color: Colors.grey.withOpacity(.3),
            borderRadius: BorderRadius.circular(10)),
        tabs: emojis.map((e) {
          final x = e.split(' ');
          return Tab(
              child: SizedBox(width: 35, child: Center(child: Text(x[0]))));
        }).toList());
  }
}

class ImojisList extends StatelessWidget {
  const ImojisList({
    Key? key,
    required this.cross,
    required TextEditingController textController,
    required this.tabController,
  })  : _textController = textController,
        super(key: key);

  final int cross;
  final TextEditingController _textController;
  final TabController tabController;
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: TabBarView(
            controller: tabController,
            children: emojis.map((e) {
              final x = e.split(' ');
              return GridView.builder(
                  itemCount: x.length,
                  scrollDirection: Axis.vertical,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2),
                  itemBuilder: (context, index) => GestureDetector(
                      onTap: () {
                        _textController.text = _textController.text + x[index];
                      },
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: FittedBox(
                              child: Text(x[index],
                                  style: const TextStyle(fontSize: 30))))));
            }).toList()));
  }
}
