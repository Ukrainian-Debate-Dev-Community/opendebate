defmodule Uadebate.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ~w(tournament training club other)
  @visibilities ~w(public private)
  @languages ~w(uk en other)

  schema "events" do
    field :title, :string
    field :kind, :string, default: "tournament"
    field :starts_on, :date
    field :ends_on, :date
    field :city, :string
    field :format, :string
    field :details, :string
    field :link, :string
    # uk, en or other; language_other names it (Polish) only for other
    field :language, :string
    field :language_other, :string
    # private events exist only under /manage
    field :visibility, :string, default: "public"
    field :created_by_user_id, :integer

    timestamps(type: :utc_datetime)
  end

  def kinds, do: @kinds
  def languages, do: @languages

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :kind,
      :starts_on,
      :ends_on,
      :city,
      :format,
      :details,
      :link,
      :visibility,
      :language,
      :language_other
    ])
    |> validate_required([:title, :kind, :starts_on, :visibility])
    |> validate_inclusion(:kind, @kinds)
    |> validate_inclusion(:language, @languages)
    |> clear_language_other()
    |> validate_length(:language_other, max: 60)
    |> validate_inclusion(:visibility, @visibilities)
    |> validate_format(:link, ~r{^https?://}, message: "must start with http:// or https://")
    |> validate_end()
  end

  defp clear_language_other(changeset) do
    if get_field(changeset, :language) == "other",
      do: changeset,
      else: put_change(changeset, :language_other, nil)
  end

  defp validate_end(changeset) do
    with %Date{} = from <- get_field(changeset, :starts_on),
         %Date{} = to <- get_field(changeset, :ends_on),
         :lt <- Date.compare(to, from) do
      add_error(changeset, :ends_on, "must not be before the start")
    else
      _ -> changeset
    end
  end
end
