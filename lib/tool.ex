defmodule Tool do
  defmacro pp(a) do
    quote do
      Tool.do_pp(unquote(a))
    end
  end
  def do_pp({:_var, arg}) when is_atom(arg) do
#    {:_var, arg}
      {arg, [], nil}
  end
  def do_pp({:_fun, :list, arg}) do
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
  def do_pp(x) do
    x
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
    a
  end
  def depp([]) do
    []
  end
  def depp([{:|, _meta, [a,b]}]) do
    [depp(a)|depp(b)]
  end
  def depp([h|t]) do
    [depp(h)|depp(t)]
  end
  def depp({f, _meta, nil}) do
    {:_var, f}
  end
  def depp({f, _meta, atom}) when is_atom(atom) do
    {:_var, f}
  end
  def depp({f, _meta, args}) do
    {:_fun, f, depp(args)}
  end
  def depp(x) do
    x
  end
  def assignment(x, mgu) do
    ff = fn(e) ->
           v = Enum.find_value(mgu, 
                               e, 
                               fn({k,v}) -> 
                                 cond do
                                   k == e -> 
                                     v
#                                   v == e ->
#                                     k
                                   true ->
                                     false
                                 end
                             end)
#           IO.inspect [from: e, to: v]
           v
    end
    walker(x, ff)
  end
  def folding(m) do
    Enum.map(m, fn({k, v}) ->
                  {k, assignment(v, m)}
             end)
  end

end
