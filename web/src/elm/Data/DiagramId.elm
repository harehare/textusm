module Data.DiagramId exposing (DiagramId, decoder, fromString, toString)

import Json.Decode as D exposing (Decoder)


type DiagramId
    = DiagramId String


decoder : Decoder DiagramId
decoder =
    D.map DiagramId D.string


fromString : String -> DiagramId
fromString id =
    DiagramId id


toString : DiagramId -> String
toString (DiagramId id) =
    id
