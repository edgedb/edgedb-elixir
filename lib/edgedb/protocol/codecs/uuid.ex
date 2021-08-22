defmodule EdgeDB.Protocol.Codecs.UUID do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Datatypes,
    Error
  }

  defbuiltinscalarcodec(
    type_name: "std::uuid",
    type_id: Datatypes.UUID.from_string("00000000-0000-0000-0000-000000000100"),
    type: Datatypes.UUID.t()
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(uuid) do
    Datatypes.UUID.encode(uuid)
  rescue
    _exc in ArgumentError ->
      reraise Error.invalid_argument_error("unable to encode #{inspect(uuid)} as #{@type_name}"),
              __STACKTRACE__
  end

  @impl EdgeDB.Protocol.Codec
  def decode_instance(<<_content::uuid>> = data) do
    Datatypes.UUID.to_string(data)
  end
end
