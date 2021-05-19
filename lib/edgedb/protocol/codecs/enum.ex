defmodule EdgeDB.Protocol.Codecs.Enum do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.Codecs

  # internally enum values are just strings
  # so we don't need to add byte size of encoded/decoded instance here
  # since we just pass data to std::str codec which will do this itself
  defcodec(
    calculate_size?: false,
    type: EdgeDB.Enum.t()
  )

  def new(type_id, members) do
    encoder =
      create_encoder(fn %EdgeDB.Enum{value: data} ->
        Codecs.Str.encode(data)
      end)

    decoder =
      create_decoder(fn data ->
        {member, <<>>} = Codecs.Str.decode(data)

        EdgeDB.Enum._new(members, member)
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
