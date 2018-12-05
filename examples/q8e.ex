defmodule Q8e do
  use Cps
  def not_reachable(q, t) do
    not_reachable(q, 1, t)
  end
  def not_reachable(_q, x, []) do
    x
  end
  def not_reachable(q, x, [h|t]) do
    cond do
      (q == h - x) ->
        false
      (q == h + x) ->
        false
      true ->
        not_reachable(q, x + 1, t)
    end
  end
  def_ solve(l, a) do
    choose_bind l,
      fn (p) ->
        t = l -- [p]
        case t do
          [] ->
            values_([p|a])
          t ->
            if (not_reachable(p, a)) do
              solve(t, [p|a])
            else
              fail()
            end
        end
    end
  end
  def solve() do
    use_cont
    s = [1,2,3,4,5,6,7,8]
    solve(s, [])
  end
end