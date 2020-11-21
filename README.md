# Starchoice

Starchoice takes his name from the satellite tv company (now called [Shaw Direct](https://en.wikipedia.org/wiki/Shaw_Direct)) because they are selling TV decoders. Since this lib is used to declare map decoders, I thought it felt appropriate to be named that way. Maybe not. Anyway.

The goal of the library is to provide a streamline process for convertir String keyed maps to well defined structures. It is highly inspired by [Elm](https://elm-lang.org/)'s JSON decoders where you create different JSON decoders for the same data type.

For more information about creating decoder, visit the `Starchoice.Decoder` module documentation.

## Installation

```elixir
def deps do
  [
    {:starchoice, "~> 0.1.0"}
  ]
end
```

## Basic usage

### Define decoders

You can define decoders in your struct's module by doing the following (this is the macro approach).

```elixir
defmodule User do
  defstruct email: nil, password: nil, profile: nil, permissions: []
  use Starchoice.Decoder

  defdecoder do
    field(:email, with: &String.downcase/1)
    field(:password)
    field(:profile, with: Profile)
    field(:permissions, with: {Permission, :simple})
  end

  defdecoder :simple do
    field(:email)
  end
end

defmodule Profile do
  defstruct address: nil

  defdecoder do
    field(:address)
  end
end

defmodule Permission do
  defstruct name: nil, access: nil

  defdecoder do
    field(:name)
    field(:access, with: &Permission.decode_access/1)
  end

  def decode_access("r"), do: :read
  def decode_access("w"), do: :write
  def decode_access("rw"), do: :full
end
```

We can now easily decode map payloads:

```elixir
input = %{
  "email" => "NICOLAS@nboisvert.com",
  "password" => "noneofyourbusiness",
  "profile" => %{
    "address" => "Somewhere str."
  },
  "permissions" => [
    %{"name" => "Articles", access: "rw"}
    %{"name" => "Settings", access: "r"}
  ]
}
{:ok, decoded} = Starchoice.decode(input, User)
%User{
  email: "nicolas@nboisvert.com",
  password: "noneofyourbusiness",
  profile: %Profile{
    address: "Somewhere str."
  },
  permissions: [
    %Permission{name: "Articles", access: :full},
    %Permission{name: "Settings", access: :read},
  ]
}
```

The basic of this can easily be achieved by using Ecto. However, for building a HTTP client or packaging lib, it might be a bit overkill to import a whole library like Ecto. This lightweight package can be pretty handy and is quite extensible.

