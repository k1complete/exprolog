use Exprolog
defrule x = y do
  :elixir
end
defrule x == x
defrule gt(x, y) do
  z = x > y
end

defrule retrieve(1, [x|_], x)
defrule retrieve(n, [_|ls], x) do
  gt(n, 1)
  n1 = n - 1
  retrieve(n1, ls, x)
end
