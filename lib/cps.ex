defmodule Cps do
  defmacro __using__(opt \\ []) do
    quote do
      import Cps, unquote(opt)
    end
  end
  defmacro use_cont() do
    quote do
      var!(cont_) = fn(x) -> x end
    end
  end
  defmacro fn_(clause) do
    block = Keyword.get(clause, :do, nil)
    {_,meta,_} = hd(block)
    c = Macro.var(:cont_, nil)
    block2 = Enum.map(block, fn({:->, meta, [head, body]}) ->
                               {:->, meta, [[c|head], body]}
                      end)
    f = quote do
      unquote(block2)
    end
    {:fn, meta, f}
  end
  defmacro apply_(fun, args) do
    quote do
      unquote(fun).(var!(cont_), unquote_splicing(args))
    end
  end

  defmacro def_(name, exp) do
    c = Macro.var(:cont_, nil)
    {n, m, a} = name
    arg = [c|a]
    nm = :"#{n}_"
    name_ = {nm, m, arg}
    s = quote  do
      defmacro unquote(n)(unquote_splicing(a)) do
        snm = unquote(nm)
        a_ = unquote(a)
        quote do
          unquote(snm)(var!(cont_), unquote_splicing(a_))
        end
      end
      Kernel.def(unquote(name_), unquote(exp))
    end
    s
  end
  defmacro values_(name) do
    s = quote do
      var!(cont_).(unquote(name))
    end
    s
  end
  defmacro bind_([{param, exp}], block) do
    p = Macro.var(param, nil)
    block = Keyword.get(block, :do, nil)
    s = quote do
      fn(cont_) ->
        unquote(exp)
      end.(fn(unquote(p)) -> unquote(block) end)
    end
    s = Macro.prewalk(s, fn(x) ->
                           case x do
                             {:cont_, m, _atom} ->
                               {:cont_, m, nil}
                             x -> x
                           end end)
    s
  end
  def ppush(name, s) do
    Process.put(name, Stack.push(Process.get(name, []), s))
  end
  def ppop(name) do
    case Process.get(name, []) do
      [] -> nil
      x ->
#        IO.inspect [ppop: x]
        {r, s} = Stack.pop(x)
        Process.put(name, s)
        r
    end
  end
  @choose_stack :choose
  def get_choose_stack() do
    Process.get(@choose_stack)
  end
  def set_choose_stack(s) do
    Process.put(@choose_stack, s)
  end
  def fail(_result \\ nil) do
    case ppop(@choose_stack) do
      nil ->
        nil # %{result: false, values: result}
      {f,t} -> 
#        IO.inspect [pop: f, t: t]
        f.(t)
    end
  end
  def do_choise_bind(c, f) do
    case c do 
      [] ->
#        IO.inspect [pickfail: c]
        fail()
      [h|t] -> 
        if (length(t) > 0) do
#          IO.inspect [choice_bind_push: f, h: h, t: t]
          ppush(@choose_stack, {fn(x) -> 
#                                  IO.inspect [pickfrom: t]
                                  do_choise_bind(x, f) end, 
                                t})
        end
        f.(h)
      _ ->
        IO.inspect [pickfail_error: c]
        fail()
    end
  end
  defmacro choose_bind(x, f) do
    quote bind_quoted: [x: x, f: f] do
      do_choise_bind(x, f)
    end
  end
end

defmodule Test do
  import Cps
  require Cps
  def message_(cont_) do
    r = [1,2,3]
    IO.inspect [r0: r]
    values_([1,2,3,3])
  end
  def_ two_numbers() do
    choose_bind([0,1,2,3,4,5], 
                fn(x) ->
                  choose_bind([0,1,2,3,4,5],
                              fn(y) ->
                                values_([x,y])
                              end)
                  end)
  end
  def_ parlor_trick(sum) do
    bind_ [p: two_numbers()] do
      [x,y] = p
      if (x + y == sum) do
        values_([:sum, x, y])
      else
        fail()
      end
    end
  end
  def_ restart() do
    case ppop(:saved) do
      nil -> values_(:done)
      x -> x.()
    end
  end
  def_ dft_node(tree) do
    case tree do
      [] -> 
        restart()
      ^tree when is_atom(tree) or is_integer(tree) -> 
        values_(tree)
      [h|t] ->
        ppush(:saved, 
              fn() ->
                dft_node(t)
              end)
        dft_node(h)
    end
  end
  def dft2(tree) do
    use_cont()
    bind_ [param: dft_node(tree)] do
      case param do
        :done -> values_(param)
        param ->
          IO.inspect [p2: param]
          restart()
      end
    end
  end
end
