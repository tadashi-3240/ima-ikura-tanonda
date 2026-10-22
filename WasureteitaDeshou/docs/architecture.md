# 忘れていたでしょう — プロジェクト構成案

iOS 18+ / SwiftUI / iPhone専用。既存 Expo・Web とは独立し、ルート直下の **`WasureteitaDeshou/`** に置く。

## 入力方針

- 起動直後はテキスト入力（大きな `TextEditor`）。独自巨大マイク／SFSpeech 自動開始は使わない。
- 音声は iOS キーボードのマイクから。画面内ステップ切替（cover / 不安定な NavigationPath に依存しない）。

## モジュール分割

| モジュール | 責務 | 段階 |
|---|---|---|
| **Features/Registration** | テキスト入力 → 内容確認 → 検索 phase | 1〜2 |
| **Features/Schedule** | 予定一覧・編集・削除・通知距離 | 2〜3 |
| **Features/Settings** | 通知距離デフォルト・権限・距離非保証の説明 | 3 |
| **Features/History** | 履歴 | 4（枠のみ） |
| **Services/PlaceSearch** | MapKit 検索 | 2 |
| **Services/LocationMonitor** | `CLCircularRegion` 監視 | 3 |
| **Services/ReminderNotifier** | ローカル通知＋`piroriron.caf` | 3 |
| **Services/AppNotifySettings** | デフォルト距離 300/500/1000 | 3 |
| **Services/ReminderStore** | 永続化＋監視同期 | 2〜3 |

## 権限

| 権限 | タイミング |
|---|---|
| 位置 When In Use | 店舗検索・地図 |
| 位置 Always | 予定登録時の説明シート／設定。バックグラウンド接近通知に推奨 |
| 通知 | 同上 |

## 第3段階（現行）の振る舞い

1. 予定登録時に `notifyDistanceMeters`（初期は設定のデフォルト、通常 1000）で円形領域を監視開始
2. 進入（または登録時点ですでに内側）でローカル通知: タイトル「忘れていたでしょう？」／本文「{用事}予定ですよ！」／音 `piroriron.caf`
3. 削除・手動完了で監視解除。距離は予定ごと・設定のデフォルトで変更可
4. **正確な距離は保証しない**（設定に明記）
5. ビルド識別: `build: stage3-geo-1`
6. 音の再生成: `python3 scripts/generate_piroriron_sound.py`（ffmpeg 必要）

### やらない（未実装）

- 第4: 滞在による自動解除・履歴本実装
- 第5: AVSpeech 読み上げ本実装

## 主要パス

```
WasureteitaDeshou/WasureteitaDeshou/
├── Services/LocationMonitor.swift
├── Services/ReminderNotifier.swift
├── Services/AppNotifySettings.swift
├── Resources/Sounds/piroriron.caf
└── Features/Settings/...
WasureteitaDeshou/scripts/generate_piroriron_sound.py
```
