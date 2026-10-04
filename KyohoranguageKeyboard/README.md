# 協豊ランゲージ（キーボード MVP）

Xcode で `KyohoranguageKeyboard.xcodeproj` を開き、**KyohoranguageHost** を実機 Run。

計画書: `/cursor/stores/self/docs/mvp-plan.md`

## 現状

1. キーボード一覧・地球儀表示
2. 協豊専用辞書補正 + ホスト CRUD
3. **音声入力（ホスト経由）+ 辞書補正**

## ターゲット

| ターゲット | Bundle ID |
| --- | --- |
| KyohoranguageHost | `jp.kyohoranguage.app` |
| KyohoranguageKeyboardExt | `jp.kyohoranguage.app.keyboard` |

App Group: `group.jp.kyohoranguage.shared`  
URL Scheme: `kyohoranguage://voice`
