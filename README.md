# Gmail 一括既読プロ (IMAP Direct Connection)

Gmail API審査を完全に回避し、`enough_mail` を利用して直接 `imap.gmail.com:993`（SSL/TLS）に接続し、未読メールを一括で既読化するiOS/Android対応のFlutterアプリケーションです。

---

## 🌟 特徴

- **Gmail API審査不要**: IMAP直結により、Google Cloud Consoleの審査や制限を気にせずアプリを配布・運用可能。
- **セキュア認証情報保存**: `flutter_secure_storage` により、ログイン情報を端末の暗号化領域（Keychain / Keystore）へ安全に保存。
- **RevenueCat 課金連携**: `purchases_flutter` を用いたフリーミアムモデル構築。
  - **無料版**: 1回の実行で最新50件まで既読化。
  - **有料版 (Pro)**: 未読メールを「全件一括」で既読化。
- **洗練されたダークUI**: ピュアブラック (`#000000`) 背景に、240pxの光彩付き赤色円形メインボタンを配したUI。

---

## 📁 フォルダ構成

```
bulk-read-gmail-imap/
├── pubspec.yaml
├── android/
│   └── app/src/main/AndroidManifest.xml
├── ios/
│   └── Runner/Info.plist
├── lib/
│   ├── main.dart                       # アプリ登録・AuthGate
│   ├── models/
│   │   └── user_credentials.dart       # 認証情報モデル
│   ├── services/
│   │   ├── auth_service.dart           # KeyChain/KeyStore安全保存
│   │   ├── mail_service.dart           # IMAP (enough_mail) 一括既読ロジック
│   │   └── purchase_service.dart       # RevenueCat (purchases_flutter) 連携
│   ├── providers/
│   │   ├── auth_provider.dart          # ログイン・認証状態管理
│   │   ├── mail_provider.dart          # 既読化実行状態管理
│   │   └── purchase_provider.dart      # 有料会員判定管理
│   └── screens/
│       ├── login_screen.dart           # ログイン画面
│       ├── main_screen.dart            # メイン画面 (240pxボタン)
│       └── paywall_modal.dart          # 課金モーダル
└── README.md
```

---

## 🚀 セットアップ・実行手順

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. RevenueCat API Keyの設定

`lib/services/purchase_service.dart` 内の API Key を自身のRevenueCatプロジェクトのキーに置き換えてください。

```dart
static const String _revenueCatApiKeyIOS = 'appl_YOUR_REVENUECAT_IOS_KEY';
static const String _revenueCatApiKeyAndroid = 'goog_YOUR_REVENUECAT_ANDROID_KEY';
```

### 3. アプリの起動

```bash
flutter emulators
2 available emulators:

Id                  • Name          • Manufacturer • Platform

apple_ios_simulator • iOS Simulator • Apple        • ios
Pixel_8a            • Pixel 8a      • Google       • android

# Android
flutter emulators --launch Pixel_8a
flutter run -d Pixel_8a

# iOS
flutter emulators --launch apple_ios_simulator
flutter run -d apple_ios_simulator
```

---

## 🔐 ユーザー側の事前設定 (Googleアプリパスワードの取得)

本アプリはIMAP通信を使用するため、Googleアカウントでの事前設定が必要です。

1. [Googleアカウント管理](https://myaccount.google.com/) にアクセス。
2. **2段階認証プロセス** を有効化。
3. [アプリ パスワード](https://myaccount.google.com/apppasswords) 画面でアプリパスワード（16桁）を生成。
4. 生成された16桁の英数字をアプリに入力してログイン。
