defmodule EdgeDB.Protocol.Types.Dimension do
  @moduledoc false

  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.Datatypes

  @lower 1

  deftype(
    fields: [
      upper: Datatypes.Int32.t(),
      lower: {Datatypes.Int32.t(), default: @lower}
    ]
  )

  @impl EdgeDB.Protocol.Type
  def encode_type(%__MODULE__{upper: upper}) do
    [
      Datatypes.Int32.encode(upper),
      Datatypes.Int32.encode(@lower)
    ]
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<upper::int32, @lower::int32, rest::binary>>) do
    {%__MODULE__{upper: upper, lower: @lower}, rest}
  end
end
