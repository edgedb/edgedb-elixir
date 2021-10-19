defmodule EdgeDB.Connection.Config.Credentials do
  alias EdgeDB.Connection.Config.{
    Platform,
    Validation
  }

  @instance_name_regex ~r/^[A-Za-z_][A-Za-z_0-9]*$/

  @file_module Application.compile_env(:edgedb, :file_module, File)
  @path_module Application.compile_env(:edgedb, :path_module, Path)

  @spec get_credentials_path(String.t()) :: String.t()
  def get_credentials_path(instance_name) do
    if not Regex.match?(@instance_name_regex, instance_name) do
      raise RuntimeError,
        message: "invalid instance name: #{inspect(instance_name)}"
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
    |> Enum.into([], fn
      {"host", value} ->
        {:host, Validation.validate_host(value)}

      {"port", value} ->
        {:port, Validation.validate_port(value, :strict)}

      {"database", value} ->
        {:database, Validation.validate_database(value)}

      {"user", value} ->
        {:user, Validation.validate_user(value)}

      {"password", value} ->
        {:password, value}

      {"tls_cert_data", value} ->
        {:tls_ca_data, value}

      {"tls_verify_hostname", value} ->
        {:tls_verify_hostname, Validation.validate_tls_verify_hostname(value, :strict)}

      {key, _value} ->
        {key, :skip}
    end)
    |> Enum.reject(fn {_key, value} ->
      value == :skip
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

    credentials
  end
end
