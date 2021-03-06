defmodule Builtin.Elixir do
  use Cps
  use Tool

  def eval({:_fun, :!=, [arg1, arg2]}, mgu) do
    if (arg1 != arg2) do
      {true, mgu}
    else
      {false, mgu}
    end
  end
  def eval({:_fun, :var, [arg]}, mgu) do
    case arg do
      {:_var, _x}  -> 
#        IO.inspect [var: _x]
        {true, mgu}
      _ -> {true, mgu}
    end
  end
  
  def eval(exp = {:_fun, :>, [left, right]}, mgu) do
    IO.inspect [left: left, right: right]
    mguv = Enum.map(mgu, fn({{:_var, x}, v}) -> {x, v} end)
#   IO.inspect [right2: Tool.pp(right), mgu: mguv]
#    IO.inspect [eval: Tool.pp(right), mgu: mguv]
    {s, _m} = Code.eval_quoted(Tool.pp(exp), mguv)
#    IO.inspect [eval: s, m: _m]
    if (s != true) do
      {s, nil, mgu}
    else
      {s, s, mgu}
    end
  end
  def eval({:_fun, :=, [left, right]}, mgu) do
#    IO.inspect [right: right]
    {_s, mmgu} = Macro.prewalk(right, 
                              [], 
                              fn (t = {v, _m, nil}, a) ->
                                case Map.get(mgu, {:_var, "#{v}"}) do
                                  nil ->
                                    {t, a}
                                  n ->
                                    {t, [{:v, n}|a]}
                                end
                                 (x, a) ->
                                {x, a}
                              end)
#    mguv = Enum.map(mgu, fn({{:_var, x}, v}) -> {:"#{x}", v} end)
    mguv = mmgu
#   IO.inspect [right2: Tool.pp(right), mgu: mguv]
#    IO.inspect [eval: Tool.pp(right), mgu: mguv]
    {s, _m} = Code.eval_quoted(Tool.pp(right), mguv)
    case Unification.unification({left, s}) do
      {mg, false} ->
        mg = Enum.into(mg, %{})
        mgu = Dict.merge(mg, mgu)
#        IO.inspect [mg: mg]
        {{:_fun, :=, [left, s]}, [s], mgu}
      _ ->
        {nil, nil, mgu}
    end
  end
  def eval(g, mgu) do
    IO.inspect [g: g]
    {g, mgu}
  end
end

