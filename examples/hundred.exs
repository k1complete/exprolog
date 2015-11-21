use Exprolog

defrule x = y do
  :elixir
end

defrule append([], y, y)
defrule append([x|xs], y, [x|zs]) do
  append(xs, y, zs)
end
defrule solve_a(s, n, a1) do
  solve(s, n, [], ["+"|a1])
end
defrule solve([h], x, a, a1) do
  z = x - h
  z == 0
  append(a, ["+", h], a1)
end
defrule solve([], 0, a, a)

defrule solve([h|t], x, a, a2) do
  y = x + h
  append(a, ["-", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h|t], x, a, a2) do
  y = x - h
  append(a, ["+", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h1,h2|t], x, a, a2) do
  h = h1 * 10 + h2
  y = x + h
  append(a, ["-", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h1,h2|t], x, a, a2) do
  h = h1*10+h2
  y = x - h
  append(a, ["+", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h1,h2,h3|t], x, a, a2) do
  h = h1 * 100 + h2*10 + h3
  y = x + h
  append(a, ["-", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h1,h2,h3|t], x, a, a2) do
  h = h1*100+h2*10+h3
  y = x - h
  append(a, ["+", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h1,h2,h3,h4|t], x, a, a2) do
  h = h1 * 1000 + h2*100 + h3 * 10 + h4
  y = x + h
  append(a, ["-", h], a1)
  solve(t, y, a1, a2)
end
defrule solve([h1,h2,h3,h4|t], x, a, a2) do
  h = h1 * 1000 + h2*100 + h3 * 10 + h4
  y = x - h
  append(a, ["+", h], a1)
  solve(t, y, a1, a2)
end
