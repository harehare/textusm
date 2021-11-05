module Models.DiagramItem exposing
    ( DiagramItem
    , decoder
    , empty
    , encoder
    , getId
    , isRemoteDiagram
    , listToString
    , listToValue
    , localFile
    , mapToDateTime
    , ofText
    , ofTitle
    , stringToList
    , toInputGistItem
    , toInputItem
    )

import Graphql.Enum.Diagram
import Graphql.InputObject exposing (InputGistItem, InputItem)
import Graphql.OptionalArgument as OptionalArgument
import Graphql.Scalar
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Iso8601
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.DiagramId as DiagramId exposing (DiagramId)
import Models.DiagramLocation as DiagramLocation exposing (DiagramLocation)
import Models.DiagramType as DiagramType
import Models.Session as Session exposing (Session)
import Models.Text as Text exposing (Text)
import Models.Title as Title exposing (Title)
import Monocle.Lens exposing (Lens)
import Time exposing (Posix)


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
                OptionalArgument.Present <| Graphql.Scalar.Id <| DiagramId.toString id

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
    }


toInputGistItem : DiagramItem -> InputGistItem
toInputGistItem item =
    { id =
        case item.id of
            Just id ->
                OptionalArgument.Present <| Graphql.Scalar.Id <| DiagramId.toString id

            Nothing ->
                OptionalArgument.Absent
    , title = Title.toString item.title
    , thumbnail =
        case item.thumbnail of
            Just thumbnail ->
                OptionalArgument.Present thumbnail

            Nothing ->
                OptionalArgument.Absent
    , diagram = item.diagram
    , url = ""
    , isBookmark = item.isBookmark
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
    , createdAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    }


localFile : String -> String -> DiagramItem
localFile title text =
    let
        tokens =
            String.split "." title
    in
    case tokens of
        [ _, ext ] ->
            { empty | title = Title.fromString title, text = Text.fromString text, diagram = DiagramType.fromString ext, location = Just DiagramLocation.LocalFileSystem }

        _ ->
            { empty | title = Title.fromString title, text = Text.fromString text, location = Just DiagramLocation.LocalFileSystem }


isRemoteDiagram : Session -> DiagramItem -> Bool
isRemoteDiagram session diagram =
    case ( diagram.location, diagram.id ) of
        ( Nothing, Nothing ) ->
            Session.isSignedIn session

        ( Just DiagramLocation.Local, Just _ ) ->
            False

        ( Just DiagramLocation.Local, Nothing ) ->
            Session.isSignedIn session

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
        |> optional "location" (D.map Just DiagramLocation.decoder) Nothing
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


listToValue : List DiagramItem -> E.Value
listToValue items =
    E.list encoder items


listToString : List DiagramItem -> String
listToString items =
    E.encode 4 (listToValue items)


stringToList : String -> Result D.Error (List DiagramItem)
stringToList json =
    D.decodeString (D.list decoder) json


ofTitle : Lens DiagramItem Title
ofTitle =
    Lens .title (\b a -> { a | title = b })


ofText : Lens DiagramItem Text
ofText =
    Lens .text (\b a -> { a | text = b })
