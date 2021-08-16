defmodule EdgeDB.Config do
  alias EdgeDB.Config.{
    Credentials,
    Platform
  }

  alias EdgeDB.Protocol.Error

  @type connect_options() :: list(EdgeDB.connect_option())

  # options priority:
  # 1. explicitly passed options
  # 2. options from config/#{env}.exs
  # 3. options parsed from passed DSN (either as explicitly passed or from config)
  # 4. options parsed from instance credentials file
  # 5. options parsed from environment variables
  # 6. default options
  @spec connect_opts(connect_options()) :: connect_options()
  def connect_opts(opts \\ []) do
    opts = clear_opts(opts)
    opts = Keyword.merge(opts_from_config(), opts)

    dsn = opts[:dsn] || from_config(:dsn)
    endpoints = opts[:endpoints]

    opts =
      cond do
        not is_nil(dsn) ->
          dsn
          |> opts_from_dsn()
          |> Keyword.merge(opts)

        endpoints ->
          opts

        true ->
          instance = instance_name()

          instance
          |> Credentials.read_creadentials()
          |> Keyword.merge(opts)
      end

    opts =
      opts
      |> maybe_add_default_opts()
      |> Keyword.merge(opts_from_env())
      |> Keyword.merge(opts)
      |> validate_required_opts()
      |> process_endpoints()

    if opts[:tls_ca_file] || opts[:tls_ca_data] do
      Keyword.put_new(opts, :tls_verify_hostname, false)
    else
      Keyword.put_new(opts, :tls_verify_hostname, true)
    end
  end

  defp process_endpoints(opts) do
    host = opts[:host]
    port = opts[:port]
    endpoints = [{host, port} | opts[:endpoints] || []]

    endpoints =
      endpoints
      |> Enum.map(fn
        "/" <> _socket_path = path ->
          {{:local, path}, 0}

        {"/" <> _socket_path = path, port} ->
          path =
            if String.contains?(path, ".s.EDGEDB.") do
              path
            else
              Path.join(path, ".s.EDGEDB.#{port}")
            end

          {{:local, path}, 0}

        {host, port} ->
          {to_charlist(host), port}
      end)
      |> Enum.uniq()

    Keyword.put(opts, :endpoints, endpoints)
  end

  defp validate_required_opts(opts) do
    if is_nil(opts[:user]) do
      raise Error.interface_error("could not determine user name to connect with")
    end

    if is_nil(opts[:database]) do
      raise Error.interface_error("could not determine database name to connect to")
    end

    opts
  end

  defp maybe_add_default_opts(opts) do
    opts =
      Keyword.merge(
        [
          user: "edgedb",
          database: "edgedb"
        ],
        opts
      )

    if opts[:endpoints] do
      opts
    else
      Keyword.merge(
        [
          host: "localhost",
          port: 5656
        ],
        opts
      )
    end
  end

  defp opts_from_config do
    clear_opts(
      host: from_config(:host),
      port: from_config(:port),
      endpoints: from_config(:endpoints),
      database: from_config(:database),
      user: from_config(:user),
      password: from_config(:password),
      tls_ca_file: from_config(:tls_ca_file),
      tls_verify_hostname: from_config(:tls_verify_hostname)
    )
  end

  defp opts_from_env do
    clear_opts(
      host: from_env("EDGEDB_HOST"),
      port: from_env("EDGEDB_PORT"),
      user: from_env("EDGEDB_USER"),
      password: from_env("EDGEDB_PASSWORD"),
      database: from_env("EDGEDB_DATABASE")
    )
  end

  defp opts_from_dsn(nil) do
    []
  end

  defp opts_from_dsn(dsn) when is_binary(dsn) do
    case URI.parse(dsn) do
      %URI{scheme: "edgedb"} = edgedb_dsn ->
        opts_from_dsn(edgedb_dsn)

      %URI{} = dsn ->
        raise RuntimeError, "invalid DSN: scheme expected to be `edgedb`, got: #{dsn.scheme}"
    end
  end

  defp opts_from_dsn(%URI{} = dsn) do
    query =
      if dsn.query do
        URI.decode_query(dsn.query)
      else
        %{}
      end

    []
    |> Keyword.put(:host, dsn.host || query["host"])
    |> Keyword.put(:port, dsn.port || query["port"])
    |> Keyword.put(:database, fn ->
      dsn_db =
        case dsn.path do
          "/" <> database ->
            database

          _other ->
            dsn.path
        end

      dsn_db || query["dbname"] || query["database"]
    end)
    |> Keyword.put(:user, fn ->
      user =
        with userinfo when is_binary(userinfo) <- dsn.userinfo,
             [user | _other] <- String.split(userinfo, ":", parts: 2) do
          user
        else
          _other ->
            nil
        end

      user || query["user"]
    end)
    |> Keyword.put(:password, fn ->
      password =
        with userinfo when is_binary(userinfo) <- dsn.userinfo,
             [_user | password] <- String.split(userinfo, ":", parts: 2) do
          password
        else
          _other ->
            nil
        end

      password || query["password"]
    end)
    |> Keyword.put(:tls_ca_file, query["tls_ca_file"])
    |> Keyword.put_new_lazy(
      :tls_verify_hostname,
      fn ->
        verify_hostname = query["tls_verify_hostname"]
        key_present? = Map.has_key?(query, "tls_verify_hostname")

        cond do
          key_present? and verify_hostname in ~w(1 yes true y t on) ->
            true

          key_present? and verify_hostname in ~w(0 no false n f off) ->
            false

          not key_present? ->
            nil

          true ->
            raise RuntimeError, "tls_verify_hostname can only be one of yes/no"
        end
      end
    )
    |> clear_opts()
  end

  defp instance_name do
    if instance = from_env("EDGEDB_INSTANCE") do
      instance
    else
      dir = File.cwd!()
      project_file = Path.join(dir, "edgedb.toml")

      if not File.exists?(project_file) do
        raise Error.client_connection_error(
                "no `edgedb.toml` found and no connection options specified"
              )
      end

      stash_dir = stash_dir(dir)

      if not File.exists?(stash_dir) do
        raise Error.client_connection_error(
                "Found `edgedb.toml` but the project is not initialized. Run `edgedb project init`."
              )
      end

      [stash_dir, "instance-name"]
      |> Path.join()
      |> File.read!()
      |> String.trim()
    end
  end

  defp stash_dir(path) do
    path = Path.expand(path)

    hash =
      :sha
      |> :crypto.hash(path)
      |> Base.encode16(case: :lower)

    base_name = Path.basename(path)
    dir_name = base_name <> "-" <> hash

    ["projects", dir_name]
    |> Platform.search_config_dir()
    |> Path.expand()
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
    System.get_env(name)
  end
end
