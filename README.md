# Starchoice

[![Build Status](https://circleci.com/gh/nicklayb/starchoice.svg?style=svg)](https://circleci.com/gh/nicklayb/starchoice.svg)
[![Coverage Status](https://coveralls.io/repos/github/nicklayb/starchoice/badge.svg?branch=master)](https://coveralls.io/github/nicklayb/starchoice?branch=master)
[![Module Version](https://img.shields.io/hexpm/v/starchoice.svg)](https://hex.pm/packages/starchoice)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/starchoice/)
[![Total Download](https://img.shields.io/hexpm/dt/starchoice.svg)](https://hex.pm/packages/starchoice)
[![License](https://img.shields.io/hexpm/l/starchoice.svg)](https://github.com/nicklayb/starchoice/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/nicklayb/starchoice.svg)](https://github.com/nicklayb/starchoice/commits/master)

<!-- MDOC !-->

Starchoice takes his name from the satellite TV company (now called [Shaw Direct](https://en.wikipedia.org/wiki/Shaw_Direct)) because they are selling TV decoders. Since this lib is used to declare map decoders, I thought it felt appropriate to be named that way. Maybe not. Anyway.

The goal of the library is to provide a streamline process for converting String keyed maps to well defined structures. It is highly inspired by [Elm](https://elm-lang.org/)'s JSON decoders where you create different JSON decoders for the same data type.

For more information about creating decoder, visit the `Starchoice.Decoder` module documentation.

<!-- MDOC !-->

## Installation

```elixir
def deps do
  [
    {:starchoice, "~> 0.1.0"}
  ]
end
```

## Basic usage

Examples:
- [Snowhite](https://github.com/nicklayb/snowhite/tree/master/lib/open_weather): Snowhite uses Starchoice to decode HTTP responses from APIs.

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

  defdecoder :simple do
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
    %{"name" => "Articles", "access" => "rw"}
    %{"name" => "Settings", "access" => "r"}
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

## Polymorphic decoding

This is something that might become helpful. Have for an instance, an API that returns every results under a `results` key like `{"results": [{}, {}, ...]}`. It would be pretty useful to have a polymorphic decoder. It is supported out of the box by doing the following:

```elixir
defmodule Results do
  defstruct results: []

  def decoder(sub_type) do
    __MODULE__
    |> Starchoice.Decoder.new()
    |> Starchoice.Decoder.put_field(:results, sub_type)
  end
end
```

Then you can use it like that:

```elixir
input = %{"results" => [%{"email" => "email@email.com"}, %{"email" => "another_email@email.com"}]}
Starchoice.decode(input, Results.decoder({User, :simple})) # this uses the :simple decoder defined for User before.
%Results{
  results: %{
    %User{email: "email@email.com"},
    %User{email: "another_email@email.com"},
  }
}
```


## License

This source code is licensed under the [MIT license](https://github.com/nicklayb/starchoice/blob/master/LICENSE). Copyright (c) 2020-present Nicolas Boisvert.
