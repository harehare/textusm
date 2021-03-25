module Route exposing (Route(..), replaceRoute, toDiagramToRoute, toRoute, toString)

import Browser.Navigation as Nav
import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramItem exposing (DiagramItem)
import Data.DiagramType as DiagramType
import Data.ShareToken as ShareToken exposing (ShareToken)
import TextUSM.Enum.Diagram exposing (Diagram(..))
import UUID
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, custom, map, oneOf, parse, s, string)


type alias Title =
    String


type Route
    = Home
    | New
    | Edit Diagram
    | EditFile Diagram DiagramId
    | ViewPublic Diagram DiagramId
    | DiagramList
    | Settings
    | Help
    | Tag
    | Share
    | Embed Diagram Title ShareToken
    | ViewFile Diagram ShareToken
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Embed (s "embed" </> diagramType </> string </> shareId)
        , map DiagramList (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map Tag (s "tag")
        , map New (s "new")
        , map Share (s "share")
        , map Edit (s "edit" </> diagramType)
        , map EditFile (s "edit" </> diagramType </> diagramId)
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
            UUID.fromString segment
                |> Result.toMaybe
                |> Maybe.map (\_ -> DiagramId.fromString segment)


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

        Tag ->
            absolute [ "tag" ] []

        Share ->
            absolute [ "share" ] []

        NotFound ->
            absolute [ "notfound" ] []

        Embed diagramPath title token ->
            absolute [ "Embed", DiagramType.toString diagramPath, title, ShareToken.toString token ] []


replaceRoute : Nav.Key -> Route -> Cmd msg
replaceRoute key route =
    Nav.replaceUrl key (toString route)
