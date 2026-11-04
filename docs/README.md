# ドキュメント

XIAO ESP32-C5 + AtomVM + SN74HC595N + 8 LED の単体実験に関する資料です。

## まず読む

- [配線ガイド](hardware.md) — 実際のボードのピン配置、SN74HC595N の向き、ブレッドボードの接続
- [開発・再現手順](development.md) — ホストテスト、書き込み、点灯確認、診断モード
- [アーキテクチャ](architecture.md) — 3 本の信号線で 8 個の LED を制御する仕組み
- [ロードマップ](roadmap.md) — 確認済みの項目と次に検証する項目

## 設計判断と実測

- [ADR](adr/README.md) — GPIO bit-bang 方式を採用した理由
- [実機検証ログ](worklog/README.md) — 実機で観測したことと未確認事項
- [写真・ピン配置図](assets/README.md) — 図の出典と撮影写真

README は最短の実行手順、`docs/` は再現のための具体的な配線と検証記録に分けています。
