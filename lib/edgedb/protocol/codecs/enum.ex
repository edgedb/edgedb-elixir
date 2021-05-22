defmodule EdgeDB.Protocol.Codecs.Enum do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    DataTypes,
    Errors
  }

  # internally enum values are just strings
  # so we don't need to add byte size of encoded/decoded instance here
  # since we just pass data to std::str codec which will do this itself
  defcodec(
    type: EdgeDB.Enum.t(),
    calculate_size?: false
  )

  @spec new(DataTypes.UUID.t(), list(String.t())) :: Codec.t()
  def new(type_id, members) do
    encoder =
      create_encoder(fn data when is_binary(data) ->
        if data in members do
          Codecs.Str.encode(data)
        else
          raise Errors.InvalidArgumentError,
                "unable to encode #{inspect(data)} as enum: #{inspect(data)} is not member of enum"
        end
      end)

    decoder =
      create_decoder(fn data ->
        Codecs.Str.decode(data)
      end)

    %Codec{
      type_id: <<type_id::uuid>>,
      encoder: encoder,
      decoder: decoder,
      scalar?: true,
      module: __MODULE__
    }
  end
end
