module Route exposing (Route(..), replaceRoute, toDiagramToRoute, toRoute, toString)

import Browser.Navigation as Nav
import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramItem exposing (DiagramItem)
import Data.DiagramType as DiagramType
import TextUSM.Enum.Diagram exposing (Diagram(..))
import UUID
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, custom, map, oneOf, parse, s, string)


type alias Title =
    String


type alias Path =
    String


type alias SettingsJson =
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
    | SharingDiagram
    | Share Diagram Title Path
    | Embed Diagram Title Path
    | View Diagram SettingsJson
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Share (s "share" </> diagramType </> string </> string)
        , map Embed (s "embed" </> diagramType </> string </> string)
        , map View (s "view" </> diagramType </> string)
        , map DiagramList (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map Tag (s "tag")
        , map New (s "new")
        , map SharingDiagram (s "sharing")
        , map Edit (s "edit" </> diagramType)
        , map EditFile (s "edit" </> diagramType </> diagramId)
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

        SharingDiagram ->
            absolute [ "sharing" ] []

        NotFound ->
            absolute [ "notfound" ] []

        Share diagramPath title path ->
            absolute [ "share", DiagramType.toString diagramPath, title, path ] []

        Embed diagramPath title path ->
            absolute [ "Embed", DiagramType.toString diagramPath, title, path ] []

        View diagramPath settingsJson ->
            absolute [ "view", DiagramType.toString diagramPath, settingsJson ] []


replaceRoute : Nav.Key -> Route -> Cmd msg
replaceRoute key route =
    Nav.replaceUrl key (toString route)
