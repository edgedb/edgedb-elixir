defmodule EdgeDB.Protocol.CodecStorage do
  @moduledoc since: "0.2.0"
  @moduledoc """
  A storage for each codec that the connection knows how to decode.
  """

  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.{
    Codec,
    Codecs
  }

  @typedoc """
  A storage for each codec that the connection knows how to decode.
  """
  @type t() :: :ets.tab()

  @known_base_codecs [
    Codecs.UUID,
    Codecs.Str,
    Codecs.Bytes,
    Codecs.Int16,
    Codecs.Int32,
    Codecs.Int64,
    Codecs.Float32,
    Codecs.Float64,
    Codecs.Decimal,
    Codecs.Bool,
    Codecs.DateTime,
    Codecs.Duration,
    Codecs.LocalDateTime,
    Codecs.LocalDate,
    Codecs.LocalTime,
    Codecs.JSON,
    Codecs.BigInt,
    Codecs.RelativeDuration,
    Codecs.ConfigMemory,

    # special case
    Codecs.Null
  ]

  @doc false
  @spec new() :: t()
  def new do
    storage = :ets.new(:codec_storage, [:set, :public, {:read_concurrency, true}])
    register_base_scalar_codecs(storage)
    storage
  end

  @doc """
  Find a codec in the storage by ID.
  """
  @spec get(t(), binary()) :: Codec.t() | nil
  def get(storage, id) do
    case :ets.lookup(storage, id) do
      [{^id, codec}] ->
        codec

      [] ->
        nil
    end
  end

  @doc """
  Find a codec in the storage by type name.
  """
  @spec get_by_name(t(), binary()) :: Codec.t() | nil
  def get_by_name(storage, name) do
    # created with Ex2ms
    # fun do {idx, %{name: name}} = result when name == ^name -> result end

    match_spec = [{{:"$1", %{name: :"$2"}}, [{:==, :"$2", name}], [:"$_"]}]

    case :ets.select(storage, match_spec) do
      [{_id, %{name: ^name} = codec}] ->
        codec

      [] ->
        nil
    end
  end

  @doc false
  @spec add(t(), bitstring() | binary(), Codec.t()) :: :ok

  def add(storage, <<id::uuid>>, codec) do
    add_codec(storage, id, codec)
  end

  def add(storage, id, codec) do
    add_codec(storage, UUID.string_to_binary!(id), codec)
  end

  @doc false
  @spec update(t(), binary(), map()) :: :ok
  def update(storage, id, updates) do
    if codec = get(storage, id) do
      add_codec(storage, id, Map.merge(codec, updates))
    end

    :ok
  end

  defp add_codec(storage, id, codec) do
    :ets.insert(storage, {id, codec})
    :ok
  end

  defp register_base_scalar_codecs(storage) do
    Enum.each(@known_base_codecs, fn codec_mod ->
      add_codec(storage, codec_mod.id(), codec_mod.new())
    end)
  end
end
