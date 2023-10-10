# credo:disable-for-this-file
defmodule Mix.Tasks.Edgedb.Generate do
  @validator_definition [
    silent: [
      type: :boolean,
      doc: "Show processing messages."
    ],
    dsn: [
      type: :string,
      doc: "DSN that defines the primary information that can be used to connect to the instance."
    ],
    credentials_file: [
      type: :string,
      doc:
        "the path to the instance credentials file containing the instance parameters to connect to."
    ],
    instance: [
      type: :string,
      doc: "the name of the instance to connect to."
    ],
    host: [
      type: :string,
      doc: "the host name of the instance to connect to."
    ],
    port: [
      type: :non_neg_integer,
      doc: "the port number of the instance to connect to."
    ],
    database: [
      type: :string,
      doc: "the name of the database to connect to."
    ],
    user: [
      type: :string,
      doc: "the user name to connect to."
    ],
    password: [
      type: :string,
      doc: "the user password to connect."
    ],
    tls_ca_file: [
      type: :string,
      doc: "the path to the TLS certificate to be used when connecting to the instance."
    ],
    tls_security: [
      type: {:in, ["insecure", "no_host_verification", "strict", "default"]},
      doc: "security mode for the TLS connection."
    ]
  ]

  @shortdoc "Generate Elixir modules from EdgeQL queries"

  @moduledoc """
  Generate Elixir modules from EdgeQL queries.

  To configure generation modify `:generation` key under
    the `:edgedb` application configuration.

  Supported options (may be provided as a list of configs):

    * `:queries_path` - path to queries. Required.
    * `:output_path` - path to store generated Elixir code. By default
      `./lib` is used.
    * `:module_prefix` - prefix to name generated modules. By default
      no prefix is used.

  Supported arguments for task:

  #{NimbleOptions.docs(@validator_definition)}
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:edgedb)

    with {args, [], []} <- OptionParser.parse(args, strict: parser_definition()),
         {:ok, args} <- NimbleOptions.validate(args, @validator_definition),
         {:ok, _files} <- EdgeDB.EdgeQL.Generator.generate(args) do
      Mix.shell().info("Modules for queries generated succesfully!")
    else
      {_args, _unparsed, errors} ->
        Mix.shell().error(
          "Unable to parse arguments: #{inspect(Enum.map(errors, fn {key, _value} -> key end))}"
        )

      {_args, unparsed, []} ->
        Mix.shell().error("Unable to parse some of provided arguments: #{inspect(unparsed)}")

      {:error, %NimbleOptions.ValidationError{key: key} = error} ->
        Mix.shell().error(
          "Error while validating #{inspect(key)} argument: #{Exception.message(error)}"
        )

      {:error, {query_file, %EdgeDB.Error{} = error}} ->
        Mix.shell().error("Error while generating module for query from #{query_file}!")
        Mix.shell().error(Exception.message(error))
    end
  end

  defp parser_definition do
    Enum.map(@validator_definition, fn {arg, opts} ->
      type =
        case opts[:type] do
          :non_neg_integer ->
            :integer

          {:in, _variants} ->
            :string

          type ->
            type
        end

      {arg, type}
    end)
  end
end
