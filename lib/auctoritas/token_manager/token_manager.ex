defmodule Auctoritas.TokenManager do
  @moduledoc """
  TokenManager module
  * Specifies `TokenManager` behaviour
  * Implements default `TokenManager` with `__using__` macro
  """

  @typedoc "Authentication token"
  @type token() :: String.t()

  @typedoc "Name from config (Auctoritas supervisor name)"
  @type name() :: String.t()

  @doc """
  Invoked when generating token from inserted `authentication_data`
  """
  @callback generate_token_and_data(name(), authentication_data :: map()) ::
              {:ok, token(), map()} | {:error, error :: any()}

  @doc """
  Invoked when generating token with :refresh_token config option
  """
  @callback generate_refresh_token(name(), authentication_data :: map()) ::
              {:ok, refresh_token :: token()} | {:error, error :: any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Auctoritas.TokenManager

      alias Auctoritas.TokenGenerator

      @type token() :: String.t()
      @type name() :: String.t()

      @spec generate_token_and_data(name(), authentication_data :: map()) ::
              {:ok, token(), map()} | {:error, error :: any()}
      def generate_token_and_data(_name, authentication_data)
          when is_bitstring(_name)
          when is_map(authentication_data) do
          {:ok, TokenGenerator.generate_token(), authentication_data}
      end

      @spec generate_refresh_token(name(), authentication_data :: map()) ::
              {:ok, token()} | {:error, error :: any()}
      def generate_refresh_token(_name, _authentication_data)
          when is_bitstring(_name)
          when is_map(_authentication_data) do
        {:ok, TokenGenerator.generate_token()}
      end


      defoverridable generate_token_and_data: 2,
                     generate_refresh_token: 2
    end
  end
end
