# 忘れていたでしょう（iOS）

指定場所に近づいたら知らせる忘れ物防止アプリ（Swift / SwiftUI / iOS 18+）。入力はテキスト中心。音声は iOS キーボードのマイクから使えます。

このディレクトリは既存の「今いくら頼んだ？」（Expo / Web）とは独立しています。既存プロジェクトは変更しません。

## いま実装されていること（第1段階）

- 起動直後は「登録」タブの**大きなテキスト入力欄**
- iOS キーボードのマイク（音声入力）でテキスト欄へ入力可能（アプリ独自の Speech 認識はなし）
- 「次へ」で文章を確定し、端末内に保持して表示
- 下部ナビ枠: 登録 / 予定一覧 / 履歴 / 設定（予定一覧・履歴はプレースホルダ）
- 起動時の音声自動開始は**なし**（削除済み）

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
4. 上部の実行先で **実機の iPhone**（iOS 18+）を選ぶ（キーボードのマイク確認は実機推奨）
5. Run（▶）でインストール＆起動

### 推奨環境

- macOS + Xcode 16 以降
- iPhone（iOS 18.0 以上）
- Bundle ID: `com.wasureteitadeshou.app`（必要なら Signing で変更可）

## 実機テスト手順（第1段階・テキスト入力）

1. アプリを起動する → 「登録」タブに大きな入力欄が開く（キーボードが出ること）
2. 手入力、またはキーボードの**マイク**をタップして話す → テキスト欄に文字が入る
3. 「次へ」をタップ → 「確定した文章」に同じ内容が表示・保持される
4. アプリを一度終了して再起動しても、下書き／確定文が残ること（端末内保存）
5. 「予定一覧」「履歴」はプレースホルダ文言のみ（未実装）
6. 「設定」にキーボード音声入力の案内があり、起動時自動開始トグルが**ない**こと

## 構成の参照

詳細なモジュール分割・段階ごとのファイル配置は [`docs/architecture.md`](docs/architecture.md) を参照。

アプリ内の主なパス:

```
WasureteitaDeshou/
├── WasureteitaDeshou.xcodeproj
└── WasureteitaDeshou/
    ├── App/                      # 起動・タブシェル
    ├── Features/Registration/    # テキスト入力・「次へ」
    ├── Features/Settings/
    ├── Features/Placeholders/
    ├── Models/                   # DraftUtteranceStore
    └── Resources/                # Info.plist, Assets
```
