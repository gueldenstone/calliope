Mix.install([
  {:emlx, github: "elixir-nx/emlx", branch: "main"},
  {:bumblebee, "~> 0.6.0"}
])

Nx.global_default_backend(EMLX.Backend)

{:ok, model_info} =
  Bumblebee.load_model({:hf, "mlx-community/nomicai-modernbert-embed-base-4bit"},
    module: Bumblebee.Text.Bert
  )

{:ok, tokenizer} =
  Bumblebee.load_tokenizer({:hf, "mlx-community/nomicai-modernbert-embed-base-4bit"},
    type: :bert
  )

defmodule Distance do
  import Nx.Defn

  @doc """
  Computes the cosine distance between two Nx tensors.
  Cosine distance = 1 - cosine similarity
  """
  defn cosine_distance(x, y) do
    dot_product = Nx.dot(x, y)
    norm_x = Nx.LinAlg.norm(x)
    norm_y = Nx.LinAlg.norm(y)
    cosine_similarity = dot_product / (norm_x * norm_y)
    cosine_similarity
  end
end

# text1 =
#   "We’re excited to announce the launch of our new AI-powered analytics dashboard. Designed for enterprise users, the dashboard offers real-time insights, customizable visualizations, and seamless integration with existing data pipelines. The beta release is now available to select partners, with general availability expected next quarter."

# text2 =
#   "The analytics team has completed the initial rollout of the new dashboard for enterprise clients. This tool provides real-time data views, flexible charting options, and integrates with current infrastructure. Feedback from early users will guide improvements before the full release next quarter."
#

text1 = "aaaaaaaaaaaaaaaaa"
text2 = "zzzzzzzzzzzzzzzzz"

serving = Bumblebee.Text.text_embedding(model_info, tokenizer)

embedding1 = Nx.Serving.run(serving, text1)
embedding2 = Nx.Serving.run(serving, text2)

distance = Distance.cosine_distance(embedding1.embedding, embedding2.embedding) |> Nx.to_number()
IO.inspect(distance)
