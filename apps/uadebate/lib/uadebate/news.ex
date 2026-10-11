defmodule Uadebate.News do
  @moduledoc "The federation's news: drafts for content managers, published posts for everyone."
  import Ecto.Query

  alias Uadebate.News.Post
  alias Uadebate.Repo

  def list_published(opts \\ []) do
    from(p in Post, where: not is_nil(p.published_at), order_by: [desc: p.published_at])
    |> by_rubric(opts[:rubric])
    |> limit_to(opts[:limit])
    |> Repo.all()
  end

  def list_all do
    Repo.all(from p in Post, order_by: [desc_nulls_first: p.published_at, desc: p.updated_at])
  end

  def get_published(slug) do
    Repo.one(from p in Post, where: p.slug == ^slug and not is_nil(p.published_at))
  end

  def get!(id), do: Repo.get!(Post, id)

  def change(post \\ %Post{}, attrs \\ %{}), do: Post.changeset(post, attrs)

  def create(attrs, user_id) do
    %Post{author_user_id: user_id, editor_user_id: user_id}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def update(%Post{} = post, attrs, user_id) do
    post
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_change(:editor_user_id, user_id)
    |> Repo.update()
  end

  def publish(%Post{} = post, user_id) do
    post
    |> Ecto.Changeset.change(published_at: DateTime.utc_now(:second), editor_user_id: user_id)
    |> Repo.update()
  end

  def unpublish(%Post{} = post, user_id) do
    post
    |> Ecto.Changeset.change(published_at: nil, editor_user_id: user_id)
    |> Repo.update()
  end

  def count_drafts, do: Repo.aggregate(from(p in Post, where: is_nil(p.published_at)), :count)

  defp by_rubric(query, rubric) when rubric in [nil, ""], do: query
  defp by_rubric(query, rubric), do: from(p in query, where: p.rubric == ^rubric)

  defp limit_to(query, nil), do: query
  defp limit_to(query, n), do: from(p in query, limit: ^n)
end
