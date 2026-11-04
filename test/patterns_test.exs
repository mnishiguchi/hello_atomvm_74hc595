defmodule HelloAtomvm74hc595.PatternsTest do
  use ExUnit.Case, async: true

  alias HelloAtomvm74hc595.{Demo, Patterns}

  test "QA から QH まで 1 灯ずつ動き、QA に戻る" do
    assert Patterns.walking() == [1, 2, 4, 8, 16, 32, 64, 128]

    assert Patterns.bouncing() == [
             1,
             2,
             4,
             8,
             16,
             32,
             64,
             128,
             64,
             32,
             16,
             8,
             4,
             2,
             1
           ]
  end

  test "通常デモは全灯と消灯で始まり、往復点灯と交互点灯を含む" do
    sequence = Demo.sequence()

    assert Enum.take(sequence, 2) == [{:all_on, 0xFF, 1_200}, {:all_off, 0x00, 500}]
    assert Enum.count(sequence, fn {label, _, _} -> label == :walking end) == 15
    assert {:alternating_a, 0x55, 900} in sequence
    assert {:alternating_b, 0xAA, 900} in sequence
    assert List.last(sequence) == {:all_off, 0x00, 700}
  end

  test "診断モードは単一ビットまたは全灯・消灯を返す" do
    assert Demo.sequence(:all_on) == [{:all_on, 0xFF, 1_000}]
    assert Demo.sequence(:all_off) == [{:all_off, 0x00, 1_000}]
    assert Demo.sequence(:qa) == [{:qa, 0x01, 1_000}]
    assert Demo.sequence(:qh) == [{:qh, 0x80, 1_000}]
  end

  test "表示値はすべて 8 bit で、待ち時間は正" do
    for mode <- [:demo, :all_on, :all_off, :qa, :qh] do
      assert Enum.all?(Demo.sequence(mode), fn {label, pattern, duration_ms} ->
               is_atom(label) and is_integer(pattern) and pattern in 0..255 and duration_ms > 0
             end)
    end
  end
end
