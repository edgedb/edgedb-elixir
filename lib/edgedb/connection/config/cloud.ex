defmodule EdgeDB.Connection.Config.Cloud do
  @moduledoc false

  alias EdgeDB.Connection.Config.Platform

  @max_domain_label_length 63
  @dns_buckets 100
  @default_cloud_profile "default"

  @path_module Application.compile_env(:edgedb, :path_module, Path)
  @file_module Application.compile_env(:edgedb, :file_module, File)
  @json_library Application.compile_env(:edgedb, :json, Jason)

  @spec parse_cloud_credentials(
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil
        ) :: Keyword.t()
  def parse_cloud_credentials(org_slug, instance_name, secret_key, cloud_profile) do
    label = "#{instance_name}--#{org_slug}"

    if String.length(label) > @max_domain_label_length do
      raise RuntimeError,
            "invalid instance name: " <>
              "cloud instance name length cannot exceed #{@max_domain_label_length - 1} characters: " <>
              "#{org_slug}/#{label}"
    end

    secret_key =
      if is_nil(secret_key) do
        read_secret_key(cloud_profile)
      else
        secret_key
      end

    dns_zone = read_dsn_zone_from_secret_key(secret_key)
    dns_bucket = rem(CRC.ccitt_16_xmodem("#{org_slug}/#{instance_name}"), @dns_buckets)
    bucket_repr = String.pad_leading(to_string(dns_bucket), 2, "0")
    host = "#{label}.c-#{bucket_repr}.i.#{dns_zone}"

    [
      host: host,
      secret_key: secret_key
    ]
  end

  defp read_secret_key(cloud_profile) do
    cloud_profile = cloud_profile || @default_cloud_profile
    config_dir = Platform.config_dir()
    path = @path_module.join([config_dir, "cloud-credentials", "#{cloud_profile}.json"])

    path
    |> @file_module.read!()
    |> @json_library.decode!()
    |> Map.fetch!("secret_key")
  rescue
    File.Error ->
      reraise EdgeDB.ClientConnectionError.new("can not determine secret key for cloud instance"),
              __STACKTRACE__

    KeyError ->
      reraise EdgeDB.ClientConnectionError.new("can not determine secret key for cloud instance"),
              __STACKTRACE__
  end

  defp read_dsn_zone_from_secret_key(secret_key) do
    with [_header, payload, _signature] <- String.split(secret_key, ".", parts: 3),
         {:ok, raw_claims} <- Base.url_decode64(payload, padding: false),
         %{"iss" => zone} <- JOSE.json_module().decode(raw_claims) do
      zone
    else
      _other ->
        raise EdgeDB.ClientConnectionError.new("invalid secret key")
    end
  end
end
