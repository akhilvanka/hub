defmodule Nexus.Elasticsearch do

  @es_url Application.get_env(:nexus, :elasticsearch_url)

  def put(job) do
    ssl_config = ssl_config()

    case HTTPoison.put("#{@es_url}/_create/#{job["id"]}", Jason.encode!(job), [{"Content-Type", "application/json"}], ssl: ssl_config) do
      {:ok, %HTTPoison.Response{status_code: 201}} -> {:ok}
      {:ok, %HTTPoison.Response{status_code: 409}} -> {:error, "Job already exists"}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
    end
  end

  defp ssl_config do
    [
      hackney: [
        ssl_options: [
          cacertfile: "priv/certs/ca.crt"
        ]
      ]
    ]
  end

end
