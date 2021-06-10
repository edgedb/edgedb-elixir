defmodule EdgeDB.Protocol.TypeDescriptors.TypeAnnotationDescriptor do
  use EdgeDB.Protocol.TypeDescriptor

  alias EdgeDB.Protocol.{
    Codecs,
    Datatypes
  }

  @start_code 0x80
  @end_code 0xFE

  defguard is_supported_type(type) when @start_code <= type and type <= @end_code

  # id of type here is always known, so no need to parse
  # custom consume to handle range of codes
  deftypedescriptor(
    type: @start_code..@end_code,
    parse?: false,
    consume?: false
  )

  # ignore annotation since right now driver doesn't understand any annotation

  @spec consume(Codecs.Storage.t(), bitstring()) :: bitstring()
  def consume(_storage, <<type::uint8, _type_id::uuid, rest::binary>>)
      when is_supported_type(type) do
    {_annotation, rest} = Datatypes.String.decode(rest)
    rest
  end
end
