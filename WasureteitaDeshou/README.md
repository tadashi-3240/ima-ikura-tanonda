# 忘れていたでしょう（iOS）

指定場所に近づいたら知らせる忘れ物防止アプリ（Swift / SwiftUI / iOS 18+）。入力はテキスト中心。音声は iOS キーボードのマイクから。

## 実装済み

- **第1**: テキスト入力・「次へ」
- **第2**: 場所／用事抽出、MapKit 検索・候補／地図、予定一覧
- **第3**: 接近時ローカル通知（300/500/1000m）、専用音 `piroriron.caf`、Always 位置の導線
- **第4**: 店舗付近の滞在で自動解除、履歴、ワンタップ再登録
- **自宅**: 設定で自宅を保存し、「帰ったら洗濯」などを自宅へ登録（`stage4-home-1`）
- **呼び名**: 登録した場所を端末内に覚え、次回検索で候補先頭に出す（`stage4-places-1`）
- **接近通知の重複抑止**: 圏内にいるあいだ1回まで（`stage4-dedupe-1`）

ビルド識別: **`build: stage4-dedupe-1`**

## 未実装

- 第5: 音声読み上げ（いまは通知音＋文字）。未実装を実装済みとはしない
- クラウド同期

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

## 実機テスト（接近通知 dedupe / dedupe-1）

1. 設定で `build: stage4-dedupe-1` を確認
2. 予定の通知圏内にいる状態で Run／アプリをフォアグラウンドへ戻す
3. 接近通知が **同じ予定について1回だけ** 届くこと（短時間に2〜3回来ないこと）
4. 圏外に出てから再度入ると、また1回通知されること

## 実機テスト（呼び名 / places-1）

1. 地図などで「水江の製油所」などを予定登録 → 設定「保存した場所」に出ること
2. 新規登録で「製油所」や「水江」と入力 → 候補の先頭（または一意なら確認）に出ること
3. 設定で呼び名の編集・削除ができること
4. 「自宅を使う」で登録しても SavedPlace に自宅が二重保存されないこと

## 構成

[`docs/architecture.md`](docs/architecture.md)
