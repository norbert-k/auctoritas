defmodule AuctoritasTest.TokenGeneratorTest do
  use ExUnit.Case, async: true
  doctest Auctoritas

  alias Auctoritas.TokenGenerator

  test "generates default size token" do
    assert String.length(TokenGenerator.generate_token()) == 64
  end

  test "generates custom length token" do
    1..10
    |> Enum.each(fn(_) ->
      random_number = :rand.uniform(64)
      expected_length = random_number * 2
      assert String.length(TokenGenerator.generate_token(random_number)) == expected_length
    end)
  end
end