# 忘れていたでしょう — プロジェクト構成案

iOS 18+ / SwiftUI / iPhone専用。既存 Expo・Web とは独立し、ルート直下の **`WasureteitaDeshou/`** に置く。

## 入力方針

- 起動直後はテキスト入力（大きな `TextEditor`）。独自巨大マイク／SFSpeech 自動開始は使わない。
- 音声は iOS キーボードのマイクから。画面内ステップ切替（cover / 不安定な NavigationPath に依存しない）。

## モジュール分割

| モジュール | 責務 | 段階 |
|---|---|---|
| **Features/Registration** | テキスト入力 → 内容確認 → 検索 phase | 1〜2 |
| **Features/Schedule** | 予定一覧・編集・削除・手動完了（履歴へ） | 2〜4 |
| **Features/History** | 履歴表示・ワンタップ再登録 | 4 |
| **Features/Settings** | 通知距離・権限・距離／滞在非保証の説明 | 3〜4 |
| **Services/PlaceSearch** | MapKit 検索 | 2 |
| **Services/LocationMonitor** | 接近＋滞在の `CLCircularRegion`、限定的位置更新 | 3〜4 |
| **Services/ReminderNotifier** | ローカル通知＋`piroriron.caf` | 3 |
| **Services/AppNotifySettings** | デフォルト距離 300/500/1000 | 3 |
| **Services/ReminderStore** | 予定・履歴の永続化＋監視同期 | 2〜4 |

## 権限

| 権限 | タイミング |
|---|---|
| 位置 When In Use | 店舗検索・地図 |
| 位置 Always | 予定登録時の説明シート／設定。BG 接近・滞在に推奨 |
| 通知 | 同上 |

## 第4段階（現行）の振る舞い

1. 予定ごとに **接近領域**（`notifyDistanceMeters`）と **滞在領域**（約 75m）を監視
2. 接近進入でローカル通知（第3と同じ）。退出で再通知フラグ解除
3. 滞在領域に進入したら計測開始。滞在中のみ限定的な位置更新（常時 GPS は使わない）
4. 約1分滞在で自動解除 → 履歴へ。監視停止。**再通知しない**
5. 手動完了も履歴へ。削除は履歴に残さない。編集・削除の既存操作は維持
6. 履歴表示: 登録日時・店舗名・用事・解除日時。ワンタップ再登録で監視再開
7. **正確な距離は保証しない**／**バックグラウンドで正確な1分は保証できない**（設定に明記）
8. ビルド識別: `build: stage4-dwell-1`

### やらない（未実装）

- 第5: AVSpeech 読み上げ本実装

## 主要パス

```
WasureteitaDeshou/WasureteitaDeshou/
├── Models/ReminderHistoryItem.swift
├── Services/LocationMonitor.swift
├── Services/ReminderStore.swift
├── Features/History/HistoryView.swift
├── Features/Settings/...
└── Resources/Sounds/piroriron.caf
```
