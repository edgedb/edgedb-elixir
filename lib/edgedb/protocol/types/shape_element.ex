defmodule EdgeDB.Protocol.Types.ShapeElement do
  use EdgeDB.Protocol.Type

  alias EdgeDB.Protocol.{
    Datatypes,
    Enums
  }

  @field_is_implicit Bitwise.bsl(1, 0)
  @field_is_link_property Bitwise.bsl(1, 1)
  @field_is_link Bitwise.bsl(1, 2)

  deftype(
    encode: false,
    fields: [
      flags: Datatypes.UInt8.t(),
      cardinality: Enums.Cardinality.t(),
      name: Datatypes.String.t(),
      type_pos: Datatypes.UInt16.t()
    ]
  )

  @spec link?(t()) :: boolean()
  def link?(%__MODULE__{flags: flags}) do
    Bitwise.band(flags, @field_is_link) != 0
  end

  @spec link_property?(t()) :: boolean()
  def link_property?(%__MODULE__{flags: flags}) do
    Bitwise.band(flags, @field_is_link_property) != 0
  end

  @spec implicit?(t()) :: boolean()
  def implicit?(%__MODULE__{flags: flags}) do
    Bitwise.band(flags, @field_is_implicit) != 0
  end

  @impl EdgeDB.Protocol.Type
  def decode_type(<<flags::uint32, rest::binary>>) do
    {cardinality, rest} = Enums.Cardinality.decode(rest)
    {name, rest} = Datatypes.String.decode(rest)
    {type_pos, rest} = Datatypes.UInt16.decode(rest)

    {%__MODULE__{
       flags: flags,
       cardinality: cardinality,
       name: name,
       type_pos: type_pos
     }, rest}
  end
end
