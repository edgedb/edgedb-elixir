defmodule EdgeDB.Range do
  @moduledoc since: "0.4.0"
  @moduledoc """
  A value representing some interval of values.

  ```elixir
  iex(1)> {:ok, client} = EdgeDB.start_link()
  iex(2)> EdgeDB.query_required_single!(client, "select range(1, 10)")
  #EdgeDB.Range<[1, 10)>
  ```
  """

  defstruct [
    :lower,
    :upper,
    inc_lower: true,
    inc_upper: false,
    is_empty: false
  ]

  @typedoc """
  A value representing some interval of values.

  Fields:

    * `:lower` - data for the lower range boundary.
    * `:upper` - data for the upper range boundary.
    * `:inc_lower` - flag whether the range should strictly include the lower boundary.
    * `:inc_upper` - flag whether the range should strictly include the upper boundary.
    * `:is_empty` - flag for an empty range.
  """
  @type t(value) :: %__MODULE__{
          lower: value | nil,
          upper: value | nil,
          inc_lower: boolean(),
          inc_upper: boolean(),
          is_empty: boolean()
        }

  @typedoc """
  A value representing some interval of values.
  """
  @type t() :: t(term())

  @typedoc """
  Options for `EdgeDB.Range.new/3` function.

  Supported options:

    * `:inc_lower` - flag whether the created range should strictly include the lower boundary.
    * `:inc_upper` - flag whether the created range should strictly include the upper boundary.
    * `:empty` - flag to create an empty range.
  """
  @type creation_option() ::
          {:inc_lower, boolean()}
          | {:inc_upper, boolean()}
          | {:empty, boolean()}

  @doc """
  Create an empty range.

    ```elixir
  iex(1)> EdgeDB.Range.empty()
  #EdgeDB.Range<empty>
  ```
  """
  @spec empty() :: t()
  def empty do
    new(nil, nil, empty: true, inc_lower: false)
  end

  @doc """
  Create new range.

    ```elixir
  iex(1)> EdgeDB.Range.new(1.1, 3.3, inc_upper: true)
  #EdgeDB.Range<[1.1, 3.3]>
  ```
  """
  @spec new(value, value, list(creation_option())) :: t(value) when value: term()
  def new(lower, upper, opts \\ []) do
    inc_lower? = Keyword.get(opts, :inc_lower, true)
    inc_upper? = Keyword.get(opts, :inc_upper, false)
    empty? = Keyword.get(opts, :empty, false)

    %__MODULE__{
      lower: lower,
      upper: upper,
      inc_lower: inc_lower?,
      inc_upper: inc_upper?,
      is_empty: empty?
    }
  end
end

defimpl Inspect, for: EdgeDB.Range do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.Range{is_empty: true}, _opts) do
    concat(["#EdgeDB.Range<empty>"])
  end

  @impl Inspect
  def inspect(%EdgeDB.Range{} = range, opts) do
    concat([
      "#EdgeDB.Range<",
      if(range.inc_lower, do: "[", else: "("),
      if(range.lower, do: Inspect.inspect(range.lower, opts), else: empty()),
      ",",
      if(range.upper, do: Inspect.inspect(range.upper, opts), else: empty()),
      if(range.inc_upper, do: "]", else: ")"),
      ">"
    ])
  end
end
