.. _edgedb-elixir-api-errors:

API/Errors
==========

EdgeDB.Error
------------

Exception returned by the client if an error occurred.

Most of the functions in the ``EdgeDB.Error`` module are a shorthands for simplifying ``EdgeDB.Error`` exception constructing. These functions
are generated at compile time from a copy of the `errors.txt`_ file.

The useful ones are:

-  ``EdgeDB.Error.retry?/1``
-  ``EdgeDB.Error.inheritor?/2``

Types
~~~~~

*type* ``EdgeDB.Error.t/0``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @type EdgeDB.Error.t() :: %EdgeDB.Error{message: String.t(), type: module(), name: String.t(), code: integer()}

Exception returned by the client if an error occurred.

Fields:

-  ``:message`` - human-readable error message.
-  ``:type`` - alias module for EdgeDB error.
-  ``:name`` - error name from EdgeDB.
-  ``:code`` - internal error code.

Functions
~~~~~~~~~

*function* ``EdgeDB.Error.access_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.access_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.AccessError`` type.

*function* ``EdgeDB.Error.access_policy_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.access_policy_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.AccessPolicyError`` type.

*function* ``EdgeDB.Error.authentication_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.authentication_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.AuthenticationError`` type.

*function* ``EdgeDB.Error.availability_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.availability_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.AvailabilityError`` type.

*function* ``EdgeDB.Error.backend_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.backend_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.BackendError`` type.

*function* ``EdgeDB.Error.backend_unavailable_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.backend_unavailable_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.BackendUnavailableError`` type.

*function* ``EdgeDB.Error.binary_protocol_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.binary_protocol_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.BinaryProtocolError`` type.

*function* ``EdgeDB.Error.capability_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.capability_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.CapabilityError`` type.

*function* ``EdgeDB.Error.cardinality_violation_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.cardinality_violation_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.CardinalityViolationError`` type.

*function* ``EdgeDB.Error.client_connection_closed_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.client_connection_closed_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ClientConnectionClosedError`` type.

*function* ``EdgeDB.Error.client_connection_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.client_connection_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ClientConnectionError`` type.

*function* ``EdgeDB.Error.client_connection_failed_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.client_connection_failed_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ClientConnectionFailedError`` type.

*function* ``EdgeDB.Error.client_connection_failed_temporarily_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.client_connection_failed_temporarily_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ClientConnectionFailedTemporarilyError`` type.

*function* ``EdgeDB.Error.client_connection_timeout_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.client_connection_timeout_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ClientConnectionTimeoutError`` type.

*function* ``EdgeDB.Error.client_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.client_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ClientError`` type.

*function* ``EdgeDB.Error.configuration_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.configuration_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ConfigurationError`` type.

*function* ``EdgeDB.Error.constraint_violation_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.constraint_violation_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ConstraintViolationError`` type.

*function* ``EdgeDB.Error.disabled_capability_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.disabled_capability_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DisabledCapabilityError`` type.

*function* ``EdgeDB.Error.division_by_zero_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.division_by_zero_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DivisionByZeroError`` type.

*function* ``EdgeDB.Error.duplicate_cast_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_cast_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateCastDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_constraint_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_constraint_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateConstraintDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_database_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_database_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateDatabaseDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_function_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_function_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateFunctionDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_link_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_link_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateLinkDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_module_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_module_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateModuleDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_operator_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_operator_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateOperatorDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_property_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_property_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicatePropertyDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_user_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_user_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateUserDefinitionError`` type.

*function* ``EdgeDB.Error.duplicate_view_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.duplicate_view_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.DuplicateViewDefinitionError`` type.

*function* ``EdgeDB.Error.edge_ql_syntax_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.edge_ql_syntax_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.EdgeQLSyntaxError`` type.

*function* ``EdgeDB.Error.execution_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.execution_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ExecutionError`` type.

*function* ``EdgeDB.Error.graph_ql_syntax_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.graph_ql_syntax_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.GraphQLSyntaxError`` type.

*function* ``EdgeDB.Error.idle_session_timeout_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.idle_session_timeout_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.IdleSessionTimeoutError`` type.

*function* ``EdgeDB.Error.idle_transaction_timeout_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.idle_transaction_timeout_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.IdleTransactionTimeoutError`` type.

*function* ``EdgeDB.Error.inheritor?(exception, base_error_type)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.inheritor?(t(), module()) :: boolean()

Check if the exception is an inheritor of another EdgeDB error.

*function* ``EdgeDB.Error.input_data_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.input_data_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InputDataError`` type.

*function* ``EdgeDB.Error.integrity_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.integrity_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.IntegrityError`` type.

*function* ``EdgeDB.Error.interface_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.interface_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InterfaceError`` type.

*function* ``EdgeDB.Error.internal_client_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.internal_client_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InternalClientError`` type.

*function* ``EdgeDB.Error.internal_server_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.internal_server_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InternalServerError`` type.

*function* ``EdgeDB.Error.invalid_alias_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_alias_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidAliasDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_argument_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_argument_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidArgumentError`` type.

*function* ``EdgeDB.Error.invalid_cast_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_cast_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidCastDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_constraint_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_constraint_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidConstraintDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_database_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_database_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidDatabaseDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_function_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_function_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidFunctionDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_link_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_link_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidLinkDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_link_target_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_link_target_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidLinkTargetError`` type.

