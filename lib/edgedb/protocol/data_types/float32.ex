defmodule EdgeDB.Protocol.DataTypes.Float32 do
  use EdgeDB.Protocol.DataType

  @nan_literal <<0::1, 255, 1::1, 0::22>>
  @infinity_literal <<0::1, 255, 0::23>>
  @negative_infinity_literal <<1::1, 255, 0::23>>

  defdatatype(type: float() | :nan | :infinity | :negative_infinity)

  @spec encode(t()) :: bitstring()

  def encode(float) when is_number(float) do
    <<float::float32>>
  end

  def encode(:nan) do
    @nan_literal
  end

  def encode(:infinity) do
    @infinity_literal
  end

  def encode(:negative_infinity) do
    @negative_infinity_literal
  end

  @spec decode(bitstring()) :: {t(), bitstring()}

  def decode(<<@nan_literal, rest::binary>>) do
    {:nan, rest}
  end

  def decode(<<@infinity_literal, rest::binary>>) do
    {:infinity, rest}
  end

  def decode(<<@negative_infinity_literal, rest::binary>>) do
    {:negative_infinity, rest}
  end

  def decode(<<float::float32, rest::binary>>) do
    {float, rest}
  end
end
