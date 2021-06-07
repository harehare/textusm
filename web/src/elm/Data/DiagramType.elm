module Data.DiagramType exposing (defaultText, fromString, toDiagram, toLongString, toString)

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

        Freeform ->
            "free"

        UseCaseDiagram ->
            "ucd"


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

        Freeform ->
            "Freeform"

        UseCaseDiagram ->
            "UseCaseDiagram"


toDiagram : String -> Maybe Diagram
toDiagram s =
    case s of
        "usm" ->
            Just UserStoryMap

        "opc" ->
            Just OpportunityCanvas

        "bmc" ->
            Just BusinessModelCanvas

        "4ls" ->
            Just Fourls

        "ssc" ->
            Just StartStopContinue

        "kpt" ->
            Just Kpt

        "persona" ->
            Just UserPersona

        "mmp" ->
            Just MindMap

        "emm" ->
            Just EmpathyMap

        "table" ->
            Just Table

        "smp" ->
            Just SiteMap

        "gct" ->
            Just GanttChart

        "imm" ->
            Just ImpactMap

        "erd" ->
            Just ErDiagram

        "kanban" ->
            Just Kanban

        "sed" ->
            Just SequenceDiagram

        "free" ->
            Just Freeform

        "ucd" ->
            Just UseCaseDiagram

        _ ->
            Nothing


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

        "free" ->
            Freeform

        "ucd" ->
            UseCaseDiagram

        _ ->
            UserStoryMap


defaultText : Diagram -> String
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
