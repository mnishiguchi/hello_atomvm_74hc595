# AtomVM に書き込まずに LED パターンを表示する。
root = Path.expand("..", __DIR__)
Code.require_file(Path.join(root, "lib/hello_atomvm_74hc595/patterns.ex"))
Code.require_file(Path.join(root, "lib/hello_atomvm_74hc595/demo.ex"))

alias HelloAtomvm74hc595.Demo

mode =
  case System.get_env("LED_DEMO_MODE", "demo") do
    "demo" -> :demo
    "all_on" -> :all_on
    "all_off" -> :all_off
    "qa" -> :qa
    "qh" -> :qh
    other -> raise "unknown LED_DEMO_MODE: #{inspect(other)}"
  end

Enum.each(Demo.sequence(mode), fn {label, pattern, ms} ->
  binary = pattern |> Integer.to_string(2) |> String.pad_leading(8, "0")
  IO.puts("#{String.pad_trailing(Atom.to_string(label), 14)} #{binary} #{ms} ms")
end)
