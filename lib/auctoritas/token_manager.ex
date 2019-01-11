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
  @callback generate_token(name(), authentication_data :: map()) ::
              {:ok, token()} | {:error, error :: any()}

  @doc """
  Invoked when generating token with :refresh_token config option
  """
  @callback generate_refresh_token(name(), authentication_data :: map()) ::
              {:ok, token()} | {:error, error :: any()}

  @doc """
  Invoked when authenticating; checks supplied `authentication_data`
  """
  @callback authentication_data_check(name(), authentication_data :: map()) ::
              {:ok, authentication_data :: map()} | {:error, error :: any()}

  @doc """
  Invoked when authenticating; checks `supplied data`
  """
  @callback data_check(name(), data :: map()) ::
              {atom(), any()} :: {:ok, data :: map()} | {:error, error :: any()}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Auctoritas.TokenManager

      alias Auctoritas.TokenGenerator

      @type token() :: String.t()
      @type name() :: String.t()

      @spec generate_token(name(), authentication_data :: map()) ::
              {:ok, token()} | {:error, error :: any()}
      def generate_token(_name, _authentication_data)
          when is_bitstring(_name)
          when is_map(_authentication_data) do
        {:ok, TokenGenerator.generate_token()}
      end

      @spec generate_refresh_token(name(), authentication_data :: map()) ::
              {:ok, token()} | {:error, error :: any()}
      def generate_refresh_token(_name, _authentication_data)
          when is_bitstring(_name)
          when is_map(_authentication_data) do
        {:ok, TokenGenerator.generate_token()}
      end

      @spec authentication_data_check(name(), authentication_data :: map()) ::
              {:ok, authentication_data :: map()} | {:error, error :: any()}
      def authentication_data_check(name, data) when is_bitstring(name) and is_map(data) do
        {:ok, data}
      end

      @spec data_check(name(), data :: map()) ::
              {atom(), any()} :: {:ok, data :: map()} | {:error, error :: any()}
      def data_check(name, data) when is_bitstring(name) and is_map(data) do
        {:ok, data}
      end

      defoverridable generate_token: 2,
                     generate_refresh_token: 2,
                     authentication_data_check: 2,
                     data_check: 2
    end
  end
end
