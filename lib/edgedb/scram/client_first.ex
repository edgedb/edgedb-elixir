defmodule EdgeDB.SCRAM.ClientFirst do
  alias EdgeDB.SCRAM.ServerFirst

  @base_gs2header "n,,"
  @nonce_length 24

  defstruct [
    :gs2header,
    :username,
    :password,
    :nonce
  ]

  @type t() :: %__MODULE__{
          gs2header: binary(),
          username: binary(),
          password: binary(),
          nonce: binary()
        }

  @spec new(binary(), binary()) :: t()
  def new(username, password) do
    %__MODULE__{
      gs2header: @base_gs2header,
      username: username,
      password: password,
      nonce: generate_nonce()
    }
  end

  @spec client_first(t()) :: {ServerFirst.t(), binary()}
  def client_first(%__MODULE__{} = cf) do
    client_first_message_bare = "n=#{cf.username},r=#{cf.nonce}"
    client_first_message = "#{cf.gs2header}#{client_first_message_bare}"

    sf =
      ServerFirst.new(
        cf.gs2header,
        cf.password,
        cf.nonce,
        client_first_message_bare
      )

    {sf, client_first_message}
  end

  @spec generate_nonce() :: binary()
  defp generate_nonce do
    @nonce_length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
