# Gmail 一括既読プロ (bulk-read-gmail-imap) アプリケーション詳細仕様書

## 1. 概要 (Overview)

### 1.1 アプリ概要
「Gmail 一括既読プロ」は、GoogleのGmail API審査を完全に回避し、IMAPプロトコル（`imap.gmail.com:993` SSL/TLS）を介してGmail内の未読メールを直接取得し、ワンタップで一括既読化するクロスプラットフォーム（iOS / Android）Flutterアプリケーションです。

### 1.2 開発背景と目的
- **Gmail API審査回避**: REST APIの制限やGoogle Cloud Consoleの厳密な認証審査（制限付きスコープ審査）を受けずに、安全かつ即座に導入可能。
- **プライバシー保護**: ユーザーのメール本文やログイン認証情報を第三者サーバー経由せず、すべて端末内の暗号化領域（Keychain / Keystore）のみでローカル処理。
- **マネタイズ構造**: RevenueCatを活用し、無料版（50件制限）と有料プロ版（全件一括既読化＆マルチアカウント対応）のフリーミアムモデルを提供。

### 1.3 主要技術スタック
| 分類 | 使用技術 / パッケージ | バージョン / 詳細 |
| :--- | :--- | :--- |
| **フレームワーク** | Flutter SDK | `>=3.0.0 <4.0.0` (Dart 3.x) |
| **状態管理** | `provider` | `^6.1.2` (MultiProvider構造) |
| **IMAP通信** | `enough_mail` | `^2.1.4` (`ImapClient` 通信) |
| **セキュアストレージ** | `flutter_secure_storage` | `^9.0.0` (Keychain / EncryptedSharedPreferences) |
| **課金サブスクリプション** | `purchases_flutter` | `^8.0.0` (RevenueCat SDK) |
| **ブラウザ起動** | `url_launcher` | `^6.3.0` (Googleアプリパスワード設定ページ移動用) |
| **UIコンポーネント** | `flutter_spinkit`, `cupertino_icons` | マテリアル＆ダークテーマ統合 |

---

## 2. システムアーキテクチャ (System Architecture)

### 2.1 全体構造図
```
[ UI Layer (Screens & Modals) ]
       │
       ▼
[ Provider Layer (State Management) ]
 ├── AuthProvider
 ├── MailProvider
 └── PurchaseProvider
       │
       ▼
[ Service Layer (Business Logic & External API) ]
 ├── AuthService        ───► flutter_secure_storage (Keychain/Keystore)
 ├── MailService        ───► enough_mail (imap.gmail.com:993)
 └── PurchaseService    ───► purchases_flutter (RevenueCat REST Client)
       │
       ▼
[ Config & Models Layer ]
 ├── EnvConfig          ───► --dart-define-from-file (環境変数)
 └── UserCredentials    ───► データモデル＆入力形式バリデーション
```

### 2.2 ディレクトリ構成
```
lib/
├── config/
│   └── env_config.dart          # --dart-define-from-file 環境設定読み込み
├── models/
│   └── user_credentials.dart    # アカウント資格情報モデル＆検証ロジック
├── providers/
│   ├── auth_provider.dart       # アカウント認証・保持状態管理
│   ├── mail_provider.dart       # IMAP既読処理実行状態管理
│   └── purchase_provider.dart   # RevenueCat課金・Pro権限状態管理
├── screens/
│   ├── account_switcher_modal.dart # アカウント切替・追加・削除ダイアログ
│   ├── login_screen.dart        # ログイン＆アカウント追加画面
│   ├── main_screen.dart         # メイン画面（一括既読アクション）
│   └── paywall_modal.dart       # Pro版購入・復元プロモーション画面
├── services/
│   ├── auth_service.dart        # セキュアストレージへの認証情報CRUD＆移行
│   ├── mail_service.dart        # IMAP通信・ソケット処理・UNSEEN既読化
│   └── purchase_service.dart    # RevenueCat API連携＆同一端末権限共有
└── main.dart                    # エントリポイント・MultiProvider設定・AuthGate
```

---

## 3. 機能仕様の詳細 (Detailed Functional Specifications)

### 3.1 環境設定・セキュリティ保護 (`EnvConfig`)
- **環境変数の動的注入**: ソースコードへのAPIキー直接書き込みを完全に防止するため、起動時に `--dart-define-from-file` を必須化。
- **未設定時の安全停止**: `EnvConfig.isConfigured` によるチェックを実施。環境変数が存在しない場合、アプリ起動時に警告画面 (`EnvErrorScreen`) を表示して処理を遮断。
- **環境設定ファイル構造**:
  - `REVENUECAT_KEY_IOS`: iOS用 RevenueCat パブリックAPIキー
  - `REVENUECAT_KEY_ANDROID`: Android用 RevenueCat パブリックAPIキー
  - `IS_PRODUCTION`: 本番フラグ (Boolean)

