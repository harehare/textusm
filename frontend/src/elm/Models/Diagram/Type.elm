module Models.Diagram.Type exposing
    ( DiagramType(..)
    , defaultText
    , fromGraphqlValue
    , fromString
    , fromTypeString
    , toDiagram
    , toGraphqlValue
    , toLongString
    , toString
    , toTypeString
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
    | KeyboardLayout


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

        MindMap ->
            "USER ACTIVITY\nUSER TASK\nUSER STORY"

        ImpactMap ->
            "USER ACTIVITY\nUSER TASK\nUSER STORY"

        SiteMap ->
            "USER ACTIVITY\nUSER TASK\nUSER STORY"

        Freeform ->
            ""

        KeyboardLayout ->
            "r4\n    Esc\n    1u\n    F1\n    F2\n    F3\n    F4\n    0.5u\n    F5\n    F6\n    F7\n    F8\n    0.5u\n    F9\n    F10\n    F11\n    F12\n    0.5u\n    Home\n    End\n    PgUp\n    PgDn\n0.25u\nr4\n    ~,`\n    !,1\n    @,2\n    {sharp},3\n    $,4\n    %,5\n    ^,6\n    &,7\n    *,8\n    (,9\n    ),0\n    _,-\n    =,+\n    Backspace,,2u\n    0.5u\n    Num,Lock\n    /\n    *\n    -\nr4\n    Tab,,1.5u\n    Q\n    W\n    E\n    R\n    T\n    Y\n    U\n    I\n    O\n    P\n    {,[\n    },]\n    |,\\,1.5u\n    0.5u\n    7,Home\n    8,↑\n    9,PgUp\n    +,,,2u\nr3\n    Caps Lock,,1.75u\n    A\n    S\n    D\n    F\n    G\n    H\n    J\n    K\n    L\n    :,;\n    \",'\n    Enter,,2.25u\n    0.5u\n    4, ←\n    5\n    6,→\nr2\n    Shift,,2.25u\n    Z\n    X\n    C\n    V\n    B\n    N\n    M\n    <,{comma}\n    >,.\n    ?,/\n    Shift,,1.75u\n    0.25u\n    ↑,,,,0.25u\n    0.25u\n    1,End\n    2,↓\n    3,PgDn\n    Enter,,,2u\nr1\n    Ctrl,,1.5u\n    Alt,,1.5u\n    ,,7u\n    Alt,,1.5u\n    Ctl,,1.5u\n    0.25u\n    ←,,,,0.25u\n    ↓,,,,0.25u\n    →,,,,0.25u\n    0.25u\n    0,Ins\n    .,Del"


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

        Diagram.KeyboardLayout ->
            KeyboardLayout


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

        "kbd" ->
            KeyboardLayout

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

        "kbd" ->
            Just KeyboardLayout

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

        KeyboardLayout ->
            Diagram.KeyboardLayout


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

        KeyboardLayout ->
            "KeyboardLayout"


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

        KeyboardLayout ->
            "kbd"

        UseCaseDiagram ->
            "ucd"


toTypeString : DiagramType -> String
toTypeString diagramType =
    case diagramType of
        UserStoryMap ->
            "UserStoryMap"

        OpportunityCanvas ->
            "OpportunityCanvas"

        BusinessModelCanvas ->
            "BusinessModelCanvas"

        Fourls ->
            "Fourls"

        StartStopContinue ->
            "StartStopContinue"

        Kpt ->
            "Kpt"

        UserPersona ->
            "UserPersona"

        MindMap ->
            "MindMap"

        EmpathyMap ->
            "EmpathyMap"

        SiteMap ->
            "SiteMap"

        GanttChart ->
            "GanttChart"

        ImpactMap ->
            "ImpactMap"

        ErDiagram ->
            "ErDiagram"

        Kanban ->
            "Kanban"

        Table ->
            "Table"

        SequenceDiagram ->
            "SequenceDiagram"

        Freeform ->
            "Freeform"

        UseCaseDiagram ->
            "UseCaseDiagram"

        KeyboardLayout ->
            "KeyboardLayout"


fromTypeString : String -> DiagramType
fromTypeString s =
    case s of
        "BusinessModelCanvas" ->
            BusinessModelCanvas

        "OpportunityCanvas" ->
            OpportunityCanvas

        "4Ls" ->
            Fourls

        "StartStopContinue" ->
            StartStopContinue

        "Kpt" ->
            Kpt

        "UserPersona" ->
            UserPersona

        "MindMap" ->
            MindMap

        "EmpathyMap" ->
            EmpathyMap

        "Table" ->
            Table

        "SiteMap" ->
            SiteMap

        "GanttChart" ->
            GanttChart

        "ImpactMap" ->
            ImpactMap

        "ER" ->
            ErDiagram

        "Kanban" ->
            Kanban

        "SequenceDiagram" ->
            SequenceDiagram

        "Freeform" ->
            Freeform

        "UseCaseDiagram" ->
            UseCaseDiagram

        "KeyboardLayout" ->
            KeyboardLayout

        _ ->
            UserStoryMap
