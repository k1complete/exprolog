use Exprolog
deffact true
deffact :elixir
defrule x = y do
  :elixir
end
defrule x == x
defrule x > y do
  :elixir
end
deffact assert(x1, x1)
defrule gt(x, y) do
  z = x < y
  true == z
end
defrule ge(x, y) do
  z = x <= y
  true == z
end
defrule le(x, y) do
  z = x > y
  true == z
end
defrule lt(x, y) do
  z = x >= y
  true == z
end

deffact 0
defrule s(0)
deffact natural_number(0)
defrule natural_number(s(x)) do
  natural_number(x)
end
defrule plus2(x, y, z) do
  z = x + y
end
defrule minus2(x, y, z) do
  z = x - y
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

defrule member(x, [x|ys])
defrule member(x, [y|ys]) do
  member(x, ys)
end
defrule ak(0,n,s(n))
defrule ak(s(x),0,a) do
  ak(x, s(0), a)
end
defrule ak(s(m), s(n), a) do
  ak(s(m), n, a1)
  ak(m, a1, a)
end
defrule select(x, [x|xs], xs)
defrule select(x, [y|xs], [y|ys]) do
  select(x, xs, ys)
end
defrule permutation([], [])
defrule permutation(xs, [x|ys]) do
  select(x, xs, zs)
  permutation(zs, ys)
end
