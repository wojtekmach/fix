defmodule FixTest do
  use ExUnit.Case, async: true

  test "fix/2" do
    code = """
    def foo(a, b) do
      a + b
    end\
    """

    fixed = """
    def bar(a, b) do
      a + b
    end\
    """

    foo2bar = fn
      {:def, meta1, [{:foo, meta2, args}, expr]} ->
        {:def, meta1, [{:bar, meta2, args}, expr]}

      other ->
        other
    end

    assert Fix.fix(code, [foo2bar]) == fixed
  end
end
