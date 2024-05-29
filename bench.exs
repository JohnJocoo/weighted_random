elements = Enum.map(1..10000, fn i -> {:"el#{i}", :rand.uniform()} end)
searcher = WeightedRandom.create_searcher(elements)

Benchee.run(
  %{
    "take_one with list" => fn -> WeightedRandom.take_one(elements) end,
    "take_one with searcher" => fn -> WeightedRandom.take_one(searcher) end
  }
)

Benchee.run(
  %{
    "take_n 100 with list" => fn -> WeightedRandom.take_n(elements, 100) end,
    "take_n 100 with searcher" => fn -> WeightedRandom.take_n(searcher, 100) end
  }
)
