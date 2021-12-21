defmodule Tests.Support.Codecs.NotRegisteredString do
  use EdgeDB.Protocol.Codec

  defscalarcodec(
    type_name: "default::not_registered_string",
    type: term(),
    calculate_size: false
  )

  defdelegate encode_instance(term), to: EdgeDB.Protocol.Codecs.Builtin.Str
  defdelegate decode_instance(binary_data), to: EdgeDB.Protocol.Codecs.Builtin.Str
end
