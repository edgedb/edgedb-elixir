defmodule EdgeDB.Connection.QueryBuilder do
  @moduledoc false

  @type statement() :: String.t()

  @spec start_transaction_statement(list(EdgeDB.Client.transaction_option())) :: statement()
  def start_transaction_statement(opts) do
    # only serializable exists at the moment
    isolation =
      case Keyword.get(opts, :isolation, :serializable) do
        _isolation ->
          "isolation serializable"
      end

    read =
      if Keyword.get(opts, :readonly, false) do
        "read only"
      else
        "read write"
      end

    deferrable =
      if Keyword.get(opts, :deferrable, false) do
        "deferrable"
      else
        "not deferrable"
      end

    mode = Enum.join([isolation, read, deferrable], ", ")
    "start transaction #{mode};"
  end

  @spec commit_transaction_statement() :: statement()
  def commit_transaction_statement do
    "commit;"
  end

  @spec rollback_transaction_statement() :: statement()
  def rollback_transaction_statement do
    "rollback;"
  end

  @spec declare_savepoint_statement(String.t()) :: statement()
  def declare_savepoint_statement(savepoint_name) do
    "declare savepoint #{savepoint_name};"
  end

  @spec release_savepoint_statement(String.t()) :: statement()
  def release_savepoint_statement(savepoint_name) do
    "release savepoint #{savepoint_name};"
  end

  @spec rollback_to_savepoint_statement(String.t()) :: statement()
  def rollback_to_savepoint_statement(savepoint_name) do
    "rollback to savepoint #{savepoint_name};"
  end

  @spec scalars_type_ids_by_names_statement() :: statement()
  def scalars_type_ids_by_names_statement do
    """
      select schema::ScalarType {
        id,
        name,
      }
      filter contains(<array<str>>$0, .name);
    """
  end
end
