# 忘れていたでしょう（iOS）

指定場所に近づいたら知らせる忘れ物防止アプリ（Swift / SwiftUI / iOS 18+）。入力はテキスト中心。音声は iOS キーボードのマイクから。

## 実装済み

- **第1**: テキスト入力・「次へ」
- **第2**: 場所／用事抽出、MapKit 検索・候補／地図、予定一覧
- **第3**: 接近時ローカル通知（300/500/1000m）、専用音 `piroriron.caf`、Always 位置の導線
- **第4**: 店舗付近の滞在で自動解除、履歴、ワンタップ再登録
- **自宅**: 設定で自宅を保存し、「帰ったら洗濯」などを自宅へ登録（`stage4-home-1`）

ビルド識別: **`build: stage4-home-1`**

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

## 実機テスト（自宅 / home-1）

1. 設定で `build: stage4-home-1` と「自宅を設定」を確認
2. 「いまの位置を自宅にする」または地図ピンで自宅を保存
3. 登録で「帰ったら洗濯をする」→ 内容確認で「自宅を使う」→ 距離確認して登録
4. 接近通知・滞在解除・履歴は店舗と同じ（場所名は「自宅」など）
5. 自宅未設定でも「自宅を使う」からいまの位置でその場登録できること
6. 巨大マイク画面が出ないこと

## 構成

[`docs/architecture.md`](docs/architecture.md)
