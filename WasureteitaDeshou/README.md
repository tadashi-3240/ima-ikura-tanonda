# 忘れていたでしょう（iOS）

指定場所に近づいたら知らせる忘れ物防止アプリ（Swift / SwiftUI / iOS 18+）。入力はテキスト中心。音声は iOS キーボードのマイクから。

## 実装済み

- **第1**: テキスト入力・「次へ」
- **第2**: 場所／用事抽出、MapKit 検索・候補／地図、予定一覧
- **第3**: 接近時ローカル通知（300/500/1000m）、専用音 `piroriron.caf`、Always 位置の導線
- **第4**: 店舗付近の滞在で自動解除、履歴、ワンタップ再登録

ビルド識別: **`build: stage4-dwell-1`**

## 未実装

- 第5: 音声読み上げ（いまは通知音＋文字）。未実装を実装済みとはしない

## Mac で開く

Mac では `更新してXcodeを開く.command` をダブルクリック（初回は右クリック→開く）。

pbxproj にローカル署名があると `git pull` がコケやすいので、作業前は remote に合わせるのを推奨（上記 .command が同じことをします）:

```bash
cd /path/to/ima-ikura-tanonda
git fetch
git checkout cursor/wasureteita-stage1-aaa9
git reset --hard origin/cursor/wasureteita-stage1-aaa9
git log -1 --oneline
cd WasureteitaDeshou
open WasureteitaDeshou.xcodeproj
```

Signing で Team を選び、実機（iOS 18+）で Run。

### 通知音の再生成

```bash
cd WasureteitaDeshou
python3 scripts/generate_piroriron_sound.py   # ffmpeg が必要
```

## 実機テスト（第4段階 / dwell-1）

1. 設定で `build: stage4-dwell-1` と「自動解除（滞在）」の説明（正確な1分は保証しない）を確認
2. 予定を登録 → 位置「常に」＋通知を許可
3. 接近距離内で通知（第3どおり）を確認
4. 店舗付近（目安 50〜100m）に約1分滞在 → 予定が消え、履歴に登録日時・店舗・用事・解除日時が出る
5. 履歴の「再登録」で予定一覧に戻り、監視が再開すること
6. 予定一覧の「完了」／編集の「完了して履歴へ」でも履歴に残ること。削除は履歴に残さないこと
7. 自動解除後は同じ予定が再通知されないこと
8. 巨大マイク画面が出ないこと

## 構成

[`docs/architecture.md`](docs/architecture.md)
