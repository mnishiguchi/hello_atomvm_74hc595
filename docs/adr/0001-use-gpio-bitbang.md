# ADR 0001: SN74HC595N は GPIO bit-bang で制御する

## 背景

XIAO ESP32-C5 と SN74HC595N を使い、8 個の LED を最小限の部品で点灯させたい。ハードウェア SPI も利用できるが、まずはシリアル転送とラッチの仕組みを確認することを優先する。

## 決定

AtomVM v0.7 の `:gpio.set_pin_mode/2` と `:gpio.digital_write/2` を使い、SER / SRCLK / RCLK の 3 本を GPIO から直接操作する。8 bit を MSB-first で送り、RCLK の立ち上がりで出力に反映する。OE (pin 13) は GND、SRCLR (pin 10) は 3V3 に固定する。

## 理由と影響

追加 NIF が不要で、GPIO の呼び出し順序を `FakeGPIO` でテストできる。数百ミリ秒単位で LED を動かす今回の用途では、ソフトウェアでのクロック生成を採用する。高速更新が必要になった場合は SPI による実装を改めて検討する。
