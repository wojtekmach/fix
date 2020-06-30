defmodule Fix do
  @type fix() :: (Macro.t() -> Macro.t()) | built_in()

  @typep built_in() :: tuple()

  @doc """
  Transforms code in `string` according to `fixes`.

  A "fix" is a 1-arity function that transforms the AST. The function is
  given to `Macro.prewalk/2`. There's also a list of pre-prepared fixes
  that can be accessed as tuples:

    * `{:rename_function_def, :foo, :bar}`

    * `{:rename_function_call, {Foo, :foo}, {Foo, :bar}}`

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

  This fix happens to be a built-in one: `{:rename_function_def, :foo, :bar}`.
  When defining your fixes, remember to add a "catch-all" clause at the end!

  ## Examples

      iex> Fix.fix("A.a(1, 2)", [{:rename_function_call, {A, :a}, {B, :b}}])
      "B.b(1, 2)"

  """
  @spec fix(String.t(), [fix()], keyword()) :: String.t()
  def fix(string, fixes, opts \\ []) do
    Enum.reduce(fixes, string, fn fix, acc ->
      acc
      |> format_string!([transform: fix(fix)] ++ opts)
      |> IO.iodata_to_binary()
    end)
  end

  defp fix(fun) when is_function(fun, 1) do
    fun
  end

  defp fix({:rename_function_def, from, to}) do
    fn
      {:def, meta1, [{^from, meta2, args}, expr]} ->
        {:def, meta1, [{to, meta2, args}, expr]}

      other ->
        other
    end
  end

  defp fix({:rename_function_call, {from_mod, from_fun}, {to_mod, to_fun}}) do
    from_alias = from_mod |> Module.split() |> Enum.map(&String.to_atom/1)
    to_alias = to_mod |> Module.split() |> Enum.map(&String.to_atom/1)

    fn
      {{:., meta1, [{:__aliases__, meta2, ^from_alias}, ^from_fun]}, meta3, args} ->
        {{:., meta1, [{:__aliases__, meta2, to_alias}, to_fun]}, meta3, args}

      other ->
        other
    end
  end

  # Copied from https://github.com/elixir-lang/elixir/blob/v1.10.3/lib/elixir/lib/code.ex#L652
  defp format_string!(string, opts) when is_binary(string) and is_list(opts) do
    line_length = Keyword.get(opts, :line_length, 98)
    algebra = Fix.Formatter.to_algebra!(string, opts)
    Inspect.Algebra.format(algebra, line_length)
  end
end
