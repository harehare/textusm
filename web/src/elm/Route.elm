module Route exposing (Route(..), toRoute, toString)

import Url exposing (Url)
import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, string)
import Url.Parser.Query as Query


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
    | BusinessModelCanvas
    | OpportunityCanvas
    | UserStoryMap
    | FourLs
    | StartStopContinue
    | Kpt
    | Persona
    | Markdown
    | MindMap
    | EmpathyMap
    | List
    | Settings
    | Help
    | SharingSettings
    | Share DiagramPath Title Path
    | Embed DiagramPath Title Path
    | UsmView SettingsJson
    | View DiagramPath SettingsJson


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home Parser.top
        , map Share (s "share" </> string </> string </> string)
        , map Embed (s "embed" </> string </> string </> string)
        , map UsmView (s "view" </> string)
        , map View (s "view" </> string </> string)
        , map BusinessModelCanvas (s "bmc")
        , map OpportunityCanvas (s "opc")
        , map UserStoryMap (s "usm")
        , map FourLs (s "4ls")
        , map StartStopContinue (s "ssc")
        , map Kpt (s "kpt")
        , map Persona (s "persona")
        , map Markdown (s "md")
        , map MindMap (s "mmp")
        , map EmpathyMap (s "emm")
        , map List (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map SharingSettings (s "sharing")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault Home (parse parser url)


toString : Route -> String
toString route =
    case route of
        Home ->
            absolute [] []

        BusinessModelCanvas ->
            absolute [ "bmc" ] []

        OpportunityCanvas ->
            absolute [ "opc" ] []

        UserStoryMap ->
            absolute [ "usm" ] []

        FourLs ->
            absolute [ "4ls" ] []

        StartStopContinue ->
            absolute [ "ssc" ] []

        Kpt ->
            absolute [ "kpt" ] []

        Persona ->
            absolute [ "persona" ] []

        Markdown ->
            absolute [ "md" ] []

        MindMap ->
            absolute [ "mmp" ] []

        EmpathyMap ->
            absolute [ "emm" ] []

        List ->
            absolute [ "list" ] []

        Settings ->
            absolute [ "settings" ] []

        Help ->
            absolute [ "help" ] []

        SharingSettings ->
            absolute [ "sharing" ] []

        Share diagramPath title path ->
            absolute [ "share", diagramPath, title, path ] []

        Embed diagramPath title path ->
            absolute [ "Embed", diagramPath, title, path ] []

        UsmView settingsJson ->
            absolute [ "view", settingsJson ] []

        View diagramPath settingsJson ->
            absolute [ "view", diagramPath, settingsJson ] []
