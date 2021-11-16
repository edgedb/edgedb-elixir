defmodule EdgeDB.Connection.Config.Credentials do
  alias EdgeDB.Connection.Config.{
    Platform,
    Validation
  }

  @instance_name_regex ~r/^[A-Za-z_][A-Za-z_0-9]*$/

  @path_module Application.compile_env(:edgedb, :path_module, Path)
  @file_module Application.compile_env(:edgedb, :file_module, File)

  @spec get_credentials_path(String.t()) :: String.t()
  def get_credentials_path(instance_name) do
    if not Regex.match?(@instance_name_regex, instance_name) do
      raise RuntimeError,
        message:
          "invalid DSN or instance name: " <>
            "#{inspect(instance_name)} doesn't match valid instance regex"
    end

    ["credentials", "#{instance_name}.json"]
    |> Platform.search_config_dir()
    |> @path_module.expand()
  end

  @spec read_creadentials(String.t()) :: Keyword.t()
  def read_creadentials(credentials_path) do
    credentials_path
    |> @file_module.read!()
    |> Jason.decode!()
    |> Enum.reduce([], fn
      {"host", value}, opts ->
        Keyword.put(opts, :host, Validation.validate_host(value))

      {"port", value}, opts ->
        Keyword.put(opts, :port, Validation.validate_port(value, :strict))

      {"database", value}, opts ->
        Keyword.put(opts, :database, Validation.validate_database(value))

      {"user", value}, opts ->
        Keyword.put(opts, :user, Validation.validate_user(value))

      {"password", value}, opts ->
        Keyword.put(opts, :password, value)

      {"tls_cert_data", value}, opts ->
        Keyword.put(opts, :tls_ca_data, value)

      {"tls_verify_hostname", value}, opts ->
        verify = Validation.validate_tls_verify_hostname(value)

        security =
          if verify do
            :strict
          else
            :no_host_verification
          end

        opts
        |> Keyword.put(:tls_verify_hostname, verify)
        |> Keyword.put_new(:tls_security, security)

      {"tls_security", value}, opts ->
        security = Validation.validate_tls_security(value)
        Keyword.put(opts, :tls_security, security)

      _param, opts ->
        opts
    end)
    |> validate_credentials()
  rescue
    e ->
      reraise RuntimeError,
              [message: "invalid credentials: #{Exception.message(e)}"],
              __STACKTRACE__
  end

  @spec stash_dir(Path.t()) :: String.t()
  def stash_dir(path) do
    path = @path_module.expand(path)

    hash =
      :sha
      |> :crypto.hash(path)
      |> Base.encode16(case: :lower)

    base_name = @path_module.basename(path)
    dir_name = base_name <> "-" <> hash

    ["projects", dir_name]
    |> Platform.search_config_dir()
    |> @path_module.expand()
  end

  defp validate_credentials(credentials) do
    if is_nil(credentials[:user]) do
      raise RuntimeError,
        message: ~s("user" key is required)
    end

    Validation.validate_tls_verify_hostname_with_tls_security(
      credentials[:tls_verify_hostname],
      credentials[:tls_security]
    )

    credentials
  end
end
