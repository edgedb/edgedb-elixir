defmodule EdgeDB.Config.Credentials do
  alias EdgeDB.Config.Platform

  @min_port 1
  @max_port 65_635

  @spec read_creadentials(String.t()) :: Keyword.t()
  def read_creadentials(instance_name) do
    credentials_path =
      ["credentials", "#{instance_name}.json"]
      |> Platform.search_config_dir()
      |> Path.expand()

    credentials_path
    |> File.read!()
    |> Jason.decode!()
    |> validate_credentials()
  end

  defp validate_credentials(credentials) do
    credentials_opts =
      Enum.reduce(credentials, [], fn
        {"port", port}, opts ->
          if not is_number(port) or port < @min_port or port > @max_port do
            raise RuntimeError, "invalid `port` value"
          end

          Keyword.put(opts, :port, port)

        {"user", user}, opts ->
          if not is_binary(user) do
            raise RuntimeError, "`user` must be a string"
          end

          Keyword.put(opts, :user, user)

        {"host", host}, opts ->
          if not is_binary(host) do
            raise RuntimeError, "`host` must be a string"
          end

          Keyword.put(opts, :host, host)

        {"database", database}, opts ->
          if not is_binary(database) do
            raise RuntimeError, "`database` must be a string"
          end

          Keyword.put(opts, :database, database)

        {"password", password}, opts ->
          if not is_binary(password) do
            raise RuntimeError, "`password` must be a string"
          end

          Keyword.put(opts, :password, password)

        {"tls_cert_data", tls_cert_data}, opts ->
          if not is_binary(tls_cert_data) do
            raise RuntimeError, "`tls_cert_data` must be a string"
          end

          Keyword.put(opts, :tls_ca_data, tls_cert_data)

        {"tls_verify_hostname", tls_verify_hostname}, opts ->
          if not is_boolean(tls_verify_hostname) do
            raise RuntimeError, "`tls_verify_hostname` must be a boolean"
          end

          Keyword.put(opts, :tls_verify_hostname, tls_verify_hostname)
      end)

    if is_nil(credentials_opts[:user]) do
      raise RuntimeError, "`user` key is required"
    end

    credentials_opts
  end
end
