defmodule Auctoritas.AuthenticationManager.TokenManager do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Auctoritas.TokenManager

      alias Auctoritas.TokenGenerator
      alias Auctoritas.AuthenticationManager.DataStorage

      @type token() :: String.t()
      @type name() :: String.t()

      @spec generate_token(name(), map()) :: {atom(), token()}
      def generate_token(_name, _data) do
        {:ok, TokenGenerator.generate_token()}
      end

      @spec datamanager(name()) :: {atom(), DataStorage}
      def datamanager(name) when is_bitstring(name) do
        {:ok, DataStorage}
      end

      @spec authentification_data_check(name(), map()) :: {atom(), any()}
      def authentification_data_check(name, data) when is_bitstring(name) and is_map(data) do
        {:ok, data}
      end

      @spec data_check(name(), map()) :: {atom(), any()}
      def data_check(name, data) when is_bitstring(name) and is_map(data) do
        {:ok, data}
      end
    end
  end
end
