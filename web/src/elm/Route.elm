module Route exposing (Route(..), moveTo, replaceRoute, toDiagramToRoute, toRoute, toString)

import Browser.Navigation as Nav
import Graphql.Enum.Diagram exposing (Diagram(..))
import Models.DiagramId as DiagramId exposing (DiagramId)
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramType as DiagramType
import Models.ShareToken as ShareToken exposing (ShareToken)
import Url exposing (Url)
import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, custom, map, oneOf, parse, s, string)
import Url.Parser.Query as Query


type alias Title =
    String


type Route
    = Home
    | New
    | Edit Diagram
    | EditFile Diagram DiagramId
    | EditLocalFile Diagram DiagramId
    | ViewPublic Diagram DiagramId
    | DiagramList
    | Settings
    | Help
    | Share
    | Embed Diagram Title ShareToken (Maybe Int) (Maybe Int)
    | ViewFile Diagram ShareToken
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Embed (s "embed" </> diagramType </> string </> shareId <?> Query.int "w" <?> Query.int "h")
        , map DiagramList (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map New (s "new")
        , map Share (s "share")
        , map Edit (s "edit" </> diagramType)
        , map EditFile (s "edit" </> diagramType </> diagramId)
        , map EditLocalFile (s "edit" </> diagramType </> s "local" </> diagramId)
        , map ViewFile (s "view" </> diagramType </> shareId)
        , map ViewPublic (s "public" </> diagramType </> diagramId)
        ]


diagramType : Parser (Diagram -> a) a
diagramType =
    custom "DIAGRAM_TYPE" <|
        \segment ->
            DiagramType.toDiagram segment


diagramId : Parser (DiagramId -> a) a
diagramId =
    custom "DIAGRAM_ID" <|
        \segment ->
            if String.length segment >= 32 || String.length segment <= 35 then
                Just <| DiagramId.fromString segment

            else
                Nothing


shareId : Parser (ShareToken -> a) a
shareId =
    custom "SHARE_TOKEN" <|
        \segment ->
            ShareToken.fromString segment


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse parser url)


toDiagramToRoute : DiagramItem -> Route
toDiagramToRoute diagram =
    case diagram.id of
        Nothing ->
            Edit diagram.diagram

        Just id_ ->
            if diagram.isPublic then
                ViewPublic diagram.diagram id_

            else
                EditFile diagram.diagram id_


toString : Route -> String
toString route =
    case route of
        Home ->
            absolute [] []

        New ->
            absolute [ "new" ] []

        Edit type_ ->
            absolute [ "edit", DiagramType.toString type_ ] []

        EditFile type_ id_ ->
            absolute [ "edit", DiagramType.toString type_, DiagramId.toString id_ ] []

        EditLocalFile type_ id_ ->
            absolute [ "edit", DiagramType.toString type_, "local", DiagramId.toString id_ ] []

        ViewFile type_ token_ ->
            absolute [ "view", DiagramType.toString type_, ShareToken.toString token_ ] []

        ViewPublic type_ id_ ->
            absolute [ "pubilc", DiagramType.toString type_, DiagramId.toString id_ ] []

        DiagramList ->
            absolute [ "list" ] []

        Settings ->
            absolute [ "settings" ] []

        Help ->
            absolute [ "help" ] []

        Share ->
            absolute [ "share" ] []

        NotFound ->
            absolute [ "notfound" ] []

        Embed diagramPath title token (Just width) (Just height) ->
            absolute [ "Embed", DiagramType.toString diagramPath, title, ShareToken.toString token ] [ Builder.int "w" width, Builder.int "w" height ]

        Embed diagramPath title token _ _ ->
            absolute [ "Embed", DiagramType.toString diagramPath, title, ShareToken.toString token ] []


replaceRoute : Nav.Key -> Route -> Cmd msg
replaceRoute key route =
    Nav.replaceUrl key (toString route)


moveTo : Nav.Key -> Route -> Cmd msg
moveTo key route =
    Nav.pushUrl key (toString route)
