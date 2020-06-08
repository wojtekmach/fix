defmodule Fix do
  @type fix() :: (Macro.t() -> Macro.t()) | module()

  @doc """
  Transforms code in `string` according to `fixes`.

  A "fix" is a 1-arity function that transforms the AST. The function is
  given to `Macro.prewalk/2`.

  `opts` are passed down to `Code.format_string!/2`.

  **Note**: the AST that the fix accepts and returns is not the "regular"
  Elixir AST, but the annotated Elixir formatter AST. Given we rely on Elixir
  internals, this function may not work on future Elixir versions. It has been
  tested only on Elixir v1.10.3.

  Here's an example fix that transforms `def foo` into `def bar`:

      foo2bar = fn
        {:def, meta1, [{:foo, meta2, args}, expr]} ->
          {:def, meta1, [{:bar, meta2, args}, expr]}

        other ->
          other
      end

  Remember to add a "catch-all" clause at the end!
  """
  @spec fix(String.t(), [fix()], keyword()) :: String.t()
  def fix(string, fixes, opts \\ []) do
    Enum.reduce(fixes, string, fn fix, acc ->
      acc
      |> format_string!([transform: fix] ++ opts)
      |> IO.iodata_to_binary()
    end)
  end

  # Copied from https://github.com/elixir-lang/elixir/blob/v1.10.3/lib/elixir/lib/code.ex#L652
  defp format_string!(string, opts) when is_binary(string) and is_list(opts) do
    line_length = Keyword.get(opts, :line_length, 98)
    algebra = Fix.Formatter.to_algebra!(string, opts)
    Inspect.Algebra.format(algebra, line_length)
  end
end
