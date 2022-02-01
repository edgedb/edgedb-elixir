defmodule EdgeDB.WrappedConnection do
  defstruct [
    :conn,
    :callbacks
  ]

  @type callback() :: (DBConnection.conn(), callback() -> any())
  @type t() :: %__MODULE__{
          conn: DBConnection.conn(),
          callbacks: list(callback())
        }

  @spec wrap(t() | DBConnection.conn(), callback()) :: t()

  def wrap(%__MODULE__{} = conn, callback) do
    %__MODULE__{conn | callbacks: [callback | conn.callbacks]}
  end

  def wrap(conn, callback) do
    %__MODULE__{conn: conn, callbacks: [callback]}
  end
end
