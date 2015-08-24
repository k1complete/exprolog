defmodule Stack do
  def new, do: []
  def push(s, i), do: [i|s]
  def pop([i|s]), do: {i, s}
end
