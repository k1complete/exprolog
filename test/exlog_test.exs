defmodule ExlogTest do
  use ExUnit.Case
  doctest Exprolog

  test "the truth" do
    assert 1 + 1 == 2
  end
  test "s" do
    use Exprolog
  end
end
