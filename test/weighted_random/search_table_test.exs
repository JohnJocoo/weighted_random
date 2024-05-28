defmodule WeightedRandom.SearchTableTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WeightedRandom.SearchTable

  @moduletag :capture_log

  doctest SearchTable

  describe "raw table" do
    test "only one value" do
      assert 1 == SearchTable.search([{:neg_inf, 1}], 0)
      assert 1 == SearchTable.search([{:neg_inf, 1}], -5)
      assert 1 == SearchTable.search([{:neg_inf, 1}], 6)
    end

    test "three ranges" do
      table = [{:neg_inf, -1}, {10, 1}, {100, 2}]

      assert -1 == SearchTable.search(table, 0)
      assert 1 == SearchTable.search(table, 15)
      assert 2 == SearchTable.search(table, 110)
    end

    test "negative ranges lower bound is not inclusive" do
      assert 1 == SearchTable.search([{:neg_inf, 1}, {-10, 2}, {-5, 3}], -10)
      assert 2 == SearchTable.search([{:neg_inf, 1}, {-10, 2}, {-5, 3}], -5)
    end

    test "positive ranges lower bound is inclusive" do
      assert 2 == SearchTable.search([{:neg_inf, 1}, {10, 2}, {20, 3}], 10)
      assert 3 == SearchTable.search([{:neg_inf, 1}, {10, 2}, {20, 3}], 20)
    end
  end

  describe "compiled table" do
    test "only one value" do
      assert 1 == SearchTable.compile([{:neg_inf, 1}]) |> SearchTable.search(0)
      assert 1 == SearchTable.compile([{:neg_inf, 1}]) |> SearchTable.search(-5)
      assert 1 == SearchTable.compile([{:neg_inf, 1}]) |> SearchTable.search(6)
    end

    test "three ranges" do
      table = SearchTable.compile([{:neg_inf, -1}, {10, 1}, {100, 2}])

      assert -1 == SearchTable.search(table, 0)
      assert 1 == SearchTable.search(table, 15)
      assert 2 == SearchTable.search(table, 110)
    end

    test "negative ranges lower bound is not inclusive" do
      assert 1 == SearchTable.compile([{:neg_inf, 1}, {-10, 2}, {-5, 3}]) |> SearchTable.search(-10)
      assert 2 == SearchTable.compile([{:neg_inf, 1}, {-10, 2}, {-5, 3}]) |> SearchTable.search(-5)
    end

    test "positive ranges lower bound is inclusive" do
      assert 2 == SearchTable.compile([{:neg_inf, 1}, {10, 2}, {20, 3}]) |> SearchTable.search(10)
      assert 3 == SearchTable.compile([{:neg_inf, 1}, {10, 2}, {20, 3}]) |> SearchTable.search(20)
    end
  end

  test "raw and compiled versions are functionally the same" do
    check all(
            ranges <- StreamData.list_of(StreamData.integer()),
            items <- StreamData.list_of(StreamData.term(), length: length(ranges)),
            searches <- StreamData.list_of(StreamData.integer(), max_length: 10)
          ) do
      ranges =
        ranges
        |> Enum.uniq()
        |> Enum.sort()

      data = [{:neg_inf, :default_value_neg_inf} | Enum.zip(ranges, items)]
      compiled = SearchTable.compile(data)

      Enum.each(searches, fn value ->
        assert SearchTable.search(data, value) == SearchTable.search(compiled, value)
      end)
    end
  end
end
