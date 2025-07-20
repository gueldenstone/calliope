defmodule Storyteller.EmbeddingsService do
  @moduledoc """
  GenServer for managing the embeddings service lifecycle.

  This module handles:
  - Initialization of the MLX model and tokenizer
  - Providing access to the serving function
  - Graceful shutdown and error handling
  """

  use GenServer
  require Logger

  @doc """
  Starts the embeddings service.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Gets the current serving function for embeddings.
  Returns {:ok, serving} or {:error, reason}
  """
  def get_serving do
    GenServer.call(__MODULE__, :get_serving)
  end

  @doc """
  Checks if the embeddings service is ready.
  """
  def ready? do
    GenServer.call(__MODULE__, :ready?)
  end

  # GenServer callbacks

  @impl true
  def init(_args) do
    Logger.info("Starting embeddings service...")

    # Start initialization asynchronously to avoid blocking the application startup
    Process.send_after(self(), :init_embeddings, 0)

    {:ok, %{model_info: nil, tokenizer: nil, serving: nil, ready: false}}
  end

  @impl true
  def handle_info(:init_embeddings, _state) do
    case Storyteller.Embeddings.init_embeddings() do
      {:ok, {model_info, tokenizer, serving}} ->
        Logger.info("Embeddings service started successfully")
        {:noreply, %{model_info: model_info, tokenizer: tokenizer, serving: serving, ready: true}}

      {:error, reason} ->
        Logger.error("Failed to start embeddings service: #{inspect(reason)}")
        # Retry after a delay
        Process.send_after(self(), :retry_init, 5000)
        {:noreply, %{model_info: nil, tokenizer: nil, serving: nil, ready: false}}
    end
  end

  @impl true
  def handle_call(:get_serving, _from, %{serving: serving, ready: true} = state) do
    {:reply, {:ok, serving}, state}
  end

  @impl true
  def handle_call(:get_serving, _from, %{ready: false} = state) do
    {:reply, {:error, "Embeddings service not ready"}, state}
  end

  @impl true
  def handle_call(:ready?, _from, %{ready: ready} = state) do
    {:reply, ready, state}
  end

  @impl true
  def handle_info(:retry_init, _state) do
    Logger.info("Retrying embeddings service initialization...")

    case Storyteller.Embeddings.init_embeddings() do
      {:ok, {model_info, tokenizer, serving}} ->
        Logger.info("Embeddings service started successfully on retry")
        {:noreply, %{model_info: model_info, tokenizer: tokenizer, serving: serving, ready: true}}

      {:error, reason} ->
        Logger.error("Failed to start embeddings service on retry: #{inspect(reason)}")
        # Retry again after a longer delay
        Process.send_after(self(), :retry_init, 10000)
        {:noreply, %{model_info: nil, tokenizer: nil, serving: nil, ready: false}}
    end
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("Embeddings service shutting down")
    :ok
  end
end
