defmodule EdgeDB.Protocol.TypeDescriptors.BaseScalarTypeDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  # base scalar codecs always exist in storage
  # so we don't need parsing
  deftypedescriptor(
    type: 2,
    parse?: false
  )

  defp consume_description(_codecs, _id, <<rest::binary>>) do
    rest
  end
end
