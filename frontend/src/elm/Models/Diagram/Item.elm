module Models.Diagram.Item exposing
    ( DiagramItem
    , copy
    , decoder
    , empty
    , encoder
    , getId
    , isRemoteDiagram
    , listToString
    , listToValue
    , localFile
    , mapToDateTime
    , new
    , ofDiagram
    , ofLocation
    , ofText
    , ofThumbnail
    , ofTitle
    , stringToList
    , toInputGistItem
    , toInputItem
    )

import Graphql.InputObject exposing (InputGistItem, InputItem)
import Graphql.OptionalArgument as OptionalArgument
import Graphql.Scalar
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Iso8601
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Diagram.Id as DiagramId exposing (DiagramId)
import Models.Diagram.Location as DiagramLocation exposing (Location)
import Models.Diagram.Type as DiagramType exposing (DiagramType)
import Models.Session as Session exposing (Session)
import Models.Text as Text exposing (Text)
import Models.Title as Title exposing (Title)
import Monocle.Lens exposing (Lens)
import Time exposing (Posix)


type alias DiagramItem =
    { id : Maybe DiagramId
    , text : Text
    , diagram : DiagramType
    , title : Title
    , thumbnail : Maybe String
    , isPublic : Bool
    , isBookmark : Bool
    , location : Maybe Location
    , createdAt : Posix
    , updatedAt : Posix
    }


copy : DiagramItem -> DiagramItem
copy diagram =
    { id = Nothing
    , text = diagram.text
    , diagram = diagram.diagram
    , title = Title.map (\t -> Title.fromString <| "Copy of " ++ t) diagram.title
    , thumbnail = diagram.thumbnail
    , isPublic = False
    , isBookmark = False
    , location = Nothing
    , createdAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    }


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
        |> optional "location" (D.map Just DiagramLocation.decoder) Nothing
        |> required "createdAt" (D.map Time.millisToPosix D.int)
        |> required "updatedAt" (D.map Time.millisToPosix D.int)


encoder : DiagramItem -> E.Value
encoder diagram =
    E.object
        [ ( "id", maybe E.string (Maybe.map DiagramId.toString diagram.id) )
        , ( "text", E.string <| Text.toString diagram.text )
        , ( "diagram", E.string <| DiagramType.toString diagram.diagram )
        , ( "title", E.string (Title.toString diagram.title) )
        , ( "thumbnail", maybe E.string diagram.thumbnail )
        , ( "isPublic", E.bool diagram.isPublic )
        , ( "isBookmark", E.bool diagram.isBookmark )
        , ( "location", maybe E.string <| Maybe.map DiagramLocation.toString diagram.location )
        , ( "createdAt", E.int <| Time.posixToMillis diagram.createdAt )
        , ( "updatedAt", E.int <| Time.posixToMillis diagram.updatedAt )
        ]


getId : DiagramItem -> DiagramId
getId item =
    case item.id of
        Just id_ ->
            id_

        Nothing ->
            DiagramId.fromString ""


isRemoteDiagram : Session -> DiagramItem -> Bool
isRemoteDiagram session diagram =
    case ( diagram.location, diagram.id ) of
        ( Just DiagramLocation.Local, Just _ ) ->
            False

        ( Just DiagramLocation.Local, Nothing ) ->
            Session.isSignedIn session

        ( Nothing, Nothing ) ->
            Session.isSignedIn session

        _ ->
            True


listToString : List DiagramItem -> String
listToString items =
    E.encode 4 (listToValue items)


listToValue : List DiagramItem -> E.Value
listToValue items =
    E.list encoder items


localFile : String -> String -> DiagramItem
localFile title text =
    let
        tokens : List String
        tokens =
            String.split "." title
    in
    case tokens of
        [ _, ext ] ->
            { empty | text = Text.fromString text, diagram = DiagramType.fromString ext, title = Title.fromString title, location = Just DiagramLocation.LocalFileSystem }

        _ ->
            { empty | text = Text.fromString text, title = Title.fromString title, location = Just DiagramLocation.LocalFileSystem }


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


empty : DiagramItem
empty =
    { id = Nothing
    , text = Text.empty
    , diagram = DiagramType.UserStoryMap
    , title = Title.untitled
    , thumbnail = Nothing
    , isPublic = False
    , isBookmark = False
    , location = Nothing
    , createdAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    }


new : DiagramType -> DiagramItem
new diagramType =
    { id = Nothing
    , text = Text.fromString <| DiagramType.defaultText diagramType
    , diagram = diagramType
    , title = Title.untitled
    , thumbnail = Nothing
    , isPublic = False
    , isBookmark = False
    , location = Nothing
    , createdAt = Time.millisToPosix 0
    , updatedAt = Time.millisToPosix 0
    }


ofText : Lens DiagramItem Text
ofText =
    Lens .text (\b a -> { a | text = b })


ofTitle : Lens DiagramItem Title
ofTitle =
    Lens .title (\b a -> { a | title = b })


ofDiagram : Lens DiagramItem DiagramType
ofDiagram =
    Lens .diagram (\b a -> { a | diagram = b })


ofThumbnail : Lens DiagramItem (Maybe String)
ofThumbnail =
    Lens .thumbnail (\b a -> { a | thumbnail = b })


ofLocation : Lens DiagramItem (Maybe Location)
ofLocation =
    Lens .location (\b a -> { a | location = b })


stringToList : String -> Result D.Error (List DiagramItem)
stringToList json =
    D.decodeString (D.list decoder) json


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
    , diagram = DiagramType.toGraphqlValue item.diagram
    , isBookmark = item.isBookmark
    , url = ""
    }


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
    , diagram = DiagramType.toGraphqlValue item.diagram
    , isPublic = item.isPublic
    , isBookmark = item.isBookmark
    }
