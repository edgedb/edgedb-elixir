defmodule EdgeDB.Protocol.Messages.Server.Authentication do
  @behaviour EdgeDB.Protocol.Message

  import EdgeDB.Protocol.Converters

  alias EdgeDB.Protocol.Message

  alias EdgeDB.Protocol.Messages.Server.Authentication.{
    AuthenticationOK,
    AuthenticationSASL,
    AuthenticationSASLContinue,
    AuthenticationSASLFinal
  }

  @type t() ::
          AuthenticationOK.t()
          | AuthenticationSASL.t()
          | AuthenticationSASLContinue.t()
          | AuthenticationSASLFinal.t()

  @mtype 0x52
  @sasl_code 0xA
  @sasl_continue_code 0xB
  @sasl_final_code 0xC

  @spec mtype() :: integer()
  def mtype do
    @mtype
  end

  @spec decode(bitstring()) :: {:ok, {t(), bitstring()}} | {:error, {:not_enough_size, integer()}}
  def decode(<<data::binary>>) do
    Message.decode(&__MODULE__.decode_message/1, @mtype, data)
  end

  @impl EdgeDB.Protocol.Message
  def decode_message(<<@sasl_code::uint32, _rest::binary>> = data) do
    AuthenticationSASL.decode_message(data)
  end

  @impl EdgeDB.Protocol.Message
  def decode_message(<<@sasl_continue_code::uint32, _rest::binary>> = data) do
    AuthenticationSASLContinue.decode_message(data)
  end

  @impl EdgeDB.Protocol.Message
  def decode_message(<<@sasl_final_code::uint32, _rest::binary>> = data) do
    AuthenticationSASLFinal.decode_message(data)
  end

  @impl EdgeDB.Protocol.Message
  def decode_message(<<_auth_status::uint32, _rest::binary>> = data) do
    AuthenticationOK.decode_message(data)
  end
end
