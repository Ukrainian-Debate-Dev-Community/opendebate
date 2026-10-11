defmodule Uadebate.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ~w(tournament training club other)
  @visibilities ~w(public private)

  schema "events" do
    field :title, :string
    field :kind, :string, default: "tournament"
    field :starts_on, :date
    field :ends_on, :date
    field :city, :string
    field :format, :string
    field :details, :string
    field :link, :string
    # private events exist only under /manage
    field :visibility, :string, default: "public"
    field :created_by_user_id, :integer

    timestamps(type: :utc_datetime)
  end

  def kinds, do: @kinds

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :kind, :starts_on, :ends_on, :city, :format, :details, :link, :visibility])
    |> validate_required([:title, :kind, :starts_on, :visibility])
    |> validate_inclusion(:kind, @kinds)
    |> validate_inclusion(:visibility, @visibilities)
    |> validate_format(:link, ~r{^https?://}, message: "must start with http:// or https://")
    |> validate_end()
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
