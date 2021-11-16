defmodule EdgeDB.Connection.Config.DSN do
  alias EdgeDB.Connection.Config.Validation

  @file_module Application.compile_env(:edgedb, :file_module, File)
  @system_module Application.compile_env(:edgedb, :system_module, System)

  @spec parse_dsn_into_opts(String.t() | URI.t(), Keyword.t()) :: Keyword.t()
  def parse_dsn_into_opts(dsn, opts) do
    parse(dsn, opts)
  end

  defp parse(dsn, opts) when is_binary(dsn) do
    dsn
    |> URI.parse()
    |> parse(opts)
  end

  defp parse(%URI{host: ""} = dsn, opts) do
    parse(%URI{dsn | host: nil}, opts)
  end

  defp parse(%URI{authority: ""} = dsn, opts) do
    parse(%URI{dsn | authority: nil}, opts)
  end

  defp parse(%URI{path: ""} = dsn, opts) do
    parse(%URI{dsn | path: nil}, opts)
  end

  defp parse(%URI{path: "/"} = dsn, opts) do
    parse(%URI{dsn | path: nil}, opts)
  end

  defp parse(
         %URI{
           scheme: "edgedb",
           host: host,
           port: port,
           path: database,
           query: query
         } = dsn,
         opts
       ) do
    Validation.validate_dsn_authority(dsn.authority)

    {user, password} =
      with userinfo when is_binary(userinfo) <- dsn.userinfo,
           [user, password] <- String.split(userinfo, ":", parts: 2) do
        {user, password}
      else
        [user] ->
          {user, nil}

        _other ->
          {nil, nil}
      end

    query =
      if query do
        query
        |> URI.query_decoder()
        |> Enum.reduce(%{}, fn {key, value}, acc ->
          if acc[key] do
            raise RuntimeError,
              message: "invalid DSN or instance name: duplicate query parameter #{inspect(key)}"
          else
            Map.put(acc, key, value)
          end
        end)
      else
        %{}
      end

    database =
      if database do
        String.replace_prefix(database, "/", "")
      else
        database
      end

    {database, query} = handle_dsn_part(:database, opts[:database], database, query)

    database =
      if database do
        String.replace_prefix(database, "/", "")
      else
        database
      end

    {host, query} = handle_dsn_part(:host, opts[:host], host, query)
    {port, query} = handle_dsn_part(:port, opts[:port], port, query)

    {user, query} = handle_dsn_part(:user, opts[:user], user, query)
    {password, query} = handle_dsn_part(:password, opts[:password], password, query)
    {tls_ca_file, query} = handle_dsn_part(:tls_cert_file, opts[:tls_ca_file], nil, query)

    {tls_security, query} = handle_dsn_part(:tls_security, opts[:tls_security], nil, query)

    server_settings = Validation.validate_server_settings(query)

    Keyword.merge(opts,
      host: Validation.validate_host(host),
      port: Validation.validate_port(port),
      database: Validation.validate_database(database),
      user: Validation.validate_user(user),
      password: password,
      tls_ca_file: Validation.validate_tls_ca_file(tls_ca_file),
      tls_security: Validation.validate_tls_security(tls_security),
      server_settings: Map.merge(server_settings, opts[:server_settings])
    )
  end

  defp parse(%URI{} = dsn, _opts) do
    raise RuntimeError,
      message:
        ~s(invalid DSN or instance name: scheme is expected to be "edgedb", got #{inspect(dsn.scheme)})
  end

  defp handle_dsn_part(option, value, uri_value, query) when is_atom(option) do
    option
    |> Atom.to_string()
    |> handle_dsn_part(value, uri_value, query)
  end

  defp handle_dsn_part(option, value, uri_value, query) do
    option_values =
      Enum.reject(
        [
          {:dsn, uri_value},
          {:query, query[option]},
          {:env, query["#{option}_env"]},
          {:file, query["#{option}_file"]}
        ],
        fn {_source, value} ->
          is_nil(value)
        end
      )

    {source, option_value} =
      case option_values do
        [] ->
          {nil, nil}

        [{source, value}] ->
          {source, value}

        _other ->
          message = "invalid DSN or instance name: more than one of "

          message =
            if value do
              "#{message} #{option},"
            else
              message
            end

          message = "#{message}?#{option}=, ?#{option}_env=, ?#{option}_file= was specified"

          raise RuntimeError, message: message
      end

    value =
      if is_nil(value) do
        case source do
          :dsn ->
            option_value

          :query ->
            option_value

          :env ->
            env_value = @system_module.get_env(option_value)

            if is_nil(env_value) do
              raise RuntimeError,
                message:
                  "invalid DSN or instance name: " <>
                    "#{option}_env environment variable #{inspect(option_value)} doesn't exist"
            else
              env_value
            end

          :file ->
            @file_module.read!(option_value)

          nil ->
            nil
        end
      else
        value
      end

    query = Map.drop(query, [option, "#{option}_env", "#{option}_file"])
    {value, query}
  end
end
