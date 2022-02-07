defmodule EdgeDB.Protocol.Datatypes.Float64 do
  @moduledoc false

  use EdgeDB.Protocol.Datatype

  @nan_literal <<0::1, 2047::11, 1::1, 0::51>>
  @infinity_literal <<0::1, 2047::11, 0::52>>
  @negative_infinity_literal <<1::1, 2047::11, 0::52>>

  defdatatype(type: float() | :nan | :infinity | :negative_infinity)

  @impl EdgeDB.Protocol.Datatype
  def encode_datatype(float) when is_number(float) do
    <<float::float64>>
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
  def decode_datatype(<<float::float64, rest::binary>>) do
    {float, rest}
  end
end
