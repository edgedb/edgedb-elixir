defmodule EdgeDB.SCRAM.ServerFinal do
  @moduledoc false

  defstruct [
    :server_signature
  ]

  @type t() :: %__MODULE__{
          server_signature: String.t()
        }

  @spec new(String.t()) :: t()
  def new(server_signature) do
    %__MODULE__{server_signature: server_signature}
  end

  @spec handle(t(), String.t()) ::
          :ok | {:error, :wrong_server_final_data | :mismatched_server_signatures}
  def handle(%__MODULE__{} = sf, sf_data) do
    with {:ok, server_signature} <- parse_server_final_data(sf_data) do
      verify_server_signature(server_signature, sf.server_signature)
    end
  end

  defp parse_server_final_data(server_final_data) do
    with "v=" <> encoded_signature <- server_final_data,
         {:ok, signature} <- Base.decode64(encoded_signature) do
      {:ok, signature}
    else
      _term ->
        {:error, :wrong_server_final_data}
    end
  end

  defp verify_server_signature(received_server_signature, calculated_server_signature) do
    if received_server_signature == calculated_server_signature do
      :ok
    else
      {:error, :mismatched_server_signatures}
    end
  end
end
