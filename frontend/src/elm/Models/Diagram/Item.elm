module Models.Diagram.Item exposing
    ( DiagramItem
    , copy
    , decoder
    , diagram
    , empty
    , encoder
    , getId
    , id
    , isRemoteDiagram
    , listToString
    , listToValue
    , localFile
    , location
    , mapToDateTime
    , new
    , stringToList
    , text
    , thumbnail
    , title
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
copy diagram_ =
    { id = Nothing
    , text = diagram_.text
    , diagram = diagram_.diagram
    , title = Title.map (\t -> Title.fromString <| "Copy of " ++ t) diagram_.title
    , thumbnail = diagram_.thumbnail
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
encoder diagram_ =
    E.object
        [ ( "id", maybe E.string (Maybe.map DiagramId.toString diagram_.id) )
        , ( "text", E.string <| Text.toString diagram_.text )
        , ( "diagram", E.string <| DiagramType.toString diagram_.diagram )
        , ( "title", E.string (Title.toString diagram_.title) )
        , ( "thumbnail", maybe E.string diagram_.thumbnail )
        , ( "isPublic", E.bool diagram_.isPublic )
        , ( "isBookmark", E.bool diagram_.isBookmark )
        , ( "location", maybe E.string <| Maybe.map DiagramLocation.toString diagram_.location )
        , ( "createdAt", E.int <| Time.posixToMillis diagram_.createdAt )
        , ( "updatedAt", E.int <| Time.posixToMillis diagram_.updatedAt )
        ]


getId : DiagramItem -> DiagramId
getId item =
    case item.id of
        Just id_ ->
            id_

        Nothing ->
            DiagramId.fromString ""


isRemoteDiagram : Session -> DiagramItem -> Bool
isRemoteDiagram session diagram_ =
    case ( diagram_.location, diagram_.id ) of
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
localFile title_ text_ =
    let
        tokens : List String
        tokens =
            String.split "." title_
    in
    case tokens of
        [ _, ext ] ->
            { empty | text = Text.fromString text_, diagram = DiagramType.fromString ext, title = Title.fromString title_, location = Just DiagramLocation.LocalFileSystem }

        _ ->
            { empty | text = Text.fromString text_, title = Title.fromString title_, location = Just DiagramLocation.LocalFileSystem }


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


text : Lens DiagramItem Text
text =
    Lens .text (\b a -> { a | text = b })


title : Lens DiagramItem Title
title =
    Lens .title (\b a -> { a | title = b })


diagram : Lens DiagramItem DiagramType
diagram =
    Lens .diagram (\b a -> { a | diagram = b })


thumbnail : Lens DiagramItem (Maybe String)
thumbnail =
    Lens .thumbnail (\b a -> { a | thumbnail = b })


location : Lens DiagramItem (Maybe Location)
location =
    Lens .location (\b a -> { a | location = b })


id : Lens DiagramItem (Maybe DiagramId)
id =
    Lens .id (\b a -> { a | id = b })


stringToList : String -> Result D.Error (List DiagramItem)
stringToList json =
    D.decodeString (D.list decoder) json


toInputGistItem : DiagramItem -> InputGistItem
toInputGistItem item =
    { id =
        case item.id of
            Just id_ ->
                OptionalArgument.Present <| Graphql.Scalar.Id <| DiagramId.toString id_

            Nothing ->
                OptionalArgument.Absent
    , title = Title.toString item.title
    , thumbnail =
        case item.thumbnail of
            Just thumbnail_ ->
                OptionalArgument.Present thumbnail_

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
            Just id_ ->
                OptionalArgument.Present <| Graphql.Scalar.Id <| DiagramId.toString id_

            Nothing ->
                OptionalArgument.Absent
    , title = Title.toString item.title
    , text = Text.toString item.text
    , thumbnail =
        case item.thumbnail of
            Just thumbnail_ ->
                OptionalArgument.Present thumbnail_

            Nothing ->
                OptionalArgument.Absent
    , diagram = DiagramType.toGraphqlValue item.diagram
    , isPublic = item.isPublic
    , isBookmark = item.isBookmark
    }
