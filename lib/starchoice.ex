defmodule Starchoice do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")                                                                              |> Enum.fetch!(1)

  alias Starchoice.Decoder

  @type decoder :: Decoder.t() | function() | module() | {module(), atom()}

  @type decode_option :: {:as_map, boolean()}

  @doc """
  Decodes a map into a `{:ok, _} | {:error | _}` tuple format. It accepts the same options and parameters as `decode!/3`
  """
  @spec decode(any(), decoder(), [decode_option()]) :: {:ok, any()} | {:error, any()}
  def decode(item, decoder, options \\ []) do
    result = decode!(item, decoder, options)
    {:ok, result}
  rescue
    error ->
      {:error, error}
  end

  @doc """
  Decodes a map into according to the given decoder. A decoder can either be a `%Starchoice.Decoder{}`, a one or two arity function that returns a decoder or a module implementing `Starchoice.Decoder`.

  See module `Starchoice.Decoder` for more information about decoders.

  ## Examples

  ```elixir
  iex> decoder = %Decoder{struct: User, fields: [first_name: [], age: [with: &String.to_integer/1]]}
  iex> Decoder.decode!(%{"first_name" => "Bobby Hill", "age" => "13"}, decoder)
  %User{first_name: "Bobby Hill", age: 13}
  ```

  If the module `User` implements `Starchoice.Decoder`, it can be used directly

  ```elixir
  iex> Decoder.decode!(%{"first_name" => "Bobby Hill", "age" => "13"}, User)
  iex> Decoder.decode!(%{"first_name" => "Bobby Hill", "age" => "13"}, {User, :default}) # same as above
  ```
  """
  @spec decode!(any(), decoder(), [decode_option]) :: any()
  def decode!(items, decoder, options \\ [])

  def decode!(items, decoder, options) when is_list(items) do
    Enum.map(items, &decode!(&1, decoder, options))
  end

  def decode!(item, _decoder, _options) when is_nil(item), do: nil

  def decode!(item, %Decoder{fields: fields, struct: struct}, options) do
    fields =
      Enum.reduce(fields, %{}, fn {field, opts}, map ->
        source_name =
          opts
          |> Keyword.get(:source, field)
          |> to_string()

        value =
          item
          |> Map.get(source_name)
          |> decode_field!(field, opts, options)

        Map.put(map, field, value)
      end)

    if Keyword.get(options, :as_map, struct == :map) do
      fields
    else
      struct(struct, fields)
    end
  end

  def decode!(item, decoder, options) do
    case fetch_decoder(item, decoder, options) do
      %Decoder{} = decoder ->
        decode!(item, decoder, options)

      result ->
        result
    end
  end

  defp fetch_decoder(item, decoder, options) do
    case decoder do
      {decoder, sub_decoder} ->
        decoder.__decoder__(sub_decoder)

      decoder when is_atom(decoder) ->
        decoder.__decoder__(:default)

      func when is_function(func, 1) ->
        func.(item)

      func when is_function(func, 2) ->
        func.(item, options)
    end
  end

  defp decode_field!(nil, field, opts, _) do
    cond do
      Keyword.has_key?(opts, :default) ->
        Keyword.get(opts, :default)

      Keyword.get(opts, :required, false) ->
        raise "Field #{field} is marked as required"

      true ->
        nil
    end
  end

  defp decode_field!(value, _, opts, decode_options) do
    value = sanitize_field(value, opts)

    case Keyword.get(opts, :with) do
      nil ->
        value

      decoder ->
        decode!(value, decoder, decode_options)
    end
  end

  defp sanitize_field(value, opts) do
    case Keyword.get(opts, :sanitize, true) do
      true ->
        sanitize(value)

      func when is_function(func) ->
        func.(value)

      _ ->
        value
    end
  end

  defp sanitize(""), do: nil

  defp sanitize(str) when is_bitstring(str) do
    case String.trim(str) do
      "" ->
        nil

      str ->
        str
    end
  end

  defp sanitize(value), do: value
end
