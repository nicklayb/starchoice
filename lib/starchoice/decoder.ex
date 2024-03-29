defmodule Starchoice.Decoder do
  defstruct struct: nil, fields: []

  @moduledoc """
  This module can be used from two different ways:
  - [As a macro](#as-a-macro)
  - [Manually](#manually)

  ## As a macro

  To be defining decoders as macro, you need to use the `Starchoice.Decoder` module in your struct. It's declaration is highly (like totally) inspired by [Ecto](https://hexdocs.pm/ecto)'s schemas.

  To see available options, take a look at `put_field/3`'s documentation

  ### Examples

  ```elixir
  defmodule User do
    use Starchoice.Decoder
    defstruct first_name: nil, age: nil

    defdecoder do
      field(:first_name)
      field(:age)
    end
  end

  User.__decoder__() # %Decoder{}
  User.__decoder__(:default) # %Decoder{}
  ```

  When you don't pass a name to the `defdecoder/2` function, it defaults to `default`. So calling `defdecoder do` and `defdecoder :default do` is identical. This is because you might be interested in creating multiple decoders for the same struct like below:

  ```elixir
  defmodule User do
    use Starchoice.Decoder
    defstruct first_name: nil, last_name: nil, email: nil, age: nil

    defdecoder do
      field(:first_name)
      field(:age)
    end

    defdecoder :full do
      field(:first_name)
      field(:last_name)
      field(:email)
      field(:age)
    end
  end

  User.__decoder__() # %Decoder{fields: [{:first_name, _}, {:age, _}]}
  User.__decoder__(:default) # %Decoder{fields: [{:first_name, _}, {:age, _}]}
  User.__decoder__(:full) # %Decoder{fields: [{:first_name, _}, {:last_name, _}, {:email, _}, {:age, _}]}
  ```

  And you can now use the module directly when calling `Starchoice.decode/3` like:

  ```elixir
  iex> Starchoice.decode(input, User)
  iex> Starchoice.decode(input, {User, :full})
  ```

  #### Source mapper

  While each field supports a `:source` option to specify what key to use in the
  parsed map, you can provide a module to perform the casting. If, as an example,
  the map is using `camelCaseKeys`, you can provide a source mapper that perform
  the appropriate conversion.

  ```elixir
  defmodule CamelCase do
    def map_source(field) do
      splitted =
        field
        |> to_string()
        |> String.split("_", parts: 2)

      case splitted do
        [key] -> key
        [head, rest] -> head <> Macro.camelize(rest)
      end
    end
  end

  defmodule User do
    defstruct [:first_name, :last_name]

    use Starchoice.Decoder, source_mapper: CamelCase

    defdecoder do
      field(:first_name)
      field(:last_name)
    end
  end

  iex> map = %{"firstName" => "Bobby", "lastName" => "Hill"}
  iex> Starchoice.decode(map, User)
  %User{first_name: "Bobby", last_name: "Hill"}

  iex> map = %{"first_name" => "Bobby", "last_name" => "Hill"}
  iex> Starchoice.decode(map, User)
  %User{first_name: nil, last_name: nil}
  ```

  Doing so is the same as adding individual `:source` option to each field.

  ## Manually

  You could also build decoder manually like the following:
  ```elixir
  defmodule User do
    defstruct email: nil, password: nil

    def mask_password(_), do: "MASKED"
  end

  User
  |> Decoder.new()
  |> Decoder.put_field(:email)
  |> Decoder.put_field(:password, with: &User.mask_password/1)

  # or

  Decoder.new(User, [
    {:email, []},
    {:password, with: &User.mask_password/1}
  ])
  ```

  To see available options, take a look at `put_field/3`'s documentation
  """

  alias __MODULE__

  @type decoder_struct :: module() | :map
  @type field_option ::
          {:required, boolean()}
          | {:with, Starchoice.decoder()}
          | {:default, any()}
          | {:sanitize, function()}
          | {:source, String.t()}
  @type using_option :: {:source_mapper, module()}
  @type field_definition :: {atom(), [field_option()]}
  @type t :: %Starchoice.Decoder{
          struct: module(),
          fields: [field_definition()]
        }
  @callback __decoder__(atom()) :: t()

  @spec __using__([using_option()]) :: Macro.t()
  defmacro __using__(opts) do
    source_mapper = Keyword.get(opts, :source_mapper)

    quote do
      import Starchoice.Decoder
      @behaviour Starchoice.Decoder
      @before_compile Starchoice.Decoder
      @decoders %{}
      @source_mapper unquote(source_mapper)
    end
  end

  @spec defdecoder(atom(), do: Macro.t()) :: Macro.t()
  defmacro defdecoder(name \\ :default, do: block) do
    quote do
      @decoder Decoder.new(__MODULE__)
      unquote(block)
      @decoders Map.put(@decoders, unquote(name), @decoder)
    end
  end

  @spec field(atom(), [field_option()]) :: Macro.t()
  defmacro field(name, opts \\ []) do
    quote do
      name = unquote(name)
      options = Decoder.put_source_option(name, unquote(opts), @source_mapper)

      if Keyword.get(options, :required, false) and
           Keyword.has_key?(options, :default) do
        raise "Field #{name} is marked as required but also has a default value"
      end

      @decoder Decoder.put_field(@decoder, name, options)
    end
  end

  @spec __before_compile__(any()) :: Macro.t()
  defmacro __before_compile__(_) do
    quote do
      def __decoder__, do: __decoder__(:default)

      def __decoder__(name) do
        Map.get(@decoders, name)
      end
    end
  end

  @doc """
  Initiates a new Decoder, you can pass a list of fields with options.

  To see available options, take a look at `put_field/3`'s documentation
  """
  @spec new(decoder_struct(), [field_definition()]) :: t()
  def new(struct, fields \\ []) do
    fields =
      Enum.map(fields, fn
        field when is_atom(field) ->
          {field, []}

        field ->
          field
      end)

    %Decoder{fields: fields, struct: struct}
  end

  @doc """
  Puts a field decoding in the decoder. Available options are:

  - `:required`: Defines if a field is required, will caused a raise (or `{:error, _}` tuple) when the required field isn't present
  - `:default`: Specifies a fallback value in case the field is missing (can't be used with `required: true`)
  - `:with`: Specifies a decoder the decode the given field. Like the `Starchoice.decode/3` call, it can support any valid decoder in `Module`, `{Module, :decoder}` and a function.
  - `:sanitize`: Specifies a sanitizer. By default, the value is sanitized by trimming the value and casting to nil if the value is "". Can either be a boolean or a function.
  - `:source`: Specifies the source key in the decoding item
  """
  @spec put_field(t(), atom(), [field_option()]) :: t()
  def put_field(%Decoder{fields: fields} = decoder, field, options \\ []) do
    %Decoder{decoder | fields: [{field, options} | fields]}
  end

  @doc "Puts source option casted from source mapper"
  @spec put_source_option(atom(), [field_option()], module() | nil) :: String.t() | atom()
  def put_source_option(_name, options, nil), do: options

  def put_source_option(name, options, source_mapper) do
    Keyword.put_new_lazy(options, :source, fn ->
      source_mapper.map_source(name)
    end)
  end
end
