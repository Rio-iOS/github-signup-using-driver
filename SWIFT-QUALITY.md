# Swiftコード品質

## このリポジトリへの適用

Driver／SignalによるMVVM教材です。GitHubSignUpViewModel、SignUpUseCase、GitHubAPIの抽象を通して表示・登録操作・データ取得を分けます。UI要素の名前はTextField・Label・Buttonに揃えています。Wireframeは対象画面をweakで保持し、アラート終了時にObservableを完了させます。登録自体はモックです。

Driverで表示状態を共有し、結果イベントには再送しないSignalを使います。登録の入口で入力状態を検証し、登録から結果確認までの連打を抑止します。モックの成否とSchedulerを注入でき、HTTP 200・404と通信失敗を区別します。

パスワード条件、仮想時刻でのモック結果・破棄、不正入力・連打・失敗後の再試行、古いユーザー名検証の解除、ViewModelの解放をSwift Packageで検証します。

## 共通の設計基準

- 型・メンバーは必要な範囲だけに公開します。内部状態は`private`、外部から読む状態は必要に応じて`private(set)`にします。プロトコルの要件、Storyboardの接続、サブクラスからの利用を確認して変更します。
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)に従い、型はUpperCamelCase、値・関数・enum caseはlowerCamelCaseとし、利用箇所で役割が分かる名前にします。通信のキーやStoryboardの接続は改名と同時に整合させます。
- UIKitはViewController・View・Cell・delegateの役割とAPIに合わせます。SwiftUIではViewの値型、`body`、状態の所有元とBindingの受け渡しを区別します。
- 状態・業務処理を持つ画面はVIPERまたはMVVM＋Clean Architectureの依存方向に揃えます。Viewは表示と入力、Presenter／ViewModelは表示状態、UseCaseは処理、Repositoryの実装は外部サービスを担当します。依存関係の組み立ては境界で行います。
- 戻り方向のdelegateや画面参照は`weak`を検討し、購読・タイマー・タスクの所有元と終了条件を確認します。クロージャすべてに機械的に`weak`を付けるのではなく、所有関係と必要な生存期間で判断します。

## コメントとドキュメントコメント

- 型やAPIの役割・利用条件は宣言直前の`///`に記述します。引数・戻り値・エラー・呼び出すスレッドは、利用時の判断に必要なものを実装に合わせて説明します。
- 通常のコメントは、設計上の理由、所有関係、処理順序、教材の比較意図を補います。コードを読み上げるだけの説明や、使われていない自動生成テンプレートは残しません。
- モック、未実装、空のテスト、意図的な失敗例は、その範囲を明示します。コメントアウトした教材の比較例は、実行される処理と区別します。
- 改名や設計変更と同時にコメントも更新します。出典URLとライセンス表記は維持し、出典不明の教材へ推測で情報を追加しません。

## 検証

READMEのSwift製スクリプトでビルドとテストを実行します。参照の解放や処理結果を変更した箇所には回帰テストを追加します。ビルド成功や一部の解放テストだけで、全画面・全経路のメモリリーク不在を保証するものではありません。画面操作時のMemory Graph／Instrumentsによる確認も併用します。
