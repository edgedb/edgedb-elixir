defmodule EdgeDB.Protocol.Codecs.Builtin.Scalar do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  defcodec(
    type:
      Codecs.Builtin.UUID.t()
      | Codecs.Builtin.Str.t()
      | Codecs.Builtin.Bytes.t()
      | Codecs.Builtin.Int16.t()
      | Codecs.Builtin.Int32.t()
      | Codecs.Builtin.Int64.t()
      | Codecs.Builtin.Float32.t()
      | Codecs.Builtin.Float64.t()
      | Codecs.Builtin.Decimal.t()
      | Codecs.Builtin.Bool.t()
      | Codecs.Builtin.DateTime.t()
      | Codecs.Builtin.LocalDateTime.t()
      | Codecs.Builtin.LocalDate.t()
      | Codecs.Builtin.LocalTime.t()
      | Codecs.Builtin.Duration.t()
      | Codecs.Builtin.JSON.t()
      | Codecs.Builtin.BigInt.t()
  )

  @spec new(Datatypes.UUID.t(), Codec.t()) :: Codec.t()
  def new(type_id, %Codec{is_scalar: true} = codec) do
    %Codec{
      type_id: type_id,
      encoder: codec.encoder,
      decoder: codec.decoder,
      is_scalar: true,
      parent: codec.module,
      module: __MODULE__
    }
  end
end
