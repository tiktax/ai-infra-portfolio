# governance-healthcheck

散文のガバナンス台帳を「自己検証する実行可能な不変条件(invariant)」に置換するツール。

## なぜ作ったか(教訓の系譜)

個人運用の ITSM ガバナンス(ISO 20000/27001 軽量版)を実装したが、監査の結果、それは「動いているフリ」だった:

- 週次 scheduled-task は**発火するのに結果を書かない**(fires-but-doesn't-land)
- セキュリティ hook が **exec-bit 欠落で作成以来 no-op**(INC-020)
- INC を「解決済み」と記録して**11日放置**(自己認証された resolved)
- 台帳が worktree と canonical で**分裂**(split-brain)

共通点は1つ —— **すべて「静かに」壊れた**。敵は「壊れること」ではなく「**静かに**壊れること」だ。

一方、生き残ったのは hook(secret-guard, worktree-guard)だけだった。違いは複雑さでも知性でもない:

> **機械が自動執行する assertion(hook)は生き、人間が手で現実と同期する散文(.md 台帳)は腐った。**

このツールは、その教訓を一般化する。**過去の失敗を1つずつ実行可能な assertion として化石化し、機械が毎回検証する。**

## 設計(Stage-1 敵対検証で硬化)

| 原則 | 内容 |
|---|---|
| **default-FAIL** | check は明示的に `RESULT=PASS` と言った時だけ PASS。判定不能・未実行・error は全て FAIL。grep の終了コードや「0件ヒット」に合否を委ねない |
| **2枚カナリア** | 必ず FAIL / 必ず PASS する check を置く。両者が名前通り判定されることで「検証エンジンが空振りしていない」ことを**実行時に自己証明**する。「検証者を誰が検証するか」の無限後退を、人間の分析層でなく機械で深さ1で止める |
| **exec-bit 検査** | 非実行ビットの check は silent skip でなく FAIL(INC-020 教訓を自分自身に適用) |
| **実行証跡** | registered(check 総数)を出力。実行されなかった check は MISSING=FAIL |

## 使い方

```sh
GOV_DIR=/path/to/your/governance-vault \
INCIDENTS_MD=/path/to/your/governance-vault/INCIDENTS.md \
tools/governance-healthcheck/healthcheck.sh
```

`GOV_DIR` / `INCIDENTS_MD` はガバナンス台帳の実パスを指す必須の環境変数(デフォルト値なし)。個人の vault パスをリポジトリにハードコードしない設計。

終了コード: `0`=全 gov check PASS / `1`=gov check FAIL / `3`=エンジン整合性異常(カナリア破綻=結果を信用するな)

check は `checks/*.sh` に置く。各 check は標準出力に1行 `RESULT=PASS` または `RESULT=FAIL` を出す(契約)。

## ロードマップ

- [x] **v1: 自己検証エンジンの背骨** — default-FAIL / 2枚カナリア / exec-bit 検査 / 実行証跡
- [ ] ドメイン assertion(教訓の化石): `cip-c-traceability` / `split-brain` / `scheduled-task-liveness`(発火と書き込みの乖離=今日の病①直撃) / `index-integrity`(manifest 駆動) / `orphan-tokens`
- [ ] manifest 集約(GOVERNANCE.md を単一真実源にしパスのハードコードを排除)
- [ ] 二層通知: session-start バナー(ground truth)+ 毎朝 AI秘書(Telegram)ハートビート + 相互鮮度監視
- [ ] fail-closed の opt-in 化(override-token)

## 設計原則(自戒)

検証には収穫逓減がある。**敵対検証は成果物ごと1回。その後は出荷し、現実とカナリアに検証させる。** 検証を口実にした先送り(分析麻痺)は、このツールが防ごうとしている「動いているフリ」と同じ病だ。
