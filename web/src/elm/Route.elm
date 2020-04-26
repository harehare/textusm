module Route exposing (Route(..), toDiagramToRoute, toRoute, toString)

import TextUSM.Enum.Diagram as Diagram
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, parse, s, string)


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
    | CustomerJourneyMap
    | SiteMap
    | GanttChart
    | ImpactMap
    | ErDiagram
    | Kanban
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
        , map SiteMap (s "smp")
        , map EmpathyMap (s "emm")
        , map CustomerJourneyMap (s "cjm")
        , map GanttChart (s "gct")
        , map ImpactMap (s "imm")
        , map ErDiagram (s "erd")
        , map Kanban (s "kanban")
        , map List (s "list")
        , map Settings (s "settings")
        , map Help (s "help")
        , map Tag (s "tag")
        , map SharingSettings (s "sharing")
        ]


toRoute : Url -> Route
toRoute url =
    Maybe.withDefault NotFound (parse parser url)


toDiagramToRoute : Diagram.Diagram -> Route
toDiagramToRoute diagram =
    case diagram of
        Diagram.UserStoryMap ->
            UserStoryMap

        Diagram.OpportunityCanvas ->
            OpportunityCanvas

        Diagram.BusinessModelCanvas ->
            BusinessModelCanvas

        Diagram.Fourls ->
            FourLs

        Diagram.StartStopContinue ->
            StartStopContinue

        Diagram.Kpt ->
            Kpt

        Diagram.UserPersona ->
            Persona

        Diagram.Markdown ->
            Markdown

        Diagram.MindMap ->
            MindMap

        Diagram.EmpathyMap ->
            EmpathyMap

        Diagram.CustomerJourneyMap ->
            CustomerJourneyMap

        Diagram.SiteMap ->
            SiteMap

        Diagram.GanttChart ->
            GanttChart

        Diagram.ImpactMap ->
            ImpactMap

        Diagram.ErDiagram ->
            ErDiagram

        Diagram.Kanban ->
            Kanban


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

        CustomerJourneyMap ->
            absolute [ "cjm" ] []

        SiteMap ->
            absolute [ "smp" ] []

        GanttChart ->
            absolute [ "gct" ] []

        ImpactMap ->
            absolute [ "imm" ] []

        ErDiagram ->
            absolute [ "erd" ] []

        Kanban ->
            absolute [ "kanban" ] []

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
