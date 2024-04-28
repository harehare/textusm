module Route exposing (CopyDiagramId, IsRemote, Route(..), Title, isViewFile, moveTo, replaceRoute, toRoute, toString)

import Bool.Extra as BoolEx
import Browser.Navigation as Nav
import Diagram.Types.Id as DiagramId exposing (DiagramId)
import Diagram.Types.Type as DiagramType exposing (DiagramType)
import Types.ShareToken as ShareToken exposing (ShareToken)
import Types.UrlEncodedText as UrlEncodedText exposing (UrlEncodedText)
import Url exposing (Url)
import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, custom, map, oneOf, parse, s, string)
import Url.Parser.Query as Query


type alias CopyDiagramId =
    Maybe DiagramId


type alias IsRemote =
    Maybe Bool


type Route
    = DiagramList
    | Edit DiagramType CopyDiagramId IsRemote
    | EditFile DiagramType DiagramId
    | EditLocalFile DiagramType DiagramId
    | Embed DiagramType Title ShareToken (Maybe Int) (Maybe Int)
    | Help
    | Home
    | New
    | NotFound
    | Preview DiagramType UrlEncodedText
    | Settings DiagramType
    | Share
    | ViewFile DiagramType ShareToken
    | ViewPublic DiagramType DiagramId


type alias Title =
    String


isViewFile : Route -> Bool
isViewFile route =
    case route of
        ViewFile _ _ ->
            True

        _ ->
            False


moveTo : Nav.Key -> Route -> Cmd msg
moveTo key route =
    Nav.pushUrl key (toString route)


replaceRoute : Nav.Key -> Route -> Cmd msg
replaceRoute key route =
    Nav.replaceUrl key (toString route)


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse parser url)


toString : Route -> String
toString route =
    case route of
        Home ->
            absolute [] []

        New ->
            absolute [ "new" ] []

        Edit type_ (Just copyDiagramId) (Just isRemote_) ->
            absolute [ "edit", DiagramType.toString type_ ]
                [ Builder.string "copy" (DiagramId.toString copyDiagramId)
                , Builder.string "remote"
                    (if isRemote_ then
                        "true"

                     else
                        "false"
                    )
                ]

        Edit type_ _ _ ->
            absolute [ "edit", DiagramType.toString type_ ] []

        EditFile type_ id_ ->
            absolute [ "edit", DiagramType.toString type_, DiagramId.toString id_ ] []

        EditLocalFile type_ id_ ->
            absolute [ "edit", DiagramType.toString type_, "local", DiagramId.toString id_ ] []

        ViewPublic type_ id_ ->
            absolute [ "pubilc", DiagramType.toString type_, DiagramId.toString id_ ] []

        DiagramList ->
            absolute [ "list" ] []

        Settings type_ ->
            absolute [ "settings", DiagramType.toString type_ ] []

        Help ->
            absolute [ "help" ] []

        Share ->
            absolute [ "share" ] []

        Embed diagramPath title token (Just width) (Just height) ->
            absolute [ "embed", DiagramType.toString diagramPath, title, ShareToken.toString token ] [ Builder.int "w" width, Builder.int "w" height ]

        Embed diagramPath title token _ _ ->
            absolute [ "embed", DiagramType.toString diagramPath, title, ShareToken.toString token ] []

        ViewFile type_ token_ ->
            absolute [ "view", DiagramType.toString type_, ShareToken.toString token_ ] []

        NotFound ->
            absolute [ "notfound" ] []

        Preview type_ text_ ->
            absolute [ "preview", DiagramType.toString type_, UrlEncodedText.toString text_ ] []


diagramId : Parser (DiagramId -> a) a
diagramId =
    custom "DIAGRAM_ID" <|
        \segment ->
            if String.length segment >= 32 || String.length segment <= 35 then
                Just <| DiagramId.fromString segment

            else
                Nothing


diagramType : Parser (DiagramType -> a) a
diagramType =
    custom "DIAGRAM_TYPE" <|
        \segment ->
            DiagramType.toDiagram segment


urlEncodedText : Parser (UrlEncodedText -> a) a
urlEncodedText =
    custom "URL_ENCODED_TEXT" <|
        \segment ->
            UrlEncodedText.fromString segment


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Embed (s "embed" </> diagramType </> string </> shareId <?> Query.int "w" <?> Query.int "h")
        , map DiagramList (s "list")
        , map Settings (s "settings" </> diagramType)
        , map Help (s "help")
        , map New (s "new")
        , map Share (s "share")
        , map Edit (s "edit" </> diagramType <?> Query.map (Maybe.map DiagramId.fromString) (Query.string "copy") <?> Query.map (Maybe.andThen BoolEx.fromString) (Query.string "remote"))
        , map EditFile (s "edit" </> diagramType </> diagramId)
        , map EditLocalFile (s "edit" </> diagramType </> s "local" </> diagramId)
        , map ViewFile (s "view" </> diagramType </> shareId)
        , map ViewPublic (s "public" </> diagramType </> diagramId)
        , map Preview (s "preview" </> diagramType </> urlEncodedText)
        ]


shareId : Parser (ShareToken -> a) a
shareId =
    custom "SHARE_TOKEN" <|
        \segment ->
            ShareToken.fromString segment
