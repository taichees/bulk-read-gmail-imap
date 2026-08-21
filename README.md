# Gmail 一括既読アプリ (IMAP Direct Connection)

Gmail API審査を完全に回避し、`enough_mail` を利用して直接 `imap.gmail.com:993`（SSL/TLS）に接続し、未読メールを一括で既読化するiOS/Android対応のFlutterアプリケーションです。

---

## 🌟 特徴

- **Gmail API審査不要**: IMAP直結により、Google Cloud Consoleの審査や制限を気にせずアプリを配布・運用可能。
- **マルチアカウント＆セキュア保存**: `flutter_secure_storage` により、複数アカウントのログイン情報を端末の暗号化領域（Keychain / Keystore）へ安全に保存・1タップ切り替え。
- **RevenueCat 課金連携**: `purchases_flutter` を用いたフリーミアムモデル構築。
  - **無料版**: 1回の実行で最新50件まで既読化。
  - **有料版 (Pro)**: 未読メールを「全件一括」で既読化。
- **環境別API Key分離管理（Git漏洩防止）**: 開発用（Test Store）と本番用のAPIキーを分離管理し、ソースコード内に鍵をハードコーディングしない安全な設計。

---

## 🔑 環境変数・RevenueCat API Keyの管理

本アプリではFlutter公式推奨の `--dart-define-from-file` を使用し、秘密鍵をソースコードにハードコーディングせず分離管理しています。起動時に指定がない場合は安全のため起動を中断し、環境エラー画面が表示されます。

### 1. 設定ファイルの配置

プロジェクト直下の `config/` ディレクトリに環境別設定ファイルを配置します。

- `config/env.json.example` (Gitにコミットされる設定テンプレート)
- `config/env.dev.json` (ローカル開発用・Test Storeキー／**Git除外**)
- `config/env.prod.json` (本番用キー／**Git除外**)

※ `config/*.json` （`.example` を除く）は `.gitignore` に登録されているため、Gitにコミットされません。

#### `config/env.dev.json` (ローカル開発時)

```json
{
  "REVENUECAT_KEY_IOS": "appl_YOUR_TEST_STORE_IOS_KEY",
  "REVENUECAT_KEY_ANDROID": "goog_YOUR_TEST_STORE_ANDROID_KEY",
  "IS_PRODUCTION": false
}
```

#### `config/env.prod.json` (本番ビルド時)

```json
{
  "REVENUECAT_KEY_IOS": "appl_PROD_KEY_HERE",
  "REVENUECAT_KEY_ANDROID": "goog_PROD_KEY_HERE",
  "IS_PRODUCTION": true
}
```

---

## 🚀 実行・ビルドコマンド

起動時は必ず `--dart-define-from-file` オプションで該当の環境設定ファイルを渡してください。設定ファイルが指定されていない場合、アプリは起動時に警告画面を出力します。

### 0. エミュレーターの起動

```bash
flutter emulators
flutter emulators --launch <エミュレータID>
flutter devices
```

### 1. ローカル開発（dev設定ファイルを指定）

```bash
flutter run --dart-define-from-file=config/env.dev.json
```

### 2. 本番用ビルド（prod設定ファイルを指定）

```bash
# Android App Bundle 本番ビルド
flutter build appbundle --release --dart-define-from-file=config/env.prod.json

# iOS IPA 本番ビルド
flutter build ipa --release --dart-define-from-file=config/env.prod.json
```

---

## 🔐 ユーザー側の事前設定 (Googleアプリパスワードの取得)

本アプリはIMAP通信を使用するため、Googleアカウントでの事前設定が必要です。

1. [Googleアカウント管理](https://myaccount.google.com/) にアクセス。
2. **2段階認証プロセス** を有効化。
3. [アプリ パスワード](https://myaccount.google.com/apppasswords) 画面でアプリパスワード（16桁）を生成。
4. 生成された16桁の英数字をアプリに入力してログイン。

---

## 🔒 プライバシーポリシー

- **URL**: [https://bulk-read-gmail-privacy.tsushinryo.com](https://bulk-read-gmail-privacy.tsushinryo.com)
- **ソース管理**: `web_privacy/index.html`
