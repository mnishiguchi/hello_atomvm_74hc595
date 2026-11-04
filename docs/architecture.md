# アーキテクチャ

AtomVM の GPIO API を使い、SN74HC595N のシリアル入力へ 8 bit を送り、8 個の LED を同時に更新します。通信プロトコルや外部デバイスは必要ありません。

```text
     HelloAtomvm74hc595.start/0
                │
                ▼
     Demo.sequence/1（表示時間・順序）
                │
                ▼
     ShiftRegister.write/1（8-bit 値）
                │
         ┌──────┼──────┐
         ▼      ▼      ▼
        SER   SRCLK   RCLK         ← XIAO の 3 GPIO
         └──────┼──────┘
                ▼
            SN74HC595N
                │
           QA … QH（8 出力）
                │
          1 kΩ 抵抗 ×8
                │
             LED ×8
                │
               GND
```

## ファイルごとの役割

| ファイル | 責務 |
| --- | --- |
| `lib/hello_atomvm_74hc595.ex` | AtomVM の起動と LED デモの繰り返し |
| `lib/hello_atomvm_74hc595/demo.ex` | 表示する値、順序、表示時間。実機なしでも利用できる |
| `lib/hello_atomvm_74hc595/patterns.ex` | QA〜QH の 1 灯ずつの往復パターン |
| `lib/hello_atomvm_74hc595/shift_register.ex` | GPIO を出力へ設定し、8 bit を送信してラッチする |
| `config/config.exs` | ホストでコンパイルするときのデモモード |
| `test/` | GPIO の代用品 (`FakeGPIO`) を使った送信順のテスト |

## 8 bit とクロックの関係

例: `0x01` は QA だけを HIGH にします。

```text
pattern: 00000001
SER:       0 0 0 0 0 0 0 1   （上位ビットから送る）
SRCLK:     ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑   （各立ち上がりで 1 bit 送る）
RCLK:                      ↑ （8 bit 後に反映）

QA = 1、QB〜QH = 0
```

シフト中は `RCLK` を LOW に保ち、最後に一度だけ HIGH→LOW にします。これにより、データを 1 bit ずつ送っている最中の内容を LED に反映せずに済みます。

### Elixir コードの読み方

`ShiftRegister.write(0xA5)` は、次の順で進みます。

```text
write(0xA5)
  ├─ bits_msb_first/1: 0xA5 を [1, 0, 1, 0, 0, 1, 0, 1] にする
  ├─ send_bits/2: 8 bit を順に処理する
  │    └─ send_bit/2: SER に 0/1 を設定し、SRCLK を 1 回 pulse/2
  └─ pulse/2: 最後に RCLK を 1 回動かして、8 個の LED を同時に更新する
```

`pulse/2` は GPIO を `HIGH → LOW` にするだけの小さな関数です。`SRCLK` なら「次の 1 bit を取り込む」、`RCLK` なら「8 個の出力をまとめて更新する」という意味になります。

ドライバーは GPIO の操作に失敗したら、そのエラーを呼び出し元に返します。`gpio \\ :gpio` はテスト用の代替 GPIO モジュールを渡すための引数で、実機では通常 `ShiftRegister.write(0xA5)` とだけ書きます。

IC の **OE (pin 13) は GND**、**SRCLR (pin 10) は 3V3** に固定します。これらは GPIO に接続しません。

## 表示モード

| モード | 内容 |
| --- | --- |
| `demo`（既定） | 全灯・消灯 → 往復点灯 → 交互点灯 → 全灯・消灯 |
| `all_on` | 全灯 (`0xFF`) を保持 |
| `all_off` | 全消灯 (`0x00`) を保持 |
| `qa` | QA (`0x01`) だけを保持 |
| `qh` | QH (`0x80`) だけを保持 |

`LED_DEMO_MODE` はビルド時に読み込み、コンパイルされたアプリへ設定されます。実機上で環境変数を読む仕組みではありません。切り替え手順は [開発・再現手順](development.md) を参照してください。

## ホストテストと実機の違い

- ホストテストでは、8 bit の並び、GPIO の呼び出し回数、パターンの順序を検証できます。
- 実際の電圧、LED の点灯、配線の接触、抵抗値はホストテストでは確認できません。
- 実機で確認した範囲は [worklog](worklog/README.md) に記録します。

設計の採用理由は [ADR 0001](adr/0001-use-gpio-bitbang.md) に記載しています。
