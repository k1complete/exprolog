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
  @doc """
  prog: rule list
  gm: original query goal
  g: current sub goal list
  de: derivered clauses by 
  cp: choose point
  """
  def_ do_interprete(prog, gm, g, de, mg, cp) do
#    IO.inspect [g: g, de: de]
    case de do
      nil ->
        values_([status3: true, gm: gm, mgu: mg])
      [] ->
        {_, v} = Tool.walker2(gm, 
                         fn ({:_var, _a} = arg, ac) -> 
                           {arg, Set.put(ac, arg)}
                            (v2, ac) ->
                           {v2, ac}
                         end, MapSet.new())
        g = Tool.assignment(gm, Dict.to_list(mg))
        mg2 = Enum.into(Tool.folding(mg), %{})
        v = Enum.map(v, &{elem(&1, 1), Dict.get(mg2, &1)})
        values_([status: true, query: Tool.pp(gm), 
                 answer: Tool.pp(v),
                 goal: Tool.pp(g)])
      [d|dt] ->
        choose_bind prog,
          fn(p) ->
            {head, body} = p
            seed = make_seed()
            head = renaming(head, seed)
            case Unification.unification({d, head}) do
              {_mgus, true} -> 
                case d do
                  {:_fun, :cut, []} ->
                    IO.inspect [dt: dt, body: body]
                    cph = []
                    case cp do
                      [cph | cpt] ->
                        cp = cpt
                        Cps.set_choose_stack(cph)
                      [] ->
                        Cps.set_choose_stack([])
                        cp = []
                    end
                    IO.inspect "cut!!!!\n"
                    d0 = dt
                    IO.inspect [cp: cph, dt: dt, g: g]
                    do_interprete(prog, gm, g, d0, mg, cp)
                  {:_fun, :fail, []} ->
                    IO.inspect [s: "fail!!!!\n", d: d, dt: dt]
#                    fail()
                    values_([status: false, query: Tool.pp(gm), 
                             answer: [],
                             goal: Tool.pp(g)])
                  _ ->
                    IO.inspect [fail_: d, head: head]
                    fail()
                end
#                IO.inspect [unif: false, d: d, head: head]
              {mgus, false} ->
                cp = save_choose_point(cp, {:_fun, :cut, []})
                # IO.inspect [unif: true, d: d, head: head, mgus: mgus]
                case body do
                  [:elixir] ->
                    {_d2, _head, mg} = Builtin.eval(d, mg)
                  #                mg2 = Dict.to_list(mg)
                  IO.inspect [prog: {head, body}, d: d, mg: mg, d2: _d2]
                    dt = Tool.assignment(dt, mg)
#                  IO.inspect [dt: dt]
                    d0 = dt
                  _ ->
                    body = Enum.map(body, &(renaming(&1, seed)))
                    d0 = body ++ dt
                end
                d0 = Enum.map(d0, &(Tool.assignment(&1, mgus)))
                g0 = Tool.assignment(g, mgus)
                mgus = Enum.into(mgus, %{})
                mg = Enum.into(mg, %{})
                m0 = Dict.merge(mgus,  mg)
                do_interprete(prog, gm, g0, d0, m0, cp)
            end
          end
    end
  end
  def interprete(prog, goal, bind) do
    use_cont
    goal2 = Tool.assignment(goal, bind)
    IO.inspect [A: Tool.pp(goal2), prog: prog]
    do_interprete(prog, goal2, goal2, [goal2], [], [])
  end
  defmacro interprete(goal, bind \\ []) do
    bind = Enum.map(bind, fn({k,v}) ->
                            {{:_var, k}, v} 
                    end)
    p = :ets.match(:prolog, :"$1") |> Enum.map(&(hd(&1)))|> Macro.escape
#    IO.inspect [p: p]
    quote  do
      g = defquery(unquote(goal))
      #Macro.escape(Exprolog.interprete(unquote(p), g))
      Exprolog.interprete(unquote(p), g, unquote(bind))
    end
  end
  def save_choose_point(cp, pred) do
    case Cps.get_choose_stack() do
      [{_f,bodies},_dt|ct] ->
        if (Enum.find(bodies, &(&1 == pred))) do
          [ct|cp]
        else
          cp
        end
      _ ->
        cp
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
