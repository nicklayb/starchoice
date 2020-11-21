defmodule Starchoice do
  alias Starchoice.Decoder

  @moduledoc """
  Starchoice takes his name from the satellite tv company (now called [Shaw Direct](https://en.wikipedia.org/wiki/Shaw_Direct)) because they are selling TV decoders. Since this lib is used to declare map decoders, I thought it felt appropriate to be named that way. Maybe not. Anyway.

  The goal of the library is to provide a streamline process for convertir String keyed maps to well defined structures. It is highly inspired by [Elm](https://elm-lang.org/)'s JSON decoders where you create different JSON decoders for the same data type.

  For more information about creating decoder, visit the `Starchoice.Decoder` module documentation.
  """

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
  Decodes a map into according to the given decoder. A decoder can either be a `%Starchoice.Decoder{}`, a one or two arity function or a module implementing `Starchoice.Decoder`.

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
        value =
          item
          |> Map.get(to_string(field))
          |> decode_field!(field, opts)

        Map.put(map, field, value)
      end)

    if Keyword.get(options, :as_map, false) do
      fields
    else
      struct(struct, fields)
    end
  end

  def decode!(item, {decoder, sub_decoder}, options) do
    decode!(item, decoder.__decoder__(sub_decoder), options)
  end

  def decode!(item, decoder, options) do
    cond do
      is_function(decoder, 2) ->
        decoder.(item, options)

      is_function(decoder, 1) ->
        decoder.(item)

      true ->
        decode!(item, {decoder, :default}, options)
    end
  end

  defp decode_field!(nil, field, opts) do
    cond do
      Keyword.has_key?(opts, :default) ->
        Keyword.get(opts, :default)

      Keyword.get(opts, :required, false) ->
        raise "Field #{field} is marked as required"

      true ->
        nil
    end
  end

  defp decode_field!(value, _, opts) do
    value =
      case Keyword.get(opts, :sanitize, true) do
        true ->
          sanitize(value)

        func when is_function(func) ->
          func.(value)

        _ ->
          value
      end

    case Keyword.get(opts, :with) do
      nil ->
        value

      decoder ->
        decode!(value, decoder)
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
