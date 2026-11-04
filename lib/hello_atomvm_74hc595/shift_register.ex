defmodule HelloAtomvm74hc595.ShiftRegister do
  @moduledoc "SN74HC595N に 8 bit を送り、8 個の LED をまとめて更新する。"

  import Bitwise

  # XIAO ESP32-C5 の GPIO 番号（D 番号ではない）。
  # D10 -> SN74HC595N SER (pin 14)
  @data_pin 10
  # D8  -> SN74HC595N SRCLK (pin 11)
  @clock_pin 8
  # D9  -> SN74HC595N RCLK (pin 12)
  @latch_pin 9

  @doc "GPIO を準備し、最初はすべての LED を消す。"
  def init(gpio \\ :gpio) do
    with :ok <- gpio.set_pin_mode(@data_pin, :output),
         :ok <- gpio.set_pin_mode(@clock_pin, :output),
         :ok <- gpio.set_pin_mode(@latch_pin, :output),
         :ok <- gpio.digital_write(@data_pin, :low),
         :ok <- gpio.digital_write(@clock_pin, :low),
         :ok <- gpio.digital_write(@latch_pin, :low) do
      write(0, gpio)
    end
  end

  @doc "0〜255 の値を出力する。bit 0 が QA、bit 7 が QH に対応する。"
  def write(pattern, gpio \\ :gpio)

  def write(pattern, gpio) when is_integer(pattern) and pattern in 0..255 do
    # データは 1 bit ずつ送り、最後にラッチして LED を一斉に更新する。
    with :ok <- gpio.digital_write(@latch_pin, :low),
         :ok <- send_bits(bits_msb_first(pattern), gpio),
         :ok <- pulse(@latch_pin, gpio) do
      :ok
    end
  end

  def write(_pattern, _gpio), do: {:error, :invalid_pattern}

  @doc "8 bit を上位ビットから送る順番に並べる。例: 0x01 -> [0, 0, 0, 0, 0, 0, 0, 1]。"
  def bits_msb_first(pattern) when is_integer(pattern) and pattern in 0..255 do
    Enum.map(7..0//-1, fn index -> pattern >>> index &&& 1 end)
  end

  # 8 bit を順に送る。GPIO エラーが発生したらそこで中止する。
  defp send_bits([], _gpio), do: :ok

  defp send_bits([bit | rest], gpio) do
    with :ok <- send_bit(bit, gpio) do
      send_bits(rest, gpio)
    end
  end

  # SER に 0/1 を設定して、SRCLK を 1 回動かす。
  defp send_bit(bit, gpio) do
    with :ok <- gpio.digital_write(@clock_pin, :low),
         :ok <- gpio.digital_write(@data_pin, level(bit)),
         :ok <- pulse(@clock_pin, gpio) do
      :ok
    end
  end

  # IC はクロックが HIGH になった瞬間に動作する。
  # パルス後は LOW に戻し、次の操作に備える。
  defp pulse(pin, gpio) do
    with :ok <- gpio.digital_write(pin, :high),
         :ok <- gpio.digital_write(pin, :low) do
      :ok
    end
  end

  defp level(0), do: :low
  defp level(1), do: :high
end
