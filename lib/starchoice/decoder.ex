defmodule Starchoice.Decoder do
  defstruct struct: nil, fields: []

  alias __MODULE__

  @type decoder_struct :: module() | :map
  @type field_option ::
          {:required, boolean()}
          | {:with, Starchoice.decoder()}
          | {:default, any()}
          | {:sanitize, function()}
  @type field_definition :: {atom(), [field_option()]}
  @type t :: %Starchoice.Decoder{
          struct: module(),
          fields: [field_definition()]
        }
  @callback __decoder__(atom()) :: t()

  @spec __using__(any()) :: Macro.t()
  defmacro __using__(_) do
    quote do
      import Starchoice.Decoder
      @behaviour Starchoice.Decoder
      @before_compile Starchoice.Decoder
      @decoders %{}
    end
  end

  @spec decode(atom(), do: Macro.t()) :: Macro.t()
  defmacro decode(name \\ :default, do: block) do
    quote do
      @decoder Decoder.new(__MODULE__)
      unquote(block)
      @decoders Map.put(@decoders, unquote(name), @decoder)
    end
  end

  @spec field(atom(), [field_option()]) :: Macro.t()
  defmacro field(name, opts \\ []) do
    quote do
      @options unquote(opts)
      if Keyword.get(@options, :required, false) and
           Keyword.has_key?(@options, :default) do
        raise "Field #{unquote(name)} is marked as required but also has a default value"
      end

      @decoder Decoder.put_field(@decoder, unquote(name), @options)
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

  @spec new(decoder_struct(), [field_definition()]) :: t()
  def new(struct, fields \\ []) do
    %Decoder{fields: fields, struct: struct}
  end

  @spec put_field(t(), atom(), [field_option()]) :: t()
  def put_field(%Decoder{fields: fields} = decoder, field, options \\ []) do
    %Decoder{decoder | fields: [{field, options} | fields]}
  end
end
