defmodule Unification do
  import Tool;
  def is_variable({:_var, t}) when is_binary(t) do
#    IO.inspect [is_variable: t]
#    Regex.match?(~r/^[A-Z].*/, Atom.to_string(t))
    true
  end
  def is_variable(_t) do
#    IO.inspect [is_variable: _t, state: false]
    false
  end
  def is_function({:_fun, _f, _t}) do
    true
  end
  def is_function(_t) do
    false
  end
  def not_exists(ti, tlist) do
    ff = fn(x) -> 
           case x do
             ^ti -> 
#               IO.inspect [exists_: ti, tlist: tlist]
               throw(:exist)
             _x -> 
#               IO.inspect [not_exists:  x, ti: ti, tlist: tlist]
               true
           end
    end
    r = try  do
          walker(tlist, ff)
        catch 
          :throw, :exist -> false
        end
#    IO.inspect [not_exists: :out, r: r]
    r 
#    not(Enum.any?(tlist, &(&1 === ti)))
  end
#  def not_exists(ti, term) do
#    not(ti === term)
#  end
  def iis_function({:_fun, f, [h1|t1]}, {:_fun, f, [h2|t2]}) do
    {f, [h1|t1], [h2|t2]}
  end
  def iis_function(_, _) do
    false
  end
  ####
  def replace_do(u, x, y) do
    r = fn(i) -> 
          case i do
            ^x -> 
#               IO.inspect [x: x, y: y]
               y
            i -> 
#               IO.inspect [x: x, y: y, i: i]
               i
          end
    
        end
    walker(u, r)
  end
  def replace(ret, s, x, y) do
    ret = replace_do(ret, x, y)
    s = replace_do(s, x, y)
    {ret, s}
  end
  def trans(t1) do
    case is_list(t1) do
      true -> {:_fun, :_list, t1}
      false -> t1
    end
  end
  def do_unification([], ret, failure) do
    {ret, failure}
  end
  def do_unification(s0, ret, failure) do
    {{t1, t2}, s2} = Stack.pop(s0)
    s = s2
    t1 = trans(t1)
    t2 = trans(t2)
#    IO.inspect [t1: t1, t2: t2, s: s]
    cond do
      is_variable(t1) and not_exists(t1, t2) ->
#        IO.inspect [m: :not_exists1, t1: t1, t2: t2, s: s, ret: ret]
        {ret, s} = replace(ret, s, t1, t2)
#        IO.inspect [m2: :after, ret: ret, s: s]
        ret = Map.put(ret, t1, t2);
      is_variable(t2) and not_exists(t2, t1) ->
#        IO.inspect [m: :not_exists2, t1: t1, t2: t2, s: s]
        {ret, s} = replace(ret, s, t2, t1)
        ret = Map.put(ret, t2, t1)
      t1 === t2 ->
        ret
      true ->
        case iis_function(t1, t2) do
          {:_list, [th1|tl1], [th2|tl2]} ->
            s = Stack.push(s, {tl1, tl2})
            s = Stack.push(s, {th1, th2})
          {_f, tt1, tt2} ->
            s = Stack.push(s, {tt1, tt2})
#            IO.inspect [iis_function: s]
            s
          _x -> 
#            IO.inspect [x: _x, s: s, t1: t1, t2: t2, failure: true]
            failure = true
        end
    end
#    IO.inspect [do_unificate: s, ret: ret, failure: failure]
    do_unification(s, ret, failure)
  end
  def unification({t1, t2}) do
    ret = %{}
    s = Stack.new
    s = Stack.push(s, {t1, t2})
    failure = false
    {ret, status} = do_unification(s, ret, failure)
#    IO.inspect [fun: :uification, ret: ret, status: status]
    {ret, status}
  end
  def unification_old({t1, t2}) do
    case unify(t1, t2, []) do
      nil ->
        {[], true}
      ret ->
        {ret, false}
    end
  end
  def unify(_t1, _t2, nil) do
    nil
  end
  def unify(t1, t2, ret) do
    t1 = trans(t1)
    t2 = trans(t2)
    cond do
      is_variable(t1) and not_exists(t1, t2) ->
        IO.inspect t1: t1, t2: t2, s: 1
        ret = replace_do(ret, t1, t2)
        [{t1, t2}|ret]
      is_variable(t2) and not_exists(t2, t1) ->
        IO.inspect t1: t1, t2: t2, s: 2, ret: ret
        ret = replace_do(ret, t2, t1)
        IO.inspect t1: t1, t2: t2, s: 2.5, ret: ret
        [{t2, t1}|ret]
      t1 === t2 ->
        IO.inspect t1: t1, t2: t2, s: 3
        ret
      true ->
        case iis_function(t1, t2) do
          {:_list, [th1|tl1], [th2|tl2]} ->
            IO.inspect t1: t1, t2: t2, s: 5, ret: ret
            ret = unify(th1, th2, ret)
            IO.inspect t1: tl1, t2: tl2, s: 6, ret: ret
            ret = unify(tl1, tl2, ret)
          {_f, tt1, tt2} ->
            ret = unify(tt1, tt2, ret)
            IO.inspect tt1: tt1, tt2: tt2, s: 4, ret: ret
            ret
          _x ->
#            IO.inspect [x: _x, t1: t1, t2: t2]
            nil
        end
    end
  end

end
