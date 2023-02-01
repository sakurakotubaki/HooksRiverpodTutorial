import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'board_provider.dart';

// 外部からStateNotifierを呼び出せるようになるProvider
// dynamicにしているのは実はよろしくなかったりする.
// モデルクラスがあればそれを型に使う.
final boardStateProvider = StateNotifierProvider<BoardState, dynamic>((ref) {
  // final Ref _ref;を書いたら、クラスにコンストラクターできるので、引数がいる。なので、refと書かないとエラーが出る。
  return BoardState(ref);
});

// dynamicにしているのは実はよろしくなかったりする.
// モデルクラスがあればそれを型に使う.
class BoardState extends StateNotifier<dynamic> {
  // Refを使うと他のファイルのProviderを呼び出せる
  final Ref _ref;
  // superは、親クラスのコンストクラスターを呼び出す
  BoardState(this._ref) : super([]);

  // FireStoreにデータを追加するメソッド
  Future<void> addPost(String name, String content) async {
    // _ref.read()と書いて、firebaseProviderを呼び出す
    final ref = await _ref.read(firebaseProvider).collection('posts').add({
      'name': name,
      'content': content,
      'time': Timestamp.now(),
    });
  }

  // FireStoreの値を削除するメソッド
  Future<void> deletePost(dynamic element) async {
    final ref = await _ref
        .read(firebaseProvider)
        .collection('posts')
        .doc(element.id)
        .delete();
  }
}
