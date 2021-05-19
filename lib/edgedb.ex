defmodule EdgeDB do
  def start_link(opts) do
    DBConnection.start_link(EdgeDB.Connection, opts)
  end
end
