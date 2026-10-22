# 忘れていたでしょう — プロジェクト構成案

iOS 18+ / SwiftUI / iPhone専用。既存リポジトリ内の Expo・Web（「今いくら頼んだ？」）とは独立し、ルート直下の **`WasureteitaDeshou/`** に置く。

## 入力方針（訂正済み）

- **起動直後の主画面はテキスト入力**（大きな `TextEditor`）。独自の巨大マイク UI や `SFSpeechRecognizer` の自動開始は使わない。
- 音声を使う場合は、**iOS キーボードのマイク（音声入力）** からテキスト欄に入れる。
- 「次へ」で文章を確定し、場所／用事の確認 → MapKit 検索へ進む。

## ディレクトリ配置（リポジトリ）

```
ima-ikura-tanonda/
├── mobile/                 # Expo — 変更禁止方針
├── src/                    # Vite Web — 変更禁止方針
└── WasureteitaDeshou/
    ├── README.md
    ├── docs/architecture.md
    ├── WasureteitaDeshou.xcodeproj
    └── WasureteitaDeshou/
        ├── App/
        ├── Features/
        ├── Models/
        ├── Services/
        └── Resources/
```

## モジュール分割

| モジュール | 責務 | 導入段階 |
|---|---|---|
| **App** | `@main`、タブシェル | 1 |
| **Features/Registration** | テキスト入力、「次へ」 | 1 |
| **Features/PlaceConfirm** | 場所／用事確認、候補一覧、地図指定、登録確認 | 2 |
| **Features/Schedule** | 予定一覧・簡易編集・削除・手動完了 | 2 |
| **Features/Settings** | 入力・未実装機能の案内 | 1〜2 |
| **Features/History** | 履歴・再登録 | 4（枠のみ） |
| **Models** | `DraftUtteranceStore` / `ParsedUtterance` / `PlaceCandidate` / `Reminder` | 1〜2 |
| **Services/UtteranceParser** | 「で」等で場所と用事を分割 | 2 |
| **Services/PlaceSearch** | MapKit `MKLocalSearch`・逆ジオコード | 2 |
| **Services/ReminderStore** | 予定の UserDefaults 永続化 | 2 |
| **Services/UserLocationProvider** | When In Use の現在地（検索ヒント） | 2 |
| **Services/Location**（ジオフェンス） | Core Location 監視 | 3（未実装） |
| **Services/Notification** | ローカル通知・専用音 | 3（未実装） |

依存の向きは **Features → Services → Models**。

## 画面構成

| タブ | 画面 | 状態 |
|---|---|---|
| 登録 | `RegistrationInputView` → `PlaceResolveView` | **実装**（テキスト → 解析 → 検索／候補／地図 → 保存） |
| 予定一覧 | `ScheduleListView` | **実装**（表示・簡易編集・削除・手動完了） |
| 履歴 | `HistoryView` | プレースホルダのみ |
| 設定 | `SettingsView` | 案内のみ（通知設定は第3段階） |

## 権限

| 権限 | タイミング | 段階 |
|---|---|---|
| 位置 When In Use | 場所検索・地図指定の補助 | 2（実装） |
| 位置 Always | ジオフェンス通知 | 3（未実装） |
| 通知 | 初回リマインダー通知 | 3（未実装） |
| アプリ独自マイク／Speech | — | 不採用 |

## 段階ごとのファイル（第2段階・現行）

```
WasureteitaDeshou/WasureteitaDeshou/
├── App/
├── Features/
│   ├── Registration/RegistrationInputView.swift
│   ├── PlaceConfirm/
│   │   ├── PlaceResolveView.swift
│   │   ├── PlaceCandidateListView.swift
│   │   └── MapPlacePickerView.swift
│   ├── Schedule/ScheduleListView.swift
│   ├── Settings/SettingsView.swift
│   └── Placeholders/HistoryView.swift
├── Models/
│   ├── DraftUtteranceStore.swift
│   ├── ParsedUtterance.swift
│   ├── PlaceCandidate.swift
│   └── Reminder.swift
├── Services/
│   ├── UtteranceParser.swift
│   ├── PlaceSearchService.swift
│   ├── ReminderStore.swift
│   └── UserLocationProvider.swift
└── Resources/
```

### 第2段階の振る舞い

1. テキスト確定 → 場所／用事を抽出（主に「で」分割。編集可）
2. MapKit 検索: **1件なら確認へ**、**複数なら一覧**、**0件／場所なしなら地図**
3. 確定後に `Reminder` を端末内保存 → 予定一覧に表示
4. **やらない**: GPS ジオフェンス、ローカル通知、専用音、履歴本実装

### 第3段階以降（未実装）

- 第3: 位置通知・距離設定・Always 許可・専用音
- 第4: 滞在による自動解除・履歴・再登録
- 第5: TTS 検証（未検証を実装済みと書かない）

## 技術メモ

- iOS 18+ / iPhone のみ。ログインなし。予定は JSON + UserDefaults。
- Linux ではビルド不可。実機手順は `WasureteitaDeshou/README.md`。
