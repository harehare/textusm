module GraphQL.Models.DiagramItem exposing (DiagramItem, decoder, empty, encoder, idToString, mapToDateTime, toInputItem)

import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Iso8601
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.DiagramType as DiagramType
import TextUSM.Enum.Diagram
import TextUSM.InputObject exposing (InputItem)
import TextUSM.Scalar exposing (Id(..))
import Time exposing (Posix)


type alias DiagramItem =
    { id : Maybe String
    , text : String
    , diagram : TextUSM.Enum.Diagram.Diagram
    , title : String
    , thumbnail : Maybe String
    , isPublic : Bool
    , isBookmark : Bool
    , isRemote : Bool
    , createdAt : Posix
    , updatedAt : Posix
    }


toInputItem : DiagramItem -> InputItem
toInputItem item =
    { id =
        case item.id of
            Just id ->
                Present <| Id id

            Nothing ->
                Absent
    , title = item.title
    , text = item.text
    , thumbnail =
        case item.thumbnail of
            Just thumbnail ->
                Present thumbnail

            Nothing ->
                Absent
    , diagram = item.diagram
    , isPublic = item.isPublic
    , isBookmark = item.isBookmark
    }


empty : DiagramItem
empty =
    { id = Nothing
    , text = ""
    , diagram = TextUSM.Enum.Diagram.UserStoryMap
    , title = ""
    , thumbnail = Nothing
    , isPublic = False
    , isBookmark = False
    , isRemote = False
    , createdAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    }


encoder : DiagramItem -> E.Value
encoder diagram =
    E.object
        [ ( "id", maybe E.string diagram.id )
        , ( "text", E.string diagram.text )
        , ( "diagram", E.string <| DiagramType.toString diagram.diagram )
        , ( "title", E.string diagram.title )
        , ( "thumbnail", maybe E.string diagram.thumbnail )
        , ( "isPublic", E.bool diagram.isPublic )
        , ( "isBookmark", E.bool diagram.isBookmark )
        , ( "isRemote", E.bool diagram.isRemote )
        , ( "createdAt", E.int <| Time.posixToMillis diagram.createdAt )
        , ( "updatedAt", E.int <| Time.posixToMillis diagram.updatedAt )
        ]


decoder : D.Decoder DiagramItem
decoder =
    D.succeed DiagramItem
        |> optional "id" (D.map Just D.string) Nothing
        |> required "text" D.string
        |> required "diagram" (D.map DiagramType.fromString D.string)
        |> required "title" D.string
        |> optional "thumbnail" (D.map Just D.string) Nothing
        |> required "isPublic" D.bool
        |> required "isBookmark" D.bool
        |> required "isRemote" D.bool
        |> required "createdAt" (D.map Time.millisToPosix D.int)
        |> required "updatedAt" (D.map Time.millisToPosix D.int)


mapToDateTime : SelectionSet TextUSM.Scalar.Time typeLock -> SelectionSet Posix typeLock
mapToDateTime =
    SelectionSet.mapOrFail
        (\(TextUSM.Scalar.Time value) ->
            Iso8601.toTime value
                |> Result.mapError
                    (\_ ->
                        "Failed to parse "
                            ++ value
                            ++ " as Iso8601 DateTime."
                    )
        )


idToString : SelectionSet TextUSM.Scalar.Id typeLock -> SelectionSet (Maybe String) typeLock
idToString =
    SelectionSet.map
        (\(TextUSM.Scalar.Id value) ->
            Just value
        )
