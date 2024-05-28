defmodule WeightedRandomTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  describe "take_one weighted list" do
    test "with empty list throws Enum.EmptyError" do
      assert_raise Enum.EmptyError, fn ->
        WeightedRandom.take_one([])
      end
    end

    test "with one element with zero weight throws ArgumentError" do
      assert_raise Enum.EmptyError, fn ->
        WeightedRandom.take_one([{:element, 0}])
      end
    end

    test "with negative weight throws ArgumentError" do
      assert_raise ArgumentError, fn ->
        WeightedRandom.take_one([{:element, -1.0}])
      end

      assert_raise ArgumentError, fn ->
        WeightedRandom.create_searcher([{:element, 1.0}, {:element, -1.0}])
      end
    end

    test "with one element returns it" do
      assert :element == WeightedRandom.take_one([{:element, 1.0}])
    end

    test "with many same elements" do
      assert :element == WeightedRandom.take_one([{:element, 0.5}, {:element, 1.5}])
      assert :element == WeightedRandom.take_one([{:element, 0.5}, {:element, 1.5}, {:element, 1.0}])
    end

    test "statistically returns elements based on weights" do
      data = [{:c, 0.7}, {:a, 0.1}, {:b, 0.2}]

      %{
        a: frequency_a,
        b: frequency_b,
        c: frequency_c
      } =
        elements =
        Enum.map(1..1000, fn _ -> WeightedRandom.take_one(data) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b, :c] end)

      assert frequency_a > 50
      assert frequency_a < 150
      assert frequency_b > 100
      assert frequency_b < 300
      assert frequency_c > 500
      assert frequency_c < 900
    end

    test "statistically returns elements based on weights (for duplicate elements their sum weight is used)" do
      data = [{:a, 0.5}, {:b, 0.3}, {:b, 0.2}]

      %{
        a: frequency_a,
        b: frequency_b
      } =
        elements =
        Enum.map(1..100, fn _ -> WeightedRandom.take_one(data) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b] end)

      assert frequency_a > 25
      assert frequency_a < 75
      assert frequency_b > 25
      assert frequency_b < 75
    end

    test "never return element with zero weight" do
      data = [{:a, 0.1}, {:b, 0.0}]

      assert %{a: 100} ==
               Enum.map(1..100, fn _ -> WeightedRandom.take_one(data) end)
               |> Enum.frequencies()
    end

    test "smoke test" do
      check all(
              weights <- StreamData.list_of(StreamData.float(min: 0.1, max: 100.0), min_length: 1),
              items <- StreamData.list_of(StreamData.term(), length: length(weights))
            ) do
        data = Enum.zip(items, weights)

        Enum.each(1..10, fn _ ->
          assert Enum.member?(items, WeightedRandom.take_one(data))
        end)
      end
    end
  end

  describe "take_one searcher" do
    test "with empty list throws Enum.EmptyError" do
      searcher = WeightedRandom.create_searcher([])

      assert_raise Enum.EmptyError, fn ->
        WeightedRandom.take_one(searcher)
      end
    end

    test "with one element with zero weight throws ArgumentError" do
      searcher = WeightedRandom.create_searcher([{:element, 0}])

      assert_raise Enum.EmptyError, fn ->
        WeightedRandom.take_one(searcher)
      end
    end

    test "with negative weight throws ArgumentError" do
      assert_raise ArgumentError, fn ->
        WeightedRandom.create_searcher([{:element, -1.0}])
      end

      assert_raise ArgumentError, fn ->
        WeightedRandom.create_searcher([{:element, 1.0}, {:element, -1.0}])
      end
    end

    test "with one element returns it" do
      assert :element == WeightedRandom.create_searcher([{:element, 1.0}]) |> WeightedRandom.take_one()
    end

    test "with many same elements" do
      assert :element == WeightedRandom.create_searcher([{:element, 0.5}, {:element, 1.5}]) |> WeightedRandom.take_one()
      assert :element == WeightedRandom.create_searcher([{:element, 0.5}, {:element, 1.5}, {:element, 1.0}]) |> WeightedRandom.take_one()
    end

    test "statistically returns elements based on weights" do
      data = WeightedRandom.create_searcher([{:c, 0.7}, {:a, 0.1}, {:b, 0.2}])

      %{
        a: frequency_a,
        b: frequency_b,
        c: frequency_c
      } =
        elements =
        Enum.map(1..1000, fn _ -> WeightedRandom.take_one(data) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b, :c] end)

      assert frequency_a > 50
      assert frequency_a < 150
      assert frequency_b > 100
      assert frequency_b < 300
      assert frequency_c > 500
      assert frequency_c < 900
    end

    test "statistically returns elements based on weights (for duplicate elements their sum weight is used)" do
      data = WeightedRandom.create_searcher([{:a, 0.5}, {:b, 0.3}, {:b, 0.2}])

      %{
        a: frequency_a,
        b: frequency_b
      } =
        elements =
        Enum.map(1..100, fn _ -> WeightedRandom.take_one(data) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b] end)

      assert frequency_a > 25
      assert frequency_a < 75
      assert frequency_b > 25
      assert frequency_b < 75
    end

    test "never return element with zero weight" do
      data = WeightedRandom.create_searcher([{:a, 0.1}, {:b, 0.0}])

      assert %{a: 100} ==
               Enum.map(1..100, fn _ -> WeightedRandom.take_one(data) end)
               |> Enum.frequencies()
    end

    test "smoke test" do
      check all(
              weights <- StreamData.list_of(StreamData.float(min: 0.1, max: 100.0), min_length: 1),
              items <- StreamData.list_of(StreamData.term(), length: length(weights))
            ) do
        data =
          Enum.zip(items, weights)
          |> WeightedRandom.create_searcher()

        Enum.each(1..10, fn _ ->
          assert Enum.member?(items, WeightedRandom.take_one(data))
        end)
      end
    end
  end

  describe "take_n weighted list" do
    test "with empty list always returns empty list" do
      assert [] == WeightedRandom.take_n([], 0)
      assert [] == WeightedRandom.take_n([], 1)
      assert [] == WeightedRandom.take_n([], 3)
      assert [] == WeightedRandom.take_n([], -1)
    end

    test "with one element with zero weight returns empty" do
      assert [] == WeightedRandom.take_n([{:element, 0}], 1)
    end

    test "with negative weight throws ArgumentError" do
      assert_raise ArgumentError, fn ->
        WeightedRandom.take_n([{:element, -1.0}], 1)
      end
    end

    test "with one element and number = 1 returns it" do
      assert [:element] == WeightedRandom.take_n([{:element, 1.0}], 1)
    end

    test "with number = 0, return empty list" do
      assert [] == WeightedRandom.take_n([], 0)
      assert [] == WeightedRandom.take_n([{:element, 1.0}], 0)
      assert [] == WeightedRandom.take_n([{:element1, 1.0}, {:element2, 1.0}], 0)
    end

    test "with number = 1 return one from list (same elements)" do
      assert [:element] == WeightedRandom.take_n([{:element, 1.0}, {:element, 1.0}, {:element, 1.0}], 1)
    end

    test "with number = 1 return one from list" do
      [element] = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 1.0}, {:element3, 1.0}], 1)
      assert element in [:element1, :element2, :element3]
    end

    test "do not pick elements again" do
      data_low = Enum.map(1..200, fn i -> {:"element_#{i}", 0.0001} end)
      elements = WeightedRandom.take_n([{:element_big, 1.0} | data_low], 100)
      assert length(elements) == 100
      assert Enum.member?(elements, :element_big)
      assert 1 == Enum.count(elements, fn el -> el == :element_big end)
    end

    test "do not pick elements again (be aware of duplicates in data)" do
      data_low = Enum.map(1..200, fn i -> {:"element_#{i}", 0.0001} end)
      elements = WeightedRandom.take_n([{:element_big, 10.0} | [{:element_big, 10.0} | [{:element_big, 1.0} | data_low]]], 100)
      assert length(elements) == 100
      assert Enum.member?(elements, :element_big)
      assert 3 == Enum.count(elements, fn el -> el == :element_big end)
    end

    test "do not pick elements again (size = number)" do
      elements = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 1.0}, {:element3, 1.0}], 3)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size = number), one big" do
      elements = WeightedRandom.take_n([{:element1, 100.0}, {:element2, 1.0}, {:element3, 1.0}], 3)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size = number), (be aware of duplicates in data)" do
      elements = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 1.0}, {:element2, 1.0}], 3)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size = number), (be aware of duplicates in data), one big" do
      elements = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 100.0}, {:element2, 1.0}], 3)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size < number)" do
      elements = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 1.0}, {:element3, 1.0}], 100)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size < number), one big" do
      elements = WeightedRandom.take_n([{:element1, 100.0}, {:element2, 1.0}, {:element3, 1.0}], 100)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size < number), (be aware of duplicates in data)" do
      elements = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 1.0}, {:element2, 1.0}], 100)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size < number), (be aware of duplicates in data), one big" do
      elements = WeightedRandom.take_n([{:element1, 1.0}, {:element2, 100.0}, {:element2, 1.0}], 100)
      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size < number), (all duplicates)" do
      elements = WeightedRandom.take_n([{:element, 1.0}, {:element, 1.0}, {:element, 1.0}], 100)
      assert length(elements) == 3
      assert Enum.member?(elements, :element)
      assert Enum.member?(elements, :element)
      assert Enum.member?(elements, :element)
    end

    test "statistically returns elements based on weights" do
      data = [{:c, 0.7}, {:a, 0.1}, {:b, 0.2}]

      %{
        a: frequency_a,
        b: frequency_b,
        c: frequency_c
      } =
        elements =
        Enum.flat_map(1..1000, fn _ -> WeightedRandom.take_n(data, 2) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b, :c] end)

      assert frequency_a > 250
      assert frequency_a < 470
      assert frequency_b > 550
      assert frequency_b < 800
      assert frequency_c > 650
      assert frequency_c < 1000
    end

    test "statistically returns elements based on weights (for duplicate elements their sum weight is used)" do
      data = [{:a, 0.5}, {:b, 0.3}, {:b, 0.2}]

      %{
        a: frequency_a,
        b: frequency_b
      } =
        elements =
        Enum.flat_map(1..50, fn _ -> WeightedRandom.take_n(data, 2) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b] end)

      assert frequency_a > 25
      assert frequency_a < 75
      assert frequency_b > 25
      assert frequency_b < 75
    end

    test "never return element with zero weight" do
      data = [{:a, 0.1}, {:a, 0.1}, {:b, 0.0}]

      assert %{a: 100} ==
               Enum.flat_map(1..50, fn _ -> WeightedRandom.take_n(data, 2) end)
               |> Enum.frequencies()
    end

    test "smoke test" do
      check all(
              weights <- StreamData.list_of(StreamData.float(min: 0.1, max: 100.0), min_length: 1),
              items <- StreamData.list_of(StreamData.term(), length: length(weights)),
              take_n <- StreamData.integer(1..10)
            ) do
        data = Enum.zip(items, weights)

        Enum.each(1..10, fn _ ->
          elements = WeightedRandom.take_n(data, take_n)
          assert length(elements) == min(length(data), take_n)
          assert Enum.each(elements, &Enum.member?(items, &1))
        end)
      end
    end
  end

  describe "take_n searcher" do
    test "with empty list always returns empty list" do
      searcher = WeightedRandom.create_searcher([])

      assert [] == WeightedRandom.take_n(searcher, 0)
      assert [] == WeightedRandom.take_n(searcher, 1)
      assert [] == WeightedRandom.take_n(searcher, 3)
      assert [] == WeightedRandom.take_n(searcher, -1)
    end

    test "with one element with zero weight returns empty" do
      searcher = WeightedRandom.create_searcher([{:element, 0}])

      assert [] == WeightedRandom.take_n(searcher, 1)
    end

    test "with negative weight throws ArgumentError" do
      assert_raise ArgumentError, fn ->
        WeightedRandom.create_searcher([{:element, -1.0}])
      end
    end

    test "with one element and number = 1 returns it" do
      searcher = WeightedRandom.create_searcher([{:element, 1.0}])

      assert [:element] == WeightedRandom.take_n(searcher, 1)
    end

    test "with number = 0, return empty list" do
      assert [] == WeightedRandom.create_searcher([]) |> WeightedRandom.take_n(0)
      assert [] == WeightedRandom.create_searcher([{:element, 1.0}]) |> WeightedRandom.take_n(0)
      assert [] == WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 1.0}]) |> WeightedRandom.take_n(0)
    end

    test "with number = 1 return one from list (same elements)" do
      assert [:element] ==
               WeightedRandom.create_searcher([{:element, 1.0}, {:element, 1.0}, {:element, 1.0}])
               |> WeightedRandom.take_n(1)
    end

    test "with number = 1 return one from list" do
      [element] =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 1.0}, {:element3, 1.0}])
        |> WeightedRandom.take_n(1)

      assert element in [:element1, :element2, :element3]
    end

    test "do not pick elements again" do
      data_low = Enum.map(1..200, fn i -> {:"element_#{i}", 0.0001} end)

      elements =
        WeightedRandom.create_searcher([{:element_big, 1.0} | data_low])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 100
      assert Enum.member?(elements, :element_big)
      assert 1 == Enum.count(elements, fn el -> el == :element_big end)
    end

    test "do not pick elements again (be aware of duplicates in data)" do
      data_low = Enum.map(1..200, fn i -> {:"element_#{i}", 0.0001} end)

      elements =
        WeightedRandom.create_searcher([{:element_big, 10.0} | [{:element_big, 10.0} | [{:element_big, 1.0} | data_low]]])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 100
      assert Enum.member?(elements, :element_big)
      assert 3 == Enum.count(elements, fn el -> el == :element_big end)
    end

    test "do not pick elements again (size = number)" do
      elements =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 1.0}, {:element3, 1.0}])
        |> WeightedRandom.take_n(3)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size = number), one big" do
      elements =
        WeightedRandom.create_searcher([{:element1, 100.0}, {:element2, 1.0}, {:element3, 1.0}])
        |> WeightedRandom.take_n(3)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size = number), (be aware of duplicates in data)" do
      elements =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 1.0}, {:element2, 1.0}])
        |> WeightedRandom.take_n(3)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size = number), (be aware of duplicates in data), one big" do
      elements =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 100.0}, {:element2, 1.0}])
        |> WeightedRandom.take_n(3)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size < number)" do
      elements =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 1.0}, {:element3, 1.0}])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size < number), one big" do
      elements =
        WeightedRandom.create_searcher([{:element1, 100.0}, {:element2, 1.0}, {:element3, 1.0}])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element3)
    end

    test "do not pick elements again (size < number), (be aware of duplicates in data)" do
      elements =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 1.0}, {:element2, 1.0}])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size < number), (be aware of duplicates in data), one big" do
      elements =
        WeightedRandom.create_searcher([{:element1, 1.0}, {:element2, 100.0}, {:element2, 1.0}])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 3
      assert Enum.member?(elements, :element1)
      assert Enum.member?(elements, :element2)
      assert Enum.member?(elements, :element2)
    end

    test "do not pick elements again (size < number), (all duplicates)" do
      elements =
        WeightedRandom.create_searcher([{:element, 1.0}, {:element, 1.0}, {:element, 1.0}])
        |> WeightedRandom.take_n(100)

      assert length(elements) == 3
      assert Enum.member?(elements, :element)
      assert Enum.member?(elements, :element)
      assert Enum.member?(elements, :element)
    end

    test "statistically returns elements based on weights" do
      data = WeightedRandom.create_searcher([{:c, 0.7}, {:a, 0.1}, {:b, 0.2}])

      %{
        a: frequency_a,
        b: frequency_b,
        c: frequency_c
      } =
        elements =
        Enum.flat_map(1..1000, fn _ -> WeightedRandom.take_n(data, 2) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b, :c] end)

      assert frequency_a > 250
      assert frequency_a < 470
      assert frequency_b > 550
      assert frequency_b < 800
      assert frequency_c > 650
      assert frequency_c < 1000
    end

    test "statistically returns elements based on weights (for duplicate elements their sum weight is used)" do
      data = WeightedRandom.create_searcher([{:a, 0.5}, {:b, 0.3}, {:b, 0.2}])

      %{
        a: frequency_a,
        b: frequency_b
      } =
        elements =
        Enum.flat_map(1..50, fn _ -> WeightedRandom.take_n(data, 2) end)
        |> Enum.frequencies()

      elements
      |> Map.keys()
      |> Enum.each(fn element -> assert element in [:a, :b] end)

      assert frequency_a > 25
      assert frequency_a < 75
      assert frequency_b > 25
      assert frequency_b < 75
    end

    test "never return element with zero weight" do
      data = WeightedRandom.create_searcher([{:a, 0.1}, {:a, 0.1}, {:b, 0.0}])

      assert %{a: 100} ==
               Enum.flat_map(1..50, fn _ -> WeightedRandom.take_n(data, 2) end)
               |> Enum.frequencies()
    end

    test "smoke test" do
      check all(
              weights <- StreamData.list_of(StreamData.float(min: 0.1, max: 100.0), min_length: 1),
              items <- StreamData.list_of(StreamData.term(), length: length(weights)),
              take_n <- StreamData.integer(1..10)
            ) do
        data = Enum.zip(items, weights)
        searcher = WeightedRandom.create_searcher(data)

        Enum.each(1..10, fn _ ->
          elements = WeightedRandom.take_n(searcher, take_n)
          assert length(elements) == min(length(data), take_n)
          assert Enum.each(elements, &Enum.member?(items, &1))
        end)
      end
    end
  end
end
