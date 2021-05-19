defmodule EdgeDB.SCRAM do
  @spec handle_client_first(binary(), binary()) :: EdgeDB.SCRAM.ClientFirst.client_first()
  def handle_client_first(username, password) do
    username
    |> EdgeDB.SCRAM.ClientFirst.new(password)
    |> EdgeDB.SCRAM.ClientFirst.client_first()
  end

  @spec handle_server_final(EdgeDB.SCRAM.ServerFirst.t(), binary()) ::
          EdgeDB.SCRAM.ServerFirst.server_first()
  def handle_server_first(%EdgeDB.SCRAM.ServerFirst{} = sf, sf_data) do
    EdgeDB.SCRAM.ServerFirst.server_first(sf, sf_data)
  end

  @spec handle_server_final(EdgeDB.SCRAM.ServerFinal.t(), binary()) ::
          EdgeDB.SCRAM.ServerFinal.server_final()
  def handle_server_final(%EdgeDB.SCRAM.ServerFinal{} = sf, sf_data) do
    EdgeDB.SCRAM.ServerFinal.server_final(sf, sf_data)
  end
end
