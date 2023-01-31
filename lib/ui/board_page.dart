import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_tutorial/service/board_state.dart';

class BoardPage extends HookConsumerWidget {
  const BoardPage({Key? key}) : super(key: key);

  // void型でしか関数を書けない.
  // _bottomSheetは、関数として切り分けたWidgetと思われる.
  // 切り分けたWidgetに、WidgetRef refを追加してrefメソッド使えるようにする.
  void _bottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return HookBuilder(
          builder: (context) {
            // Formに値を保存するuseTextEditingControllerを定義する.
            final name = useTextEditingController(text: '匿名');
            final content = useTextEditingController();

            // StateNotifierProviderを呼び出して、ref.readで使う.
            final board = ref.read(boardStateProvider.notifier);

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: '名前',
                  ),
                  controller: name,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'コメント',
                  ),
                  controller: content,
                ),
                ElevatedButton(
                  child: const Text('投稿'),
                  onPressed: () {
                    board.addPost(name.text, content.text);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Widgetを部品ごとに切り分けていたので、StateNotifireProviderをここでも呼び出す.
    final board = ref.read(boardStateProvider.notifier);
    // ListViewで表示するList.
    List<Widget> listTile = [];
    // useMemoizedでFirestoreのPostコレクションのキャッシュをとる.
    // 更新があったときだけ、firestoreのpostsコレクションを読み込む.
    // orderBy("time")でドキュメントを投稿時間でソート.
    final memo = useMemoized(() => FirebaseFirestore.instance
        .collection('posts')
        .orderBy("time")
        .snapshots());
    final snapshot = useStream(memo);
    // useStreamでは、キャッシュされたスナップショットをstreamとして受け取る.
    // これで、StreamBuilderを使わず、Firestoreの保持しているデータを扱えるようになる.
    if (snapshot.hasData) {
      final docs = snapshot.data?.docs;
      docs?.forEach((element) {
        listTile.add(ListTile(
          trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // ブログを削除するメソッド.
                board.deletePost(element);
              }),
          title: Text(element.data()['content']),
          subtitle: Text(element.data()['name']),
        ));
      });
    }
    // この下のWidgetで切り分けたWidgetを使う.
    return Scaffold(
      appBar: AppBar(
        title: const Text('HooksTutorial'),
      ),
      body: ListView(
        children: listTile,
      ),
      // floatingActionButtonクリックするとデータを追加するモーダルが現れる.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // WidgetRefを追加したので、refを書かないとエラーになる.
          _bottomSheet(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
