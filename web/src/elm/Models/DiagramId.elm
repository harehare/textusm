module Models.DiagramId exposing (DiagramId, decoder, fromString, isGithubId, toString)

import Json.Decode as D exposing (Decoder)


type DiagramId
    = DiagramId String


decoder : Decoder DiagramId
decoder =
    D.map DiagramId D.string


fromString : String -> DiagramId
fromString id =
    DiagramId id


isGithubId : DiagramId -> Bool
isGithubId diagramId =
    (diagramId |> toString |> String.length) == 32


toString : DiagramId -> String
toString (DiagramId id) =
    id
