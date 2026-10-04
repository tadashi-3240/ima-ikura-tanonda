# 協豊ランゲージ（キーボード MVP）

Xcode で `KyohoranguageKeyboard.xcodeproj` を開き、ターゲット **KyohoranguageHost** を実機に Run してください。

計画書: Project store `docs/mvp-plan.md`（`/cursor/stores/self/docs/mvp-plan.md`）

## 現状

- **マイルストーン1:** 設定・地球儀に「協豊ランゲージ」表示
- **マイルストーン2:** 協豊専用辞書補正 + ホスト CRUD（音声なし）

## ターゲット

| ターゲット | Bundle ID | 表示名 |
| --- | --- | --- |
| KyohoranguageHost | `jp.kyohoranguage.app` | 協豊ランゲージ |
| KyohoranguageKeyboardExt | `jp.kyohoranguage.app.keyboard` | 協豊ランゲージ |

App Group: `group.jp.kyohoranguage.shared`
