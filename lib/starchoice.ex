defmodule Starchoice do
  alias Starchoice.Decoder

  @type decoder :: Decoder.t() | function() | module() | {module(), atom()}

  @spec decode(any(), decoder()) :: {:ok, any()} | {:error, any()}
  def decode(item, decoder, options \\ []) do
    result = decode!(item, decoder, options)
    {:ok, result}
  rescue
    error ->
      {:error, error}
  end

  @spec decode!(any(), decoder()) :: any()
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
