defmodule Auctoritas.TokenGenerator do
  @moduledoc """
  Manages token generation
  """

  @doc """
  Generates a random hexadecimal string to use as a authentication token

  ## Examples
      iex> Auctoritas.TokenManager.generate_token()
      "nD3xJccmcHsm6F3cBt3yx6oVr2brCmotrSRXnI3sITo="
  """
  @spec generate_token() :: String.t()
  def generate_token() do
    generate_token(32)
  end

  @doc """
  Generates a random hexadecimal string to use as a authentication token

  Argument length specifies length of the generated random number in bytes (then converted to hex)

  ## Examples
      iex> Auctoritas.TokenManager.generate_token(32)
      "iuwBlPj5q/BYazWH1dr12mja3Q7ZvRV122PuTKIaywg="
  """
  @spec generate_token(non_neg_integer()) :: String.t()
  def generate_token(length) when is_number(length) do
    SecureRandom.hex(length)
  end
end
