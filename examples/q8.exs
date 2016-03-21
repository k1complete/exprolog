use Exprolog

defrule x = y do
  :elixir
end
deffact x == x

defrule gt(x, y) do
  z = x > y
  true == z
end

#3,5,2,4,1
defrule not(x) do
  x
  cut()
  fail()
end
defrule not(x)

defrule not_reachable(q, t) do
  not_reachable(q, 1, t)
end
defrule not_reachable(q, x, [])
defrule not_reachable(q, x, [h|t]) do
  v = (q != h - x)
  true == v
  u = (q != h + x)
  true == u
  x2 = x + 1
  not_reachable(q, x2, t)
end
defrule select(x, [x|xs], xs)
defrule select(x, [y|xs], [y|ys]) do
  select(x, xs, ys)
end
defrule perm([], [])
defrule perm(xs, [z|zs]) do
  select(z, xs, ys)
  perm(ys, zs)
end

defrule solve([])
defrule solve([h|t]) do
  not_reachable(h, t)
  solve(t)
end
defrule target_area([h|t]) do
  z = h < 5
  z == true
end
defrule q8(s) do
  perm([1,2,3,4,5,6,7,8], s)
  target_area(s)
  solve(s)
end
defrule q8_sub(l, xs, q) do
  select(x, l, restq)
  not_reachable(x, xs)
  q8_sub(restq, [x|xs], q)
end
defrule q8_sub([], q, q)

defrule q8e(s) do
  q8_sub([1,2,3,4,5,6,7,8], [], s)
end
interprete(q8e(s))
