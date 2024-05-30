# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Nexus.Repo.insert!(%Nexus.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule Nexus.Seeds do
  @moduledoc """
  A simple module to define necessary functions to initially seed
  the database with company data
  """

  alias Nexus.{Company, Repo}

  require Logger

  @doc """
  Store the company name and a hash of it's JSON resonse in the database
  """
  def store({:ok, [company_name | _tail]}) do
    api_url = "https://api.lever.co/v0/postings/#{company_name}?mode=json"

    case HTTPoison.get(api_url) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        cached_hash = :crypto.hash(:sha256, body) |> Base.encode16()

        %Company{name: company_name, cached_hash: cached_hash}
        |> Repo.insert()

        body
        |> Jason.decode!()
        |> Enum.each(&Nexus.Elasticsearch.put/1)

      {:ok, %HTTPoison.Response{body: _body, status_code: 404}} ->
        Logger.error("Company not found: #{company_name}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to fetch company data for #{company_name}: #{reason}")
    end
  end


  def store({:error, reason}),
    do: Logger.error("Failed to decode CSV row for #{reason}")

end

# Read the CSV file and store the company data
File.stream!("priv/repo/seeds.csv")
  |> CSV.decode()
  |> Enum.each(&Nexus.Seeds.store/1)
