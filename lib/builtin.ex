defmodule Builtin do
  use Exprolog
  defmacro __using__(opt \\[]) do
    quote do
      defrule atom(a), do: :builtin
      defrule integer(a), do: :builtin
      defrule float(a), do: :builtin
      defrule atomic(a), do: :builtin
      defrule compound(a), do: :builtin
    end
  end
  defmacro init() do
    defrule atom(a), do: :builtin
    defrule integer(a), do: :builtin
    defrule float(a), do: :builtin
    defrule atomic(a), do: :builtin
    defrule compound(a), do: :builtin
  end
  def atom(a), do: is_atom(a)
  def integer(a), do: is_integer(a) 
  def float(a), do: is_float(a)
  def atomic(a), do: atom(a) or integer(a) or float(a)
  def compound(a), do: not(atomic(a))
  def var(a) do
    case a do
      {:_var, _} -> IO.inspect "aaa"
                    true
      _ -> false
    end
  end
end
