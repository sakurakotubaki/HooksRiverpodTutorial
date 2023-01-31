# hooks_tutorial
ナルンさん学習用資料
## 参考にしたZennの記事
https://zenn.dev/antman/articles/cb49aa8294113f

ReactのようなWidgetで、同じページだけで状態を管理したい時に使われるようです。
https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/HookBuilder-class.html

ビルドをコールバックに委ねるHookWidgetです。

継承
オブジェクト DiagnosticableTree Widget StatelessWidget HookWidget HookBuilder

## 使用例
今回は、HooksRiverpodと一緒に使うので、HookConsumerWidgetに変更しています。

```dart
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
```

## StreamBuilderの代わりの機能
https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useMemoized.html

### 複合オブジェクトのインスタンスをキャッシュする。
useMemoizedは、最初の呼び出しで直ちにvalueBuilderを呼び出してその結果を保存します。
その後、HookWidgetが再構築されると、useMemoizedの呼び出しは、
valueBuilderを呼び出さずに、以前に作成されたインスタンスを返します。
その後、別のキーで useMemoized を呼び出すと、再び useMemoized が呼び出され、
新しいインスタンスが作成されます。

-----

### useStreamについて
https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/useStream.html
Streamに登録し、その現在の状態をAsyncSnapshotとして返します。
preserveState は、Stream インスタンスを変更する際に現在の値を保存するかどうかを決定します。
こちらも参照してください。
Stream, オブジェクトのリスニング。
useFuture、useStreamと似ていますが、Futureの場合です。

```dart
// useMemoizedでFirestoreのPostコレクションのキャッシュをとる.
    // 更新があったときだけ、firestoreのpostsコレクションを読み込む.
    // orderBy("time")でドキュメントを投稿時間でソート.
    final memo = useMemoized(() => FirebaseFirestore.instance
        .collection('posts')
        .orderBy("time")
        .snapshots());
    final snapshot = useStream(memo);
```

----

## HooksRiverpodの機能
FirestoreへアクセスするためのProviderを定義する。
ただの変数と思って貰えばいいです。グローバルなのでどこからでも呼べる!

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Firebaseを使うためのProvider
final firebaseProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
```

StateNotifierProviderを使って、グローバルにメソッドを呼び出されるようにしています。

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'board_provider.dart';

// 外部からStateNotifierを呼び出せるようになるProvider
final boardStateProvider = StateNotifierProvider<BoardState, dynamic>((ref) {
  // Riverpod2.0はここの引数にrefを書かなければエラーになる!
  return BoardState(ref);
});

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
```