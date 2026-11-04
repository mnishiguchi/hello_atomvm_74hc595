defmodule HelloAtomvm74hc595.Demo do
  @moduledoc "LED 表示パターンと待ち時間。GPIO に依存しない。"

  alias HelloAtomvm74hc595.Patterns

  @doc "通常デモ、または配線確認用の固定パターンを返す。"
  def sequence(mode \\ :demo)

  def sequence(:demo) do
    [{:all_on, 0xFF, 1_200}, {:all_off, 0x00, 500}] ++
      Enum.map(Patterns.bouncing(), fn pattern -> {:walking, pattern, 600} end) ++
      [
        {:all_off, 0x00, 500},
        {:alternating_a, 0x55, 900},
        {:alternating_b, 0xAA, 900},
        {:all_on, 0xFF, 1_200},
        {:all_off, 0x00, 700}
      ]
  end

  def sequence(:all_on), do: [{:all_on, 0xFF, 1_000}]
  def sequence(:all_off), do: [{:all_off, 0x00, 1_000}]
  def sequence(:qa), do: [{:qa, 0x01, 1_000}]
  def sequence(:qh), do: [{:qh, 0x80, 1_000}]
end
