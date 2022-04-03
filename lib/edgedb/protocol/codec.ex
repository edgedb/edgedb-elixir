defprotocol EdgeDB.Protocol.Codec do
  @moduledoc since: "0.2.0"
  @moduledoc """
  A codec knows how to work with the internal binary data from EdgeDB.
  The binary protocol specification for the codecs can be found on
    [the official EdgeDB site](https://www.edgedb.com/docs/reference/protocol).
  Useful links for codec developers:
    * [EdgeDB datatypes used in data descriptions](https://www.edgedb.com/docs/reference/protocol/index#conventions-and-data-types).
    * [EdgeDB data wire formats](https://www.edgedb.com/docs/reference/protocol/dataformats).
    * [Built-in EdgeDB codec implementations](https://github.com/nsidnev/edgedb-elixir/tree/master/lib/edgedb/protocol/codecs).
    * [Custom codecs implementations](https://github.com/nsidnev/edgedb-elixir/tree/master/test/edgedb/protocol/codecs/custom).
    * [Guide to developing custom codecs](pages/custom-codecs.md).
  """

  alias EdgeDB.Protocol.CodecStorage

  @typedoc """
  Codec ID.
  """
  @type id() :: bitstring()

  @doc """
  Function that can encode an entity to EdgeDB binary format.
  """
  @spec encode(t(), value, CodecStorage.t()) :: iodata() when value: term()
  def encode(codec, value, codec_storage)

  @doc """
  Function that can decode EdgeDB binary format into an entity.
  """
  @spec decode(t(), bitstring(), CodecStorage.t()) :: value when value: term()
  def decode(codec, data, codec_storage)
end
