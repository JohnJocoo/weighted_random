defmodule WeightedRandomTest do
  use ExUnit.Case
  doctest WeightedRandom

  test "greets the world" do
    assert WeightedRandom.hello() == :world
  end
end
