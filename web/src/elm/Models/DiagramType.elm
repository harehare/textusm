module Models.DiagramType exposing (fromString, toString)

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

        CustomerJourneyMap ->
            "cjm"

        SiteMap ->
            "smp"

        GanttChart ->
            "gct"


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

        "cjm" ->
            CustomerJourneyMap

        "smp" ->
            SiteMap

        "gct" ->
            GanttChart

        _ ->
            UserStoryMap
