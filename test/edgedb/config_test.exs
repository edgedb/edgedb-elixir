defmodule EdgeDB.ConfigTest do
  use EdgeDB.Case, async: false

  alias EdgeDB.Config

  setup do
    %{instance: instance_name()}
  end

  setup do
    original_config_env = Application.get_all_env(:edgedb)

    on_exit(fn ->
      exit_config_env = Application.get_all_env(:edgedb)

      for {key, _value} <- exit_config_env do
        if Keyword.has_key?(original_config_env, key) do
          Application.put_env(:edgedb, key, original_config_env[key])
        else
          Application.delete_env(:edgedb, key)
        end
      end
    end)

    :ok
  end

  setup do
    original_env = System.get_env()

    on_exit(fn ->
      exit_env = System.get_env()

      for {key, _value} <- exit_env do
        if Map.has_key?(original_env, key) do
          System.put_env(key, original_env[key])
        else
          System.delete_env(key)
        end
      end
    end)

    :ok
  end

  describe "connect_opts/1 without options inside EdgeDB project" do
    setup %{instance: instance} do
      %{credentials: Config.Credentials.read_creadentials(instance)}
    end

    test "returns options from linked project", %{credentials: credentials} do
      opts = Config.connect_opts()

      port = credentials[:port]
      assert [{_host, ^port} | _other] = opts[:endpoints]
      assert opts[:tls_ca_data] == credentials[:tls_ca_data]
      assert opts[:user] == credentials[:user]
      assert opts[:password] == credentials[:password]
      assert opts[:database] == credentials[:database]
    end
  end

  describe "connect_opts/1 with instance name outside of EdgeDB project" do
    setup %{instance: instance} do
      pwd = File.cwd!()

      on_exit(fn ->
        File.cd!(pwd)
      end)

      File.cd!("/tmp")

      %{credentials: Config.Credentials.read_creadentials(instance)}
    end

    test "returns options from linked project", %{instance: instance, credentials: credentials} do
      opts = Config.connect_opts(instance: instance)

      port = credentials[:port]
      assert [{_host, ^port} | _other] = opts[:endpoints]
      assert opts[:tls_ca_data] == credentials[:tls_ca_data]
      assert opts[:user] == credentials[:user]
      assert opts[:password] == credentials[:password]
      assert opts[:database] == credentials[:database]
    end
  end

  describe "connect_opts/1 with instance name as environment variable outside of EdgeDB project" do
    setup %{instance: instance} do
      pwd = File.cwd!()

      on_exit(fn ->
        System.delete_env("EDGEDB_INSTANCE")
        File.cd!(pwd)
      end)

      System.put_env("EDGEDB_INSTANCE", instance)
      File.cd!("/tmp")

      %{credentials: Config.Credentials.read_creadentials(instance)}
    end

    test "returns options from instance credentials", %{credentials: credentials} do
      opts = Config.connect_opts()

      port = credentials[:port]
      assert [{_host, ^port} | _other] = opts[:endpoints]
      assert opts[:tls_ca_data] == credentials[:tls_ca_data]
      assert opts[:user] == credentials[:user]
      assert opts[:password] == credentials[:password]
      assert opts[:database] == credentials[:database]
    end
  end

  describe "connect_opts/1 with DSN in options" do
    test "returns options from parsed DSN" do
      opts = Config.connect_opts(dsn: "edgedb://edgedb:edgedb@localhost:5656/edgedb")

      expected_opts = [
        tls_verify_hostname: true,
        host: "localhost",
        port: 5656,
        database: "edgedb",
        user: "edgedb",
        password: "edgedb"
      ]

      for {key, value} <- expected_opts do
        assert value == opts[key]
      end
    end

    test "returns options from parsed DSN with user in query" do
      opts = Config.connect_opts(dsn: "edgedb://localhost:5656/edgedb?user=edgedb")

      expected_opts = [
        tls_verify_hostname: true,
        host: "localhost",
        port: 5656,
        database: "edgedb",
        user: "edgedb"
      ]

      for {key, value} <- expected_opts do
        assert value == opts[key]
      end
    end

    test "returns options from parsed DSN with password in query" do
      opts = Config.connect_opts(dsn: "edgedb://edgedb@localhost:5656/edgedb?password=edgedb")

      expected_opts = [
        tls_verify_hostname: true,
        host: "localhost",
        port: 5656,
        database: "edgedb",
        user: "edgedb",
        password: "edgedb"
      ]

      for {key, value} <- expected_opts do
        assert value == opts[key]
      end
    end

    test "returns options from parsed DSN with TLS cert file path in query" do
      opts =
        Config.connect_opts(
          dsn: "edgedb://edgedb:edgedb@localhost:5656/edgedb?tls_ca_file=%2Ftmp%2Fsome%2Fpath"
        )

      expected_opts = [
        tls_ca_file: "/tmp/some/path",
        host: "localhost",
        port: 5656,
        database: "edgedb",
        user: "edgedb",
        password: "edgedb"
      ]

      for {key, value} <- expected_opts do
        assert value == opts[key]
      end

      assert opts[:tls_verify_hostname] == false
    end

    test "returns options from parsed DSN with TLS cert file path and TLS verify hostname in query" do
      opts =
        Config.connect_opts(
          dsn:
            "edgedb://edgedb:edgedb@localhost:5656/edgedb?tls_ca_file=%2Ftmp%2Fsome%2Fpath&tls_verify_hostname=t"
        )

      expected_opts = [
        tls_verify_hostname: true,
        tls_ca_file: "/tmp/some/path",
        host: "localhost",
        port: 5656,
        database: "edgedb",
        user: "edgedb",
        password: "edgedb"
      ]

      for {key, value} <- expected_opts do
        assert value == opts[key]
      end
    end
  end

  describe "connect_opts/1 options priority" do
    test "explicit options take precedence over config options", %{instance: instance} do
      config_opts = [
        instance: "instance",
        endpoints: [{'some.host', 42}],
        database: "database",
        user: "user",
        password: "password",
        tls_ca_file: "/some/path",
        tls_verify_hostname: true
      ]

      for {key, value} <- config_opts do
        Application.put_env(:edgedb, key, value)
      end

      opts = [
        instance: instance,
        endpoints: [{'another.host', 84}],
        host: "another.host",
        port: 84,
        database: "production",
        user: "internal",
        password: "very safe",
        tls_ca_file: "/another/path",
        tls_verify_hostname: false
      ]

      connect_opts = Config.connect_opts(opts)

      for {key, value} <- opts do
        assert value == connect_opts[key]
      end
    end

    test "config options take precedence over DSN options" do
      config_opts = [
        instance: "instance",
        endpoints: [{'some.host', 42}],
        database: "database",
        user: "user",
        password: "password",
        tls_ca_file: "/some/path",
        tls_verify_hostname: true
      ]

      for {key, value} <- config_opts do
        Application.put_env(:edgedb, key, value)
      end

      dsn = "edgedb://edgedb:edgedb@localhost:5656/edgedb"

      connect_opts = Config.connect_opts(dsn: dsn)

      for {key, value} <- config_opts do
        assert value == connect_opts[key]
      end
    end

    test "DSN options take precedence over instance credentials options" do
      dsn =
        "edgedb://username:password@hostname:5432/database?tls_ca_file=%2Ftmp%2Fsome%2Fpath&tls_verify_hostname=yes"

      dsn_options = [
        endpoints: [{'hostname', 5432}],
        user: "username",
        password: "password",
        database: "database",
        tls_ca_file: "/tmp/some/path",
        tls_verify_hostname: true
      ]

      connect_opts = Config.connect_opts(dsn: dsn)

      for {key, value} <- dsn_options do
        assert value == connect_opts[key]
      end
    end

    test "instance credentials options take precedence over environment variables options", %{
      instance: instance
    } do
      instance_options = Config.Credentials.read_creadentials(instance)
      connect_opts = Config.connect_opts(instance: instance)

      for {key, value} <- instance_options do
        assert value == connect_opts[key]
      end
    end

    test "environment variables options take precedence over default options" do
      env = %{
        "EDGEDB_HOST" => "hostname",
        "EDGEDB_PORT" => "9999",
        "EDGEDB_USER" => "username",
        "EDGEDB_PASSWORD" => "password",
        "EDGEDB_DATABASE" => "database"
      }

      for {key, value} <- env do
        System.put_env(key, value)
      end

      env_opts = [
        endpoints: [{'hostname', 9999}],
        tls_verify_hostname: true,
        user: "username",
        password: "password",
        database: "database"
      ]

      # we need either the instance name or the DSN anyway so pass a simple DSN
      connect_opts = Config.connect_opts(dsn: "edgedb://")

      for {key, value} <- env_opts do
        assert value == connect_opts[key]
      end
    end
  end

  describe "processing endpoints" do
    test "explicit host and port define endpoint" do
      connect_opts = Config.connect_opts(host: "hostname", port: 8888)

      assert connect_opts[:endpoints] == [{'hostname', 8888}]
    end

    test "explicit endpoints ingore explicit host and port" do
      connect_opts =
        Config.connect_opts(
          host: "hostname",
          port: 8888,
          endpoints: [{"hostname2", 1111}, "hostname3"]
        )

      assert connect_opts[:endpoints] == [{'hostname2', 1111}, {'hostname3', 5656}]
    end

    test "absolute paths in endpoints convert into unix socket form" do
      connect_opts =
        Config.connect_opts(
          endpoints: [
            "/tmp",
            "/tmp/.s.EDGEDB.1111",
            {"/tmp", 2222},
            {"/tmp/.s.EDGEDB.3333", 4444}
          ]
        )

      assert connect_opts[:endpoints] == [
               {{:local, "/tmp/.s.EDGEDB.5656"}, 0},
               {{:local, "/tmp/.s.EDGEDB.1111"}, 0},
               {{:local, "/tmp/.s.EDGEDB.2222"}, 0},
               {{:local, "/tmp/.s.EDGEDB.3333"}, 0}
             ]
    end
  end

  defp instance_name do
    dir = File.cwd!()

    path = Path.expand(dir)

    hash =
      :sha
      |> :crypto.hash(path)
      |> Base.encode16(case: :lower)

    base_name = Path.basename(path)
    dir_name = base_name <> "-" <> hash

    stash_dir =
      ["projects", dir_name]
      |> Config.Platform.search_config_dir()
      |> Path.expand()

    [stash_dir, "instance-name"]
    |> Path.join()
    |> File.read!()
    |> String.trim()
  end
end
