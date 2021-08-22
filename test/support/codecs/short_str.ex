defmodule Tests.Support.Codecs.ShortStr do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{Codecs, Error}

  defscalarcodec(
    type_name: "default::short_str",
    type: String.t(),

    # inherit this from parent codec
    calculate_size: false
  )

  @impl EdgeDB.Protocol.Codec
  def encode_instance(str) do
    if String.length(str) <= 5 do
      Codecs.Str.encode_instance(str)
    else
      raise Error.invalid_argument_error("string is too long")
    end
  end

  defdelegate decode_instance(binary_data), to: Codecs.Str
end
