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
defrule ticket(a, m) do
  le(a, 15)
  m = 1000
end
defrule ticket(a, m) do
  m = 2000
end

