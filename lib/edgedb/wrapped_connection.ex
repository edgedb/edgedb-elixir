defmodule EdgeDB.WrappedConnection do
  defstruct [
    :conn,
    :callbacks
  ]

  @type callback() :: (DBConnection.t(), callback() -> any())
  @type t() :: %__MODULE__{
          conn: any(),
          callbacks: list(callback())
        }

  @spec wrap(t() | DBConnection.t(), callback()) :: t()

  def wrap(%__MODULE__{} = conn, callback) do
    %__MODULE__{conn | callbacks: [callback | conn.callbacks]}
  end

  def wrap(conn, callback) do
    %__MODULE__{conn: conn, callbacks: [callback]}
  end
end
