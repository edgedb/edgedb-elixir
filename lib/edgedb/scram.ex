defmodule EdgeDB.SCRAM do
  alias EdgeDB.SCRAM.{
    ClientFirst,
    ServerFinal,
    ServerFirst
  }

  @spec handle_client_first(String.t(), String.t()) :: {ServerFirst.t(), iodata()}
  def handle_client_first(user, password) do
    user
    |> ClientFirst.new(password)
    |> ClientFirst.client_first()
  end

  @spec handle_server_first(ServerFirst.t(), String.t()) ::
          {:ok, {ServerFinal.t(), iodata()}}
          | {:error, :wrong_server_first_data | :mismatched_nonces}
  def handle_server_first(%ServerFirst{} = sf, sf_data) do
    ServerFirst.server_first(sf, sf_data)
  end

  @spec handle_server_final(ServerFinal.t(), String.t()) ::
          :ok
          | {:error, :wrong_server_final_data | :mismatched_server_signatures}
  def handle_server_final(%ServerFinal{} = sf, sf_data) do
    ServerFinal.server_final(sf, sf_data)
  end
end
