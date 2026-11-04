defmodule HelloAtomvm74hc595.Patterns do
  @moduledoc "8 個の LED を操作するための純粋なビットパターン。"

  import Bitwise

  @doc "QA (bit 0) から QH (bit 7) へ 1 灯ずつ進める。"
  def walking do
    Enum.map(0..7, fn index -> 1 <<< index end)
  end

  @doc "QA → QH → QA の順で往復し、折り返し点の重複を避ける。"
  def bouncing do
    walking() ++ Enum.map(6..0//-1, fn index -> 1 <<< index end)
  end
end
