defmodule EdgeDB.Protocol.Codecs.JSON do
  @moduledoc false

  @behaviour EdgeDB.Protocol.BaseScalarCodec

  @id UUID.string_to_binary!("00000000-0000-0000-0000-00000000010F")
  @name "std::json"

  defstruct id: @id,
            name: @name

  @impl EdgeDB.Protocol.BaseScalarCodec
  def new do
    %__MODULE__{}
  end

  @impl EdgeDB.Protocol.BaseScalarCodec
  def id do
    @id
  end

  @impl EdgeDB.Protocol.BaseScalarCodec
  def name do
    @name
  end
end

defimpl EdgeDB.Protocol.Codec, for: EdgeDB.Protocol.Codecs.JSON do
  import EdgeDB.Protocol.Converters

  @json_library Application.compile_env(:edgedb, :json, Jason)

  @impl EdgeDB.Protocol.Codec
  def encode(_codec, data, _codec_storage) do
    data = @json_library.encode_to_iodata!(data)
    [<<IO.iodata_length(data) + 1::uint32, 1::uint8>> | data]
  end

  @impl EdgeDB.Protocol.Codec
  def decode(
        _codec,
        <<json_type_size::uint32, rest::binary(json_type_size)>>,
        _codec_storage
      ) do
    json_size = json_type_size - 1
    <<1::uint8, json::binary(json_size)>> = rest

    json
    |> :binary.copy()
    |> @json_library.decode!()
  end
end
