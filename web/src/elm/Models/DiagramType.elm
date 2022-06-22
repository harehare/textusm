module Models.DiagramType exposing
    ( DiagramType(..)
    , defaultText
    , fromGraphqlValue
    , fromString
    , toDiagram
    , toGraphqlValue
    , toLongString
    , toString
    )

import Graphql.Enum.Diagram as Diagram exposing (Diagram)


type DiagramType
    = UserStoryMap
    | OpportunityCanvas
    | BusinessModelCanvas
    | Fourls
    | StartStopContinue
    | Kpt
    | UserPersona
    | MindMap
    | EmpathyMap
    | SiteMap
    | GanttChart
    | ImpactMap
    | ErDiagram
    | Kanban
    | Table
    | SequenceDiagram
    | Freeform
    | UseCaseDiagram


defaultText : DiagramType -> String
defaultText diagram =
    case diagram of
        UserStoryMap ->
            "# user_activities: USER ACTIVITIES\n# user_tasks: USER TASKS\n# user_stories: USER STORIES\n# release1: RELEASE 1\n# release2: RELEASE 2\n# release3: RELEASE 3\nUSER ACTIVITY\n    USER TASK\n        USER STORY"

        BusinessModelCanvas ->
            "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships"

        OpportunityCanvas ->
            "Problems\nSolution Ideas\nUsers and Customers\nSolutions Today\nBusiness Challenges\nHow will Users use Solution?\nUser Metrics\nAdoption Strategy\nBusiness Benefits and Metrics\nBudget"

        Fourls ->
            "Liked\nLearned\nLacked\nLonged for"

        StartStopContinue ->
            "Start\nStop\nContinue"

        Kpt ->
            "K\nP\nT"

        UserPersona ->
            "Name\n    https://app.textusm.com/images/logo.svg\nWho am i...\nThree reasons to use your product\nThree reasons to buy your product\nMy interests\nMy personality\nMy Skills\nMy dreams\nMy relationship with technology"

        EmpathyMap ->
            "SAYS\nTHINKS\nDOES\nFEELS"

        Table ->
            "Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6\n    Column7\nRow1\n    Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6\nRow2\n    Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6"

        GanttChart ->
            "2019-12-26 2020-01-31\n    title1\n        subtitle1\n            2019-12-26 2019-12-31\n    title2\n        subtitle2\n            2019-12-31 2020-01-04\n"

        ErDiagram ->
            "relations\n    # one to one\n    Table1 - Table2\n    # one to many\n    Table1 < Table3\ntables\n    Table1\n        id int pk auto_increment\n        name varchar(255) unique\n        rate float null\n        value double not null\n        values enum(value1,value2) not null\n    Table2\n        id int pk auto_increment\n        name double unique\n    Table3\n        id int pk auto_increment\n        name varchar(255) index\n"

        Kanban ->
            "TODO\nDOING\nDONE"

        SequenceDiagram ->
            "participant\n    object1\n    object2\n    object3\nobject1 -> object2\n    Sync Message\nobject1 ->> object2\n    Async Message\nobject2 --> object1\n    Reply Message\no-> object1\n    Found Message\nobject1 ->o\n    Stop Message\nloop\n    loop message\n        object1 -> object2\n            Sync Message\n        object1 ->> object2\n            Async Message\nPar\n    par message1\n        object2 -> object3\n            Sync Message\n    par message2\n        object1 -> object2\n            Sync Message\n"

        UseCaseDiagram ->
            "[Customer]\n    Sign In\n    Buy Products\n(Buy Products)\n    >Browse Products\n    >Checkout\n(Checkout)\n    <Add New Credit Card\n[Staff]\n    Processs Order\n"

        _ ->
            ""


