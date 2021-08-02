module Types.DiagramId exposing (DiagramId, decoder, fromString, toString, isGithubId)

import Json.Decode as D exposing (Decoder)


type DiagramId
    = DiagramId String


isGithubId: DiagramId -> Bool
isGithubId diagramId =
    (diagramId |> toString |> String.length) == 32

decoder : Decoder DiagramId
decoder =
    D.map DiagramId D.string


fromString : String -> DiagramId
fromString id =
    DiagramId id


toString : DiagramId -> String
toString (DiagramId id) =
    id
