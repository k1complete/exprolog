use Exprolog
defrule z == z
defrule x = y do
  :elixir
end
defrule le(x, y) do
  z = x <= y
  true == z
end
defrule ticket(a, m) do
  le(a, 13)
  m = 500
  cut()
end
defrule ticket(b, m) do
  m = 1000
end
