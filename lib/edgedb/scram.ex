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
    |> ClientFirst.handle()
  end

  @spec handle_server_first(ServerFirst.t(), String.t()) ::
          {:ok, {ServerFinal.t(), iodata()}}
          | {:error, :wrong_server_first_data | :mismatched_nonces}
  def handle_server_first(%ServerFirst{} = sf, sf_data) do
    ServerFirst.handle(sf, sf_data)
  end

  @spec handle_server_final(ServerFinal.t(), String.t()) ::
          :ok
          | {:error, :wrong_server_final_data | :mismatched_server_signatures}
  def handle_server_final(%ServerFinal{} = sf, sf_data) do
    ServerFinal.handle(sf, sf_data)
  end
end
