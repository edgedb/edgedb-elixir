defmodule EdgeDB.Protocol.Datatypes.Float32 do
  use EdgeDB.Protocol.Datatype

  @nan_literal <<0::1, 255, 1::1, 0::22>>
  @infinity_literal <<0::1, 255, 0::23>>
  @negative_infinity_literal <<1::1, 255, 0::23>>

  defdatatype(type: float() | :nan | :infinity | :negative_infinity)

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(float) when is_number(float) do
    <<float::float32>>
  end

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(:nan) do
    @nan_literal
  end

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(:infinity) do
    @infinity_literal
  end

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(:negative_infinity) do
    @negative_infinity_literal
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<@nan_literal, rest::binary>>) do
    {:nan, rest}
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<@infinity_literal, rest::binary>>) do
    {:infinity, rest}
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<@negative_infinity_literal, rest::binary>>) do
    {:negative_infinity, rest}
  end

  @impl EdgeDB.Protocol.Datatype
  def decode_datatype(<<float::float32, rest::binary>>) do
    {float, rest}
  end
end
