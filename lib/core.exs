use Exprolog
deffact 0
defrule s(0)
deffact natural_number(0)
defrule natural_number(s(x)) do
  natural_number(x)
end
defrule plus(0, x, x) do
  natural_number(x)
end
defrule plus(s(x), y, s(z)) do
  plus(x, y, z)
end
defrule times(0, x, 0) do
  natural_number(x)
end
defrule times(s(0), x, x) do
  natural_number(x)
end
defrule times(s(x), y, z) do
  times(x, y, w)
  plus(y, w, z)
end
deffact append([], y, y)
defrule append([x|xs], y, [x|zs]) do
  append(xs, y, zs)
end
