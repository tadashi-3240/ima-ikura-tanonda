# 忘れていたでしょう — プロジェクト構成案

iOS 18+ / SwiftUI / iPhone専用。既存リポジトリ内の Expo・Web（「今いくら頼んだ？」）とは独立し、ルート直下の **`WasureteitaDeshou/`** に置く。

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
        ├── Services/       # 第2段階以降で拡充
        ├── Models/         # 第2段階以降で拡充
        └── Resources/
```

## モジュール分割

| モジュール | 責務 | 導入段階 |
|---|---|---|
| **App** | `@main`、タブシェル、起動ルーティング | 1 |
| **Features/VoiceInput** | マイク UI、Speech 認識、許可フロー | 1 |
| **Features/Settings** | 起動時自動開始などのユーザー設定 | 1 |
| **Features/Schedule** | 予定一覧・編集・削除・手動完了 | 3〜4（枠は1でプレースホルダ） |
| **Features/History** | 履歴・ワンタップ再登録 | 4（枠は1でプレースホルダ） |
| **Services/Speech** | `SFSpeechRecognizer` / マイクセッション | 1 |
| **Services/PlaceSearch** | MapKit 店舗検索・候補 | 2 |
| **Services/Location** | Core Location、距離監視 | 3 |
| **Services/Notification** | ローカル通知・専用音 | 3 |
| **Services/Persistence** | 端末内ストア（予定・履歴・設定） | 2〜4（設定の UserDefaults は1から） |
| **Models** | `Reminder` / `HistoryEntry` など | 2〜4 |

依存の向きは **Features → Services → Models**。UI が Speech/MapKit を直接握らないよう、認識・検索は Service 経由にする。

## 画面構成

下部タブ（大きめ日本語ラベル）:

| タブ | 画面 | 第1段階 |
|---|---|---|
| 登録 | `VoiceInputView` | **実装** — 中央大マイク、認識結果の大きい表示 |
| 予定一覧 | `ScheduleListView` | プレースホルダのみ |
| 履歴 | `HistoryView` | プレースホルダのみ |
| 設定 | `SettingsView` | **実装** — 「起動時に音声入力を自動開始」トグル |

起動直後は「登録」タブ。設定で自動開始がオンなら、許可済みのとき認識を自動で開始する。

## 権限（説明タイミング）

| 権限 | Info.plist キー | 取得タイミング | 段階 |
|---|---|---|---|
| マイク | `NSMicrophoneUsageDescription` | 初回マイクタップ（または自動開始）時、説明シート後 | 1 |
| 音声認識 | `NSSpeechRecognitionUsageDescription` | 同上 | 1 |
| 位置（When In Use → Always） | `NSLocationWhenInUse…` / `NSLocationAlwaysAndWhenInUse…` | 場所登録・通知設定時 | 2〜3 |
| 通知 | —（UNUserNotificationCenter） | 初回リマインダー登録時 | 3 |

第1段階では位置・通知の本実装と Info キー追加は行わない（必要になった段階で追加）。

## 段階ごとのファイル配置

### 第1段階（今回）— 音声入力と文字変換

```
WasureteitaDeshou/WasureteitaDeshou/
├── App/
│   ├── WasureteitaDeshouApp.swift
│   └── RootTabView.swift
├── Features/
│   ├── VoiceInput/
│   │   ├── VoiceInputView.swift
│   │   └── PermissionExplainerView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Placeholders/
│       ├── ScheduleListView.swift
│       └── HistoryView.swift
├── Services/
│   ├── SpeechRecognizer.swift
│   └── AppSettingsStore.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

未実装（第2段階以降）: 場所／用事の抽出、MapKit、候補選択、GPS 通知、自動解除、履歴本実装、音声読み上げ。

### 第2段階 — 店舗検索と場所の確定

追加予定: `Services/PlaceSearchService.swift`、`Models/ParsedUtterance.swift`、`Features/PlaceConfirm/`（候補リスト・地図指定）、音声結果からの簡易パース。

### 第3段階 — GPS 位置通知

追加予定: `Services/LocationMonitor.swift`、`Services/ReminderNotifier.swift`、距離設定 UI、専用通知音リソース、Always 位置許可。

### 第4段階 — 自動解除と履歴

追加予定: 滞在判定、`Models/Reminder` / `HistoryEntry` 永続化、予定一覧・履歴の本実装、再登録。

### 第5段階 — 音声読み上げの実現可能性検証

追加予定: TTS バックグラウンド検証ノートと、不可時は「通知音＋文字」を正式フォールバックとする実装方針。**未検証を実装済みと書かない。**

## 技術メモ

- 最低デプロイ: iOS 18.0、デバイスファミリー iPhone。
- 音声認識はオンデバイス優先（`requiresOnDeviceRecognition` が使える環境では true）。ネットワーク必須時はユーザーに明示。
- データは端末内のみ（ログインなし）。第1段階の設定は `UserDefaults` / `@AppStorage` で十分。
- Linux CI では Xcode ビルド不可。実機・シミュレータ検証は macOS + Xcode 上で行う（手順は `WasureteitaDeshou/README.md`）。

## 既存コードとの境界

- `mobile/`・`src/`・ルートの Vite/Expo 設定は変更しない。
- ルート `README.md` への追記は任意・最小限。本アプリの Open / 実機手順は `WasureteitaDeshou/README.md` に集約する。
