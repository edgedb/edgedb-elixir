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
  iex(3)> object.id
  "44f330d1-741d-11ec-9526-a39dc731bdc7"
  iex(4)> object[:name]
  "std::Object"
  iex(5)> object["name"]
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
    :__tid__,
    :id
  ]

  @typedoc """
  UUID value.
  """
  @type uuid() :: String.t()

  @typedoc """
  An immutable representation of an object instance returned from a query.

  Fields:

    * `:id` - a unique ID of the object instance in the database.
  """
  @type t() :: %{
          __struct__: __MODULE__,
          id: uuid() | nil
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

  @impl Access
  def fetch(%__MODULE__{} = object, key) when is_atom(key) do
    fetch(object, Atom.to_string(key))
  end

  @impl Access
  def fetch(%__MODULE__{__fields__: fields}, key) do
    case find_field(fields, key) do
      nil ->
        :error

      field ->
        {:ok, field.value}
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

  defp find_field(fields, name_to_find) do
    Enum.find(fields, fn %{name: name} ->
      name == name_to_find
    end)
  end
end

defimpl Inspect, for: EdgeDB.Object do
  import Inspect.Algebra

  @impl Inspect
  def inspect(%EdgeDB.Object{__fields__: fields}, opts) do
    visible_fields =
      Enum.reject(fields, fn %EdgeDB.Object.Field{is_implicit: implicit?} ->
        implicit?
      end)

    fields_count = Enum.count(visible_fields)

    elements_docs =
      visible_fields
      |> Enum.with_index(1)
      |> Enum.map(fn
        {%EdgeDB.Object.Field{name: name, value: value}, ^fields_count} ->
          concat([name, " := ", Inspect.inspect(value, opts)])

        {%EdgeDB.Object.Field{name: name, value: value}, _index} ->
          concat([name, " := ", Inspect.inspect(value, opts), ", "])
      end)

    concat(["#EdgeDB.Object<", concat(elements_docs), ">"])
  end
end