fromGraphqlValue : Diagram -> DiagramType
fromGraphqlValue diagram =
    case diagram of
        Diagram.UserStoryMap ->
            UserStoryMap

        Diagram.OpportunityCanvas ->
            OpportunityCanvas

        Diagram.BusinessModelCanvas ->
            BusinessModelCanvas

        Diagram.Fourls ->
            Fourls

        Diagram.StartStopContinue ->
            StartStopContinue

        Diagram.Kpt ->
            Kpt

        Diagram.UserPersona ->
            UserPersona

        Diagram.MindMap ->
            MindMap

        Diagram.EmpathyMap ->
            EmpathyMap

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

        Diagram.Table ->
            Table

        Diagram.SequenceDiagram ->
            SequenceDiagram

        Diagram.Freeform ->
            Freeform

        Diagram.UseCaseDiagram ->
            UseCaseDiagram


fromString : String -> DiagramType
fromString s =
    case s of
        "4ls" ->
            Fourls

        "bmc" ->
            BusinessModelCanvas

        "emm" ->
            EmpathyMap

        "erd" ->
            ErDiagram

        "free" ->
            Freeform

        "gct" ->
            GanttChart

        "imm" ->
            ImpactMap

        "kanban" ->
            Kanban

        "kpt" ->
            Kpt

        "mmp" ->
            MindMap

        "opc" ->
            OpportunityCanvas

        "persona" ->
            UserPersona

        "sed" ->
            SequenceDiagram

        "smp" ->
            SiteMap

        "ssc" ->
            StartStopContinue

        "table" ->
            Table

        "ucd" ->
            UseCaseDiagram

        "usm" ->
            UserStoryMap

        _ ->
            UserStoryMap


toDiagram : String -> Maybe DiagramType
toDiagram s =
    case s of
        "4ls" ->
            Just Fourls

        "bmc" ->
            Just BusinessModelCanvas

        "emm" ->
            Just EmpathyMap

        "erd" ->
            Just ErDiagram

        "free" ->
            Just Freeform

        "gct" ->
            Just GanttChart

        "imm" ->
            Just ImpactMap

        "kanban" ->
            Just Kanban

        "kpt" ->
            Just Kpt

        "mmp" ->
            Just MindMap

        "opc" ->
            Just OpportunityCanvas

        "persona" ->
            Just UserPersona

        "sed" ->
            Just SequenceDiagram

        "smp" ->
            Just SiteMap

        "ssc" ->
            Just StartStopContinue

        "table" ->
            Just Table

        "ucd" ->
            Just UseCaseDiagram

        "usm" ->
            Just UserStoryMap

        _ ->
            Nothing


toGraphqlValue : DiagramType -> Diagram
toGraphqlValue diagramType =
    case diagramType of
        UserStoryMap ->
            Diagram.UserStoryMap

        OpportunityCanvas ->
            Diagram.OpportunityCanvas

        BusinessModelCanvas ->
            Diagram.BusinessModelCanvas

        Fourls ->
            Diagram.Fourls

        StartStopContinue ->
            Diagram.StartStopContinue

        Kpt ->
            Diagram.Kpt

        UserPersona ->
            Diagram.UserPersona

        MindMap ->
            Diagram.MindMap

        EmpathyMap ->
            Diagram.EmpathyMap

        SiteMap ->
            Diagram.SiteMap

        GanttChart ->
            Diagram.GanttChart

        ImpactMap ->
            Diagram.ImpactMap

        ErDiagram ->
            Diagram.ErDiagram

        Kanban ->
            Diagram.Kanban

        Table ->
            Diagram.Table

        SequenceDiagram ->
            Diagram.SequenceDiagram

        Freeform ->
            Diagram.Freeform

        UseCaseDiagram ->
            Diagram.UseCaseDiagram


toLongString : DiagramType -> String
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

        MindMap ->
            "Mind Map"

        EmpathyMap ->
            "Empathy Map"

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

        Table ->
            "Table"

        SequenceDiagram ->
            "Sequence Diagram"

        Freeform ->
            "Freeform"

        UseCaseDiagram ->
            "UseCaseDiagram"


toString : DiagramType -> String
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

        MindMap ->
            "mmp"

        EmpathyMap ->
            "emm"

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

        Table ->
            "table"

        SequenceDiagram ->
            "sed"

        Freeform ->
            "free"

        UseCaseDiagram ->
            "ucd"
