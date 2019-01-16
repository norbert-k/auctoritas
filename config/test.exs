use Mix.Config

config :logger, level: :error

config :auctoritas, :config,
       name: "auctoritas_default",
       data_storage: Auctoritas.AuthenticationManager.CachexDataStorage,
       token_manager: Auctoritas.AuthenticationManager.DefaultTokenManager,
       token_type: :sliding,
       expiration: 60 * 60 * 24,
       refresh_token_expiration: 60 * 60 * 24 * 3