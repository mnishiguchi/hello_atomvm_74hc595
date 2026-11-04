defmodule HelloAtomvm74hc595.ShiftRegisterTest do
  use ExUnit.Case, async: true

  alias HelloAtomvm74hc595.ShiftRegister

  # テストプロセスの呼び出し履歴へ記録する、AtomVM GPIO の代用品。
  defmodule FakeGPIO do
    def set_pin_mode(pin, mode), do: record({:mode, pin, mode})
    def digital_write(pin, level), do: record({:write, pin, level})

    defp record(call) do
      Process.put(:gpio_calls, [call | Process.get(:gpio_calls, [])])
      :ok
    end
  end

  # GPIO の失敗を再現し、エラーを呼び出し元に返すことを確認する。
  defmodule ErrorGPIO do
    def set_pin_mode(_pin, _mode), do: :ok
    def digital_write(10, :high), do: {:error, :data_pin_failed}
    def digital_write(_pin, _level), do: :ok
  end

  setup do
    Process.put(:gpio_calls, [])
    :ok
  end

  defp calls, do: Enum.reverse(Process.get(:gpio_calls, []))

  test "MSB-first で QA の点灯には最後に 1 を送る" do
    assert ShiftRegister.bits_msb_first(0x01) == [0, 0, 0, 0, 0, 0, 0, 1]
    assert ShiftRegister.bits_msb_first(0x80) == [1, 0, 0, 0, 0, 0, 0, 0]
    assert ShiftRegister.bits_msb_first(0xA5) == [1, 0, 1, 0, 0, 1, 0, 1]
  end

  test "シフトクロック 8 回、ラッチ 1 回で 1 byte を出力する" do
    assert :ok = ShiftRegister.write(0x01, FakeGPIO)
    history = calls()

    assert Enum.count(history, &(&1 == {:write, 8, :high})) == 8
    assert Enum.count(history, &(&1 == {:write, 9, :high})) == 1
    assert List.last(history) == {:write, 9, :low}

    data_levels = for {:write, 10, level} <- history, do: level
    assert data_levels == [:low, :low, :low, :low, :low, :low, :low, :high]
  end

  test "8 bit すべてを送ってからラッチする" do
    assert :ok = ShiftRegister.write(0xA5, FakeGPIO)
    history = calls()

    latch_index = Enum.find_index(history, &(&1 == {:write, 9, :high}))
    assert is_integer(latch_index)

    before_latch = Enum.take(history, latch_index)
    assert Enum.count(before_latch, &(&1 == {:write, 8, :high})) == 8
  end

  test "全灯は SER に HIGH を 8 bit 送り、消灯は LOW を 8 bit 送る" do
    assert :ok = ShiftRegister.write(0xFF, FakeGPIO)
    assert Enum.count(calls(), &(&1 == {:write, 10, :high})) == 8

    Process.put(:gpio_calls, [])
    assert :ok = ShiftRegister.write(0x00, FakeGPIO)
    assert Enum.count(calls(), &(&1 == {:write, 10, :low})) == 8
  end

  test "GPIO のエラーを握りつぶさず呼び出し元へ返す" do
    assert {:error, :data_pin_failed} = ShiftRegister.write(0x01, ErrorGPIO)
  end

  test "初期化では 3 pin を出力に設定し全消灯する" do
    assert :ok = ShiftRegister.init(FakeGPIO)

    assert Enum.take(calls(), 3) == [
             {:mode, 10, :output},
             {:mode, 8, :output},
             {:mode, 9, :output}
           ]

    assert Enum.count(calls(), &(&1 == {:write, 8, :high})) == 8
    assert List.last(calls()) == {:write, 9, :low}
    refute Enum.member?(calls(), {:write, 10, :high})
  end

  test "範囲外の値では GPIO を操作しない" do
    assert {:error, :invalid_pattern} = ShiftRegister.write(256, FakeGPIO)
    assert {:error, :invalid_pattern} = ShiftRegister.write(-1, FakeGPIO)
    assert {:error, :invalid_pattern} = ShiftRegister.write(:not_a_byte, FakeGPIO)
    assert calls() == []
  end
end
