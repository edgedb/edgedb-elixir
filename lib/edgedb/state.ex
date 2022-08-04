defmodule EdgeDB.State do
  @moduledoc """
  State is an execution context that affects the execution of EdgeQL commands in different ways:

    1. default module.
    2. module aliases.
    3. session config.
    4. global values.

  The most convenient way to use the `EdgeDB` API to change a part of state.
  See `EdgeDB.with_default_module/2`, `EdgeDB.with_module_aliases/2`/`EdgeDB.without_module_aliases/2`,
    `EdgeDB.with_config/2`/`EdgeDB.without_config/2`, `EdgeDB.with_globals/2`/`EdgeDB.without_globals/2`
    and `EdgeDB.with_state/2` for more information.
  """

  @default_module "default"

  defstruct module: @default_module,
            aliases: %{},
            config: %{},
            globals: %{}

  @typedoc """
  State is an execution context that affects the execution of EdgeQL commands.
  """
  @opaque t() :: %__MODULE__{
            module: String.t(),
            aliases: %{String.t() => String.t()},
            config: %{String.t() => term()},
            globals: %{String.t() => term()}
          }

  @doc """
  Returns an `EdgeDB.State` with adjusted default module.

  This is equivalent to using the `set module` command,
    or using the `reset module` command when giving `nil`.
  """
  @spec with_default_module(t(), String.t() | nil) :: t()
  def with_default_module(%__MODULE__{} = state, module \\ nil) do
    %__MODULE__{state | module: module}
  end

  @doc """
  Returns an `EdgeDB.State` with adjusted module aliases.

  This is equivalent to using the `set alias` command.
  """
  @spec with_module_aliases(t(), %{String.t() => String.t()}) :: t()
  def with_module_aliases(%__MODULE__{} = state, aliases \\ %{}) do
    %__MODULE__{state | aliases: Map.merge(state.aliases, aliases)}
  end

  @doc """
  Returns an `EdgeDB.State` without specified module aliases.

  This is equivalent to using the `reset alias` command.
  """
  @spec without_module_aliases(t(), list(String.t())) :: t()
  def without_module_aliases(%__MODULE__{} = state, aliases \\ []) do
    new_aliases =
      case aliases do
        [] ->
          %{}

        aliases ->
          Enum.reduce(aliases, state.aliases, &Map.delete(&2, &1))
      end

    %__MODULE__{state | aliases: new_aliases}
  end

  @doc """
  Returns an `EdgeDB.State` with adjusted session config.

  This is equivalent to using the `configure session set` command.
  """
  @spec with_config(t(), %{atom() => term()}) :: t()
  def with_config(%__MODULE__{} = state, config \\ %{}) do
    %__MODULE__{state | config: Map.merge(state.config, config)}
  end

  @doc """
  Returns an `EdgeDB.State` without specified session config.

  This is equivalent to using the `configure session reset` command.
  """
  @spec without_config(t(), list(atom())) :: t()
  def without_config(%__MODULE__{} = state, config_keys \\ []) do
    new_config =
      case config_keys do
        [] ->
          %{}

        config_keys ->
          Enum.reduce(config_keys, state.config, &Map.delete(&2, &1))
      end

    %__MODULE__{state | config: new_config}
  end

  @doc """
  Returns an `EdgeDB.State` with adjusted global values.

  This is equivalent to using the `set global` command.
  """
  @spec with_globals(t(), %{String.t() => String.t()}) :: t()
  def with_globals(%__MODULE__{} = state, globals \\ %{}) do
    module = state.module || @default_module

    globals =
      state.globals
      |> Map.merge(globals)
      |> Enum.into(%{}, fn {global, value} ->
        {resolve_name(state.aliases, module, global), value}
      end)

    %__MODULE__{state | globals: globals}
  end

  @doc """
  Returns an `EdgeDB.State` without specified globals.

  This is equivalent to using the `reset global` command.
  """
  @spec without_globals(t(), list(String.t())) :: t()
  def without_globals(%__MODULE__{} = state, global_names \\ []) do
    module = state.module || @default_module

    new_globals =
      case global_names do
        [] ->
          %{}

        global_names ->
          Enum.reduce(
            global_names,
            state.config,
            &Map.delete(&2, resolve_name(state.aliases, module, &1))
          )
      end

    %__MODULE__{state | globals: new_globals}
  end

  @doc false
  @spec to_encodable(t()) :: map()
  def to_encodable(%__MODULE__{} = state) do
    state
    |> Map.from_struct()
    |> stringify_map_keys()
    |> Enum.reduce(%{}, fn
      {"module", nil}, acc ->
        acc

      {"aliases", aliases}, acc when map_size(aliases) == 0 ->
        acc

      {"aliases", aliases}, acc ->
        Map.put(acc, "aliases", Map.to_list(aliases))

      {"config", config}, acc when map_size(config) == 0 ->
        acc

      {"globals", config}, acc when map_size(config) == 0 ->
        acc

      {key, value}, acc ->
        Map.put(acc, key, value)
    end)
  end

  defp resolve_name(aliases, module_name, global_name) do
    case String.split(global_name, "::") do
      [global_name] ->
        "#{module_name}::#{global_name}"

      [module_name, global_name] ->
        module_name = aliases[module_name] || module_name
        "#{module_name}::#{global_name}"

      _other ->
        raise EdgeDB.InvalidArgumentError.new("invalid global name: #{inspect(global_name)}")
    end
  end

  defp stringify_map_keys(%{} = map) when not is_struct(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_binary(key) ->
        {key, stringify_map_keys(value)}

      {key, value} when is_atom(key) ->
        {to_string(key), stringify_map_keys(value)}
    end)
  end

  defp stringify_map_keys(list) when is_list(list) do
    Enum.map(list, &stringify_map_keys/1)
  end

  defp stringify_map_keys(term) do
    term
  end
end
