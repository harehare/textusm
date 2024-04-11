module Types.SplitDirection exposing (SplitDirection(..), decoder, encoder, fromString, toString)

import Json.Decode as D
import Json.Encode as E


type SplitDirection
    = Vertical
    | Horizontal


fromString : String -> SplitDirection
fromString s =
    case s of
        "vertical" ->
            Vertical

        "horizontal" ->
            Horizontal

        _ ->
            Vertical


toString : SplitDirection -> String
toString s =
    case s of
        Vertical ->
            "vertical"

        Horizontal ->
            "horizontal"


decoder : D.Decoder SplitDirection
decoder =
    D.map fromString D.string


encoder : SplitDirection -> E.Value
encoder s =
    E.string <| toString s
