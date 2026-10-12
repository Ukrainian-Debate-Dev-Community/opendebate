defmodule Uadebate.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  # a fixed palette; each colour is a pair of CSS tokens for light and dark
  @colors ~w(gray red orange yellow green teal blue purple)

  schema "tags" do
    field :name, :string
    field :color, :string, default: "gray"

    timestamps(type: :utc_datetime)
  end

  def colors, do: @colors

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :color])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name, :color])
    |> validate_length(:name, max: 40)
    |> validate_inclusion(:color, @colors)
    |> unique_constraint(:name)
  end
end
