defmodule EdgeDB.Protocol.Codecs.Storage do
  use GenServer

  alias EdgeDB.Protocol.{
    Codec,
    Codecs,
    Datatypes
  }

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

    # 2 special cases
    Codecs.EmptyResult,
    Codecs.EmptyTuple
  ]

  defmodule State do
    defstruct [:storage]

    @type t() :: %__MODULE__{
            storage: :ets.tab()
          }
  end

  @type t() :: GenServer.server()

  @spec start_link(list()) :: GenServer.on_start()
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  @spec get(t(), Datatypes.UUID.t()) :: Codec.t() | nil
  def get(storage, codec_id) do
    GenServer.call(storage, {:get, codec_id})
  end

  @spec get!(t(), Datatypes.UUID.t()) :: Codec.t()
  def get!(storage, codec_id) do
    case get(storage, codec_id) do
      nil ->
        raise RuntimeError, "no codec for #{Datatypes.UUID.to_string(codec_id)}"

      codec ->
        codec
    end
  end

  @spec get_or_create(t(), Datatypes.UUID.t(), (() -> Codec.t())) :: Codec.t()
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

  @spec register(t(), Codec.t()) :: :ok
  def register(storage, %Codec{} = codec) do
    GenServer.cast(storage, {:register, codec})
  end

  @spec update(t(), Datatypes.UUID.t(), map()) :: :ok
  def update(storage, codec_id, updates) do
    if codec = get(storage, codec_id) do
      GenServer.cast(storage, {:update, codec, updates})
    end

    :ok
  end

  @impl GenServer
  def init(_opts \\ []) do
    storage = new_storage()
    register_base_scalar_codecs(storage)
    {:ok, %State{storage: storage}}
  end

  @impl GenServer
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

  @impl GenServer
  def handle_cast({:register, codec}, %State{storage: storage} = state) do
    register_codec(storage, codec)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:update, codec, updates}, %State{storage: storage} = state) do
    register_codec(storage, Map.merge(codec, updates))
    {:noreply, state}
  end

  defp new_storage do
    :ets.new(:codecs_storage, [:set, :private])
  end

  defp register_codec(storage, %Codec{} = codec) do
    :ets.insert(storage, {codec.type_id, codec})
    :ok
  end

  defp register_base_scalar_codecs(storage) do
    Enum.each(@known_base_codecs, fn codec_mod ->
      register_codec(storage, codec_mod.new())
    end)
  end
end
