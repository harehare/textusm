module Route exposing (Route(..), toDiagramToRoute, toRoute, toString)

import Data.DiagramItem exposing (DiagramItem)
import Data.DiagramType as DiagramType
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, custom, map, oneOf, parse, s, string)


type alias Id =
    String


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
    | Edit DiagramPath
    | EditFile DiagramPath Id
    | List
    | Settings
    | Help
    | Tag
    | SharingSettings
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
        , map List (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map Tag (s "tag")
        , map SharingSettings (s "sharing")
        , map Edit (s "edit" </> diagramType)
        , map EditFile (s "edit" </> diagramType </> string)
        ]


diagramType : Parser (String -> a) a
diagramType =
    custom "DIAGRAM_TYPE" <|
        \segment ->
            Just <| DiagramType.toString <| DiagramType.fromString segment


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse parser url)


toDiagramToRoute : DiagramItem -> Route
toDiagramToRoute diagram =
    case diagram.id of
        Just id_ ->
            EditFile (DiagramType.toString diagram.diagram) id_

        Nothing ->
            Edit <| DiagramType.toString diagram.diagram


toString : Route -> String
toString route =
    case route of
        Home ->
            absolute [] []

        Edit type_ ->
            absolute [ "edit", type_ ] []

        EditFile type_ id_ ->
            absolute [ "edit", type_, id_ ] []

        List ->
            absolute [ "list" ] []

        Settings ->
            absolute [ "settings" ] []

        Help ->
            absolute [ "help" ] []

        Tag ->
            absolute [ "tag" ] []

        SharingSettings ->
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
