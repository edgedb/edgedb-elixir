defmodule EdgeDB.Protocol.Errors do
  defmodule Error do
    defmacro __using__(opts \\ []) do
      {:ok, error_code} = Keyword.fetch(opts, :code)

      quote do
        @code unquote(error_code)

        defexception [
          :message,
          :code,
          meta: %{}
        ]

        @type t() :: %__MODULE__{
                message: String.t(),
                code: pos_integer(),
                meta: map()
              }

        @impl Exception
        def exception(value, opts \\ []) do
          meta = Keyword.get(opts, :meta, %{})
          %__MODULE__{message: value, code: code_hex(), meta: meta}
        end

        @spec code() :: integer()
        def code do
          @code
        end

        @spec code_hex() :: String.t()
        def code_hex do
          Integer.to_string(@code, 16)
        end
      end
    end
  end

  @error_definition_regex ~r/^(?<error_code>0x(_[0-9A-Fa-f]{2}){4})\s*(?<error_name>\w+)/
  @edgedb_errors_file Path.join(
                        :code.priv_dir(:edgedb),
                        Path.join(["edgedb", "api", "errors.txt"])
                      )

  for line <- File.stream!(@edgedb_errors_file),
      Regex.match?(@error_definition_regex, line) do
    %{"error_code" => code_str, "error_name" => error} =
      Regex.named_captures(@error_definition_regex, line)

    # dynamically create errors for EdgeDB protocol, similar to:
    # defmodule EdgeDB.Protocol.Errors.InternalServerError do
    #   use EdgeDB.Protocol.Errors.Error, code: code
    # end

    code_str =
      code_str
      |> String.replace_prefix("0x", "")
      |> String.replace("_", "")

    {code, ""} = Integer.parse(code_str, 16)
    code_hex = Integer.to_string(code, 16)

    [{error_module, _}] =
      Code.compile_quoted({:defmodule, [context: Elixir, import: Kernel],
       [
         # we can disable check here, since it's compile time
         # credo:disable-for-next-line
         {:__aliases__, [alias: false], [:EdgeDB, :Protocol, :Errors, String.to_atom(error)]},
         [
           do:
             {:use, [context: Elixir, import: Kernel],
              [
                {:__aliases__, [alias: false], [:EdgeDB, :Protocol, :Errors, :Error]},
                [code: code]
              ]}
         ]
       ]})

    @spec module_from_code(integer() | binary()) :: atom()

    def module_from_code(unquote(code)) do
      unquote(error_module)
    end

    def module_from_code(unquote(code_hex)) do
      unquote(error_module)
    end

    @spec name_from_code(integer() | binary()) :: binary()

    def name_from_code(unquote(code)) do
      unquote(error)
    end

    def name_from_code(unquote(code_hex)) do
      unquote(error)
    end
  end
end
