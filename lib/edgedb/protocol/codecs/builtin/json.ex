defmodule EdgeDB.Protocol.Codecs.Builtin.JSON do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Error
  }

  @format 1

  defbuiltinscalarcodec(
    type_name: "std::json",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-00000000010F"),
    type: any(),
    calculate_size: false
  )

  # TODO: allow custom JSON libraries, but for now Jason is hardcoded

  @impl EdgeDB.Protocol.Codec
  def encode_instance(instance) do
    case Jason.encode(instance) do
      {:ok, encoded_data} ->
        data_length = byte_size(encoded_data)
        data = :binary.bin_to_list(encoded_data)

        [
          Datatypes.UInt32.encode(data_length + 1),
          Datatypes.Int8.encode(@format),
          Datatypes.Int8.encode(data, raw: true)
        ]

      {:error, error} ->
        raise Error.invalid_argument_error(
                "unable to encode #{inspect(instance)} as #{type_name()}: #{inspect(error)}"
              )
    end
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<json_type_length::uint32, @format::uint8, rest::binary>>) do
    json_content_length = json_type_length - 1
    <<json_content::binary(json_content_length)>> = rest

    case Jason.decode(json_content) do
      {:ok, instance} ->
        instance

      {:error, error} ->
        raise Error.invalid_argument_error(
                "unable to decode binary data as #{@format}: #{inspect(error)}"
              )
    end
  end
end
