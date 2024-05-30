defmodule Nexus.Elasticsearch do

  @es_url Application.compile_env!(:nexus, :elasticsearch_url)
  @es_user Application.compile_env!(:nexus, :elasticsearch_username)
  @es_pass Application.compile_env!(:nexus, :elasticsearch_password)

  def put(job) do
    ssl_config = ssl_config()
    auth = basic_auth_header()

    case HTTPoison.put("#{@es_url}/lever_jobs/_create/#{job["id"]}", Jason.encode!(job), [{"Content-Type", "application/json"} | auth], ssl: ssl_config) do
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

  defp basic_auth_header do
    encoded_credentials = Base.encode64("#{@es_user}:#{@es_pass}")

    [{"Authorization", "Basic #{encoded_credentials}"}]
  end 

end
