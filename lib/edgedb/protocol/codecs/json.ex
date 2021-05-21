defmodule EdgeDB.Protocol.Codecs.JSON do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  @format 1

  defbasescalarcodec(
    calculate_size?: false,
    type_id: UUID.from_string("00000000-0000-0000-0000-00000000010F"),
    type_name: "std::json",
    type: any()
  )

  # TODO: allow custom JSON libraries, but for now Jason is hardcoded

  @spec encode_instance(t()) :: iodata()
  def encode_instance(instanfce) do
    case Jason.encode(instanfce) do
      {:ok, encoded_data} ->
        data_length = byte_size(encoded_data)
        data = :binary.bin_to_list(encoded_data)

        [
          DataTypes.UInt32.encode(data_length + 1),
          DataTypes.Int8.encode(@format),
          DataTypes.Int8.encode(data, :raw)
        ]

      {:error, error} ->
        raise EdgeDB.Protocol.Errors.InvalidArgumentError,
              "unable to encode argument as JSON: #{inspect(error)}"
    end
  end

  @spec decode_instance(bitstring()) :: {t(), bitstring()}
  def decode_instance(<<json_type_length::uint32, @format::uint8, rest::binary>>) do
    json_content_length = json_type_length - 1

    with <<json_content::binary(json_content_length)>> <- rest,
         {:ok, data} <- Jason.decode(json_content) do
      data
    else
      {:error, error} ->
        raise EdgeDB.Protocol.Errors.InvalidValueError,
              "unable to decode JSON: #{inspect(error)}"
    end
  end
end
