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
      ...>   expat(fn _, _, _(x) -> _ end) ->
      ...>     with({name, _, _} <- x, do: name)
      ...>   _ -> :dunno
      ...> end
      :c


      iex> import Expat
      ...> expr = quote do
      ...>   fn a -> a + 22 end
      ...> end
      ...> x = 22
      ...> case expr do
      ...>   expat(fn _ -> _ + _(^x) end) -> :good
      ...>   _ -> :dunno
      ...> end
      :good

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
      [expat: :_]
    end
  end

  defmodule Post do
    def walk({:{}, _, [a, b, [expat: c]]}) do
      {:{}, [], [walk(a), walk(b), walk(expat: c)]}
    end
    def walk({:{}, _, [a, b, c]}) do
      {:{}, [], [walk(a), walk(b), Enum.map(c, &walk/1)]}
    end
    def walk(expat: :_), do: {:_, [], Elixir}
    def walk(expat: expr), do: Macro.prewalk(expr, &unscape/1)
    def walk(expr) when is_list(expr), do: Enum.map(expr, &walk/1)
    def walk(expr), do: expr

    defp unscape({:{}, _, [a, b, c]}), do: {a, b, c}
    defp unscape(expr), do: expr
  end

  defmacro expat(expr, opts \\ []) do
    expat_expr(expr, opts)
  end

  def expat_expr(expr, opts \\ []) do
    expr
    |> Pre.walk(opts)
    |> Macro.escape
    |> Post.walk
  end

end
