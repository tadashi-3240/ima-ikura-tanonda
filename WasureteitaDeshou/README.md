# 忘れていたでしょう（iOS）

指定場所に近づいたら知らせる、音声入力中心の忘れ物防止アプリ（Swift / SwiftUI / iOS 18+）。

このディレクトリは既存の「今いくら頼んだ？」（Expo / Web）とは独立しています。既存プロジェクトは変更しません。

## いま実装されていること（第1段階）

- 起動直後の音声入力画面（中央の大きなマイク）
- タップで音声認識開始。初回はマイク＋音声認識の説明付き許可
- 認識結果の大きい表示（日本語）
- 設定「起動時に自動開始」（デフォルトオフ）
- 下部ナビ枠: 登録 / 予定一覧 / 履歴 / 設定（予定一覧・履歴はプレースホルダ）

## まだないこと（第2段階以降）

- 場所／用事の抽出、MapKit 店舗検索、候補選択
- GPS による位置通知、専用通知音
- 自動解除・履歴の本実装、ワンタップ再登録
- 音声読み上げ（第5段階で検証）

## macOS で Xcode を開く

Linux ではビルドできません。Mac 上で次を実行してください。

1. このリポジトリをクローン（または pull）する
2. Finder またはターミナルでプロジェクトを開く:

```bash
cd WasureteitaDeshou
open WasureteitaDeshou.xcodeproj
```

3. Xcode 左のプロジェクト設定で **Signing & Capabilities** を開き、自分の **Team** を選ぶ（`DEVELOPMENT_TEAM` は空のままコミットしています）
4. 上部の実行先で **実機の iPhone**（iOS 18+）を選ぶ  
   ※ 音声認識・マイクはシミュレータでも一部動くことがありますが、**実機での確認を推奨**します
5. Run（▶）でインストール＆起動

### 推奨環境

- macOS + Xcode 16 以降
- iPhone（iOS 18.0 以上）
- Bundle ID: `com.wasureteitadeshou.app`（必要なら Signing で変更可）

## 実機テスト手順（第1段階）

1. アプリを起動する → 「登録」タブの音声入力画面が開く
2. 中央のマイクをタップする → 許可の説明シートが出る
3. 「許可する」を選び、システムのマイク／音声認識ダイアログを許可する
4. 「聞いています…」になり、話すと中央に大きく文字が出る
5. もう一度タップで停止できる。必要なら「クリア」で文字を消せる
6. 「設定」タブで「起動時に自動開始」をオンにし、アプリを一度終了して再起動する → 許可済みなら自動で聞き始める
7. 「予定一覧」「履歴」はプレースホルダ文言のみであること（未実装）を確認する

拒否した場合は、iPhone の「設定」→ アプリ名（または プライバシーとセキュリティ）からマイク／音声認識を許可し直してください。

## 構成の参照

詳細なモジュール分割・段階ごとのファイル配置は [`docs/architecture.md`](docs/architecture.md) を参照。

アプリ内の主なパス:

```
WasureteitaDeshou/
├── WasureteitaDeshou.xcodeproj
└── WasureteitaDeshou/
    ├── App/                 # 起動・タブシェル
    ├── Features/VoiceInput/ # マイク UI・許可説明
    ├── Features/Settings/   # 起動時自動開始
    ├── Features/Placeholders/
    ├── Services/            # SpeechRecognizer, AppSettingsStore
    └── Resources/           # Info.plist, Assets
```
