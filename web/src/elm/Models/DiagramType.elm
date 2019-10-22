module Models.DiagramType exposing (DiagramType(..), fromString, toString)


type DiagramType
    = UserStoryMap
    | OpportunityCanvas
    | BusinessModelCanvas
    | FourLs
    | StartStopContinue
    | Kpt
    | UserPersona
    | Markdown
    | MindMap
    | EmpathyMap


toString : DiagramType -> String
toString diagramType =
    case diagramType of
        UserStoryMap ->
            "usm"

        OpportunityCanvas ->
            "opc"

        BusinessModelCanvas ->
            "bmc"

        FourLs ->
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


fromString : String -> DiagramType
fromString s =
    case s of
        "usm" ->
            UserStoryMap

        "opc" ->
            OpportunityCanvas

        "bmc" ->
            BusinessModelCanvas

        "4ls" ->
            FourLs

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

        _ ->
            UserStoryMap
