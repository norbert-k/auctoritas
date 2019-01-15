defmodule AuctoritasTest do
  use ExUnit.Case

  alias Auctoritas.AuthenticationSupervisor
  alias Auctoritas.Config

  setup_all do
    IO.puts("Starting Auctoritas supervisors")
    AuthenticationSupervisor.start_link(Config.new(name: "static", token_type: :static))
    AuthenticationSupervisor.start_link(Config.new(name: "sliding", token_type: :sliding))

    AuthenticationSupervisor.start_link(
      Config.new(name: "refresh_token", token_type: :refresh_token)
    )

    AuthenticationSupervisor.start_link(
      Config.new(name: "list_token", token_type: :refresh_token)
    )

    :ok
  end

  test "Default config test" do
    auth_data = %{user_id: 1}
    {:ok, token, data} = Auctoritas.authenticate(auth_data)

    {:ok, got_data} = Auctoritas.get_token_data(token)

    assert got_data.data == data.data

    {:ok, true} = Auctoritas.deauthenticate(token, :token)

    {:error, error} = Auctoritas.get_token_data(token)
  end

  test "Static token test" do
    auth_data = %{user_id: 1}
    {:ok, token, data} = Auctoritas.authenticate("static", auth_data)

    {:ok, got_data} = Auctoritas.get_token_data("static", token)

    assert got_data.data == data.data

    {:ok, true} = Auctoritas.deauthenticate("static", token, :token)

    {:error, error} = Auctoritas.get_token_data("static", token)
  end

  test "Sliding token test" do
    auth_data = %{user_id: 1}
    {:ok, token, data} = Auctoritas.authenticate("sliding", auth_data)

    {:ok, got_data} = Auctoritas.get_token_data("sliding", token)

    assert got_data.data == data.data

    {:ok, true} = Auctoritas.deauthenticate("sliding", token, :token)

    {:error, error} = Auctoritas.get_token_data("sliding", token)
  end

  test "Refresh token test" do
    auth_data = %{user_id: 1}

    {:ok, token, refresh_token, data, auth_data} =
      Auctoritas.authenticate("refresh_token", auth_data)

    {:ok, got_data} = Auctoritas.get_token_data("refresh_token", token)

    assert got_data.data == data.data

    {:ok, true} = Auctoritas.deauthenticate("refresh_token", token, :token)

    {:ok, new_token, refresh_token, data, auth_data} =
      Auctoritas.refresh_token("refresh_token", refresh_token)

    {:ok, got_data} = Auctoritas.get_token_data("refresh_token", new_token)

    assert got_data.data == data.data

    {:ok, true} = Auctoritas.deauthenticate("refresh_token", refresh_token, :refresh_token)

    {:error, error} = Auctoritas.refresh_token("refresh_token", refresh_token)

    for _x <- 1..1000 do
      Auctoritas.authenticate("refresh_token", auth_data)
    end

    {:ok, all_tokens} = Auctoritas.get_tokens("refresh_token", 0, 1000)
    assert length(all_tokens) == 1000

    {:ok, all_tokens_with_data} = Auctoritas.get_tokens_with_data("refresh_token", 0, 1000)
    assert length(all_tokens_with_data) == 1000

    {:ok, all_refresh_tokens} = Auctoritas.get_refresh_tokens("refresh_token", 0, 1000)
    assert length(all_refresh_tokens) == 1000
  end

  test "Get all tokens" do
    auth_data = %{user_id: 1}

    for _x <- 1..1000 do
      Auctoritas.authenticate("list_token", auth_data)
    end

    {:ok, all_tokens} = Auctoritas.get_tokens("list_token", 0, 1000)
    assert length(all_tokens) == 1000

    {:ok, all_tokens_with_data} = Auctoritas.get_tokens_with_data("list_token", 0, 1000)
    assert length(all_tokens_with_data) == 1000
  end
end
