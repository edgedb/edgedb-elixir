defmodule EdgeDB.Connection.QueryBuilder do
  @type statement() :: String.t()

  @spec start_transaction_statement(list(EdgeDB.edgedb_transaction_option())) :: statement()
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
    "START TRANSACTION #{mode};"
  end

  @spec commit_transaction_statement() :: statement()
  def commit_transaction_statement do
    "COMMIT;"
  end

  @spec rollback_transaction_statement() :: statement()
  def rollback_transaction_statement do
    "ROLLBACK;"
  end

  @spec declare_savepoint_statement(String.t()) :: statement()
  def declare_savepoint_statement(savepoint_name) do
    "DECLARE SAVEPOINT #{savepoint_name};"
  end

  @spec release_savepoint_statement(String.t()) :: statement()
  def release_savepoint_statement(savepoint_name) do
    "RELEASE SAVEPOINT #{savepoint_name};"
  end

  @spec rollback_to_savepoint_statement(String.t()) :: statement()
  def rollback_to_savepoint_statement(savepoint_name) do
    "ROLLBACK TO SAVEPOINT #{savepoint_name};"
  end

  @spec scalars_type_ids_by_names_statement() :: statement()
  def scalars_type_ids_by_names_statement do
    """
      SELECT schema::ScalarType {
        id,
        name,
      }
      FILTER contains(<array<str>>$0, .name);
    """
  end
end
