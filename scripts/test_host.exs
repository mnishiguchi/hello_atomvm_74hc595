# 依存関係の取得や AtomVM firmware を必要としない、ホスト用 ExUnit runner。
root = Path.expand("..", __DIR__)

for path <- [
      "lib/hello_atomvm_74hc595/shift_register.ex",
      "lib/hello_atomvm_74hc595/patterns.ex",
      "lib/hello_atomvm_74hc595/demo.ex"
    ] do
  Code.require_file(Path.join(root, path))
end

Code.require_file(Path.join(root, "test/test_helper.exs"))

for path <- Path.wildcard(Path.join(root, "test/*_test.exs")) do
  Code.require_file(path)
end
