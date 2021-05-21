defmodule EdgeDB.Protocol.Messages.Server.Authentication do
  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.Messages.Server.Authentication.{
    AuthenticationOK,
    AuthenticationSASL,
    AuthenticationSASLContinue,
    AuthenticationSASLFinal
  }

  @mtype 0x52
  @sasl_code 0xA
  @sasl_continue_code 0xB
  @sasl_final_code 0xC

  @type t() ::
          AuthenticationOK.t()
          | AuthenticationSASL.t()
          | AuthenticationSASLContinue.t()
          | AuthenticationSASLFinal.t()

  @spec mtype() :: 0x52
  def mtype do
    @mtype
  end

  @spec decode(bitstring()) ::
          {:ok, t(), bitstring()} | {:error, {:not_enougth_size, integer()}}

  def decode(<<rest::binary>>) when byte_size(rest) < 5 do
    {:error, {:not_enougth_size, 0}}
  end

  def decode(<<@mtype::uint8, message_length::uint32, rest::binary>> = payload) do
    payload_length = message_length - 4

    case rest do
      <<message_payload::binary(payload_length), _rest::binary>> ->
        decode_authentication_message(message_payload, payload)

      _payload ->
        {:error, {:not_enougth_size, payload_length - byte_size(rest)}}
    end
  end

  @spec decode_authentication_message(bitstring(), bitstring()) :: {t(), bitstring()}

  defp decode_authentication_message(<<@sasl_code::uint32, _rest::binary>>, payload) do
    AuthenticationSASL.decode(payload)
  end

  defp decode_authentication_message(<<@sasl_continue_code::uint32, _rest::binary>>, payload) do
    AuthenticationSASLContinue.decode(payload)
  end

  defp decode_authentication_message(<<@sasl_final_code::uint32, _rest::binary>>, payload) do
    AuthenticationSASLFinal.decode(payload)
  end

  defp decode_authentication_message(<<_auth_status::uint32, _rest::binary>>, payload) do
    AuthenticationOK.decode(payload)
  end
end
