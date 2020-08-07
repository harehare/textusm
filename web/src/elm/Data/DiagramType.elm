module Data.DiagramType exposing (fromString, toLongString, toString)

import Models.Views.SequenceDiagram exposing (SequenceDiagram)
import TextUSM.Enum.Diagram exposing (Diagram(..))


toString : Diagram -> String
toString diagramType =
    case diagramType of
        UserStoryMap ->
            "usm"

        OpportunityCanvas ->
            "opc"

        BusinessModelCanvas ->
            "bmc"

        Fourls ->
            "4ls"

        StartStopContinue ->
            "ssc"

        Kpt ->
            "kpt"

        UserPersona ->
            "persona"

        Markdown ->
            "md"

        MindMap ->
            "mmp"

        EmpathyMap ->
            "emm"

        Table ->
            "table"

        SiteMap ->
            "smp"

        GanttChart ->
            "gct"

        ImpactMap ->
            "imm"

        ErDiagram ->
            "erd"

        Kanban ->
            "kanban"

        SequenceDiagram ->
            "sed"


toLongString : Diagram -> String
toLongString diagramType =
    case diagramType of
        UserStoryMap ->
            "User Story Map"

        OpportunityCanvas ->
            "Opportunity Canvas"

        BusinessModelCanvas ->
            "Business Model Canvas"

        Fourls ->
            "4Ls"

        StartStopContinue ->
            "Start, Stop, Continue"

        Kpt ->
            "KPT"

        UserPersona ->
            "User Persona"

        Markdown ->
            "Markdown"

        MindMap ->
            "Mind Map"

        EmpathyMap ->
            "Empathy Map"

        Table ->
            "Table"

        SiteMap ->
            "Site Map"

        GanttChart ->
            "Gantt Chart"

        ImpactMap ->
            "Impact Map"

        ErDiagram ->
            "ER Diagram"

        Kanban ->
            "Kanban"

        SequenceDiagram ->
            "Sequence Diagram"


fromString : String -> Diagram
fromString s =
    case s of
        "usm" ->
            UserStoryMap

        "opc" ->
            OpportunityCanvas

        "bmc" ->
            BusinessModelCanvas

        "4ls" ->
            Fourls

        "ssc" ->
            StartStopContinue

        "kpt" ->
            Kpt

        "persona" ->
            UserPersona

        "md" ->
            Markdown

        "mmp" ->
            MindMap

        "emm" ->
            EmpathyMap

        "table" ->
            Table

        "smp" ->
            SiteMap

        "gct" ->
            GanttChart

        "imm" ->
            ImpactMap

        "erd" ->
            ErDiagram

        "kanban" ->
            Kanban

        "sed" ->
            SequenceDiagram

        _ ->
            UserStoryMap
