defmodule EdgeDB.WrappedConnection do
  @moduledoc """
  A structure to wrap a connection to EdgeDB.

  This is used in driver internally for changing the behaviour of
    operations. See `EdgeDB.as_readonly/1`, `EdgeDB.with_retry_options/2`
    and `EdgeDB.with_transaction_options/2` for more information.
  """

  defstruct [
    :conn,
    :callbacks
  ]

  @typep callback() :: (DBConnection.conn(), callback() -> any())
  @typep conn() :: %__MODULE__{
           conn: DBConnection.conn(),
           callbacks: list(callback())
         }

  @typedoc """
  Wrapped connection.
  """
  @opaque t() :: %__MODULE__{}

  @doc false
  @spec wrap(conn() | DBConnection.conn(), callback()) :: t()

  def wrap(%__MODULE__{} = conn, callback) do
    %__MODULE__{conn | callbacks: [callback | conn.callbacks]}
  end

  def wrap(conn, callback) do
    %__MODULE__{conn: conn, callbacks: [callback]}
  end
end
