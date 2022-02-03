defmodule EdgeDB.Protocol.Codecs.Builtin.Enum do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  # internally enum values are just strings
  # so we don't need to add byte size of encoded/decoded instance here
  # since we just pass data to std::str codec which will do this itself
  defcodec(
    type: String.t(),
    calculate_size: false
  )

  @spec new(Datatypes.UUID.t(), list(String.t())) :: Codec.t()
  def new(type_id, members) do
    encoder = create_encoder(&encode_enum(&1, members))
    decoder = create_decoder(&decode_enum(&1))

    %Codec{
      type_id: type_id,
      encoder: encoder,
      decoder: decoder,
      is_scalar: true,
      module: __MODULE__
    }
  end

  @spec encode_enum(t(), list(t())) :: iodata()
  def encode_enum(value, members) when is_binary(value) do
    if value in members do
      Codecs.Builtin.Str.encode_instance(value)
    else
      raise EdgeDB.Error.invalid_argument_error(
              "unable to encode #{inspect(value)} as enum: #{inspect(value)} is not member of enum"
            )
    end
  end

  @spec decode_enum(bitstring()) :: t()
  def decode_enum(<<data::binary>>) do
    Codecs.Builtin.Str.decode_instance(data)
  end
end
