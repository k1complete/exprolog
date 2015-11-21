defmodule Exprolog do

@prolog :prolog

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
    use Bitwise
#    "#{:erlang.ref_to_list(:erlang.make_ref())}"
#    Integer.to_string(String.to_integer(
    m = Regex.named_captures(~r/#Ref<(?<a>\d+).(?<b>\d+).(?<c>\d+).(?<d>\d+)>/, 
                  "#{:erlang.ref_to_list(:erlang.make_ref())}", [])
    s = (String.to_integer(m["a"]) <<< (18*3)) + 
        (String.to_integer(m["b"]) <<< (18*2)) + 
        (String.to_integer(m["c"]) <<< 18) + 
        String.to_integer(m["d"])
    Integer.to_string(s, 36)
  end
  def renaming(x, seed) do
    ff = fn(e) ->
           cond do
             Unification.is_variable(e) -> 
               {:_var, n} = e
               {:_var, "#{n}##{seed}"}
             true ->
               e
           end
    end
    walker(x, ff)
  end
  @doc """
  trace
  """
  def trace(t) do
    require Logger;
    Logger.info(t)
  end
  @doc """
  cut operator
  """
  def do_cut(cp) do
    case cp do
      [_cph | cpt] ->
        cp = cpt
        Cps.set_choose_stack(cpt)
      [] ->
        Cps.set_choose_stack([])
        cp = []
    end
    cp
  end
  def do_atomic(a) do
    is_atom(a)
  end

  @doc """
  prog: rule list
  gm: original query goal
  g: current sub goal list
  de: derivered clauses by 
  cp: choose point
  """
  def_ do_interprete(prog, gm, g, de, mg, cp) do
    case de do
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
        pclause = case get_clause(@prolog, d) do
                    [{h, pclause}] -> 
                      pclause
                    [] ->
                      [{{:_fun, :true, []}, []}]
                  end
#        IO.inspect [clause: pclause, d: d, dt: dt]
        choose_bind pclause,
          fn(p) ->
            {head, body} = p
            seed = make_seed()
            head = renaming(head, seed)
#            IO.inspect [unif_before: d]
            case Unification.unification({d, head}) do
              {_mgus, true} -> 
#                IO.inspect [unif: d, dt: dt, head: head, body: body]
                case d do
                  {:_fun, :cut, []} ->
                    cp = do_cut(cp)
                    d0 = dt
                    trace "cut!!!!\n"
                    do_interprete(prog, gm, g, d0, mg, cp)
                  {:_fun, :fail, []} ->
                    trace "fail!!!!\n"
                    fail()
                  _ ->
#                    trace "fail!!!!\n"
                    fail()
                end
              {mgus, false} ->
                cp = save_choose_point(p,cp, {:_fun, :cut, []})
                case body do
                  [:elixir] ->
#                    IO.inspect [eval: d]
                    {_d2, _head, mg} = Builtin.Elixir.eval(d, mg)
                    dt = Tool.assignment(dt, mg)
                    d0 = dt
                  [:builtin] ->
                    IO.inspect [mgus: mgus, mg: mg, d: d, dt: dt]
                    {:_fun, f, a} = d
                    case apply(Builtin, f, a) do
                      false ->
                        d0 = [{:_fun, :fail, []}|dt]
                      true ->
                        IO.inspect [tmgus: mgus, mg: mg, d: d, dt: dt]
                        d0 = dt
                    end
                  _ ->
#                    IO.inspect [body: body]
                    body = Enum.map(body, &(renaming(&1, seed)))
                    d0 = body ++ dt
                end
                d0 = Enum.map(d0, &(Tool.assignment(&1, mgus)))
                g0 = Tool.assignment(g, mgus)
#                mgus = Enum.into(mgus, %{})
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
    p = :ets.match(@prolog, :"$1") |> Enum.map(&(hd(&1)))|> Macro.escape
#    IO.inspect [p: p]
    quote  do
      g = defquery(unquote(goal))
      #Macro.escape(Exprolog.interprete(unquote(p), g))
      Exprolog.interprete(unquote(p), g, unquote(bind))
    end
  end
  def save_choose_point({head, body}, cp, pred) do
#    scp = Cps.get_choose_stack()
#    IO.inspect [scp: scp, pred: pred, head: head, body: body]
    if (Enum.find(body, &(&1 == pred))) do
      case Cps.get_choose_stack() do
        [{f,dt}|rest] ->
#        IO.inspect [f: f, bh: bh, pred: pred]
          ct = Enum.filter(dt, fn({h, _b}) -> h != head end)
#          dp = Enum.filter(dt, fn({h, _b}) -> h == head end)
#          IO.inspect [save_cp: ct, discard_point: dp, scp: scp]
          [[{f,ct}|rest]|  cp]
        _ ->
          cp
      end
    else
      cp
    end
  end
  def register_rule(ets, term = {callarity, {call, body}}) do
    m = try do
          :ets.new(ets, [:set, :public, :named_table])
          rescue 
          ArgumentError ->
            ets
        end
    case :ets.lookup(m, callarity) do
      [] ->
        :ets.insert(m, {callarity, [{call, body}]})
      [{callarity, objs}] ->
        :ets.insert(m, {callarity, objs ++ [{call, body}]})
    end
  end
  def get_clause(ets, call) do
    {f, arity} = get_call_arity(call)
    :ets.lookup(ets, {f, arity})
  end
  def get_call_arity(call) do
#    IO.inspect [call: call]
    case call do
      {:_fun, f, args} ->
        {f, length(args)}
      true ->
        {:true, 0}
      x ->
        x
    end
  end
  defmacro defrule(call, clause \\ [ do: nil ]) do
    call = Tool.parse(call)
    body = case clause do
             [do: {:__block__, _meta, body}] ->
               Tool.parse(body)
             [do: nil] ->
               []
             [do: exp] ->
               Tool.parse([exp])
           end
#    IO.inspect [call: call, clause: body]
    call_arity = get_call_arity(call)
    Macro.escape(register_rule(@prolog, {call_arity, {call, body}}))
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
    m = Tool.parse(s)
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
end
