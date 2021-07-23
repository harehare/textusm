module Types.DiagramItem exposing
    ( DiagramItem
    , decoder
    , empty
    , encoder
    , getId
    , gistIdToString
    , idToString
    , isRemoteDiagram
    , listToString
    , listToValue
    , mapToDateTime
    , stringToList
    , toInputItem
    )

import Graphql.Enum.Diagram
import Graphql.InputObject exposing (InputItem)
import Graphql.OptionalArgument as OptionalArgument
import Graphql.Scalar exposing (ItemIdScalar(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Iso8601
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Time exposing (Posix)
import Types.DiagramId as DiagramId exposing (DiagramId)
import Types.DiagramLocation as DiagramLocation exposing (DiagramLocation)
import Types.DiagramType as DiagramType
import Types.Session as Session exposing (Session)
import Types.Text as Text exposing (Text)
import Types.Title as Title exposing (Title)


type alias DiagramItem =
    { id : Maybe DiagramId
    , text : Text
    , diagram : Graphql.Enum.Diagram.Diagram
    , title : Title
    , thumbnail : Maybe String
    , isPublic : Bool
    , isBookmark : Bool
    , isRemote : Bool
    , location : Maybe DiagramLocation
    , tags : Maybe (List (Maybe String))
    , createdAt : Posix
    , updatedAt : Posix
    }


getId : DiagramItem -> DiagramId
getId item =
    case item.id of
        Just id_ ->
            id_

        Nothing ->
            DiagramId.fromString ""


toInputItem : DiagramItem -> InputItem
toInputItem item =
    { id =
        case item.id of
            Just id ->
                OptionalArgument.Present (ItemIdScalar <| DiagramId.toString id)

            Nothing ->
                OptionalArgument.Absent
    , title = Title.toString item.title
    , text = Text.toString item.text
    , thumbnail =
        case item.thumbnail of
            Just thumbnail ->
                OptionalArgument.Present thumbnail

            Nothing ->
                OptionalArgument.Absent
    , diagram = item.diagram
    , isPublic = item.isPublic
    , isBookmark = item.isBookmark
    , tags = OptionalArgument.Present (item.tags |> Maybe.withDefault [])
    }


empty : DiagramItem
empty =
    { id = Nothing
    , text = Text.empty
    , diagram = Graphql.Enum.Diagram.UserStoryMap
    , title = Title.untitled
    , thumbnail = Nothing
    , isPublic = False
    , isBookmark = False
    , isRemote = False
    , location = Just DiagramLocation.Local
    , tags = Nothing
    , createdAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    }


isRemoteDiagram : Session -> DiagramItem -> Bool
isRemoteDiagram session diagram =
    case ( Maybe.withDefault DiagramLocation.Local diagram.location |> DiagramLocation.isRemote, diagram.id ) of
        ( False, Nothing ) ->
            Session.isSignedIn session

        ( False, Just _ ) ->
            False

        _ ->
            True


encoder : DiagramItem -> E.Value
encoder diagram =
    E.object
        [ ( "id", maybe E.string (Maybe.andThen (\id -> Just <| DiagramId.toString id) diagram.id) )
        , ( "text", E.string <| Text.toString diagram.text )
        , ( "diagram", E.string <| DiagramType.toString diagram.diagram )
        , ( "title", E.string (Title.toString diagram.title) )
        , ( "thumbnail", maybe E.string diagram.thumbnail )
        , ( "isPublic", E.bool diagram.isPublic )
        , ( "isBookmark", E.bool diagram.isBookmark )
        , ( "isRemote", E.bool diagram.isRemote )
        , ( "location", maybe E.string <| Maybe.map DiagramLocation.toString diagram.location )
        , ( "tags", maybe (E.list (maybe E.string)) diagram.tags )
        , ( "createdAt", E.int <| Time.posixToMillis diagram.createdAt )
        , ( "updatedAt", E.int <| Time.posixToMillis diagram.updatedAt )
        ]


decoder : D.Decoder DiagramItem
decoder =
    D.succeed DiagramItem
        |> optional "id" (D.map Just DiagramId.decoder) Nothing
        |> required "text" Text.decoder
        |> required "diagram" (D.map DiagramType.fromString D.string)
        |> required "title" (D.map Title.fromString D.string)
        |> optional "thumbnail" (D.map Just D.string) Nothing
        |> required "isPublic" D.bool
        |> required "isBookmark" D.bool
        |> required "isRemote" D.bool
        |> optional "location" (D.map (\l -> Just <| DiagramLocation.fromString l) D.string) Nothing
        |> optional "tags" (D.map Just (D.list (D.maybe D.string))) Nothing
        |> required "createdAt" (D.map Time.millisToPosix D.int)
        |> required "updatedAt" (D.map Time.millisToPosix D.int)


mapToDateTime : SelectionSet Graphql.Scalar.Time typeLock -> SelectionSet Posix typeLock
mapToDateTime =
    SelectionSet.mapOrFail
        (\(Graphql.Scalar.Time value) ->
            Iso8601.toTime value
                |> Result.mapError
                    (\_ ->
                        "Failed to parse "
                            ++ value
                            ++ " as Iso8601 DateTime."
                    )
        )


idToString : SelectionSet Graphql.Scalar.ItemIdScalar typeLock -> SelectionSet (Maybe DiagramId) typeLock
idToString =
    SelectionSet.map
        (\(Graphql.Scalar.ItemIdScalar value) ->
            Just (DiagramId.fromString value)
        )


gistIdToString : SelectionSet Graphql.Scalar.GistIdScalar typeLock -> SelectionSet (Maybe DiagramId) typeLock
gistIdToString =
    SelectionSet.map
        (\(Graphql.Scalar.GistIdScalar value) ->
            Just (DiagramId.fromString value)
        )


listToValue : List DiagramItem -> E.Value
listToValue items =
    E.list encoder items


listToString : List DiagramItem -> String
listToString items =
    E.encode 4 (listToValue items)


stringToList : String -> Result D.Error (List DiagramItem)
stringToList json =
    D.decodeString (D.list decoder) json
