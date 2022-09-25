module Models.History exposing (History, add, fromString, toString)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Models.DiagramId as DiagramId exposing (DiagramId)
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramLocation exposing (DiagramLocation(..))
import Models.Text as Text exposing (Text)
import Time exposing (Posix)


type History
    = History LocalHistories HistSize


type alias HistSize =
    Int


type alias LocalHistory =
    { id : DiagramId
    , text : Text
    , createdAt : Posix
    }


type alias LocalHistories =
    List LocalHistory


add : History -> DiagramItem -> History
add (History histories histSize) item =
    case item.id of
        Just id_ ->
            History
                ({ id = id_
                 , text = item.text
                 , createdAt = item.updatedAt
                 }
                    :: histories
                )
                histSize

        Nothing ->
            History histories histSize


fromString : String -> HistSize -> History
fromString json histSize =
    case D.decodeString decoder json of
        Ok histories ->
            History histories histSize

        Err _ ->
            History [] histSize


toString : History -> String
toString (History histories _) =
    E.encode 0 <| encoder histories


decoder : D.Decoder LocalHistories
decoder =
    D.list localHistoryDecoder


encoder : LocalHistories -> E.Value
encoder histories =
    E.list localHistoryEncoder histories


localHistoryDecoder : D.Decoder LocalHistory
localHistoryDecoder =
    D.succeed
        LocalHistory
        |> required "id" DiagramId.decoder
        |> required "text" Text.decoder
        |> required "createdAt" (D.map Time.millisToPosix D.int)


localHistoryEncoder : LocalHistory -> E.Value
localHistoryEncoder history =
    E.object
        [ ( "id", E.string <| DiagramId.toString history.id )
        , ( "text", E.string <| Text.toString history.text )
        , ( "createdAt", E.int <| Time.posixToMillis history.createdAt )
        ]
