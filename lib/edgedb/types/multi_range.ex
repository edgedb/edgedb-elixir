defmodule EdgeDB.MultiRange do
  @moduledoc since: "0.7.0"
  @moduledoc """
  A value representing a collection of ranges.

  `EdgeDB.MultiRange` implements `Enumerable` protocol for iterating over the collection.
    Each range in the collection is an instance of the `t:EdgeDB.Range.t/0` struct.

  ```iex
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> EdgeDB.query_required_single!(client, "select multirange([range(1, 10)])")
  #EdgeDB.MultiRange<[#EdgeDB.Range<[1, 10)>]>
  ```
  """

  defstruct [
    :ranges
  ]

  @typedoc """
  A type that is acceptable by EdgeDB ranges.
  """
  @type value() :: EdgeDB.Range.value()

  @typedoc """
  A value of `t:EdgeDB.MultiRange.value/0` type representing a collection of intervals of values.

  Fields:

    * `:ranges` - collection of ranges.
  """
  @type t(value) :: %__MODULE__{
          ranges: list(EdgeDB.Range.t(value))
        }

  @typedoc """
  A value of `t:EdgeDB.MultiRange.value/0` type representing a collection of intervals of values.
  """
  @type t() :: t(value())
end

defimpl Enumerable, for: EdgeDB.MultiRange do
  @impl Enumerable
  def count(%EdgeDB.MultiRange{ranges: ranges}) do
    {:ok, length(ranges)}
  end

  @impl Enumerable
  def member?(%EdgeDB.MultiRange{ranges: []}, _element) do
    {:ok, false}
  end

  @impl Enumerable
  def member?(%EdgeDB.MultiRange{}, _element) do
    {:error, __MODULE__}
  end

  @impl Enumerable
  def slice(%EdgeDB.MultiRange{ranges: []}) do
    {:ok, 0, fn _start, _amount, _step -> [] end}
  end

  @impl Enumerable
  def slice(%EdgeDB.MultiRange{}) do
    {:error, __MODULE__}
  end

  @impl Enumerable
  def reduce(%EdgeDB.MultiRange{}, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  @impl Enumerable
  def reduce(%EdgeDB.MultiRange{} = range, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(range, &1, fun)}
  end

  @impl Enumerable
  def reduce(%EdgeDB.MultiRange{ranges: []}, {:cont, acc}, _fun) do
    {:done, acc}
  end

  @impl Enumerable
  def reduce(%EdgeDB.MultiRange{ranges: [range | ranges]}, {:cont, acc}, fun) do
    reduce(%EdgeDB.MultiRange{ranges: ranges}, fun.(range, acc), fun)
  end
end

defimpl Inspect, for: EdgeDB.MultiRange do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.MultiRange{} = range, opts) do
    concat([
      "#EdgeDB.MultiRange<",
      container_doc("[", range.ranges, "]", opts, &Inspect.inspect/2),
      ">"
    ])
  end
end