### 3.2 認証＆マルチアカウント管理 (`AuthService` / `AuthProvider`)
- **Google アプリパスワード認証**:
  - 16桁の英数字で構成される「Google アプリ パスワード」を使用してログイン。
  - 入力時にスペースが混入している場合は自動的に除去 (`appPassword.replaceAll(' ', '')`)。
  - メールアドレスは正規表現 `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$` でバリデーション。
- **暗号化保存**:
  - iOS: `KeychainAccessibility.first_unlock` を使用して Keychain に保存。
  - Android: `encryptedSharedPreferences: true` を指定して暗号化領域へ保存。
- **マルチアカウント互換性マイグレーション**:
  - レガシー（v1）の単一アカウント保存形式 (`gmail_user_email`, `gmail_app_password`) が検出された場合、自動的にマルチアカウント構造（v2 JSON配列）へシームレスにデータ移行。
- **アカウント操作**:
  - アカウント切り替え: 選択したアカウントを `gmail_active_email_v2` に更新し、RevenueCat ユーザーセッションも即座に切り替え。
  - アカウント追加: ログイン済みの場合は **Pro版限定機能** としてガード。追加後は新アカウントに自動切り替え。
  - アカウント削除: 指定したメールアドレスの認証情報を削除。削除対象がアクティブアカウントだった場合、残りの中から別のアカウントをアクティブ化。アカウントがゼロになった場合は未ログイン状態に自動遷移。
  - 全ログアウト: Secure Storage 内のすべての情報を消去し、RevenueCat のセッションをリセット (`PurchaseService.logout()`)。

### 3.3 IMAP直結による一括既読機能 (`MailService` / `MailProvider`)
- **通信手順**:
  1. `imap.gmail.com:993` へ SSL/TLS 安全接続を確立 (`connectToServer`)。
  2. ユーザーの `email` と `appPassword` でログイン認証 (`login`)。
  3. `INBOX` フォルダーを選択 (`selectInbox`)。
  4. 検索条件 `'UNSEEN'` で未読メッセージのシーケンス番号一覧を取得 (`searchMessages`)。
  5. **フリーミアム件数制限**:
     - **Freeプラン (`isPro = false`)**: 未読件数が50件を超える場合、最新の50件のみを抽出して対象シーケンスを作成。
     - **Proプラン (`isPro = true`)**: 未読メッセージの全件を対象シーケンスとして処理。
  6. 対象シーケンスに対して `markSeen` フラグを適用し、既読化を実行。
  7. 通信完了後、明示的に `logout` および `disconnect` を実行してソケットを切断。
- **重複実行防止**: `MailProvider._isProcessing` フラグにより、処理中の連続タップによる重複リクエストをロック。

### 3.4 課金＆サブスクリプション権限管理 (`PurchaseService` / `PurchaseProvider`)
- **RevenueCat SDK 統合**:
  - Entitlement ID: `pro_features`
  - 初回起動時・アプリフォアグラウンド復帰時 (`resumed`) に最新の購入権利状態を自動検証。
- **マルチアカウント＆端末内権限共有設計**:
  - 同一端末内で1つのアカウントが Pro を購入している場合、端末ローカルストレージ (`app_is_pro_unlocked_v2`) に記録。
  - 端末内で別のアカウントに切り替えた場合でも、Pro版権限を継続利用可能にする柔軟な設計。
- **クロスプラットフォームユーザー紐付け**:
  - `Purchases.logIn(email)` を実行し、Gmail アドレスを RevenueCat App User ID として紐付けることで、マルチデバイス間での権利同期を実現。
- **二重購入防止＆エラーハンドリング**:
  - 既に Pro 権限を所持しているユーザーが購入ボタンを押した場合は自動的にガード。
  - `PurchasesErrorCode.productAlreadyPurchasedError`（購入済みエラー）が発生した場合は自動的にリストアフロー (`restorePurchases()`) へフォールバック。

---

## 4. UI / 画面仕様 (UI Specifications)

### 4.1 デザインシステム概要
- **基本カラーパレット**:
  - 背景色: ピュアブラック (`#000000`)
  - カード / モーダル背景: ダークチャコール (`#141414`, `#1E1E1E`)
  - プライマリ・アクセントカラー: ヴィヴィッドレッド (`#FF434F`)
  - テキスト: ホワイト (`#FFFFFF`), セカンダリグレー (`#888888`), サブテキスト (`#444444`)
  - 成功表示: エメラルドグリーン (`#2E7D32` / `Colors.greenAccent`)

### 4.2 画面別仕様

#### ① 環境エラー画面 (`EnvErrorScreen`)
- `--dart-define-from-file` が指定されずに起動された際に安全のため表示。
- 赤色の警告アイコンと、正しい起動コマンド例 (`flutter run --dart-define-from-file=config/env.dev.json`) をコード表示。

#### ② 認証ゲート (`AuthGate`)
- 起動時に Secure Storage を確認し、アクティブな資格情報が存在すれば `MainScreen`、存在しなければ `LoginScreen` へ自動分岐。

