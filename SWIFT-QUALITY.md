# Swiftコード品質

## このリポジトリへの適用

Driver／SignalによるMVVM教材です。GitHubSignUpViewModel、SignUpUseCase、GitHubAPIの抽象を通して表示・登録操作・データ取得を分けます。UI要素の名前はTextField・Label・Buttonに揃えています。Wireframeは対象画面をweakで保持し、アラート終了時にObservableを完了させます。登録自体はモックです。

## 共通の設計基準

- 型・メンバーは必要な範囲だけに公開します。内部状態は`private`、外部から読む状態は必要に応じて`private(set)`にします。プロトコルの要件、Storyboardの接続、サブクラスからの利用を確認して変更します。
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)に従い、型はUpperCamelCase、値・関数・enum caseはlowerCamelCaseとし、利用箇所で役割が分かる名前にします。通信のキーやStoryboardの接続は改名と同時に整合させます。
- UIKitはViewController・View・Cell・delegateの役割とAPIに合わせます。SwiftUIではViewの値型、`body`、状態の所有元とBindingの受け渡しを区別します。
- 状態・業務処理を持つ画面はVIPERまたはMVVM＋Clean Architectureの依存方向に揃えます。Viewは表示と入力、Presenter／ViewModelは表示状態、UseCaseは処理、Repositoryの実装は外部サービスを担当します。依存関係の組み立ては境界で行います。
- 戻り方向のdelegateや画面参照は`weak`を検討し、購読・タイマー・タスクの所有元と終了条件を確認します。クロージャすべてに機械的に`weak`を付けるのではなく、所有関係と必要な生存期間で判断します。

## 検証

READMEのSwift製スクリプトでビルドとテストを実行します。参照の解放や処理結果を変更した箇所には回帰テストを追加します。ビルド成功や一部の解放テストだけで、全画面・全経路のメモリリーク不在を保証するものではありません。画面操作時のMemory Graph／Instrumentsによる確認も併用します。
