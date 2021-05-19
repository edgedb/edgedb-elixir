defmodule EdgeDB.Protocol.Codecs.LocalDate do
  use EdgeDB.Protocol.Codec

  alias EdgeDB.Protocol.DataTypes

  @base_date elem(Date.new(2000, 1, 1), 1)

  defbasescalarcodec(
    type_id: UUID.from_string("00000000-0000-0000-0000-00000000010C"),
    type_name: "cal::local_date",
    type: Date.t()
  )

  @spec encode_instance(t()) :: bitstring()
  def encode_instance(%Date{} = d) do
    days =
      @base_date
      |> Date.diff(d)
      |> abs()

    DataTypes.Int32.encode(days)
  end

  @spec decode_instance(bitstring()) :: t()
  def decode_instance(<<days::int32>>) do
    Date.add(@base_date, days)
  end
end
