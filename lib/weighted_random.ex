defmodule WeightedRandom do
  @moduledoc """
  Module to take random elements from enumerable based on their weights.
  """

  alias WeightedRandom.SearchTable

  @type weight :: number()
  @type element :: any()
  @type searcher :: %__MODULE__{}
  @type enumerable(_type) :: Enumerable.t()

  @enforce_keys [:search_table, :total_weight, :number_elements]
  defstruct [:search_table, :total_weight, :number_elements]

  @doc """
  Turn enumerable of {element, weight} to structure optimised for search (take_* operations).
  """
  @spec create_searcher(enumerable({element(), weight()})) :: searcher()
  def create_searcher(enumerable) do
    enumerable
    |> verify_filter_input()
    |> create_searcher_impl()
  end

  @doc """
  Take one element from enumerable of {element, weight}
  or from structure returned by create_searcher/1.
  """
  @spec take_one(enumerable({element(), weight()}) | searcher()) :: element() | nil
  def take_one(enumerable_or_searcher)

  def take_one(%__MODULE__{number_elements: 0}) do
    raise Enum.EmptyError
  end

  def take_one(%__MODULE__{search_table: search_table, total_weight: total_weight}) do
    {_, element} = SearchTable.search(search_table, :rand.uniform() * total_weight)
    element
  end

  def take_one(enumerable) do
    enumerable
    |> verify_filter_input()
    |> take_one_impl()
  end

  @doc """
  Take N elements from enumerable of {element, weight}
  or from structure returned by create_searcher/1.
  """
  @spec take_n(enumerable({element(), weight()}) | searcher(), integer()) :: list(element())
  def take_n(enumerable_or_searcher, number)

  def take_n(_, 0), do: []

  def take_n(%__MODULE__{number_elements: 0}, _), do: []

  def take_n(
        %__MODULE__{
          number_elements: number_elements
        } = searcher,
        number
      )
      when number > 0 do
    number_to_take = min(number, number_elements)

    {elements, _, _, _} =
      Enum.reduce(1..number_to_take, {[], searcher, MapSet.new(), 0.0}, fn _,
                                                                           {res, searcher,
                                                                            excluded,
                                                                            excluded_weight} ->
        case take_one_excluded(searcher, excluded, excluded_weight, 0) do
          {:ok, {{key, weight}, element}, new_searcher, new_excluded, new_excluded_weight} ->
            {[element | res], new_searcher, MapSet.put(new_excluded, key),
             new_excluded_weight + weight}

          {:error, _} ->
            {res, searcher, excluded, excluded_weight}
        end
      end)

    Enum.reverse(elements)
  end

  def take_n(enumerable, number) do
    if Enum.count(enumerable) > 0 do
      enumerable
      |> verify_filter_input()
      |> create_searcher_impl()
      |> take_n(number)
    else
      []
    end
  end

  defp create_searcher_impl(enumerable) do
    {search_table, total_weight} = make_raw_search_table(enumerable)

    %__MODULE__{
      search_table: SearchTable.compile(search_table),
      total_weight: total_weight,
      number_elements: Enum.count(enumerable)
    }
  end

  defp take_one_impl([]), do: raise(Enum.EmptyError)

  defp take_one_impl(enumerable) do
    {search_table, total_weight} = make_raw_search_table(enumerable)

    {_, element} = SearchTable.search(search_table, :rand.uniform() * total_weight)

    element
  end

  defp make_raw_search_table(enumerable) do
    {total_weight, elements_list} =
      1..length(enumerable)
      |> Enum.zip_reduce(enumerable, {0.0, []}, fn i, {element, weight}, {total_weight, acc} ->
        {total_weight + weight, [{total_weight, {{i, weight}, element}} | acc]}
      end)

    {
      [
        {:neg_inf, :assert_can_not_happen}
        | Enum.reverse([{total_weight, :assert_can_not_happen} | elements_list])
      ],
      total_weight
    }
  end

  defp verify_filter_input(enumerable) do
    Enum.reject(enumerable, fn {_, weight} when is_number(weight) ->
      if weight < 0 do
        raise ArgumentError, message: "WeightedRandom weight < 0"
      end

      weight == 0
    end)
  end

  @take_retries_max 10
  @take_weights_max 0.8

  defp take_one_excluded(
         %__MODULE__{
           total_weight: +0.0
         } = _searcher,
         _excluded,
         _excluded_weights,
         _retry
       ) do
    {:error, :total_weight_0}
  end

  defp take_one_excluded(
         %__MODULE__{
           number_elements: 0
         } = _searcher,
         _excluded,
         _excluded_weights,
         _retry
       ) do
    {:error, :number_elements_0}
  end

  defp take_one_excluded(
         %__MODULE__{} = searcher,
         excluded,
         _excluded_weight,
         @take_retries_max
       ) do
    new_searcher = rebuild_searcher(searcher, excluded)
    take_one_excluded(new_searcher, MapSet.new(), 0.0, 0)
  end

  defp take_one_excluded(
         %__MODULE__{
           total_weight: total_weight
         } = searcher,
         excluded,
         excluded_weight,
         _retry
       )
       when excluded_weight / total_weight > @take_weights_max do
    new_searcher = rebuild_searcher(searcher, excluded)
    take_one_excluded(new_searcher, MapSet.new(), 0.0, 0)
  end

  defp take_one_excluded(
         %__MODULE__{
           search_table: search_table,
           total_weight: total_weight
         } = searcher,
         excluded,
         excluded_weight,
         retry
       ) do
    {{key, _}, _} = element = SearchTable.search(search_table, :rand.uniform() * total_weight)

    if MapSet.member?(excluded, key) do
      take_one_excluded(searcher, excluded, excluded_weight, retry + 1)
    else
      {:ok, element, searcher, excluded, excluded_weight}
    end
  end

  defp rebuild_searcher(%__MODULE__{search_table: search_table}, excluded) do
    SearchTable.decompile(search_table)
    |> Enum.filter(fn
      {_, :assert_can_not_happen} -> false
      {_, {{key, _}, _}} -> not MapSet.member?(excluded, key)
    end)
    |> Enum.map(fn {_, {{_, weight}, element}} -> {element, weight} end)
    |> create_searcher_impl()
  end
end
