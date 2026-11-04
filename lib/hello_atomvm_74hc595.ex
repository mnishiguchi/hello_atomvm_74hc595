defmodule HelloAtomvm74hc595 do
  @moduledoc "XIAO ESP32-C5 から SN74HC595N と 8 個の LED を操作する AtomVM entrypoint。"

  alias HelloAtomvm74hc595.{Demo, ShiftRegister}

  @demo_mode Application.compile_env(:hello_atomvm_74hc595, :demo_mode, :demo)

  def start do
    :erlang.display({:hello_atomvm_74hc595, :starting})

    case ShiftRegister.init() do
      :ok ->
        :erlang.display({:hello_atomvm_74hc595, :ready, @demo_mode})
        loop()

      error ->
        :erlang.display({:hello_atomvm_74hc595, :gpio_error, error})
        stopped_loop()
    end
  end

  # 点灯パターンを順に表示する。簡易診断モードでは 1 パターンを繰り返す。
  defp loop do
    Enum.each(Demo.sequence(@demo_mode), fn {label, pattern, duration_ms} ->
      case ShiftRegister.write(pattern) do
        :ok ->
          :erlang.display({:led, label, pattern})
          Process.sleep(duration_ms)

        error ->
          :erlang.display({:led, :write_error, label, error})
          Process.sleep(1_000)
      end
    end)

    loop()
  end

  defp stopped_loop do
    receive do
      :stop -> :ok
    after
      5_000 -> stopped_loop()
    end
  end
end
