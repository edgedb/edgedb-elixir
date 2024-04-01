defmodule EdgeDB.Connection.Config.DSN do
  @moduledoc false

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
           path: uri_database,
           query: query
         } = dsn,
         opts
       ) do
    %URI{host: host, port: port} = maybe_handle_ipv6_zone(dsn)

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
        parse_query(query)
      else
        %{}
      end

    uri_database =
      if uri_database do
        String.replace_prefix(uri_database, "/", "")
      else
        uri_database
      end

    {database_or_branch_key, {database_or_branch, query}} =
      handle_dsn_database_or_branch(opts, uri_database, query)

    database_or_branch =
      if database_or_branch do
        String.replace_prefix(database_or_branch, "/", "")
      else
        database_or_branch
      end

    {host, query} = handle_dsn_part(:host, opts[:host], host, query)
    {port, query} = handle_dsn_part(:port, opts[:port], port, query)

    {user, query} = handle_dsn_part(:user, opts[:user], user, query)
    {password, query} = handle_dsn_part(:password, opts[:password], password, query)
    {secret_key, query} = handle_dsn_part(:secret_key, opts[:secret_key], nil, query)
    {tls_ca_file, query} = handle_dsn_part(:tls_ca_file, opts[:tls_ca_file], nil, query)

    {tls_security, query} = handle_dsn_part(:tls_security, opts[:tls_security], nil, query)

    {tls_server_name, query} =
      handle_dsn_part(:tls_server_name, opts[:tls_server_name], nil, query)

    server_settings = Validation.validate_server_settings(query)

    database_or_branch =
      case database_or_branch_key do
        :branch ->
          Validation.validate_branch(database_or_branch)

        :database ->
          Validation.validate_database(database_or_branch)
      end

    opts
    |> Keyword.put(database_or_branch_key, database_or_branch)
    |> Keyword.merge(
      host: Validation.validate_host(host),
      port: Validation.validate_port(port),
      user: Validation.validate_user(user),
      password: password,
      secret_key: secret_key,
      tls_ca_file: Validation.validate_tls_ca_file(tls_ca_file),
      tls_security: Validation.validate_tls_security(tls_security),
      tls_server_name: Validation.validate_tls_server_name(tls_server_name),
      server_settings: Map.merge(server_settings, opts[:server_settings])
    )
  end

  defp parse(%URI{} = dsn, _opts) do
    raise RuntimeError,
      message:
        ~s(invalid DSN or instance name: scheme is expected to be "edgedb", got #{inspect(dsn.scheme)})
  end

  # URI module doesn't handle this, so should do that manually

  defp maybe_handle_ipv6_zone(%URI{authority: nil} = dsn) do
    dsn
  end

  defp maybe_handle_ipv6_zone(%URI{} = dsn) do
    authority =
      try do
        URI.decode_www_form(dsn.authority)
      rescue
        ArgumentError ->
          dsn.authority
      end

    {host, port} = Validation.validate_dsn_authority(authority)

    host =
      case String.split(host, "%") do
        [host, zone] ->
          zone = URI.decode_www_form(zone)
          "#{String.downcase(host)}%#{zone}"

        [host] ->
          host
      end

    %URI{dsn | host: host, port: port}
  end

  defp handle_dsn_database_or_branch(opts, uri_database, query) do
    defines_branch? =
      Enum.any?([query["branch"], query["branch_env"], query["branch_file"]], &(not is_nil(&1)))

    defines_database? =
      Enum.any?(
        [query["database"], query["database_env"], query["database_file"]],
        &(not is_nil(&1))
      )

    cond do
      defines_branch? and defines_database? ->
        raise RuntimeError,
          message:
            ~s(invalid DSN or instance name: "database" and "branch" parameters in DSN can not be present at the same time)

      defines_branch? and is_nil(opts[:database]) ->
        {:branch, handle_dsn_part(:branch, opts[:branch], uri_database, query)}

      defines_branch? and not is_nil(opts[:database]) ->
        {:database, {opts[:database], Map.drop(query, ["branch", "branch_env", "branch_file"])}}

      is_nil(opts[:branch]) ->
        {:database, handle_dsn_part(:database, opts[:database], uri_database, query)}

      true ->
        {:branch, {opts[:branch], Map.drop(query, ["database", "database_env", "database_file"])}}
    end
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
            @system_module.get_env(option_value) ||
              raise RuntimeError,
                message:
                  "invalid DSN or instance name: " <>
                    "#{option}_env environment variable #{inspect(option_value)} doesn't exist"

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

  defp parse_query(query) do
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
  end
end
