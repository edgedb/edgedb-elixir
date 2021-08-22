defmodule Tests.Support.Codecs.TicketNo do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Codecs

  defscalarcodec(type_name: "default::TicketNo")

  defstruct [
    :number
  ]

  @impl EdgeDB.Protocol.Codec
  def encode_instance(%__MODULE__{number: number}) do
    Codecs.Int64.encode_instance(number)
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(binary_representation) do
    number = Codecs.Int64.decode_instance(binary_representation)

    %__MODULE__{
      number: number
    }
  end
end
