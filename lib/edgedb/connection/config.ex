defmodule EdgeDB.Connection.Config do
  @moduledoc false

  alias EdgeDB.Connection.Config.{
    Credentials,
    DSN,
    Validation
  }

  @default_host "localhost"
  @default_port 5656
  @default_database "edgedb"
  @default_user "edgedb"
  @default_timeout 15_000

  @file_module Application.compile_env(:edgedb, :file_module, File)
  @path_module Application.compile_env(:edgedb, :path_module, Path)
  @system_module Application.compile_env(:edgedb, :system_module, System)

  @spec connect_opts(Keyword.t()) :: Keyword.t()
  def connect_opts(opts) do
    {dsn, instance_name} =
      with {:ok, dsn} <- Keyword.fetch(opts, :dsn),
           true <- Regex.match?(~r"(?i)^[a-z]+://", dsn) do
        {dsn, nil}
      else
        :error ->
          {nil, nil}

        false ->
          {nil, opts[:dsn]}
      end

    explicit_opts = Keyword.merge(opts, dsn: dsn, instance_name: instance_name)

    resolved_opts =
      with {:cont, resolved_opts} <- resolve_explicit_opts(explicit_opts),
           {:cont, resolved_opts} <- resolve_config_opts(resolved_opts),
           {:cont, resolved_opts} <- resolve_environment_opts(resolved_opts) do
        resolve_project_opts(resolved_opts)
      else
        {:halt, resolved_opts} ->
          resolved_opts
      end

    resolved_opts = transform_opts(resolved_opts)
    Keyword.merge(opts, resolved_opts)
  end

  defp transform_opts(opts) do
    tls_security = opts[:tls_security] || :default
    security = opts[:security] || :default

    tls_security =
      cond do
        security == :default and tls_security != :default ->
          tls_security

        security == :default and opts[:tls_ca] ->
          :no_host_verification

        security == :insecure_dev_mode and tls_security == :default ->
          :insecure

        security == :strict and tls_security == :default ->
          :strict

        security == :strict and
            (tls_security == :no_host_verification or tls_security == :insecure) ->
          raise RuntimeError,
            message:
              "EDGEDB_CLIENT_SECURITY=#{security} but tls_security=#{tls_security}, " <>
                "tls_security must be set to strict when EDGEDB_CLIENT_SECURITY is strict"

        true ->
          :strict
      end

    if opts[:tls_ca] && opts[:tls_ca_file] do
      raise EdgeDB.Error.client_connection_error("tls_ca and tls_ca_file are mutually exclusive")
    end

    opts
    |> Keyword.put_new_lazy(:address, fn ->
      {opts[:host] || @default_host, opts[:port] || @default_port}
    end)
    |> Keyword.update(:database, @default_database, fn database ->
      database || @default_database
    end)
    |> Keyword.update(:user, @default_user, fn user ->
      user || @default_user
    end)
    |> Keyword.put_new_lazy(:tls_ca, fn ->
      if tls_ca_file = opts[:tls_ca_file] do
        @file_module.read!(tls_ca_file)
      else
        nil
      end
    end)
    |> Keyword.put(:tls_security, tls_security)
    |> Keyword.put_new(:timeout, @default_timeout)
  end

  defp resolve_explicit_opts(opts) do
    case resolve_opts([], opts) do
      {resolved_opts, 0} ->
        {:cont, resolved_opts}

      {resolved_opts, 1} ->
        {:halt, resolved_opts}

      _other ->
        raise EdgeDB.Error.client_connection_error(
                "can not have more than one of the following connection options: " <>
                  ":dsn, :credentials, :credentials_file or :host/:port"
              )
    end
  end

  defp resolve_config_opts(resolved_opts) do
    case resolve_opts(resolved_opts, config_opts()) do
      {resolved_opts, 0} ->
        {:cont, resolved_opts}

      {resolved_opts, 1} ->
        {:halt, resolved_opts}

      _other ->
        raise EdgeDB.Error.client_connection_error(
                "can not have more than one of the following connection options in config: " <>
                  ":dsn, :credentials_file :host/:port"
              )
    end
  end

  defp resolve_environment_opts(resolved_opts) do
    case resolve_opts(resolved_opts, environment_opts()) do
      {resolved_opts, 0} ->
        {:cont, resolved_opts}

      {resolved_opts, 1} ->
        {:halt, resolved_opts}

      _other ->
        raise EdgeDB.Error.client_connection_error(
                "can not have more than one of the following connection environment variables:" <>
                  ~s("EDGEDB_DSN", "EDGEDB_INSTANCE", ) <>
                  ~s("EDGEDB_CREDENTIALS_FILE" or "EDGEDB_HOST"/"EDGEDB_PORT")
              )
    end
  end

  defp resolve_project_opts(resolved_opts) do
    project_dir = find_edgedb_project_dir()
    stash_dir = Credentials.stash_dir(project_dir)

    if not @file_module.exists?(stash_dir) do
      raise EdgeDB.Error.client_connection_error(
              ~s(found "edgedb.toml" but the project is not initialized, run "edgedb project init")
            )
    end

    instance_name =
      [stash_dir, "instance-name"]
      |> @path_module.join()
      |> @file_module.read!()
      |> String.trim()

    {resolved_opts, _compounds} = resolve_opts(resolved_opts, instance_name: instance_name)
    resolved_opts
  end

  defp resolve_opts(resolved_opts, opts) do
    resolved_opts =
      resolved_opts
      |> Keyword.put_new_lazy(:database, fn ->
        Validation.validate_database(opts[:database])
      end)
      |> Keyword.put_new_lazy(:user, fn ->
        Validation.validate_user(opts[:user])
      end)
      |> Keyword.put_new(:password, opts[:password])
      |> Keyword.put_new_lazy(:tls_ca_file, fn ->
        Validation.validate_tls_ca_file(opts[:tls_ca_file])
      end)
      |> Keyword.put_new_lazy(:tls_security, fn ->
        Validation.validate_tls_security(opts[:tls_security])
      end)
      |> Keyword.put_new_lazy(:server_settings, fn ->
        Validation.validate_server_settings(opts[:server_settings])
      end)
      |> Enum.reject(fn {_key, value} ->
        is_nil(value)
      end)

    compound_params_count =
      [
        opts[:dsn],
        opts[:instance_name],
        opts[:credentials],
        opts[:credentials_file],
        opts[:host] || opts[:port]
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.count()

    resolved_opts =
      cond do
        compound_params_count == 1 and not is_nil(opts[:dsn] || opts[:host] || opts[:port]) ->
          resolved_opts =
            if port = opts[:port] do
              Keyword.put_new_lazy(resolved_opts, :port, fn ->
                Validation.validate_port(port)
              end)
            else
              resolved_opts
            end

          dsn =
            if dsn = opts[:dsn] do
              dsn
            else
              host =
                if host = opts[:host] do
                  host =
                    if String.contains?(host, ":") do
                      "[#{host}]"
                    else
                      host
                    end

                  Validation.validate_host(host)
                else
                  ""
                end

              "edgedb://#{host}"
            end

          DSN.parse_dsn_into_opts(dsn, resolved_opts)

        compound_params_count == 1 ->
          credentials = parse_credentials(opts)
          Keyword.merge(credentials, resolved_opts)

        true ->
          resolved_opts
      end

    resolved_opts = Keyword.merge(opts, resolved_opts)
    {resolved_opts, compound_params_count}
  end

  defp parse_credentials(opts) do
    cond do
      credentials_file = opts[:credentials_file] ->
        Credentials.read_creadentials(credentials_file)

      credentials = opts[:credentials] ->
        Credentials.parse_credentials(credentials)

      true ->
        opts[:instance_name]
        |> Credentials.get_credentials_path()
        |> Credentials.read_creadentials()
    end
  end

  defp config_opts do
    clear_opts(
      dsn: from_config(:dsn),
      instance_name: from_config(:instance_name),
      credentials: from_config(:credentials),
      credentials_file: from_config(:credentials_file),
      host: from_config(:host),
      port: from_config(:port),
      database: from_config(:database),
      user: from_config(:user),
      password: from_config(:password),
      tls_ca: from_config(:tls_ca),
      tls_ca_file: from_config(:tls_ca_file),
      tls_security: from_config(:tls_security),
      timeout: from_config(:timeout),
      command_timeout: from_config(:command_timeout),
      wait_for_available: from_config(:wait_for_available),
      server_settings: from_config(:server_settings),
      tcp: from_config(:tcp),
      ssl: from_config(:ssl),
      transaction: from_config(:transaction),
      retry: from_config(:retry),
      connection: from_config(:connection),
      pool: from_config(:pool)
    )
  end

  defp environment_opts do
    port =
      case from_env("EDGEDB_PORT") do
        "tcp" <> _term ->
          nil

        env_var ->
          env_var
      end

    security =
      "EDGEDB_CLIENT_SECURITY"
      |> from_env()
      |> Validation.validate_security()

    clear_opts(
      dsn: from_env("EDGEDB_DSN"),
      instance_name: from_env("EDGEDB_INSTANCE"),
      credentials_file: from_env("EDGEDB_CREDENTIALS_FILE"),
      host: from_env("EDGEDB_HOST"),
      port: port,
      database: from_env("EDGEDB_DATABASE"),
      user: from_env("EDGEDB_USER"),
      password: from_env("EDGEDB_PASSWORD"),
      tls_ca: from_env("EDGEDB_TLS_CA"),
      tls_ca_file: from_env("EDGEDB_TLS_CA_FILE"),
      tls_security: from_env("EDGEDB_CLIENT_TLS_SECURITY"),
      security: security
    )
  end

  defp clear_opts(opts) do
    Enum.reduce(opts, [], fn
      {_key, nil}, opts ->
        opts

      {key, value}, opts ->
        Keyword.put(opts, key, value)
    end)
  end

  defp from_config(name) do
    Application.get_env(:edgedb, name)
  end

  defp from_env(name) do
    @system_module.get_env(name)
  end

  defp find_edgedb_project_dir do
    dir = @file_module.cwd!()
    find_edgedb_project_dir(dir)
  end

  defp find_edgedb_project_dir(dir) do
    dev = @file_module.stat!(dir).major_device
    project_file = @path_module.join(dir, "edgedb.toml")

    if @file_module.exists?(project_file) do
      dir
    else
      parent = @path_module.dirname(dir)

      if parent == dir do
        raise EdgeDB.Error.client_connection_error(
                ~s(no "edgedb.toml" found and no connection options specified)
              )
      end

      parent_dev = @file_module.stat!(parent).major_device

      if parent_dev != dev do
        raise EdgeDB.Error.client_connection_error(
                ~s(no "edgedb.toml" found and no connection options specified) <>
                  ~s(stopped searching for "edgedb.toml" at file system boundary #{inspect(dir)})
              )
      end

      find_edgedb_project_dir(parent)
    end
  end
end
