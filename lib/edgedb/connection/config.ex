defmodule EdgeDB.Connection.Config do
  alias EdgeDB.Protocol.Error

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

  @type connect_options() :: list(EdgeDB.connect_option())

  @spec connect_opts(connect_options()) :: connect_options()
  def connect_opts(opts) do
    # TODO: check if we can't parse URI and match it by scheme
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
    |> Keyword.put_new_lazy(:tls_ca_data, fn ->
      if tls_ca_file = opts[:tls_ca_file] do
        @file_module.read!(tls_ca_file)
      else
        nil
      end
    end)
    |> Keyword.update(:tls_verify_hostname, is_nil(opts[:tls_ca_data]), fn tls_verify_hostname ->
      if is_nil(tls_verify_hostname) do
        is_nil(opts[:tls_ca_data])
      else
        tls_verify_hostname
      end
    end)
    |> Keyword.put_new(:timeout, @default_timeout)
  end

  defp resolve_explicit_opts(opts) do
    case resolve_opts([], opts) do
      {resolved_opts, 0} ->
        {:cont, resolved_opts}

      {resolved_opts, 1} ->
        {:halt, resolved_opts}

      _other ->
        raise Error.client_connection_error(
                "can not have more than one of the following connection options: " <>
                  ":dsn, :credentials_file or :host/:port"
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
        raise Error.client_connection_error(
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
        raise Error.client_connection_error(
                "can not have more than one of the following connection environment variables:" <>
                  ~s("EDGEDB_DSN", "EDGEDB_INSTANCE", ) <>
                  ~s("EDGEDB_CREDENTIALS_FILE" or "EDGEDB_HOST"/"EDGEDB_PORT")
              )
    end
  end

  defp resolve_project_opts(resolved_opts) do
    dir = @file_module.cwd!()
    project_file = @path_module.join(dir, "edgedb.toml")

    if not @file_module.exists?(project_file) do
      raise Error.client_connection_error(
              ~s(no "edgedb.toml" found and no connection options specified)
            )
    end

    stash_dir = Credentials.stash_dir(dir)

    if not @file_module.exists?(stash_dir) do
      raise Error.client_connection_error(
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
      |> Keyword.put_new_lazy(:tls_verify_hostname, fn ->
        Validation.validate_tls_verify_hostname(opts[:tls_verify_hostname])
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
                  Validation.validate_host(host)
                else
                  ""
                end

              "edgedb://#{host}"
            end

          DSN.parse_dsn_into_opts(dsn, resolved_opts)

        compound_params_count == 1 ->
          credentials_file =
            opts[:credentials_file] || Credentials.get_credentials_path(opts[:instance_name])

          credentials = Credentials.read_creadentials(credentials_file)
          Keyword.merge(credentials, resolved_opts)

        true ->
          resolved_opts
      end

    resolved_opts = Keyword.merge(opts, resolved_opts)
    {resolved_opts, compound_params_count}
  end

  defp config_opts do
    clear_opts(
      dsn: from_config(:dsn),
      instance_name: from_config(:instance_name),
      credentials_file: from_config(:credentials_file),
      host: from_config(:host),
      port: from_config(:port),
      database: from_config(:database),
      user: from_config(:user),
      password: from_config(:password),
      tls_ca_file: from_config(:tls_ca_file),
      tls_verify_hostname: from_config(:tls_verify_hostname),
      server_settings: from_config(:server_settings)
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

    clear_opts(
      dsn: from_env("EDGEDB_DSN"),
      instance_name: from_env("EDGEDB_INSTANCE"),
      credentials_file: from_env("EDGEDB_CREDENTIALS_FILE"),
      host: from_env("EDGEDB_HOST"),
      port: port,
      database: from_env("EDGEDB_DATABASE"),
      user: from_env("EDGEDB_USER"),
      password: from_env("EDGEDB_PASSWORD"),
      tls_ca_file: from_env("EDGEDB_TLS_CA_FILE"),
      tls_verify_hostname: from_env("EDGEDB_TLS_VERIFY_HOSTNAME")
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
end
