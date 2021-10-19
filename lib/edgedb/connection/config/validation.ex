defmodule EdgeDB.Connection.Config.Validation do
  @type validation() :: :strict | :lenient

  @min_port 1
  @max_port 65_535

  @spec validate_database(term()) :: String.t() | nil

  def validate_database(option) do
    if option == "" do
      raise RuntimeError,
        message: "invalid database: database name couldn't be an empty string"
    end

    option
  end

  @spec validate_user(term()) :: String.t() | nil

  def validate_user(nil) do
    nil
  end

  def validate_user(option) when is_binary(option) do
    if option == "" do
      raise RuntimeError,
        message: "invalid user: user couldn't be an empty string"
    end

    option
  end

  def validate_user(_option) do
    raise RuntimeError,
      message: "invalid user: user should be a string"
  end

  @spec validate_host(term()) :: String.t() | nil

  def validate_host(option) do
    cond do
      is_nil(option) ->
        nil

      String.contains?(option, "/") ->
        raise RuntimeError,
          message: "invalid host: unix socket paths not supported"

      option == "" || String.contains?(option, ",") ->
        raise RuntimeError,
          message: ~s(invalid host: #{inspect(option)})

      true ->
        option
    end
  end

  @spec validate_port(term(), validation()) :: :inet.port_number()

  def validate_port(option, validation \\ :lenient)

  def validate_port(nil, _validation) do
    nil
  end

  def validate_port(option, :strict) when is_binary(option) do
    raise RuntimeError,
      message: "invalid port: #{inspect(option)}, not an integer"
  end

  def validate_port(option, :strict) do
    validate_port(option)
  end

  def validate_port(option, :lenient) when is_binary(option) do
    case Integer.parse(option) do
      {port, ""} ->
        validate_port(port)

      _other ->
        raise RuntimeError,
          message: "invalid port: #{inspect(option)}, not an integer"
    end
  end

  def validate_port(option, :lenient) when option < @min_port or option > @max_port do
    raise RuntimeError,
      message: "invalid port: #{inspect(option)}, must be between #{@min_port} and #{@max_port}"
  end

  def validate_port(option, :lenient) when is_integer(option) do
    option
  end

  def validate_port(option, :lenient) do
    raise RuntimeError,
      message: "invalid port: #{inspect(option)}, not an integer"
  end

  @spec validate_tls_ca_file(term()) :: String.t() | nil

  def validate_tls_ca_file(nil) do
    nil
  end

  def validate_tls_ca_file(option) do
    option
  end

  @spec validate_tls_verify_hostname(term(), validation()) :: boolean() | nil
  def validate_tls_verify_hostname(option, validation \\ :lenient) do
    validate_boolean("tls_verify_hostname", option, validation)
  end

  @spec validate_insecure_dev_mode(term(), validation()) :: boolean() | nil
  def validate_insecure_dev_mode(option, validation \\ :lenient) do
    validate_boolean("insecure_dev_mode", option, validation)
  end

  @spec validate_boolean(String.t(), term(), validation()) :: boolean() | nil

  def validate_boolean(key, value, validation \\ :lenient)

  def validate_boolean(_key, nil, _validation) do
    nil
  end

  def validate_boolean(_key, value, _validation) when is_boolean(value) do
    value
  end

  def validate_boolean(key, value, :strict) when is_binary(value) do
    raise RuntimeError,
      message: "invalid #{key}: #{key} must be a boolean"
  end

  def validate_boolean(key, value, :lenient) when is_binary(value) do
    cond do
      value in ~w(1 yes true y t on) ->
        true

      value in ~w(0 no false n f off) ->
        false

      true ->
        raise RuntimeError,
          message: "invalid #{key}: #{key} can only be one of yes/no"
    end
  end

  @spec validate_server_settings(term()) :: map()

  def validate_server_settings(nil) do
    %{}
  end

  def validate_server_settings(option) when is_map(option) do
    Enum.into(option, %{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} ->
        {key, value}
    end)
  end

  def validate_server_settings(_option) do
    raise RuntimeError,
      message:
        "invalid server_settings: server_settings is expected to be a map of strings/atoms to strings"
  end

  @spec validate_dsn_authority(term()) :: String.t()

  def validate_dsn_authority(nil) do
    nil
  end

  def validate_dsn_authority(authority) do
    hostinfo =
      case String.split(authority, "@", parts: 2) do
        [_userinfo, hostinfo] ->
          hostinfo

        [hostinfo] ->
          hostinfo
      end

    if String.contains?(hostinfo, ",") do
      raise RuntimeError,
        message: "invalid host: multiple hosts are not allowed"
    end

    {host, port} =
      case String.split(hostinfo, "[") do
        [_prev, hostinfo] ->
          case String.split(hostinfo, "]") do
            [host, port] ->
              ["", port] = String.split(port, ":")
              {host, port}

            [host] ->
              {host, nil}
          end

        [hostinfo] ->
          case String.split(hostinfo, ":") do
            [host, port] ->
              {host, port}

            [host] ->
              {host, nil}
          end
      end

    validate_host(host)
    validate_port(port)

    authority
  rescue
    e in RuntimeError ->
      reraise RuntimeError,
              [message: "invalid DSN: #{e.message}"],
              __STACKTRACE__
  end
end
