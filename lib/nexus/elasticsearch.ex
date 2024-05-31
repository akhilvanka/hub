defmodule Nexus.Elasticsearch do
  @moduledoc """
  A module for interacting with an Elasticsearch instance to store job data
  """

  @doc """
  Pass a Jason.decode!(body) of a company's job data to this function to store it in Elasticsearch
  through a PUT request
  """
  @spec put(map) :: {:ok} | {:error, String.t}
  def put(job) do
    # id = job["id"]
    id = Map.get(job, "id")

    job = job
          |> clean_job()
          |> hash_job()

    ssl_config = ssl_config()
    auth = [{"Authorization", "Basic #{Base.encode64("#{Application.get_env(:nexus, :elasticsearch_username)}:#{Application.get_env(:nexus, :elasticsearch_password)}")}"}]

    unless check_id?(id, ssl_config, auth) do
      case HTTPoison.put("#{Application.get_env(:nexus, :elasticsearch_url)}/lever_jobs/_create/#{id}", Jason.encode!(job), [{"Content-Type", "application/json"} | auth], ssl: ssl_config) do
        {:ok, %HTTPoison.Response{status_code: 201}} -> {:ok}
        {:ok, %HTTPoison.Response{status_code: 409}} -> {:error, "Job already exists"}
        {:ok, %HTTPoison.Response{status_code: 401}} -> {:error, "Unauthorized"}
        {:error, %HTTPoison.Error{reason: reason}}   -> {:error, reason}
      end
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

  defp check_id?(id, ssl_opts, auth_headers) do
    case HTTPoison.head("#{Application.get_env(:nexus, :elasticsearch_url)}/lever_jobs/_doc/#{id}", auth_headers, ssl: ssl_opts) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> true
      {:ok, %HTTPoison.Response{status_code: 401}} -> false
      {:ok, %HTTPoison.Response{status_code: 404}} -> false
      {:error, _} -> false
    end
  end
end
