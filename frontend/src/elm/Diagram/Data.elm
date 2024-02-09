module Diagram.Data exposing (Data(..), Hierarchy)

import Diagram.BusinessModelCanvas.Model exposing (BusinessModelCanvas)
import Diagram.ER.Model exposing (ErDiagram)
import Diagram.EmpathyMap.Model exposing (EmpathyMap)
import Diagram.FourLs.Model exposing (FourLs)
import Diagram.FreeForm.Model exposing (FreeForm)
import Diagram.GanttChart.Model exposing (GanttChart)
import Diagram.Kanban.Model exposing (Kanban)
import Diagram.KeyboardLayout.Model exposing (KeyboardLayout)
import Diagram.Kpt.Model exposing (Kpt)
import Diagram.OpportunityCanvas.Model exposing (OpportunityCanvas)
import Diagram.SequenceDiagram.Model exposing (SequenceDiagram)
import Diagram.StartStopContinue.Model exposing (StartStopContinue)
import Diagram.Table.Model exposing (Table)
import Diagram.UseCaseDiagram.Model exposing (UseCaseDiagram)
import Diagram.UserPersona.Model exposing (UserPersona)
import Diagram.UserStoryMap.Model exposing (UserStoryMap)
import Models.Item exposing (Items)


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