*function* ``EdgeDB.Error.invalid_module_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_module_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidModuleDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_operator_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_operator_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidOperatorDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_property_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_property_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidPropertyDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_property_target_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_property_target_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidPropertyTargetError`` type.

*function* ``EdgeDB.Error.invalid_reference_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_reference_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidReferenceError`` type.

*function* ``EdgeDB.Error.invalid_syntax_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_syntax_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidSyntaxError`` type.

*function* ``EdgeDB.Error.invalid_target_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_target_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidTargetError`` type.

*function* ``EdgeDB.Error.invalid_type_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_type_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidTypeError`` type.

*function* ``EdgeDB.Error.invalid_user_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_user_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidUserDefinitionError`` type.

*function* ``EdgeDB.Error.invalid_value_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.invalid_value_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.InvalidValueError`` type.

*function* ``EdgeDB.Error.log_message(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.log_message(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.LogMessage`` type.

*function* ``EdgeDB.Error.missing_argument_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.missing_argument_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.MissingArgumentError`` type.

*function* ``EdgeDB.Error.missing_required_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.missing_required_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.MissingRequiredError`` type.

*function* ``EdgeDB.Error.no_data_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.no_data_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.NoDataError`` type.

*function* ``EdgeDB.Error.numeric_out_of_range_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.numeric_out_of_range_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.NumericOutOfRangeError`` type.

*function* ``EdgeDB.Error.parameter_type_mismatch_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.parameter_type_mismatch_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ParameterTypeMismatchError`` type.

*function* ``EdgeDB.Error.protocol_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.protocol_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ProtocolError`` type.

*function* ``EdgeDB.Error.query_argument_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.query_argument_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.QueryArgumentError`` type.

*function* ``EdgeDB.Error.query_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.query_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.QueryError`` type.

*function* ``EdgeDB.Error.query_timeout_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.query_timeout_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.QueryTimeoutError`` type.

*function* ``EdgeDB.Error.reconnect?(exception)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.reconnect?(Exception.t()) :: boolean()

Check if should try to reconnect to EdgeDB server.

**NOTE**: this function is not used right now, because ``DBConnection`` reconnects it connection itself.

*function* ``EdgeDB.Error.result_cardinality_mismatch_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.result_cardinality_mismatch_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.ResultCardinalityMismatchError`` type.

*function* ``EdgeDB.Error.retry?(exception)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.retry?(Exception.t()) :: boolean()

Check if should try to repeat the query during the execution of which an error occurred.

*function* ``EdgeDB.Error.schema_definition_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.schema_definition_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.SchemaDefinitionError`` type.

*function* ``EdgeDB.Error.schema_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.schema_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.SchemaError`` type.

*function* ``EdgeDB.Error.schema_syntax_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.schema_syntax_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.SchemaSyntaxError`` type.

*function* ``EdgeDB.Error.session_timeout_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.session_timeout_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.SessionTimeoutError`` type.

*function* ``EdgeDB.Error.state_mismatch_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.state_mismatch_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.StateMismatchError`` type.

*function* ``EdgeDB.Error.transaction_conflict_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.transaction_conflict_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.TransactionConflictError`` type.

*function* ``EdgeDB.Error.transaction_deadlock_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.transaction_deadlock_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.TransactionDeadlockError`` type.

*function* ``EdgeDB.Error.transaction_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.transaction_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.TransactionError`` type.

*function* ``EdgeDB.Error.transaction_serialization_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.transaction_serialization_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.TransactionSerializationError`` type.

*function* ``EdgeDB.Error.transaction_timeout_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.transaction_timeout_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.TransactionTimeoutError`` type.

*function* ``EdgeDB.Error.type_spec_not_found_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.type_spec_not_found_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.TypeSpecNotFoundError`` type.

*function* ``EdgeDB.Error.unexpected_message_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unexpected_message_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnexpectedMessageError`` type.

*function* ``EdgeDB.Error.unknown_argument_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_argument_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownArgumentError`` type.

*function* ``EdgeDB.Error.unknown_database_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_database_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownDatabaseError`` type.

*function* ``EdgeDB.Error.unknown_link_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_link_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownLinkError`` type.

*function* ``EdgeDB.Error.unknown_module_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_module_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownModuleError`` type.

*function* ``EdgeDB.Error.unknown_parameter_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_parameter_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownParameterError`` type.

*function* ``EdgeDB.Error.unknown_property_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_property_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownPropertyError`` type.

*function* ``EdgeDB.Error.unknown_user_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unknown_user_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnknownUserError`` type.

*function* ``EdgeDB.Error.unsupported_backend_feature_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unsupported_backend_feature_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnsupportedBackendFeatureError`` type.

*function* ``EdgeDB.Error.unsupported_capability_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unsupported_capability_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnsupportedCapabilityError`` type.

*function* ``EdgeDB.Error.unsupported_feature_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unsupported_feature_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnsupportedFeatureError`` type.

*function* ``EdgeDB.Error.unsupported_protocol_version_error(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.unsupported_protocol_version_error(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.UnsupportedProtocolVersionError`` type.

*function* ``EdgeDB.Error.warning_message(msg, opts \\ [])``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: elixir

   @spec EdgeDB.Error.warning_message(String.t(), Keyword.t()) :: t()

Create a new ``EdgeDB.Error`` with ``EdgeDB.WarningMessage`` type.

.. _errors.txt: https://github.com/edgedb/edgedb/blob/a529aae753319f26cce942ae4fc7512dd0c5a37b/edb/api/errors.txt
