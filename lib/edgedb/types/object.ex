defmodule EdgeDB.Object do
  @moduledoc """
  An immutable representation of an object instance returned from a query.

  `EdgeDB.Object` implements `Access` behavior to access properties by key.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> %EdgeDB.Object{} = object =
  iex(2)>  EdgeDB.query_required_single!(pid, "
  ...(2)>   SELECT schema::ObjectType{
  ...(2)>     name
  ...(2)>   }
  ...(2)>   FILTER .name = 'std::Object'
  ...(2)>   LIMIT 1
  ...(2)>  ")
  #EdgeDB.Object<name := "std::Object">
  iex(3)> object[:name]
  "std::Object"
  iex(4)> object["name"]
  "std::Object"
  ```

  ### Links and links properties

  In EdgeDB, objects can have links to other objects or a set of objects.
    You can use the same syntax to access links values as for object properties.
    Links can also have their own properties (denoted as `@<link_prop_name>` in EdgeQL syntax).
    You can use the same property name as in the query to access them from the links.

  ```elixir
  iex(1)> {:ok, pid} = EdgeDB.start_link()
  iex(2)> %EdgeDB.Object{} = object =
  iex(2)>  EdgeDB.query_required_single!(pid, "
  ...(2)>   SELECT schema::Property {
  ...(2)>       name,
  ...(2)>       annotations: {
  ...(2)>         name,
  ...(2)>         @value
  ...(2)>       }
  ...(2)>   }
  ...(2)>   FILTER .name = 'listen_port' AND .source.name = 'cfg::Config'
  ...(2)>   LIMIT 1
  ...(2)>  ")
  #EdgeDB.Object<name := "listen_port", annotations := #EdgeDB.Set<{#EdgeDB.Object<name := "cfg::system", @value := "true">}>>
  iex(3)> annotations = object[:annotations]
  #EdgeDB.Set<{#EdgeDB.Object<name := "cfg::system", @value := "true">}>
  iex(4)> link = Enum.at(annotations, 0)
  #EdgeDB.Object<name := "cfg::system", @value := "true">
  iex(5)> link["@value"]
  "true"
  ```
  """

  @behaviour Access

  alias EdgeDB.Object.Field

  defstruct [
    :__fields__,
    :__order__,
    :__tid__,
    :id
  ]

  @typedoc """
  UUID value.
  """
  @type uuid() :: String.t()

  @typedoc since: "0.2.0"
  @typedoc """
  Options for `EdgeDB.Object.fields/2`

  Supported options:

    * `:properties` - flag to include object properties in returning list. The default is `true`.
    * `:links` - flag to include object links in returning list. The default is `true`.
    * `:link_properies` - flag to include object link properties in returning list. The default is `true`.
    * `:id` - flag to include implicit `:id` in returning list. The default is `false`.
    * `:implicit` - flag to include implicit fields (like `:id` or `:__tid__`) in returning list.
      The default is `false`.
  """
  @type fields_option() ::
          {:properties, boolean()}
          | {:links, boolean()}
          | {:link_properties, boolean()}
          | {:id, boolean()}
          | {:implicit, boolean()}

  @typedoc since: "0.2.0"
  @typedoc """
  Options for `EdgeDB.Object.properties/2`

  Supported options:

    * `:id` - flag to include implicit `:id` in returning list. The default is `false`.
    * `:implicit` - flag to include implicit properties (like `:id` or `:__tid__`) in returning list.
      The default is `false`.
  """
  @type properties_option() ::
          {:id, boolean()}
          | {:implicit, boolean()}

  @typedoc """
  An immutable representation of an object instance returned from a query.

  Fields:

    * `:id` - a unique ID of the object instance in the database.
  """
  @type t() :: %{
          __struct__: __MODULE__,
          id: uuid() | nil
        }

  @typedoc since: "0.2.0"
  @typedoc """
  An immutable representation of an object instance returned from a query.
  """
  @opaque object :: %__MODULE__{
            id: uuid() | nil,
            __tid__: uuid() | nil,
            __fields__: %{String.t() => Field.t()},
            __order__: list(String.t())
          }

  defmodule Field do
    @moduledoc false

    defstruct [
      :name,
      :value,
      :is_link,
      :is_link_property,
      :is_implicit
    ]

    @type t() :: %__MODULE__{
            name: String.t(),
            value: any(),
            is_link: boolean(),
            is_link_property: boolean(),
            is_implicit: boolean()
          }
  end

  @doc since: "0.2.0"
  @doc """
  Get object fields names (properties, links and link propries) as list of strings.

  See `t:fields_option/0` for supported options.
  """
  @spec fields(object(), list(fields_option())) :: list(String.t())
  def fields(%__MODULE__{} = object, opts \\ []) do
    include_properies? = Keyword.get(opts, :properties, true)
    include_links? = Keyword.get(opts, :links, true)
    include_link_properties? = Keyword.get(opts, :link_propeties, true)
    include_id? = Keyword.get(opts, :id, false)
    include_implicits? = Keyword.get(opts, :implicit, false)

    object.__fields__
    |> Enum.filter(fn
      {"id", %Field{is_implicit: true}} ->
        include_id? or include_implicits?

      {_name, %Field{is_implicit: true}} ->
        include_implicits?

      {_name, %Field{is_link: true}} ->
        include_links?

      {_name, %Field{is_link_property: true}} ->
        include_link_properties?

      _other ->
        include_properies?
    end)
    |> Enum.map(fn {name, _field} ->
      name
    end)
  end

  @doc since: "0.2.0"
  @doc """
  Get object properties names as list.

  See `t:properties_option/0` for supported options.
  """
  @spec properties(object(), list(properties_option())) :: list(String.t())
  def properties(%__MODULE__{} = object, opts \\ []) do
    fields(object, Keyword.merge(opts, links: false, link_properties: false))
  end

  @doc since: "0.2.0"
  @doc """
  Get object links names as list.
  """
  @spec links(object()) :: list(String.t())
  def links(%__MODULE__{} = object) do
    fields(object, properties: false, link_properties: false)
  end

  @doc since: "0.2.0"
  @doc """
  Get object link propeties names as list.
  """
  @spec link_properties(object()) :: list(String.t())
  def link_properties(%__MODULE__{} = object) do
    fields(object, properties: false, links: false)
  end

  @impl Access
  def fetch(%__MODULE__{} = object, key) when is_atom(key) do
    fetch(object, Atom.to_string(key))
  end

  @impl Access
  def fetch(%__MODULE__{__fields__: fields}, key) when is_binary(key) do
    case fields do
      %{^key => %Field{value: value}} ->
        {:ok, value}

      _other ->
        :error
    end
  end

  @impl Access
  def get_and_update(%__MODULE__{}, _key, _function) do
    raise EdgeDB.Error.interface_error("objects can't be mutated")
  end

  @impl Access
  def pop(%__MODULE__{}, _key) do
    raise EdgeDB.Error.interface_error("objects can't be mutated")
  end
end

defimpl Inspect, for: EdgeDB.Object do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.Object{__fields__: fields, __order__: order}, opts) do
    visible_fields =
      Enum.reject(order, fn name ->
        fields[name].is_implicit
      end)

    fields_count = Enum.count(visible_fields)

    elements_docs =
      visible_fields
      |> Enum.with_index(1)
      |> Enum.map(fn
        {name, ^fields_count} ->
          concat([name, " := ", Inspect.inspect(fields[name].value, opts)])

        {name, _index} ->
          concat([name, " := ", Inspect.inspect(fields[name].value, opts), ", "])
      end)

    concat(["#EdgeDB.Object<", concat(elements_docs), ">"])
  end
end
