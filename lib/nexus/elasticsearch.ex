defmodule Nexus.Elasticsearch do
  @moduledoc """
  A module for interacting with an Elasticsearch instance to store job data
  """

  @es_url Application.get_env!(:nexus, :elasticsearch_url)
  @es_user Application.get_env!(:nexus, :elasticsearch_username)
  @es_pass Application.get_env!(:nexus, :elasticsearch_password)

  @doc """
  Pass a Jason.decode!(body) of a company's job data to this function to store it in Elasticsearch
  through a PUT request
  """
  @spec put(map) :: {:ok} | {:error, String.t}
  def put(job) do
    id = job["id"]

    job = job
          |> clean_job()
          |> hash_job()

    ssl_config = ssl_config()
    auth = [{"Authorization", "Basic #{Base.encode64("#{@es_user}:#{@es_pass}")}"}]

    case HTTPoison.put("#{@es_url}/lever_jobs/_create/#{id}", Jason.encode!(job), [{"Content-Type", "application/json"} | auth], ssl: ssl_config) do
      {:ok, %HTTPoison.Response{status_code: 201}} -> {:ok}
      {:ok, %HTTPoison.Response{status_code: 409}} -> {:error, "Job already exists"}
      {:error, %HTTPoison.Error{reason: reason}}   -> {:error, reason}
    end
  end

  defp ssl_config do
    cacertfile = "priv/certs/ca.crt"
    [
      verify: :verify_peer,
      cacertfile: cacertfile
    ]
  end

  defp clean_job(job) do
    job
    |> Map.drop(["description", "descriptionBody", "opening", "openingPlain", "additional"])
    |> update_in(["categories"], fn
      nil -> %{}
      categories -> Map.drop(categories, ["location"])
    end)
  end

  defp hash_job(job) do
    hash = :crypto.hash(:sha256, Jason.encode!(job))
           |> Base.encode16()
    Map.put(job, "hash", hash)
  end
end
