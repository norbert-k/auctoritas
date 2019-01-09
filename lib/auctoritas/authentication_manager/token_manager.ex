defmodule Auctoritas.AuthenticationManager.TokenManager do
  alias Auctoritas.TokenGenerator

  @type token() :: String.t()

  @callback generate_token(any()) :: {atom(), token()}
  @spec generate_token(any()) :: {atom(), token()}
  def generate_token(data) do
    {:ok, TokenGenerator.generate_token()}
  end
end
