defmodule Exprolog do
@doc """
p1 = {{:_fun, :append, [[], :Y, :Y]}, []}
p2 = {{:_fun, :append, [[:X|:Xs], :Y, [:X |:Zs]]}, [{:_fun, :append, [:Xs, :Y, :Zs]}]}
p3 = [p1, p2]
Exprolog.interprete(p3, {{:_fun, :append, [[1],[2],:Y]}})
"""
  use Cps
  require Tool
  import Tool
  defmacro __using__(opt \\ []) do
    quote do
      import Exprolog, unquote(opt)
      use Cps
    end
  end
  def make_seed() do
    List.to_string(:erlang.ref_to_list(:erlang.make_ref()))
  end
  def renaming(x, seed) do
    ff = fn(e) ->
           cond do
             Unification.is_variable(e) -> 
               {:_var, n} = e
               {:_var, :"#{n}#{seed}"}
             true ->
               e
           end
    end
    walker(x, ff)
  end
  def_ do_interprete(prog, goalmaster, goal, deliver, mgu) do
    choose_bind deliver, 
    fn(d) ->
      choose_bind prog,
      fn(p) ->
        {head, body} = p
        seed = make_seed()
        head = renaming(head, seed)
        body = Enum.map(body, &(renaming(&1, seed)))
#        IO.inspect([unif: head, d: d, goal: goal])
        case Unification.unification({head, d}) do
          {_mgus, true} -> 
#            IO.inspect [state: fail, mgu: mgu, head: head, d: d]
            fail()
          {mgus, false} ->
#            IO.inspect [unif: :unif, 
#                        head: head, d: d, mgus: mgus, false: false]
#            mgu = mgus ++ mgu
            d0 = deliver -- [d]
            d0 = body ++ d0
            d0 = Tool.assignment(d0, mgus)
            g0 = Tool.assignment(goal, mgus)
            m0 = Tool.assignment(mgu, mgus) ++ mgus 
#            IO.inspect [m0: m0]
            m0 = Tool.folding(m0)
#            m0 = Enum.filter(m0, fn({k,v}) -> k != v end)
#            IO.inspect [g0: g0, d0: d0, m0: m0]
            case (d0) do
              [] -> 
                case Unification.unification({goalmaster, g0}) do
                  {_mgu, true} ->
#                    IO.inspect [state: :fail, mgu: mgu]
                    fail()
                  {mgu, false} ->
                    values_(pp([status: true, goalmaster: goalmaster,
                                goal: g0, mgu: mgu]))
                end
              _ -> 
                do_interprete(prog, goalmaster, g0, d0, m0)
            end
        end
      end
    end
  end
  def interprete(prog, goal) do
    use_cont
    IO.inspect [goal: goal]
#    bind_ [deliver: [goal]] do
      do_interprete(prog, goal, goal, [goal], [])
#    end
  end
  defmacro interprete(goal) do
    p = :ets.match(:prolog, :"$1") |> Enum.map(&(hd(&1)))|> Macro.escape
    IO.inspect [p: p]
    quote do
      g = defquery(unquote(goal))
      Macro.escape(Exprolog.interprete(unquote(p), g))
    end
  end
  @prolog :prolog
  def register_rule(ets, term) do
    m = try do
          :ets.new(ets, [:ordered_set, :public, :named_table])
          rescue 
          ArgumentError ->
            ets
        end
    :ets.insert(m,term)
  end
  defmacro defrule(call, clause \\ [ do: nil ]) do
    call = Tool.depp(call)
    body = case clause do
             [do: {:__block__, [], body}] ->
               Tool.depp(body)
             [do: nil] ->
               []
             [do: exp] ->
               Tool.depp([exp])
           end
#    IO.inspect [call: call, clause: body]
    Macro.escape(register_rule(@prolog, {call, body}))
  end
  defmacro deffact(call) do
    quote do
      defrule(unquote(call))
    end
  end
  defmacro defquery(call) do
    s = quote do
      unquote(call)
    end
    m = Tool.depp(s)
    Macro.escape(m)
  end
  def test_prog do
    p1 = {{:_fun, :append, [[], {:_var, :Y}, {:_var, :Y}]}, 
          []}
    p2 = {{:_fun, :append, [[{:_var,:X}| {:_var, :Xs}], 
                            {:_var,:Y}, 
                            [{:_var, :X} | {:_var, :Zs}]]}, 
          [{:_fun, :append, [{:_var, :Xs}, 
                             {:_var, :Y}, 
                             {:_var, :Zs}]}]}
    [p1, p2]
  end
  def test do
    p3 = test_prog()
    Exprolog.interprete(p3, {:_fun, :append, [[1], [2], [1,2]]})
  end
  def test2 do
    p3 = test_prog()
    Exprolog.interprete(p3, {:_fun, :append, [[1],[2],{:_var, :Y}]})
  end
  def test3 do
    p3 = test_prog()
    Exprolog.interprete(p3, {:_fun, :append, 
                             [{:_var, :X},
                              {:_var, :Y},
                              [1,2,3]]})
  end
  def test35 do
    p3 = test_prog()
    Exprolog.interprete(p3, {:_fun, :append, 
                             [{:_var, :X},
                              {:_var, :Y},
                              [1,2]]})
  end
  def test4 do
    p3 = :ets.match(@prolog, :"$1") |> Enum.map(&(hd(&1))) 
    Exprolog.interprete(p3, {:_fun, :append, [{:_var, :x}, {:_var, :y}, [1,2]]})
  end
end
