defmodule Builtin do
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
        IO.inspect [var: _x]
        {true, mgu}
      _ -> {true, mgu}
    end
  end

  def eval({:_fun, :=, [left, right]}, mgu) do
    IO.inspect [right: right]
    mguv = Enum.map(mgu, fn({{:_var, x}, v}) -> {x, v} end)
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

