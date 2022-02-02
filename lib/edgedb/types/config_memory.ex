defmodule EdgeDB.ConfigMemory do
  defstruct [
    :bytes
  ]

  @opaque t() :: %__MODULE__{
            bytes: pos_integer()
          }

  @spec bytes(t()) :: pos_integer()
  def bytes(%__MODULE__{bytes: bytes}) do
    bytes
  end
end

defimpl Inspect, for: EdgeDB.ConfigMemory do
  import Inspect.Algebra

  @kib 1024
  @mib 1024 * @kib
  @gib 1024 * @mib
  @tib 1024 * @gib
  @pib 1024 * @tib

  @impl Inspect
  def inspect(%EdgeDB.ConfigMemory{bytes: bytes}, _opts) do
    bytes_repr =
      cond do
        bytes >= @pib and rem(bytes, @pib) == 0 ->
          "#{div(bytes, @pib)}PiB"

        bytes >= @tib and rem(bytes, @tib) == 0 ->
          "#{div(bytes, @tib)}TiB"

        bytes >= @gib and rem(bytes, @gib) == 0 ->
          "#{div(bytes, @gib)}GiB"

        bytes >= @mib and rem(bytes, @mib) == 0 ->
          "#{div(bytes, @mib)}MiB"

        bytes >= @kib and rem(bytes, @kib) == 0 ->
          "#{div(bytes, @kib)}KiB"

        true ->
          "#{bytes}B"
      end

    concat(["#EdgeDB.ConfigMemory<\"", bytes_repr, "\">"])
  end
end
