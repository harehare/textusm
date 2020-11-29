module TestDiagramType exposing (all)

import Data.DiagramType exposing (toLongString, toString)
import Expect
import Test exposing (Test, describe, test)
import TextUSM.Enum.Diagram exposing (Diagram(..))


all : Test
all =
    describe "DiagramType test"
        [ describe "toString test"
            [ test "usm test" <|
                \() ->
                    Expect.equal (toString UserStoryMap) "usm"
            , test "bmc test" <|
                \() ->
                    Expect.equal (toString BusinessModelCanvas) "bmc"
            , test "opc test" <|
                \() ->
                    Expect.equal (toString OpportunityCanvas) "opc"
            , test "4ls test" <|
                \() ->
                    Expect.equal (toString Fourls) "4ls"
            , test "ssc test" <|
                \() ->
                    Expect.equal (toString StartStopContinue) "ssc"
            , test "kpt test" <|
                \() ->
                    Expect.equal (toString Kpt) "kpt"
            , test "persona test" <|
                \() ->
                    Expect.equal (toString UserPersona) "persona"
            , test "mmp test" <|
                \() ->
                    Expect.equal (toString MindMap) "mmp"
            , test "emm test" <|
                \() ->
                    Expect.equal (toString EmpathyMap) "emm"
            , test "cjm test" <|
                \() ->
                    Expect.equal (toString Table) "table"
            , test "smp test" <|
                \() ->
                    Expect.equal (toString SiteMap) "smp"
            , test "gct test" <|
                \() ->
                    Expect.equal (toString GanttChart) "gct"
            , test "imm test" <|
                \() ->
                    Expect.equal (toString ImpactMap) "imm"
            , test "erd test" <|
                \() ->
                    Expect.equal (toString ErDiagram) "erd"
            ]
        , describe "toLongString test"
            [ test "usm test" <|
                \() ->
                    Expect.equal (toLongString UserStoryMap) "User Story Map"
            , test "bmc test" <|
                \() ->
                    Expect.equal (toLongString BusinessModelCanvas) "Business Model Canvas"
            , test "opc test" <|
                \() ->
                    Expect.equal (toLongString OpportunityCanvas) "Opportunity Canvas"
            , test "4ls test" <|
                \() ->
                    Expect.equal (toLongString Fourls) "4Ls"
            , test "ssc test" <|
                \() ->
                    Expect.equal (toLongString StartStopContinue) "Start, Stop, Continue"
            , test "kpt test" <|
                \() ->
                    Expect.equal (toLongString Kpt) "KPT"
            , test "persona test" <|
                \() ->
                    Expect.equal (toLongString UserPersona) "User Persona"
            , test "mmp test" <|
                \() ->
                    Expect.equal (toLongString MindMap) "Mind Map"
            , test "emm test" <|
                \() ->
                    Expect.equal (toLongString EmpathyMap) "Empathy Map"
            , test "cjm test" <|
                \() ->
                    Expect.equal (toLongString Table) "Table"
            , test "smp test" <|
                \() ->
                    Expect.equal (toLongString SiteMap) "Site Map"
            , test "gct test" <|
                \() ->
                    Expect.equal (toLongString GanttChart) "Gantt Chart"
            , test "imm test" <|
                \() ->
                    Expect.equal (toLongString ImpactMap) "Impact Map"
            , test "erd test" <|
                \() ->
                    Expect.equal (toLongString ErDiagram) "ER Diagram"
            ]
        ]
