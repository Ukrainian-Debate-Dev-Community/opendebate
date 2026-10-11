defmodule UadebateWeb.Manage.NewsController do
  use UadebateWeb, :controller

  alias Uadebate.News

  plug :put_view, UadebateWeb.Manage.HTML

  def index(conn, _params) do
    render(conn, :news_index, manage_active: :news, page_title: gettext("News"), posts: News.list_all())
  end

  def new(conn, _params) do
    render(conn, :news_form,
      manage_active: :news,
      page_title: gettext("Write news"),
      post: nil,
      form: to_form(News.change(), as: :post)
    )
  end

  def create(conn, %{"post" => attrs}) do
    case News.create(attrs, conn.assigns.manager.id) do
      {:ok, post} ->
        conn
        |> put_flash(:info, gettext("Saved as a draft."))
        |> redirect(to: ~p"/manage/news/#{post.id}/edit")

      {:error, changeset} ->
        render(conn, :news_form,
          manage_active: :news,
          page_title: gettext("Write news"),
          post: nil,
          form: to_form(changeset, as: :post)
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    post = News.get!(id)

    render(conn, :news_form,
      manage_active: :news,
      page_title: post.title,
      post: post,
      form: to_form(News.change(post), as: :post)
    )
  end

  def update(conn, %{"id" => id, "post" => attrs}) do
    post = News.get!(id)

    case News.update(post, attrs, conn.assigns.manager.id) do
      {:ok, post} ->
        conn
        |> put_flash(:info, gettext("Saved."))
        |> redirect(to: ~p"/manage/news/#{post.id}/edit")

      {:error, changeset} ->
        render(conn, :news_form,
          manage_active: :news,
          page_title: post.title,
          post: post,
          form: to_form(changeset, as: :post)
        )
    end
  end

  def publish(conn, %{"id" => id}) do
    {:ok, _} = News.publish(News.get!(id), conn.assigns.manager.id)

    conn
    |> put_flash(:info, gettext("Published: everyone can read it now."))
    |> redirect(to: ~p"/manage/news")
  end

  def unpublish(conn, %{"id" => id}) do
    {:ok, _} = News.unpublish(News.get!(id), conn.assigns.manager.id)

    conn
    |> put_flash(:info, gettext("Back to draft: only content managers see it."))
    |> redirect(to: ~p"/manage/news")
  end
end
