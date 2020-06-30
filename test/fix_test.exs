defmodule FixTest do
  use ExUnit.Case

  test "renaming function definition" do
    code = """
    defmodule A do
      def foo(a, b) do
        a + b
      end
    end
    """

    fixed = """
    defmodule A do
      def bar(a, b) do
        a + b
      end
    end
    """

    assert Fix.fix(code, [{:rename_function_def, :foo, :bar}]) == fixed
  end

  test "renaming function call" do
    code = """
    String.upcase("foo")
    """

    fixed = """
    String.downcase("foo")
    """

    assert Fix.fix(code, [{:rename_function_call, {String, :upcase}, {String, :downcase}}]) ==
             fixed
  end

  test "replace imported calls" do
    code = """
    import String
    upcase("foo")
    """

    fixed = """
    import String
    String.upcase("foo")
    """

    assert Fix.fix(code, [{:replace_imported_calls, String}]) == fixed
  end
end
