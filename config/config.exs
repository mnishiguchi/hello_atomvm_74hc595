import Config

# モードはホストでコンパイルするときに決まる。AtomVM 実機では環境変数を読まない。
mode =
  case System.get_env("LED_DEMO_MODE", "demo") do
    "demo" -> :demo
    "all_on" -> :all_on
    "all_off" -> :all_off
    "qa" -> :qa
    "qh" -> :qh
    other -> raise "unknown LED_DEMO_MODE: #{inspect(other)}"
  end

config :hello_atomvm_74hc595, demo_mode: mode
