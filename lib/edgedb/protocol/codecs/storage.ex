defmodule EdgeDB.Protocol.Codecs.Storage do
  use GenServer

  alias EdgeDB.Protocol.Codec

  @known_base_codecs [
    EdgeDB.Protocol.Codecs.UUID,
    EdgeDB.Protocol.Codecs.Str,
    EdgeDB.Protocol.Codecs.Bytes,
    EdgeDB.Protocol.Codecs.Int16,
    EdgeDB.Protocol.Codecs.Int32,
    EdgeDB.Protocol.Codecs.Int64,
    EdgeDB.Protocol.Codecs.Float32,
    EdgeDB.Protocol.Codecs.Float64,
    EdgeDB.Protocol.Codecs.Decimal,
    EdgeDB.Protocol.Codecs.Bool,
    EdgeDB.Protocol.Codecs.DateTime,
    EdgeDB.Protocol.Codecs.Duration,
    EdgeDB.Protocol.Codecs.LocalDateTime,
    EdgeDB.Protocol.Codecs.LocalDate,
    EdgeDB.Protocol.Codecs.LocalTime,
    EdgeDB.Protocol.Codecs.JSON,
    EdgeDB.Protocol.Codecs.BigInt,

    # 2 special cases
    EdgeDB.Protocol.Codecs.EmptyResult,
    EdgeDB.Protocol.Codecs.EmptyTuple
  ]

  defmodule State do
    defstruct [:storage]
  end

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  def get(storage, codec_id) when is_number(codec_id) do
    get(storage, EdgeDB.Protocol.DataTypes.UUID.from_integer(codec_id))
  end

  def get(storage, codec_id) do
    GenServer.call(storage, {:get, codec_id})
  end

  def get!(storage, codec_id) do
    case get(storage, codec_id) do
      nil ->
        raise RuntimeError, "no codec for #{codec_id}"

      codec ->
        codec
    end
  end

  def get_or_create(storage, codec_id, creation_fn) do
    case get(storage, codec_id) do
      nil ->
        codec = creation_fn.()
        register(storage, codec)
        codec

      codec ->
        codec
    end
  end

  def register(storage, %Codec{} = codec) do
    GenServer.cast(storage, {:register, codec})
  end

  def update(storage, codec_id, updates) do
    with {:ok, codec} <- get(storage, codec_id) do
      GenServer.cast(storage, {:update, codec, updates})
    end
  end

  def init(_opts \\ []) do
    storage = new_storage()
    register_base_scalar_codecs(storage)
    {:ok, %State{storage: storage}}
  end

  def handle_call({:get, codec_id}, _from, %State{storage: storage} = state) do
    codec =
      case :ets.lookup(storage, codec_id) do
        [{^codec_id, codec}] ->
          codec

        [] ->
          nil
      end

    {:reply, codec, state}
  end

  def handle_cast({:register, codec}, %State{storage: storage} = state) do
    register_codec(storage, codec)
    {:noreply, state}
  end

  def handle_cast({:update, codec, updates}, %State{storage: storage} = state) do
    register_codec(storage, Map.merge(codec, updates))
    {:noreply, state}
  end

  defp new_storage do
    :ets.new(:codecs_storage, [:set, :private])
  end

  defp register_codec(storage, %Codec{} = codec) do
    :ets.insert(storage, {codec.type_id, codec})
  end

  defp register_base_scalar_codecs(storage) do
    Enum.each(@known_base_codecs, fn codec_mod ->
      register_codec(storage, codec_mod.new())
    end)
  end
end
