defmodule StarchoiceTest do
  use ExUnit.Case

  defmodule Profile do
    use Starchoice.Decoder
    defstruct address: nil, zip_code: nil

    defdecoder :basic do
      field(:address)
      field(:zip_code, sanitize: &Profile.escape/1)
    end

    def escape(value), do: String.replace(value, " ", "")
  end

  defmodule Post do
    use Starchoice.Decoder
    defstruct title: nil, body: nil

    defdecoder do
      field(:title)
      field(:body, default: "Coming soon...")
    end
  end

  defmodule User do
    use Starchoice.Decoder
    defstruct id: nil, name: nil, age: nil, posts: [], profile: nil

    defdecoder do
      field(:id, required: true)
      field(:name, sanitize: false)
      field(:age, with: &String.to_integer/1)
      field(:posts, with: Post)
      field(:profile, with: {Profile, :basic})
    end
  end

  setup do
    %{
      input: %{
        "name" => "Bobby Hill  ",
        "age" => "13",
        "id" => 1,
        "posts" => [
          %{"title" => "  Some title  "},
          %{"title" => "Other title", "body" => "Grown up in saint-hyrène"}
        ],
        "profile" => %{
          "zip_code" => "A1A 1A1"
        }
      }
    }
  end

  describe "decode!/3" do
    test "decodes a struct successfully", %{input: input} do
      assert %User{
               name: "Bobby Hill  ",
               age: 13,
               id: 1,
               posts: [
                 %Post{title: "Some title", body: "Coming soon..."},
                 %Post{title: "Other title", body: "Grown up in saint-hyrène"}
               ],
               profile: %Profile{address: nil, zip_code: "A1A1A1"}
             } = Starchoice.decode!(input, User)
    end

    test "decodes a map successfully", %{input: input} do
      assert %{
               name: "Bobby Hill  ",
               age: 13,
               id: 1,
               posts: [
                 %{title: "Some title", body: "Coming soon..."},
                 %{title: "Other title", body: "Grown up in saint-hyrène"}
               ],
               profile: %{address: nil, zip_code: "A1A1A1"}
             } = Starchoice.decode!(input, User, as_map: true)
    end

    test "decodes with a function" do
      assert %User{name: "Nop"} = Starchoice.decode!(%{}, fn _, _ -> %User{name: "Nop"} end)
    end

    test "raises when required field missing" do
      assert_raise(RuntimeError, fn ->
        Starchoice.decode!(%{}, User)
      end)
    end
  end

  describe "decode/3" do
    test "returns error instead of raising" do
      assert {:error, _} = Starchoice.decode(%{}, User)
    end

    test "decodes a struct successfully", %{input: input} do
      assert {:ok,
              %User{
                name: "Bobby Hill  ",
                age: 13,
                id: 1,
                posts: [
                  %Post{title: "Some title", body: "Coming soon..."},
                  %Post{title: "Other title", body: "Grown up in saint-hyrène"}
                ],
                profile: %Profile{address: nil, zip_code: "A1A1A1"}
              }} = Starchoice.decode(input, User)
    end
  end
end
