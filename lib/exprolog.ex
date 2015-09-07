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
#    "#{:erlang.ref_to_list(:erlang.make_ref())}"
#    Integer.to_string(String.to_integer(
    Regex.replace(~r/#Ref<0.0.0.(\d+)>/, 
                  "#{:erlang.ref_to_list(:erlang.make_ref())}", "\\1") 
    |> String.to_integer 
    |> Integer.to_string(36)
  end
  def renaming(x, seed) do
    ff = fn(e) ->
           cond do
             Unification.is_variable(e) -> 
               {:_var, n} = e
               {:_var, :"#{n}##{seed}"}
             true ->
               e
           end
    end
    walker(x, ff)
  end
#  def_ do_interprete(prog, goalmaster, goal, deliver, mgu) do
  def_ do_interprete(prog, gm, g, de, mg) do
#    m = fn(f, prog, gm, g, de, mg) ->
          case de do
            nil ->
              values_([status3: true, gm: gm, mgu: mg])
            [] ->
#              case Unification.unification({gm, g}) do
#                {mgu, false} ->
                  g = Tool.assignment(gm, Dict.to_list(mg))
                  mg2 = Tool.folding(mg)
                  values_([status: true, query: gm, goal: g, mgu: mg2])
#              end
            [d|dt] ->
              choose_bind prog,
              fn(p) ->
                {head, body} = p
                seed = make_seed()
                head = renaming(head, seed)
                case Unification.unification({d, head}) do
                  {_mgus, true} -> 
#                    IO.inspect([___state: false, unif: head, d: d,goal: g, mgu: _mgus])
                    fail()
                  {mgus, false} ->
#                    IO.inspect [___unif: d, ___head: head, ___mgu: mgus, deliver: dt, goal: g]
                    if (body == [:elixir]) do
#                      IO.inspect [body_before: body, mg: mg, unif: {d, head}]
                      {d2, head, mg} = Builtin.eval(d, mg)
#                      IO.inspect [body: body, mg: mg, unif: {d2, head}, dt: dt]
                      mg2 = Dict.to_list(mg)
                      dt = Tool.assignment(dt, mg2)
                      g0 = Tool.assignment(g, mg2)
                      d0 = dt
                    else 
                      body = Enum.map(body, &(renaming(&1, seed)))
                      d0 = body ++ dt
                    end
                    d0 = Enum.map(d0, &(Tool.assignment(&1, mgus)))
#                    IO.inspect [assignment_d0: d0, mgus: mgus, mg2: mg2]
                    g0 = Tool.assignment(g, mgus)
                    mgus = Enum.into(mgus, %{})
#                    IO.inspect [assignment_mgus: mgus]
                    mg = Enum.into(mg, %{})
#                    IO.inspect [assignment_mg: mg]
                    m0 = Dict.merge(mgus,  mg)
#                    IO.inspect [assignment: m0]
#                    m0 = Enum.filter(m0, fn({k,v}) -> k != v end)
#                                IO.inspect [m0: m0]
                    #m0 = Tool.folding(m0)
                    do_interprete(prog, gm, g0, d0, m0)
#                    f.(f,prog, gm, g0, d0, m0)
                end
              end
          end
#    end
#    m.(m, prog, goalmaster, goal, deliver, mgu)
  end
  def interprete(prog, goal) do
    use_cont
#    IO.inspect [goal: goal]
#    bind_ [deliver: [goal]] do
      do_interprete(prog, goal, goal, [goal], [])
#    end
  end
  defmacro interprete(goal) do
    p = :ets.match(:prolog, :"$1") |> Enum.map(&(hd(&1)))|> Macro.escape
#    IO.inspect [p: p]
    quote do
      g = defquery(unquote(goal))
      #Macro.escape(Exprolog.interprete(unquote(p), g))
      Exprolog.interprete(unquote(p), g)
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
             [do: {:__block__, _meta, body}] ->
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
