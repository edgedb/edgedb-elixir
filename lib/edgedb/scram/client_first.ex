defmodule EdgeDB.SCRAM.ClientFirst do
  alias EdgeDB.SCRAM.ServerFirst

  @base_gs2header "n,,"
  @nonce_length 24

  defstruct [
    :gs2header,
    :user,
    :password,
    :nonce
  ]

  @type t() :: %__MODULE__{
          gs2header: String.t(),
          user: String.t(),
          password: String.t(),
          nonce: String.t()
        }

  @spec new(String.t(), String.t()) :: t()
  def new(user, password) do
    %__MODULE__{
      gs2header: @base_gs2header,
      user: user,
      password: password,
      nonce: generate_nonce()
    }
  end

  @spec client_first(t()) :: {ServerFirst.t(), iodata()}
  def client_first(%__MODULE__{} = cf) do
    client_first_message_bare = "n=#{cf.user},r=#{cf.nonce}"
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

  defp generate_nonce do
    @nonce_length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
