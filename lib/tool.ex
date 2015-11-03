defmodule Tool do
  defmacro __using__(opt \\ []) do
    quote do
      import Tool, unquote(opt)
    end
  end
  defmacro pp(a) do
    quote do
      Tool.do_pp(unquote(a))
    end
  end
  def do_pp({:_var, arg}) when is_binary(arg) do
#    {:_var, arg}
      {:"#{arg}", [], nil}
  end
  def do_pp({:_fun, :_list, arg}) do
    pp(arg)
  end
  def do_pp([{k,v}|term]) do
    [{k, pp(v)}|pp(term)]
  end
  def do_pp([h|t]) do
    [pp(h)|pp(t)]
  end
  def do_pp({:_fun, f, arg}) when is_atom(f) do
#    {:_fun, f, pp(arg)}
    {f, [], pp(arg)}
  end
  def do_pp(x={:_fun, f, arg}) when is_tuple(f) do
    IO.inspect [x: x] 
    {pp(f), [], pp(arg)}
  end
  def do_pp({:_elixir, x}) do
    x
  end
  def do_pp(x) do
    x
  end
  def walker2([], _ff, ac) do
    {[], ac}
  end
  def walker2({:_fun, f, args}, ff, ac) do
    {nargs, nac} = walker2(args, ff, ac)
    {{:_fun, f, nargs}, nac}
  end
  def walker2({:_var, a}, ff, ac) do
    ff.({:_var, a}, ac)
  end
  def walker2([h|t], ff, ac) do
    {a, hac}  = walker2(h, ff, ac)
    {b, tac} = walker2(t, ff, hac)
    {[a|b], tac}
  end
  def walker2(tuple, ff, ac) when is_tuple(tuple) do
    {wlist, wac} = walker2(Tuple.to_list(tuple), ff, ac)
    {List.to_tuple(wlist), wac}
  end
  def walker2(a, ff, ac) when is_atom(a) do
    r = ff.(a, ac)
    r
  end
  def walker2(a, _ff, ac) do
#    IO.inspect [nothing: [arg: a]]
    {a, ac}
  end
  def walker([], _ff) do
    []
  end
  def walker({:_fun, f, args}, ff) do
    {:_fun, f, walker(args, ff)}
  end
  def walker([h|t], ff) do
    a = walker(h, ff)
    b = walker(t, ff)
    [a|b]
  end
  def walker({:_var, a}, ff) do
    ff.({:_var, a})
  end
  def walker(tuple, ff) when is_tuple(tuple) do
    List.to_tuple(walker(Tuple.to_list(tuple), ff))
  end
  def walker(a, ff) when is_atom(a) do
    r = ff.(a)
    r
  end
  def walker(a, _ff) do
#    IO.inspect [nothing: [arg: a]]
    a
  end
  def parse([]) do
    []
  end
  def parse([{:|, _meta, [a,b]}]) do
    [parse(a)|parse(b)]
  end
  def parse([h|t]) do
    [parse(h)|parse(t)]
  end
  def parse({f, _meta, nil}) do
    {:_var, "#{f}"}
  end
  def parse({f, _meta, atom}) when is_atom(atom) do
    {:_var, "#{f}"}
  end
  def parse({f, _meta, args}) do
    {:_fun, parse(f), parse(args)}
  end
  def parse(x) do
    x
  end
  def replace_mgu(mgu, x, mmgu) when is_map(mgu) do
    case mgu[x] do
      nil -> x
      v -> 
        cond do
          Unification.is_variable(v) ->
            replace_mgu(mmgu, v, mmgu)
          Unification.is_function(v) ->
            assignment(v, mmgu)
          true ->
            v
        end
    end
  end
  def replace_mgu([], x, _mgu) do
    x
  end
  def replace_mgu([{x,v}|_mt], x, mgu) do
#    IO.inspect [replace_mgu: x, v: v]
    cond do
      (Unification.is_variable(v)) ->
#        IO.inspect [replace_mgu_is_variable: x, v: v]
        replace_mgu(mgu, v, mgu)
      (Unification.is_function(v)) ->
#        IO.inspect [replace_mgu_is_func: x, v: v]
        assignment(v, mgu)
      true ->
        v
    end
  end
  def replace_mgu([_mh|mt], x, mgu) do
    replace_mgu(mt, x, mgu)
  end
  def assignment(x, mgu) do
    ff = fn(e) ->
           r = replace_mgu(mgu, e, mgu)
#           IO.inspect [__assignment: e, to: r]
           r
    end
    walker(x, ff)
  end
  def folding(m) do
#    m2 = Dict.to_list(m)
    Enum.map(m, fn({k, v}) ->
#                  IO.inspect([__folding: {k, v}])
                  {k, assignment(v, m)}
             end) |>
      Enum.filter(fn({k, v}) ->
                    if (k == v) do
#                      IO.inspect [delete: {k, v}]
                      false
                    else
                      true
                    end 
                  end)
  end

end
