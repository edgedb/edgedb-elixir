defmodule EdgeDB.Config.Platform do
  @spec search_config_dir(list(String.t())) :: String.t()
  def search_config_dir(suffixes) do
    Enum.reduce([config_dir() | suffixes], "", fn component, result ->
      Path.join(result, component)
    end)
  end

  case :os.type() do
    {:unix, :darwin} ->
      defp config_dir do
        Path.join(["~", "Library", "Application Support", "edgedb"])
      end

    {:unix, _} ->
      defp config_dir do
        xdg_conf_dir = System.get_env("XDG_CONFIG_HOME", ".")

        xdg_conf_dir =
          if Path.type(xdg_conf_dir) == :relative do
            Path.join("~", ".config")
          else
            xdg_conf_dir
          end

        Path.join(xdg_conf_dir, "edgedb")
      end
  end
end
