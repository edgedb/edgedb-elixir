defmodule EdgeDB.Protocol.TypeDescriptors.BaseScalarTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codecs,
    DataTypes
  }

  # base scalar codecs always exist in storage
  # so we don't need parsing
  deftypedescriptor(
    type: 2,
    parse?: false
  )

  @spec consume_description(Codecs.Storage.t(), DataTypes.UUID.t(), bitstring()) :: bitstring()
  defp consume_description(_codecs, _id, <<rest::binary>>) do
    rest
  end
end
