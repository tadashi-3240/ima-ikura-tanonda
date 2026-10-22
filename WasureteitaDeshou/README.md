# 忘れていたでしょう（iOS）

指定場所に近づいたら知らせる忘れ物防止アプリ（Swift / SwiftUI / iOS 18+）。入力はテキスト中心。音声は iOS キーボードのマイクから。

## 実装済み

- **第1**: テキスト入力・「次へ」
- **第2**: 場所／用事抽出、MapKit 検索・候補／地図、予定一覧
- **第3**: 接近時ローカル通知（300/500/1000m）、専用音 `piroriron.caf`、Always 位置の導線

ビルド識別: **`build: stage3-geo-1`**

## 未実装

- 第4: 自動解除・履歴本実装
- 第5: 音声読み上げ（いまは通知音＋文字）

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

## 実機テスト（第3段階）

1. 設定で通知距離（300/500/1000）と「正確な距離は保証しない」文言を確認
2. 予定を登録 → 位置「常に」＋通知を許可
3. 画面に `build: stage3-geo-1` があること
4. 登録した場所の通知距離内に入る（またはシミュレータで位置をシミュレート）→ 「忘れていたでしょう？」＋用事文＋ピロリローン系の音
5. 予定削除／完了後は再通知されないこと
6. 巨大マイク画面が出ないこと

## 構成

[`docs/architecture.md`](docs/architecture.md)
