defmodule FixTest do
  use ExUnit.Case, async: true
  doctest Fix

  test "renaming function definition" do
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

    assert Fix.fix(code, [{:rename_function_def, :foo, :bar}]) == fixed
  end

  test "renaming function call" do
    code = """
    def foo(a) do
      Foo.a(a)
    end\
    """

    fixed = """
    def foo(a) do
      Foo.b(a)
    end\
    """

    assert Fix.fix(code, [{:rename_function_call, {Foo, :a}, {Foo, :b}}]) == fixed
  end
end
