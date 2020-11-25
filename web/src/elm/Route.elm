module Route exposing (Route(..), replaceRoute, toDiagramToRoute, toRoute, toString)

import Browser.Navigation as Nav
import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramItem exposing (DiagramItem)
import Data.DiagramType as DiagramType
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, custom, map, oneOf, parse, s, string)


type alias DiagramPath =
    String


type alias Title =
    String


type alias Path =
    String


type alias SettingsJson =
    String


type Route
    = Home
    | New
    | Edit DiagramPath
    | EditFile DiagramPath DiagramId
    | DiagramList
    | Settings
    | Help
    | Tag
    | SharingDiagram
    | Share DiagramPath Title Path
    | Embed DiagramPath Title Path
    | UsmView SettingsJson
    | View DiagramPath SettingsJson
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Share (s "share" </> diagramType </> string </> string)
        , map Embed (s "embed" </> diagramType </> string </> string)
        , map UsmView (s "view" </> string)
        , map View (s "view" </> string </> string)
        , map DiagramList (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map Tag (s "tag")
        , map New (s "new")
        , map SharingDiagram (s "sharing")
        , map Edit (s "edit" </> diagramType)
        , map EditFile (s "edit" </> diagramType </> diagramId)
        ]


diagramType : Parser (String -> a) a
diagramType =
    custom "DIAGRAM_TYPE" <|
        \segment ->
            Just <| DiagramType.toString <| DiagramType.fromString segment


diagramId : Parser (DiagramId -> a) a
diagramId =
    custom "DIAGRAM_ID" <|
        \segment ->
            Just <| DiagramId.fromString segment


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse parser url)


toDiagramToRoute : DiagramItem -> Route
toDiagramToRoute diagram =
    case diagram.id of
        Nothing ->
            Edit <| DiagramType.toString diagram.diagram

        Just id_ ->
            EditFile (DiagramType.toString diagram.diagram) id_


toString : Route -> String
toString route =
    case route of
        Home ->
            absolute [] []

        New ->
            absolute [ "new" ] []

        Edit type_ ->
            absolute [ "edit", type_ ] []

        EditFile type_ id_ ->
            absolute [ "edit", type_, DiagramId.toString id_ ] []

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
            absolute [ "share", diagramPath, title, path ] []

        Embed diagramPath title path ->
            absolute [ "Embed", diagramPath, title, path ] []

        UsmView settingsJson ->
            absolute [ "view", settingsJson ] []

        View diagramPath settingsJson ->
            absolute [ "view", diagramPath, settingsJson ] []


replaceRoute : Nav.Key -> Route -> Cmd msg
replaceRoute key route =
    Nav.replaceUrl key (toString route)
