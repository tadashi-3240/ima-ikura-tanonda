# 協豊ランゲージ（キーボード MVP）

Xcode で `KyohoranguageKeyboard.xcodeproj` を開き、**KyohoranguageHost** を実機に **再インストール**（Run）。

## 現状

1. キーボード一覧・地球儀表示
2. 協豊専用辞書補正 + ホスト CRUD
3. **音声入力（ホスト優先）+ 辞書補正 + 結果を貼る**

## 音声の使い方（確実な順）

1. 協豊ランゲージを開く → 「音声」
2. 大きなボタン → 話す（例: 金子瑞江 → 補正後 金古水江）
3. **完了** → 「メモに戻る」
4. メモで協豊キーボードを出す → 自動挿入、または **「結果を貼る」**

## ターゲット

| ターゲット | Bundle ID |
| --- | --- |
| KyohoranguageHost | `jp.kyohoranguage.app` |
| KyohoranguageKeyboardExt | `jp.kyohoranguage.app.keyboard` |

App Group: `group.jp.kyohoranguage.shared`  
URL Scheme: `kyohoranguage://voice`
