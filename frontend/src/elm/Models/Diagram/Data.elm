module Models.Diagram.Data exposing (Data(..), Hierarchy)

import Models.Diagram.BusinessModelCanvas exposing (BusinessModelCanvas)
import Models.Diagram.ER exposing (ErDiagram)
import Models.Diagram.EmpathyMap exposing (EmpathyMap)
import Models.Diagram.FourLs exposing (FourLs)
import Models.Diagram.FreeForm exposing (FreeForm)
import Models.Diagram.GanttChart exposing (GanttChart)
import Models.Diagram.Kanban exposing (Kanban)
import Models.Diagram.KeyboardLayout exposing (KeyboardLayout)
import Models.Diagram.Kpt exposing (Kpt)
import Models.Diagram.OpportunityCanvas exposing (OpportunityCanvas)
import Models.Diagram.SequenceDiagram exposing (SequenceDiagram)
import Models.Diagram.StartStopContinue exposing (StartStopContinue)
import Models.Diagram.Table exposing (Table)
import Models.Diagram.UseCaseDiagram exposing (UseCaseDiagram)
import Models.Diagram.UserPersona exposing (UserPersona)
import Models.Diagram.UserStoryMap exposing (UserStoryMap)
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
