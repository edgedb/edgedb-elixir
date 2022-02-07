defmodule EdgeDB.SCRAM.ServerFirst do
  @moduledoc false

  alias EdgeDB.SCRAM.ServerFinal

  @sha256_output_length 32

  defstruct [
    :gs2header,
    :password,
    :client_nonce,
    :client_first_bare
  ]

  @type t() :: %__MODULE__{
          gs2header: String.t(),
          password: String.t(),
          client_nonce: String.t(),
          client_first_bare: String.t()
        }

  @spec new(String.t(), String.t(), String.t(), String.t()) :: t()
  def new(gs2header, password, client_nonce, client_first_bare) do
    %__MODULE__{
      gs2header: gs2header,
      password: password,
      client_nonce: client_nonce,
      client_first_bare: client_first_bare
    }
  end

  @spec handle(t(), String.t()) ::
          {:ok, {ServerFinal.t(), iodata()}}
          | {:error, :mismatched_nonces | :wrong_server_first_data}
  def handle(%__MODULE__{} = sf, sf_data) do
    with {:ok, {nonce, salt, iterations}} <- parse_server_first_data(sf_data),
         :ok <- verify_server_nonce(nonce, sf.client_nonce) do
      salted_password = hash_password(sf.password, salt, iterations)

      {client_proof, server_signature} =
        calculate_client_proof(
          sf.gs2header,
          sf.client_first_bare,
          sf_data,
          salted_password,
          nonce
        )

      encoded_gs2header = Base.encode64(sf.gs2header)
      encoded_proof = Base.encode64(client_proof)
      client_final_message = "c=#{encoded_gs2header},r=#{nonce},p=#{encoded_proof}"

      sf = ServerFinal.new(server_signature)

      {:ok, {sf, client_final_message}}
    end
  end

  defp parse_server_first_data(sf_data) do
    with ["r=" <> nonce, "s=" <> salt, "i=" <> iterations] <-
           String.split(sf_data, ","),
         {:ok, salt} <- Base.decode64(salt),
         {iterations, _base} <- Integer.parse(iterations) do
      {:ok, {nonce, salt, iterations}}
    else
      _term ->
        {:error, :wrong_server_first_data}
    end
  end

  defp verify_server_nonce(server_nonce, client_nonce) do
    if String.starts_with?(server_nonce, client_nonce) do
      :ok
    else
      {:error, :mismatched_nonces}
    end
  end

  defp hash_password(password, salt, iterations) do
    block_1 = hmac(password, <<salt::binary, 1::integer-size(32)>>)

    {<<output::binary-size(@sha256_output_length), _rest::binary>>, _last_block} =
      Enum.reduce(2..iterations, {block_1, block_1}, fn _iteration, {result_block, prev_block} ->
        block_i = hmac(password, prev_block)
        result_block = xor(result_block, block_i)
        {result_block, block_i}
      end)

    output
  end

  defp calculate_client_proof(gs2header, cf_bare, sf_data, password, nonce) do
    encoded_gs2header = Base.encode64(gs2header)
    client_final_without_proof = "c=#{encoded_gs2header},r=#{nonce}"

    client_key = hmac(password, "Client Key")
    server_key = hmac(password, "Server Key")
    stored_key = hash(client_key)

    auth_message = cf_bare <> "," <> sf_data <> "," <> client_final_without_proof

    client_signature = hmac(stored_key, auth_message)
    server_signature = hmac(server_key, auth_message)

    client_proof = xor(client_key, client_signature)

    {client_proof, server_signature}
  end

  defp xor(data1, data2) do
    :crypto.exor(data1, data2)
  end

  defp hash(data) do
    :crypto.hash(:sha256, data)
  end

  defp hmac(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end
end
