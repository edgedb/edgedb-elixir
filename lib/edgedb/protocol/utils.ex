defmodule EdgeDB.Protocol.Utils do
  @type encoding_option() ::
          {:raw, boolean()}
          | {:datatype, atom()}

  @spec encode_list(
          (term() -> iodata()),
          list(term()),
          list(encoding_option())
        ) :: iodata()
  def encode_list(encoder, entities, opts) do
    size_datatype = Keyword.get(opts, :datatype, EdgeDB.Protocol.Datatypes.UInt16)
    encoded_data = Enum.map(entities, &encoder.(&1))

    if Keyword.get(opts, :raw) do
      encoded_data
    else
      encoded_size =
        entities
        |> length()
        |> size_datatype.encode()

      [encoded_size, encoded_data]
    end
  end

  @spec decode_list(
          (bitstring() -> term()),
          non_neg_integer(),
          bitstring()
        ) :: {list(term()), bitstring()}

  def decode_list(_decoder, 0, data) do
    {[], data}
  end

  def decode_list(decoder, count, <<data::binary>>) do
    {entities, rest} =
      Enum.reduce(1..count, {[], data}, fn _idx, {entities, rest} ->
        {decoded_entity, rest} = decoder.(rest)
        {[decoded_entity | entities], rest}
      end)

    entities = Enum.reverse(entities)

    {entities, rest}
  end

  @spec define_record(atom(), Keyword.t()) :: Macro.t()
  def define_record(record_name, fields) do
    record_fields = Keyword.keys(fields)

    quote do
      require Record

      @type t() :: record(unquote(record_name), unquote(fields))

      Record.defrecord(unquote(record_name), unquote(record_fields))
    end
  end
end
