# WeightedRandom

Elixir weighted random pick library optimised for quick `take_one` and `take_n` operations. 

`take_one\1` and `take_n\2` behaviours are compatible with `Enum.random\1` and `Enum.take_random\2` and can almost be drop-in replacements, except that `WeightedRandom` accepts elements in format `{element :: any(), weight :: number()}`.

## Installation

The package can be installed
by adding `better_weighted_random` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:better_weighted_random, "~> 0.1.0"}
  ]
end
```

## Usage

`WeightedRandom.take_one\1` returns one random element from input, with probability based on weights.

```elixir
iex> :rand.seed(:exsss, {100, 101, 102})
iex> WeightedRandom.take_one([{:'1', 0.5}, {:'2', 1.0}, {:'3', 2.0}])
:"3"
```

`WeightedRandom.take_n\1` returns n random elements from input, with probability based on weights. Similar to `Enum.take_random\2` element can not be picked twice.

```elixir
iex> :rand.seed(:exsss, {100, 101, 102})
iex> WeightedRandom.take_n([{:'1', 0.5}, {:'2', 1.0}, {:'3', 2.0}], 2)
[:"3", :"1"]
```

## Probability and weight
Probability of picking an element directly depends on its weight. `Probability = element_weight / sum(all_weights)`

```elixir
iex> :rand.seed(:exsss, {100, 101, 102})
iex> Enum.map(1..1000, fn _ -> WeightedRandom.take_one([{:'1', 1.0}, {:'2', 2.0}, {:'3', 1.0}]) end) |> Enum.frequencies()
%{
  "1": 231, 
  "2": 522, 
  "3": 247
} 
```

## Searcher and quick lookups

You can create searcher with `WeightedRandom.create_searcher\1` for optimised lookups with `take_one\1` and `take_n\2`.

```elixir
iex> searcher = WeightedRandom.create_searcher([{:'1', 1.0}, {:'2', 2.0}, {:'3', 1.0}])

iex> :rand.seed(:exsss, {100, 101, 102})
iex> WeightedRandom.take_one(searcher)
:"3"

iex> rand.seed(:exsss, {100, 101, 102})
iex> WeightedRandom.take_n(searcher, 2)
[:"3", :"1"]
```

Using searcher is quicker if you do repetative calls.

```elixir
elements = Enum.map(1..10000, fn i -> {:"el#{i}", :rand.uniform()} end)
searcher = WeightedRandom.create_searcher(elements)
```

### WeightedRandom.take_one/1

```
Name                             ips        average  deviation         median         99th %
take_one with searcher      787.69 K     0.00127 ms  ±2423.14%     0.00109 ms     0.00180 ms
take_one with list           0.137 K        7.29 ms    ±17.57%        7.03 ms       11.42 ms

Comparison:
take_one with searcher      787.69 K
take_one with list           0.137 K - 5740.48x slower +7.29 ms
```

### WeightedRandom.take_n/2 take 100 elements

```
Name                               ips        average  deviation         median         99th %
take_n 100 with searcher        7.26 K       0.138 ms    ±30.77%       0.124 ms        0.32 ms
take_n 100 with list           0.106 K        9.43 ms    ±12.97%        8.96 ms       12.29 ms

Comparison:
take_n 100 with searcher        7.26 K
take_n 100 with list           0.106 K - 68.46x slower +9.30 ms
```

## Docs

Docs are availiable at <https://hexdocs.pm/better_weighted_random>
