# Documentation

設計レビューは、まず次の文書を参照する。

- [接続・GATT 設計レビューガイド](design/connection-and-gatt-review.md)

## 文書の役割

| 文書 | 役割 | 主な読者 |
|---|---|---|
| `design/connection-and-gatt-review.md` | 設計判断、公開契約、不変条件、レビュー論点を短くまとめたレビュー入口 | 設計レビュー担当者 |
| `superpowers/specs/2026-06-15-connection-api-and-auto-reconnect-design.md` | エッジケース、OS API 差分、内部イベントなどを含む詳細仕様 | 実装担当者 |
| `superpowers/plans/2026-06-12-deepsky-bluetooth.md` | タスク単位の実装手順と検証手順 | 実装担当者 |

レビューでは、実装計画のコード片を API 仕様として扱わない。公開契約について文書間に
不一致がある場合は、レビューガイドの「文書間の優先順位」に従う。
