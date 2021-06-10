defmodule EdgeDB.Connection.QueryBuilder do
  @type statement() :: String.t()

  @type start_transaction_option() ::
          {:isolation, :repeatable_read | :serializable}
          | {:readonly, boolean()}
          | {:deferrable, boolean()}

  @type start_transaction_options() :: list(start_transaction_option())

  @spec start_transaction_statement(start_transaction_options()) :: statement()
  def start_transaction_statement(opts) do
    isolation =
      case Keyword.get(opts, :isolation, :repeatable_read) do
        :serializable ->
          "ISOLATION SERIALIZABLE"

        :repeatable_read ->
          "ISOLATION REPEATABLE READ"
      end

    read =
      if Keyword.get(opts, :readonly, false) do
        "READ ONLY"
      else
        "READ WRITE"
      end

    deferrable =
      if Keyword.get(opts, :deferrable, false) do
        "DEFERRABLE"
      else
        "NOT DEFERRABLE"
      end

    mode = Enum.join([isolation, read, deferrable], ", ")
    "START TRANSACTION #{mode}"
  end

  @spec commit_transaction_statement() :: statement()
  def commit_transaction_statement do
    "COMMIT"
  end

  @spec rollback_transaction_statement() :: statement()
  def rollback_transaction_statement do
    "ROLLBACK"
  end
end
