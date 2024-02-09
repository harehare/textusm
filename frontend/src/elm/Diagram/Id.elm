module Diagram.Id exposing (DiagramId, decoder, encoder, fromString, isGithubId, toString)

import Json.Decode as D exposing (Decoder)
import Json.Encode as E


type DiagramId
    = DiagramId String


decoder : Decoder DiagramId
decoder =
    D.map DiagramId D.string


encoder : DiagramId -> E.Value
encoder id_ =
    E.string <| toString id_


fromString : String -> DiagramId
fromString id =
    DiagramId id


isGithubId : DiagramId -> Bool
isGithubId diagramId =
    (diagramId |> toString |> String.length) == 32


toString : DiagramId -> String
toString (DiagramId id) =
    id
