defmodule Starchoice.DecoderTest do
  use ExUnit.Case
  alias Starchoice.Decoder

  defmodule User do
    use Starchoice.Decoder

    defdecoder do
      field(:first_name)
    end

    defdecoder :other do
      field(:last_name)
    end

    defdecoder :sourced_fields do
      field(:username, source: :id)
    end
  end

  describe "defdecoder/1" do
    test "creates a default decoder" do
      decoder = %Decoder{
        fields: [first_name: []],
        struct: User
      }

      assert ^decoder = User.__decoder__()
      assert ^decoder = User.__decoder__(:default)
    end
  end

  describe "defdecoder/2" do
    test "creates a named decoder" do
      other = %Decoder{
        fields: [last_name: []],
        struct: User
      }

      assert ^other = User.__decoder__(:other)

      sourced_fields = %Decoder{
        fields: [username: [source: :id]],
        struct: User
      }

      assert ^sourced_fields = User.__decoder__(:sourced_fields)

      default = %Decoder{
        fields: [first_name: []],
        struct: User
      }

      assert ^default = User.__decoder__(:default)
      assert ^default = User.__decoder__()
    end
  end

  describe "init/2" do
    test "creates a decoder" do
      assert %Decoder{fields: [], struct: User} = Decoder.new(User)
      assert %Decoder{fields: [first_name: []], struct: User} = Decoder.new(User, first_name: [])
    end
  end

  describe "put_field/2" do
    test "put a field in the decoder" do
      decoder =
        User
        |> Decoder.new()
        |> Decoder.put_field(:first_name)
        |> Decoder.put_field(:last_name, with: &String.downcase/1)

      assert %Decoder{fields: [last_name: [with: _], first_name: []], struct: User} = decoder
    end
  end
end
