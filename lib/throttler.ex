defmodule ExBanking.Throttler do
  @moduledoc """
    This module keep track of concurrent requests to each user
  """
    alias ExBanking.Constants

    @throttle_table_name Constants.throttle_table_name
    @max_count Constants.max_concurrent_requests

    @doc """
    Increase the concurrent request counter of the user

    Returns

    ## Parameters

        - name: string Name of the user

    """
    def increment_counter(name) do
        case :ets.lookup(@throttle_table_name, name) do
            [] ->
                :ets.insert(@throttle_table_name, {name, 1})
            [{name, counter}] ->
                :ets.insert(@throttle_table_name, {name, counter + 1})
        end
    end

    @doc """
    Decrease the concurrent request counter of the user

    Returns

    ## Parameters

        - name: string Name of the user

    """
    def decrease_counter(name) do
        case :ets.lookup(@throttle_table_name, name) do
            [{name, counter}] ->
                counter = counter - 1
                if counter == 0 do
                    :ets.delete(@throttle_table_name, name)
                else 
                    :ets.insert(@throttle_table_name, {name, counter})
                end
            _ ->
                :do_nothing
        end
    end

    @doc """
    Check whether it exceeded the given concurrent request limit
    for the user

    Returns: :yes | :no

    ## Parameters

        - name: string Name of the user

    """
    def is_throttled(name) do
        case :ets.lookup(@throttle_table_name, name) do
            [{_name, counter}] ->
                if counter < @max_count do
                    :no
                else 
                    :yes
                end
            _ ->
                :no
        end
    end
end