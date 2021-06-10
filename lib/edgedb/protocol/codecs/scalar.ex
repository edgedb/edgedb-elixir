defmodule EdgeDB.Protocol.Codecs.Scalar do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  defcodec(
    type:
      Codecs.UUID.t()
      | Codecs.Str.t()
      | Codecs.Bytes.t()
      | Codecs.Int16.t()
      | Codecs.Int32.t()
      | Codecs.Int64.t()
      | Codecs.Float32.t()
      | Codecs.Float64.t()
      | Codecs.Decimal.t()
      | Codecs.Bool.t()
      | Codecs.DateTime.t()
      | Codecs.LocalDateTime.t()
      | Codecs.LocalDate.t()
      | Codecs.LocalTime.t()
      | Codecs.Duration.t()
      | Codecs.JSON.t()
      | Codecs.BigInt.t()
  )

  @spec new(Datatypes.UUID.t(), Codec.t()) :: Codec.t()
  def new(type_id, %Codec{scalar?: true} = codec) do
    %Codec{
      type_id: type_id,
      encoder: codec.encoder,
      decoder: codec.decoder,
      scalar?: true,
      parent: codec.module,
      module: __MODULE__
    }
  end
end
