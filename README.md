# github-signup-using-driver

RxSwiftのDriverを使い、サインアップ画面の入力と表示を扱う学習サンプルです。

## 検証環境と実行方法

検証用ツールチェーンはXcode 26.6 / Swift 6.3です。Swiftの言語モード・iOSの最低バージョンは各プロジェクトの設定を使用します。macOSでXcodeをインストールし、初回起動時の追加コンポーネントのインストールを完了してください。

リポジトリのルートで以下を実行します。

```sh
# 検証対象と番号の一覧
swift Scripts/verify.swift --list

# 全対象を順番に検証
swift Scripts/verify.swift

# 1件だけ検証（0始まり）
swift Scripts/verify.swift --index 0
```

アプリは署名不要のSimulator向けにビルドし、Swiftパッケージは `swift test` で検証します。作業用ディレクトリは実行ごとに作成・削除するため、初回と同様に時間がかかります。依存パッケージの取得にはネットワーク接続が必要です。

## 検証対象

| 番号 | 対象 | 種類 | 開く場所 |
| ---: | --- | --- | --- |
| 0 | `GitHubSignupUsingDriver` | Simulatorビルド | `GitHubSignupUsingDriver/GitHubSignupUsingDriver.xcodeproj` |
| 1 | `SignUpCore` | Swift Packageテスト | `Package.swift` |

アプリを操作するには表のworkspace（ある場合）またはprojectをXcodeで開き、対象のschemeとiPhone Simulatorを選択して実行します。実機で動かす場合は、ご自身のSigning Teamを設定してください。

## CIと検証範囲

`Quality` ワークフローは上記と同じ一覧・スクリプトを使い、対象ごとにビルドまたはテストを実行します。ビルドの成功だけでは、画面表示、アクセシビリティ、通信先の動作、テスト網羅性は保証されません。UIサンプルはSimulator上での操作確認も必要です。

## 学習元

既存のGitHubリポジトリ説明では、RxExampleのDriverを利用したGitHubSignupの写経として公開されています。元教材との対応は、出典の詳細確認後に追記します。

## 振る舞いの回帰テスト

Driverで表示状態を共有し、結果イベントには再送しないSignalを使います。登録の入口で入力状態を検証し、登録から結果確認までの連打を抑止します。モックの成否とSchedulerを注入でき、HTTP 200・404と通信失敗を区別します。

パスワード条件、仮想時刻でのモック結果・破棄、不正入力・連打・失敗後の再試行、古いユーザー名検証の解除、ViewModelの解放をSwift Packageで検証します。

```sh
swift test
```

登録処理はモックです。既定では1秒後に成功し、GitHubへ実際にアカウントを作成する機能ではありません。

## Swiftコード品質

[設計・命名・所有関係の方針と、この教材への適用範囲](SWIFT-QUALITY.md)を参照してください。
