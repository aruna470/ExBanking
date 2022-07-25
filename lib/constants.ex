defmodule ExBanking.Constants do
  @moduledoc """
    Maintain application constants that can be
    used within any module

  """

    # ETS table names
    def table_name, do: :bank_account
    def throttle_table_name, do: :throttle

    # Maximum number of concurrent requests for user
    def max_concurrent_requests, do: 10
end