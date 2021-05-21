defmodule EdgeDB.SCRAM do
  alias EdgeDB.SCRAM.{
    ClientFirst,
    ServerFinal,
    ServerFirst
  }

  @spec handle_client_first(binary(), binary()) :: ClientFirst.client_first()
  def handle_client_first(username, password) do
    username
    |> ClientFirst.new(password)
    |> ClientFirst.client_first()
  end

  @spec handle_server_first(ServerFirst.t(), binary()) :: ServerFirst.server_first()
  def handle_server_first(%ServerFirst{} = sf, sf_data) do
    ServerFirst.server_first(sf, sf_data)
  end

  @spec handle_server_final(ServerFinal.t(), binary()) :: ServerFinal.server_final()
  def handle_server_final(%ServerFinal{} = sf, sf_data) do
    ServerFinal.server_final(sf, sf_data)
  end
end
