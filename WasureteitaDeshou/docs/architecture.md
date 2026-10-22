# 忘れていたでしょう — プロジェクト構成案

iOS 18+ / SwiftUI / iPhone専用。既存リポジトリ内の Expo・Web（「今いくら頼んだ？」）とは独立し、ルート直下の **`WasureteitaDeshou/`** に置く。

## 入力方針（訂正済み）

- **起動直後の主画面はテキスト入力**（大きな `TextEditor`）。独自の巨大マイク UI や `SFSpeechRecognizer` の自動開始は使わない。
- 音声を使う場合は、**iOS キーボードのマイク（音声入力）** からテキスト欄に入れる。
- 「次へ」で文章を確定・保持する。場所／用事の解析・MapKit は第2段階。

## ディレクトリ配置（リポジトリ）

```
ima-ikura-tanonda/          # 既存モノレポ（触らない）
├── mobile/                 # Expo「今いくら頼んだ？」— 変更禁止方針
├── src/                    # Vite Web — 変更禁止方針
└── WasureteitaDeshou/      # 本アプリ（新規）
    ├── README.md
    ├── WasureteitaDeshou.xcodeproj
    └── WasureteitaDeshou/
        ├── App/
        ├── Features/
        ├── Models/
        ├── Services/       # 第2段階以降で拡充
        └── Resources/
```

## モジュール分割

| モジュール | 責務 | 導入段階 |
|---|---|---|
| **App** | `@main`、タブシェル | 1 |
| **Features/Registration** | テキスト入力 UI、「次へ」で確定 | 1 |
| **Features/Settings** | 設定画面（入力の説明など） | 1 |
| **Features/Schedule** | 予定一覧・編集・削除・手動完了 | 2〜4（枠は1でプレースホルダ） |
| **Features/History** | 履歴・ワンタップ再登録 | 4（枠は1でプレースホルダ） |
| **Models/DraftUtteranceStore** | 入力文・確定文の端末内保持 | 1 |
| **Services/PlaceSearch** | MapKit 店舗検索・候補 | 2 |
| **Services/Location** | Core Location、距離監視 | 3 |
| **Services/Notification** | ローカル通知・専用音 | 3 |
| **Services/Persistence** | 予定・履歴の永続化 | 2〜4 |
| **Models** | `Reminder` / `ParsedUtterance` など | 2〜4 |

依存の向きは **Features → Services → Models**。

## 画面構成

下部タブ（大きめ日本語ラベル）:

| タブ | 画面 | 第1段階 |
|---|---|---|
| 登録 | `RegistrationInputView` | **実装** — 大きなテキスト欄、「次へ」、確定文の表示 |
| 予定一覧 | `ScheduleListView` | プレースホルダのみ |
| 履歴 | `HistoryView` | プレースホルダのみ |
| 設定 | `SettingsView` | **実装** — キーボード音声入力の案内（起動時自動開始はなし） |

起動直後は「登録」タブ（テキスト入力）。

## 権限（説明タイミング）

| 権限 | Info.plist キー | 取得タイミング | 段階 |
|---|---|---|---|
| （アプリ独自のマイク／Speech） | — | **不要**（キーボード音声入力は OS 側） | — |
| 位置（When In Use → Always） | `NSLocationWhenInUse…` / `NSLocationAlwaysAndWhenInUse…` | 場所登録・通知設定時 | 2〜3 |
| 通知 | —（UNUserNotificationCenter） | 初回リマインダー登録時 | 3 |

## 段階ごとのファイル配置

### 第1段階（現行）— テキスト入力と確定

```
WasureteitaDeshou/WasureteitaDeshou/
├── App/
│   ├── WasureteitaDeshouApp.swift
│   └── RootTabView.swift
├── Features/
│   ├── Registration/
│   │   └── RegistrationInputView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Placeholders/
│       ├── ScheduleListView.swift
│       └── HistoryView.swift
├── Models/
│   └── DraftUtteranceStore.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

削除済み（方針訂正）: 独自巨大マイク UI、`SFSpeechRecognizer`、起動時自動開始設定、マイク／Speech の Info.plist キー。

未実装（第2段階以降）: 場所／用事の抽出、MapKit、候補選択、GPS 通知、自動解除、履歴本実装、音声読み上げ。

### 第2段階 — 店舗検索と場所の確定

追加予定: `Services/PlaceSearchService.swift`、`Models/ParsedUtterance.swift`、`Features/PlaceConfirm/`（候補リスト・地図指定）、確定文からの簡易パース、予定の端末内保存と一覧表示。

### 第3段階 — GPS 位置通知

追加予定: `Services/LocationMonitor.swift`、`Services/ReminderNotifier.swift`、距離設定 UI、専用通知音リソース、Always 位置許可。

### 第4段階 — 自動解除と履歴

追加予定: 滞在判定、`Models/Reminder` / `HistoryEntry` 永続化、予定一覧・履歴の本実装、再登録。

### 第5段階 — 音声読み上げの実現可能性検証

追加予定: TTS バックグラウンド検証ノートと、不可時は「通知音＋文字」を正式フォールバックとする実装方針。**未検証を実装済みと書かない。**

## 技術メモ

- 最低デプロイ: iOS 18.0、デバイスファミリー iPhone。
- データは端末内のみ（ログインなし）。確定文は `UserDefaults` で保持。
- Linux CI では Xcode ビルド不可。実機・シミュレータ検証は macOS + Xcode 上で行う（手順は `WasureteitaDeshou/README.md`）。

## 既存コードとの境界

- `mobile/`・`src/`・ルートの Vite/Expo 設定は変更しない。
- 本アプリの Open / 実機手順は `WasureteitaDeshou/README.md` に集約する。
