.PHONY: check test demo format-check

check: test format-check

test:
	elixir scripts/test_host.exs

demo:
	elixir scripts/demo_host.exs

format-check:
	mix format --check-formatted
