defmodule Builtin do
  def atom(a), do: is_atom(a)
  def integer(a), do: is_integer(a) 
  def float(a), do: is_float(a)
  def atomic(a), do: atom(a) or integer(a) or float(a)
  def compound(a), do: not(atomic(a))
end
