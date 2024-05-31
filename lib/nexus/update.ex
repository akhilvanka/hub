defmodule Nexus.Update do
  @moduledoc """
  A module to update the company data in the database, fetching any new jobs
  """

  alias Nexus.{Company, Repo}
  require Logger

  @doc """
  Run through every company and fetch the latest data from the Lever API. Compare the hash of the new data
  with the cached hash in the database and update the database if the hashes differ
  """
  def run_update do
    Logger.info("Running update")
    companies = Repo.all(Company)

    Enum.each(companies, fn company ->
      process_company(company)
    end)
  end

  defp process_company(%Company{name: company_name, cached_hash: cached_hash}) do
    api_url = "https://api.lever.co/v0/postings/#{company_name}?mode=json"

    case HTTPoison.get(api_url) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        new_hash = :crypto.hash(:sha256, body) |> Base.encode16()

        if new_hash != cached_hash do
          Logger.info("Updating company: #{company_name}")
          update_hash(company_name, new_hash)
          Nexus.Elasticsearch.put(body)
        end

      {:ok, %HTTPoison.Response{body: _body, status_code: 404}} -> {:error, "Company not found: #{company_name}"}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, "Failed to fetch company data for #{company_name}: #{reason}"}
    end
  end

  defp update_hash(name, hash) do
    case Repo.get(Company, name) do
      nil -> {:error, "Company not found"}
      company ->
        changeset = Company.changeset(company, %{cached_hash: hash})
        case Repo.update(changeset) do
          {:ok, _} -> {:ok}
          {:error, changeset} -> {:error, "Failed to update company: #{inspect(changeset)}"}
        end
    end
  end

end
