defmodule Expat do

  @moduledoc ~S"""

      iex> import Expat
      ...> expr = quote do
      ...>   fn a, b, c -> a + b + c end
      ...> end
      ...> case expr do
      ...>   expat(fn _, b, _ -> _ end) -> :b_is_second_arg
      ...>   _ -> :dunno
      ...> end
      :b_is_second_arg



      iex> import Expat
      ...> expr = quote do
      ...>   fn a, b, c -> a + b + c end
      ...> end
      ...> case expr do
      ...>   expat(fn _, _, _({name, _, _}) -> _ end) -> name
      ...> end
      :c


      iex> import Expat
      ...> expr = quote do
      ...>   fn a -> a + 22 end
      ...> end
      ...> x = 22
      ...> case expr do
      ...>   expat(fn _ -> _ + _(^x) end) -> :good
      ...> end
      :good


      iex> import Expat
      ...> expr = quote do
      ...>   fn a, b, c -> x end
      ...> end
      ...> case expr do
      ...>   expat(fn _(@args) -> _ end) -> length(args)
      ...> end
      3
  """

  defmodule Pre do

    def walk({:_, _, [expr]}, _), do: [expat: expr]
    def walk({a, b, c}, opts) when length(c) > 0 do
      {walk(a, opts), walk(b, opts), Enum.map(c, &walk(&1, opts))} |> step(opts)
    end
    def walk(expr, opts) when is_list(expr) do
      Enum.map(expr, &walk(&1, opts))
    end
    def walk(expr, opts) do
      expr |> step(opts)
    end

    defp step(expr, opts) do
      expr
      |> lowd()
      |> meta(Keyword.get(opts, :meta, false))
      |> context(Keyword.get(opts, :meta, false))
    end

    defp lowd({:_, _, nil}), do: wildcard
    defp lowd(any), do: any

    defp meta({a, _, c}, false), do: {a, wildcard, c}
    defp meta(any, _), do: any

    defp context({a, b, c}, false) when is_atom(a) and is_atom(c), do: {a, b, wildcard}
    defp context(any, _), do: any

    defp wildcard do
      [expat: {:_, [], Elixir}]
    end
  end

  defmodule Post do
    def walk([[expat: {:{}, _, [:@, _, [expr]]}]]), do: Macro.prewalk(expr, &unscape/1)
    def walk(expat: expr), do: Macro.prewalk(expr, &unscape/1)
    def walk({:{}, _, x}) when is_list(x), do: {:{}, [], walk(x)}
    def walk(expr) when is_list(expr), do: Enum.map(expr, &walk/1)
    def walk(expr), do: expr

    defp unscape({:{}, _, [a, b, c]}), do: {a, b, c}
    defp unscape(expr), do: expr
  end

  defmacro expat(expr, opts \\ []) do
    expat_expr(expr, opts)
  end

  def expat_expr(ast, opts \\ []) do
    ast
    |> Pre.walk(opts)
    |> Macro.escape
    |> Post.walk
  end

end
