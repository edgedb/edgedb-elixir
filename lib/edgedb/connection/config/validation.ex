defmodule EdgeDB.Connection.Config.Validation do
  @moduledoc false

  @type validation() :: :strict | :lenient

  @min_port 1
  @max_port 65_535

  @tls_security_options ~w(insecure no_host_verification strict default)a
  @security_options ~w(insecure_dev_mode strict default)a

  @tls_security_string_options Enum.map(@tls_security_options, &to_string/1)
  @security_string_options Enum.map(@security_options, &to_string/1)

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
          message: "invalid host: #{inspect(option)}"

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
      message: "invalid port: #{option}, must be between #{@min_port} and #{@max_port}"
  end

  def validate_port(option, :lenient) when is_integer(option) do
    option
  end

  def validate_port(option, :lenient) do
    raise RuntimeError,
      message: "invalid port: #{option}, not an integer"
  end

  @spec validate_tls_ca_file(term()) :: String.t() | nil

  def validate_tls_ca_file(nil) do
    nil
  end

  def validate_tls_ca_file(option) do
    option
  end

  @spec validate_tls_verify_hostname(term()) :: boolean() | nil

  def validate_tls_verify_hostname(nil) do
    nil
  end

  def validate_tls_verify_hostname(option) when is_boolean(option) do
    option
  end

  def validate_tls_verify_hostname(option) do
    raise RuntimeError,
      message: "invalid tls_verify_hostname: #{inspect(option)}, must be a boolean"
  end

  @spec validate_tls_security(term()) ::
          :insecure | :no_host_verification | :strict | :default | nil

  def validate_tls_security(nil) do
    nil
  end

  def validate_tls_security(option) when option in @tls_security_string_options do
    String.to_existing_atom(option)
  end

  def validate_tls_security(option) when option in @tls_security_options do
    option
  end

  def validate_tls_security(option) do
    raise RuntimeError,
      message:
        "invalid tls_security: #{option}, tls_security can only be one of `insecure`, `no_host_verification`, `strict` or `default`"
  end

  @spec validate_security(term()) :: :insecure_dev_mode | :strict | :default | nil

  def validate_security(nil) do
    nil
  end

  def validate_security(option) when option in @security_string_options do
    String.to_existing_atom(option)
  end

  def validate_security(option) when option in @security_options do
    option
  end

  def validate_security(option) do
    raise RuntimeError,
      message:
        "invalid security: #{option}, security can only be one of `insecure_dev_mode`, `strict` or `default`"
  end

  @spec validate_tls_verify_hostname_with_tls_security(atom(), atom()) :: :ok | no_return()

  def validate_tls_verify_hostname_with_tls_security(tls_verify_hostname, tls_security) do
    if (tls_security == :strict and tls_verify_hostname == false) or
         (tls_security in ~w(no_host_verification insecure)a and tls_verify_hostname == true) do
      raise RuntimeError,
        message:
          "tls_verify_hostname=#{tls_verify_hostname} and tls_security=#{tls_security} are incompatible"
    else
      :ok
    end
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

  @spec validate_server_settings(term()) :: map()

  def validate_server_settings(nil) do
    %{}
  end

  # wait_until_availble isn't an option that is supported by Elixir client
  def validate_server_settings(option) when is_map(option) do
    option
    |> Enum.into(%{}, fn
      {key, value} when is_atom(key) ->
        {to_string(key), value}

      {key, value} ->
        {key, value}
    end)
    |> Map.delete("wait_until_available")
  end

  def validate_server_settings(_option) do
    raise RuntimeError,
      message:
        "invalid server_settings: server_settings is expected to be a map of strings/atoms to strings"
  end

  @spec validate_dsn_authority(term()) :: {String.t() | nil, :inet.port_number() | nil} | nil

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

    validate_hostinfo(hostinfo)
  rescue
    e in RuntimeError ->
      reraise RuntimeError,
              [message: "invalid DSN or instance name: #{e.message}"],
              __STACKTRACE__
  end

  @spec validate_hostinfo(term()) :: {String.t() | nil, :inet.port_number() | nil}

  def validate_hostinfo(hostinfo) when is_binary(hostinfo) do
    if String.contains?(hostinfo, ",") do
      raise RuntimeError,
        message: "invalid host: multiple hosts are not allowed"
    end

    {host, port} = parse_hostinfo(hostinfo)

    host = validate_host(host)
    port = validate_port(port)

    {host, port}
  end

  def validate_hostinfo(_hostinfo) do
    raise RuntimeError,
      message: "invalid hostinfo: hostinfo should be a string"
  end

  defp parse_hostinfo(hostinfo) do
    [hostinfo] = String.split(hostinfo, "[", trim: true)

    case String.split(hostinfo, "]") do
      [host, port] ->
        case String.split(port, ":", trim: true) do
          [port] ->
            {host, port}

          [] ->
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
  end
end
