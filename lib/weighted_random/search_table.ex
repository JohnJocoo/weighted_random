defmodule WeightedRandom.SearchTable do
  @moduledoc """
  Search table maps value ranges to some result (ex. score).
  Example of such table: [{:neg_inf, 0}, {-30, 4}, {-20, 8}, {-10, 10}, {10, 7}, {20, 0}]
  It will give such results with 'search' function:
  -50 -> 0
  -30 -> 0
  -29 -> 4
  -15 -> 8
  -10 -> 8
  0 -> 10
  10 -> 7
  15 -> 7
  30 -> 0
  """

  @type t :: [{:neg_inf, any()} | list({number(), any()})] | %__MODULE__{}

  @enforce_keys [:search_tree]
  defstruct [:search_tree]

  @doc """
  Compile search table into structure optimised for quick search.
  """
  @spec compile([{:neg_inf, any()} | list({number(), any()})]) :: %__MODULE__{}
  def compile([{:neg_inf, _} | _] = table) do
    search_tree = build_subtree(table)
    %__MODULE__{search_tree: search_tree}
  end

  @spec decompile(%__MODULE__{}) :: [{:neg_inf, any()} | list({number(), any()})]
  def decompile(%__MODULE{search_tree: search_tree}) do
    decompile_impl(search_tree, [])
  end

  @doc """
  Search for value in ranges.

  ## Examples

      iex> SearchTable.search([{:neg_inf, 1}, {0, 5}], 0)
      5

      iex> SearchTable.search([{:neg_inf, 1}, {0, 5}], -9)
      1

      iex> SearchTable.search([{:neg_inf, 1}, {0, 5}], 3)
      5

      iex> SearchTable.search([{:neg_inf, 1}, {-7, 5}, {7, 3}], -7)
      1

      iex> SearchTable.search([{:neg_inf, 1}, {-7, 5}, {7, 3}], 0)
      5

      iex> SearchTable.search([{:neg_inf, 1}, {-7, 5}, {7, 3}], 7)
      3

      iex> SearchTable.search([{:neg_inf, 1}, {-7, 5}, {7, 3}], 10)
      3
  """
  @spec search(__MODULE__.t(), number()) :: any()
  def search(table_or_compiled, search_value)

  def search(%__MODULE{search_tree: {_, element, _, _} = search_tree}, search_value) do
    search_subtree(search_tree, search_value, element)
  end

  def search([{:neg_inf, initial} | table], search_value) do
    Enum.reduce_while(table, initial, fn {lower_bound, new_value}, current_value ->
      if is_less_lower_bound(lower_bound, search_value) do
        {:halt, current_value}
      else
        {:cont, new_value}
      end
    end)
  end

  defp build_subtree([]), do: nil
  defp build_subtree([{lower_bound, element}]), do: {lower_bound, element, nil, nil}

  defp build_subtree(table) do
    {left_table, [{lower_bound, element} | right_table]} = Enum.split(table, round(length(table) / 2) - 1)
    left_subtree = build_subtree(left_table)
    right_subtree = build_subtree(right_table)

    {lower_bound, element, left_subtree, right_subtree}
  end

  defp search_subtree(nil, _search_value, current_element), do: current_element

  defp search_subtree({lower_bound, new_element, left_subtree, right_subtree}, search_value, current_element) do
    if is_less_lower_bound(lower_bound, search_value) do
      search_subtree(left_subtree, search_value, current_element)
    else
      search_subtree(right_subtree, search_value, new_element)
    end
  end

  defp is_less_lower_bound(:neg_inf, _value), do: false

  defp is_less_lower_bound(lower_bound, value) do
    (lower_bound >= 0 and value < lower_bound) or (lower_bound < 0 and value <= lower_bound)
  end

  defp decompile_impl(nil, res), do: res

  defp decompile_impl({lower_bound, element, left_subtree, right_subtree}, res) do
    left_res = decompile_impl(left_subtree, res)
    mid_res = [{lower_bound, element} | left_res]
    decompile_impl(right_subtree, mid_res)
  end
end
