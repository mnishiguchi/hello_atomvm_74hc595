# 開発・再現手順

## 対象と前提

- XIAO ESP32-C5、SN74HC595N（DIP-16）、8 LED、8 本の 1 kΩ 抵抗
- AtomVM `v0.7.0-beta.0` 系
- Linux または macOS、Elixir 1.17 以降、Erlang/OTP 27 以降
- 依存関係とツールバージョンは `mix.exs`、`.tool-versions` を参照

配線がまだなら、先に [配線ガイド](hardware.md) の「USB を挿す前のチェック」まで進めてください。

## 1. ホストだけで確認する

```sh
mise install       # mise を使っている場合
make check         # 実機不要の ExUnit テストとフォーマット確認
make demo          # LED パターンを 8-bit の数値として表示
```

`make test` と `make demo` は GPIO や外部依存ライブラリを必要としません。`make check` は `make test` と `make format-check` をまとめて実行します。`mix deps.get && mix test` でもテストできます。

## 2. ボードを見つける

USB-C のデータケーブルで XIAO をホスト PC に接続します。

```sh
ls -l /dev/serial/by-id/  # Linux: ポートの識別に便利
mix deps.get
mix atomvm.esp32.info
```

`ESP32-C5` と使用するポート（例: `/dev/ttyACM0`）が表示されることを確認します。

## 3. AtomVM を準備する

既に AtomVM がインストールされていれば、この手順は飛ばします。次のコマンドは **既存のファームウェアやデータを消去する可能性があります**。

```sh
mix atomvm.esp32.install --version v0.7.0-beta.0
```

通常のデモは追加の NIF を使わず、標準の AtomVM GPIO API だけで動きます。

## 4. アプリを書き込んで確認する

```sh
mix atomvm.esp32.flash --port /dev/ttyACM0
mix atomvm.esp32.monitor --port /dev/ttyACM0
```

`flash` はアプリケーション領域 (`main.avm`) を書き換えます。ポート名は PC に合わせて変更してください。

正常起動時は、次のようなログを出します（通常デモの**想定例**）。

```text
{hello_atomvm_74hc595,starting}
{hello_atomvm_74hc595,ready,demo}
{led,all_on,255}
{led,all_off,0}
{led,walking,1}
{led,walking,2}
...
{led,walking,128}
...
{led,alternating_a,85}
{led,alternating_b,170}
```

肉眼では **全灯 → 全消灯 → 青から赤へ 1 灯ずつ移動して戻る → 交互に点灯**するはずです。ただし LED の色と出力ピンの対応は実配線によって変わります。2026-11-05 に通常デモの書き込みと 1 周分のシリアルログを確認しました。短い動画では全灯と全消灯への遷移も観測しましたが、1 灯ずつの順序と交互点灯はまだ目視確認できていません。

## 5. 配線診断モード（重要）

LED が期待どおり光らないときは、出力を固定したモードで調べます。

| モード | 出力 | 使いどころ |
| --- | --- | --- |
| `all_on` | `0xFF` | 全 LED と 3V3/GND/enable を確認 |
| `all_off` | `0x00` | 全 LED が消えることを確認 |
| `qa` | `0x01` | QA (pin 15) の 1 灯だけを確認 |
| `qh` | `0x80` | QH (pin 7) の 1 灯だけを確認 |
| `demo` | パターンを順に表示 | 全体の動作確認（既定） |

例: 全灯テスト。**モードを変える前に `mix clean`** して、アプリを確実に再コンパイルします。

```sh
LED_DEMO_MODE=all_on mix clean
LED_DEMO_MODE=all_on mix atomvm.esp32.flash --port /dev/ttyACM0
mix atomvm.esp32.monitor --port /dev/ttyACM0
```

```text
{hello_atomvm_74hc595,starting}
{hello_atomvm_74hc595,ready,all_on}
{led,all_on,255}
```

`qa` と `qh` は次のように切り替えます。

```sh
LED_DEMO_MODE=qa mix clean
LED_DEMO_MODE=qa mix atomvm.esp32.flash --port /dev/ttyACM0

LED_DEMO_MODE=qh mix clean
LED_DEMO_MODE=qh mix atomvm.esp32.flash --port /dev/ttyACM0
```

通常のデモに戻す場合:

```sh
mix clean
mix atomvm.esp32.flash --port /dev/ttyACM0
```

ホストで表示パターンを見る場合も `LED_DEMO_MODE=qa make demo` などが使えます。

## うまくいかないとき

| 症状 | 最初に確認すること |
| --- | --- |
| 全 LED が暗い | IC **pin 16 → 3V3**、**pin 8 → GND**。続けて **pin 10 → 3V3**、**pin 13 → GND** |
| 全灯は成功するが QA/QH が期待と違う | pin 15 (QA)、pin 7 (QH) から各 LED への配線 |
| `all_on` の一部しか点灯しない | LED の向き、1 kΩ 抵抗、ブレッドボードの穴の接続関係 |
| 一定の値に固定されない | D10 → SER(pin 14)、D8 → SRCLK(pin 11)、D9 → RCLK(pin 12) |
| 動作が不安定 | 0.1 µF コンデンサ、レールの切れ目、GND、接触不良 |
| C5 が見つからない | データ対応 USB ケーブル、正しいポート、シリアルポートの競合 |
| 書き込みできない | monitor を閉じてから flash、ESP32-C5 を認識しているか |

ソフトウェアが `{led,...}` を出しても、実際の LED が光ることを保証しません。ハードウェアは目視やテスターで別途確認してください。

配線を変えるときは **USB 電源を抜く**。通電したまま隣り合う IC ピンをテスターで短絡させないように注意します。

実機の記録は [worklog](worklog/README.md) にあります。
