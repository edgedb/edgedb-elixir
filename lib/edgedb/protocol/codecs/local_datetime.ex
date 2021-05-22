defmodule EdgeDB.Protocol.Codecs.LocalDateTime do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.{
    Codecs,
    DataTypes
  }

  defbasescalarcodec(
    type_name: "cal::local_datetime",
    type_id: DataTypes.UUID.from_string("00000000-0000-0000-0000-00000000010B"),
    type: NaiveDateTime.t() | non_neg_integer()
  )

  @spec encode_instance(t()) :: iodata()

  def encode_instance(unix_ts) when is_integer(unix_ts) do
    Codecs.DateTime.encode_instance(unix_ts)
  end

  def encode_instance(%NaiveDateTime{} = ndt) do
    ndt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix()
    |> encode_instance()
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(data) do
    data
    |> Codecs.DateTime.decode_instance()
    |> DateTime.to_naive()
  end
end
