defmodule Cab.TournamentsTest do
  use ExUnit.Case, async: true

  alias Cab.Tournaments

  describe "parse_team_lines/1" do
    test "parses team and speaker names, skipping blank lines" do
      assert {:ok, [{"Alpha", ["Alice", "Aaron"]}, {"Bravo", ["Bob"]}]} =
               Tournaments.parse_team_lines("Alpha: Alice, Aaron\n\nBravo: Bob\n")
    end

    test "rejects lines without a colon" do
      assert {:error, "bad line" <> _} = Tournaments.parse_team_lines("just some words")
    end

    test "rejects more than two speakers" do
      assert {:error, "bad line" <> _} = Tournaments.parse_team_lines("Alpha: A, B, C")
    end
  end

  describe "ballot_payload/2" do
    defp room do
      %{
        "RoomTeams" => [
          %{
            "id" => 1,
            "position" => 1,
            "RoomSpeakers" => [%{"id" => 11}, %{"id" => 12}]
          },
          %{
            "id" => 2,
            "position" => 2,
            "RoomSpeakers" => [%{"id" => 21}, %{"id" => 22}]
          }
        ]
      }
    end

    test "derives ranks from team score sums" do
      scores = %{11 => 70, 12 => 70, 21 => 80, 22 => 80}

      assert {:ok, rankings, speaker_scores} = Tournaments.ballot_payload(room(), scores)

      assert rankings == [
               %{room_team_id: 2, rank: 1},
               %{room_team_id: 1, rank: 2}
             ]

      assert length(speaker_scores) == 4
      assert %{room_speaker_id: 11, score: 70} in speaker_scores
    end

    test "breaks ties by table position" do
      scores = %{11 => 75, 12 => 75, 21 => 75, 22 => 75}

      assert {:ok, [%{room_team_id: 1, rank: 1}, %{room_team_id: 2, rank: 2}], _} =
               Tournaments.ballot_payload(room(), scores)
    end

    test "reports missing scores" do
      assert {:error, message} = Tournaments.ballot_payload(room(), %{11 => 70})
      assert message =~ "3 missing"
    end
  end

  describe "winner_ballot_payload/2" do
    test "ranks the chosen team first" do
      room = %{
        "RoomTeams" => [
          %{"id" => 1, "position" => 1, "RoomSpeakers" => [%{"id" => 11}]},
          %{"id" => 2, "position" => 2, "RoomSpeakers" => [%{"id" => 21}]}
        ]
      }

      assert {:ok, [%{room_team_id: 2, rank: 1}, %{room_team_id: 1, rank: 2}], scores} =
               Tournaments.winner_ballot_payload(room, 2)

      assert %{room_speaker_id: 21, score: 76} in scores
      assert %{room_speaker_id: 11, score: 75} in scores
    end
  end
end
