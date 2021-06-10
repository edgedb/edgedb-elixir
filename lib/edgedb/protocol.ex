defmodule EdgeDB.Protocol do
  alias EdgeDB.Protocol.Datatypes

  @type list_encoding_option() ::
          {:raw, boolean()}
          | {:datatype, atom()}

  @type list_encoding_options() :: list(list_encoding_option())

  defdelegate encode_message(message), to: EdgeDB.Protocol.Messages
  defdelegate decode_message(data), to: EdgeDB.Protocol.Messages

  @spec encode_list(
          (term() -> iodata()),
          list(term()),
          list_encoding_options()
        ) :: iodata()
  def encode_list(encoder, entities, opts) do
    size_datatype = Keyword.get(opts, :datatype, Datatypes.UInt16)
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

  @spec define_edgedb_record(atom(), Keyword.t(), Keyword.t()) :: Macro.t()
  def define_edgedb_record(record_name, fields, defaults) do
    default_fields_names = Keyword.keys(defaults)

    record_fields_names =
      fields
      |> Keyword.drop(default_fields_names)
      |> Keyword.keys()

    record_fields = record_fields_names ++ defaults

    quote do
      @type t() :: record(unquote(record_name), unquote(fields))

      defrecord unquote(record_name), unquote(record_fields)
    end
  end
end
