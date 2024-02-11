module Diagram.Types.Data exposing (Data(..), Hierarchy)

import Diagram.BusinessModelCanvas.Types exposing (BusinessModelCanvas)
import Diagram.ER.Types exposing (ErDiagram)
import Diagram.EmpathyMap.Types exposing (EmpathyMap)
import Diagram.FourLs.Types exposing (FourLs)
import Diagram.FreeForm.Types exposing (FreeForm)
import Diagram.GanttChart.Types exposing (GanttChart)
import Diagram.Kanban.Types exposing (Kanban)
import Diagram.KeyboardLayout.Types exposing (KeyboardLayout)
import Diagram.Kpt.Types exposing (Kpt)
import Diagram.OpportunityCanvas.Types exposing (OpportunityCanvas)
import Diagram.SequenceDiagram.Types exposing (SequenceDiagram)
import Diagram.StartStopContinue.Types exposing (StartStopContinue)
import Diagram.Table.Types exposing (Table)
import Diagram.UseCaseDiagram.Types exposing (UseCaseDiagram)
import Diagram.UserPersona.Types exposing (UserPersona)
import Diagram.UserStoryMap.Types exposing (UserStoryMap)
import Types.Item exposing (Items)


type Data
    = Empty
    | UserStoryMap UserStoryMap
    | MindMap Items Hierarchy
    | SiteMap Items Hierarchy
    | Table Table
    | Kpt Kpt
    | FourLs FourLs
    | Kanban Kanban
    | BusinessModelCanvas BusinessModelCanvas
    | EmpathyMap EmpathyMap
    | OpportunityCanvas OpportunityCanvas
    | UserPersona UserPersona
    | StartStopContinue StartStopContinue
    | ErDiagram ErDiagram
    | SequenceDiagram SequenceDiagram
    | FreeForm FreeForm
    | GanttChart (Maybe GanttChart)
    | UseCaseDiagram UseCaseDiagram
    | KeyboardLayout KeyboardLayout


type alias Hierarchy =
    Int