#### ③ ログイン画面 (`LoginScreen`)
- **コンポーネント**:
  - アプリロゴ＆タイトル
  - Gmailアドレス入力フィールド（バリデーション付き）
  - アプリパスワード（16桁）入力フィールド（表示/非表示切り替え対応）
  - 「Googleアプリパスワードの取得方法」リンク (外部ブラウザ起動)
  - ログイン実行ボタン（IMAP接続テスト中はインジケーター表示）
  - セキュリティ保護に関する注記枠
- **アカウント追加モード (`isAddingAccount: true`)**:
  - AppBarに戻るボタンを表示。
  - Proユーザーでない場合は追加処理をブロックし、Paywallモーダルを表示。

#### ④ メイン画面 (`MainScreen`)
- **AppBar**:
  - タイトル「一括既読プロ」
  - 右上「アカウント切替・管理」アイコンボタン (タップで `AccountSwitcherModal` 表示)
- **アクティブアカウント表示チップ**:
  - アプリ上部に現在ログイン中のマスクされたメールアドレス (`abc***@gmail.com`) を表示。
- **中央アクション領域**:
  - 直径 240px の巨大グローリングボタン。
  - 処理前: 白丸の中に赤チェックアイコン + 「すべて既読にする」テキスト。
  - 処理中: スピナー表示 + 「既読化処理中...」テキスト。
- **下部プラン表示バー**:
  - Free版: 「無料版：1回で最新50件まで既読（タップしてProにアップグレード）」+ 「アップグレード」バッジ。
  - Pro版: 「有料版：一回ですべての未読を処理します」 (緑色のチェックアイコン)。

#### ⑤ アカウント切替・管理モーダル (`AccountSwitcherModal`)
- ハーフサイズBottomSheet形式で表示。
- 保存済みアカウントの一覧をカード形式で表示。
- 選択中のアカウントにはチェックマークとハイライト枠。
- 右端のゴミ箱アイコンタップで個別アカウント削除ダイアログを表示。
- 「アカウントを追加」ボタン（Freeユーザーの場合はPROバッジ付き・Paywallへ誘導）。
- 「すべてのアカウントからログアウト」ボタン（確認ダイアログ表示後に初期化）。

#### ⑥ 課金ペイウォールモーダル (`PaywallModal`)
- クラウンアイコンとPro版機能一覧リスト（全件一括既読、複数アカウント無制限管理、高速IMAP通信、プライバシー保護）。
- 「Pro版を購入する」ボタン（購入手続き・スピナー表示）。
- 「購入内容を復元する (Restore)」テキストボタン。

---

## 5. データ仕様 & 暗号化キー一覧 (Data Specifications)

### 5.1 Flutter Secure Storage 格納キー
| キー名 | データ型 | 説明 |
| :--- | :--- | :--- |
| `gmail_accounts_list_v2` | String (JSON Array) | 保存済み全アカウント情報 (`[{"email": "...", "appPassword": "..."}, ...]`) |
| `gmail_active_email_v2` | String | 現在アクティブとして選択されているメールアドレス |
| `app_is_pro_unlocked_v2` | String | 端末内Pro権限フラグ (`"true"` で有効化) |
| `gmail_user_email` | String (レガシー) | 旧バージョン単一アカウント用メールアドレス（自動移行用） |
| `gmail_app_password` | String (レガシー) | 旧バージョン単一アカウント用アプリパスワード（自動移行用） |

---

## 6. ビルド＆運用手順 (Build & Operation Guide)

### 6.1 環境設定ファイルの作成
プロジェクト直下の `config/` ディレクトリに環境別ファイルを作成します。

#### `config/env.dev.json` (開発環境用)
```json
{
  "REVENUECAT_KEY_IOS": "appl_YOUR_TEST_STORE_IOS_KEY",
  "REVENUECAT_KEY_ANDROID": "goog_YOUR_TEST_STORE_ANDROID_KEY",
  "IS_PRODUCTION": false
}
```

#### `config/env.prod.json` (本番環境用)
```json
{
  "REVENUECAT_KEY_IOS": "appl_PROD_KEY_HERE",
  "REVENUECAT_KEY_ANDROID": "goog_PROD_KEY_HERE",
  "IS_PRODUCTION": true
}
```

### 6.2 実行・ビルドコマンド

#### ローカル開発実行
```bash
flutter run --dart-define-from-file=config/env.dev.json
```

#### Android App Bundle 本番ビルド
```bash
flutter build appbundle --release --dart-define-from-file=config/env.prod.json
```

#### iOS IPA 本番ビルド
```bash
flutter build ipa --release --dart-define-from-file=config/env.prod.json
```

---

## 7. まとめ

本アプリケーションは、IMAP直結通信とローカル暗号化ストレージを活用することで、高いプライバシー保護性能とAPI制限のフリーを実現した実用的なメール処理ツールです。環境変数の定義切り分けとRevenueCatの堅牢な権利連携により、安全かつ拡張性の高いモバイルプロダクトとして設計されています。
