module Diagram.Types exposing
    ( ContextMenu(..)
    , ContextMenuProps
    , Diagram
    , Distance
    , DragStatus(..)
    , IsWheelEvent
    , Model
    , MoveState(..)
    , MoveTarget(..)
    , Msg(..)
    , ResizeDirection(..)
    , SelectedItem
    , SelectedItemInfo
    , diagramType
    , dragStart
    , isFullscreen
    , moveOrZoom
    , movePosition
    , moveingItem
    , position
    , settings
    , showZoomControl
    , size
    , text
    , updatedText
    , windowSize
    )

import Browser.Dom exposing (Viewport)
import Diagram.BusinessModelCanvas.Types as BusinessModelCanvasModel
import Diagram.ER.Types as ERModel
import Diagram.EmpathyMap.Types as EmpathyMapModel
import Diagram.FourLs.Types as FourLsModel
import Diagram.FreeForm.Types as FreeFormModel
import Diagram.GanttChart.Types as GanttChartModel
import Diagram.ImpactMap.Types as ImpactMapModel
import Diagram.Kanban.Types as KanbanModel
import Diagram.KeyboardLayout.Types as KeyboardLayoutModel
import Diagram.Kpt.Types as KptModel
import Diagram.MindMap.Types as MindMapModel
import Diagram.OpportunityCanvas.Types as OpportunityCanvasModel
import Diagram.Search.Types exposing (Search)
import Diagram.SequenceDiagram.Types as SequenceDiagramModel
import Diagram.SiteMap.Types as SiteMapModel
import Diagram.StartStopContinue.Types as StartStopContinueModel
import Diagram.Table.Types as TableModel
import Diagram.Types.Data as DiagramData
import Diagram.Types.Scale exposing (Scale)
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type exposing (DiagramType(..))
import Diagram.UseCaseDiagram.Types as UseCaseDiagramModel
import Diagram.UserPersona.Types as UserPersonaModel
import Diagram.UserStoryMap.Types as UserStoryMapModel
import Events
import Events.Wheel as Wheel
import File exposing (File)
import List.Extra exposing (getAt)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Svg.Styled as Svg
import Types.Color as Color
import Types.FontSize exposing (FontSize)
import Types.FontStyle exposing (FontStyle)
import Types.Item exposing (Item, Items)
import Types.Position exposing (Position)
import Types.Property exposing (Property)
import Types.Size exposing (Size)
import Types.Text exposing (Text)
import Utils.Utils as Utils


type ContextMenu
    = CloseMenu
    | ColorSelectMenu
    | BackgroundColorSelectMenu


type alias ContextMenuProps =
    { contextMenu : ContextMenu
    , position : Position
    , displayAllMenu : Bool
    }


type alias Distance =
    Float


type DragStatus
    = NoDrag
    | DragOver


type alias Model =
    { items : Items
    , data : DiagramData.Data
    , windowSize : Size
    , diagram : Diagram
    , moveState : MoveState
    , movePosition : Position
    , settings : DiagramSettings.Settings
    , showZoomControl : Bool
    , showMiniMap : Bool
    , search : Search
    , touchDistance : Maybe Float
    , diagramType : DiagramType
    , text : Text
    , selectedItem : SelectedItem
    , contextMenu : Maybe ContextMenuProps
    , dragStatus : DragStatus
    , dropDownIndex : Maybe String
    , property : Property
    }


type MoveState
    = BoardMove
    | ItemMove MoveTarget
    | ItemResize Item ResizeDirection
    | MiniMapMove
    | WheelMove
    | NotMove


type MoveTarget
    = TableTarget ERModel.Table
    | ItemTarget Item


type alias IsWheelEvent =
    Bool


type Msg
    = NoOp
    | Init DiagramSettings.Settings Viewport String
    | ZoomIn Scale
    | ZoomOut Scale
    | PinchIn Float
    | PinchOut Float
    | Move IsWheelEvent Position
    | MoveTo Position
    | ToggleFullscreen
    | EditSelectedItem String
    | EndEditSelectedItem Item
    | FitToWindow
    | ColorChanged ContextMenu Color.Color
    | FontStyleChanged FontStyle
    | DropFiles (List File)
    | LoadFile String
    | ChangeDragStatus DragStatus
    | FontSizeChanged FontSize
    | ToggleDropDownList String
    | ToggleMiniMap
    | ToggleSearch
    | ToggleEdit
    | ToolbarClick Item
    | ChangeText String
    | Resize Int Int
    | Search String
    | Start MoveState Position
    | StartPinch Distance
    | Select (Maybe SelectedItemInfo)
    | SelectContextMenu ContextMenu
    | Stop
    | SelectFromLineNo Int String


type ResizeDirection
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Top
    | Bottom
    | Left
    | Right


type alias SelectedItem =
    Maybe Item


type alias SelectedItemInfo =
    { item : Item
    , position : Position
    , displayAllMenu : Bool
    }


type alias Diagram =
    { size : Size
    , position : Position
    , isFullscreen : Bool
    }


moveOrZoom : MoveState -> Scale -> Wheel.Event -> Msg
moveOrZoom moveState ratio wheelEvent =
    if (wheelEvent.deltaX |> Maybe.withDefault 0.0) == 0.0 then
        if wheelEvent.deltaY > 0 then
            ZoomOut ratio

        else
            ZoomIn ratio

    else
        case moveState of
            NotMove ->
                Start WheelMove ( round (wheelEvent.deltaX |> Maybe.withDefault 0.0), round wheelEvent.deltaY )

            WheelMove ->
                Move True ( round (wheelEvent.deltaX |> Maybe.withDefault 0.0), round wheelEvent.deltaY )

            _ ->
                NoOp


dragStart : MoveState -> Bool -> Svg.Attribute Msg
dragStart state isPhone =
    if isPhone then
        Events.onTouchStart
            (\event ->
                if List.length event.changedTouches > 1 then
                    let
                        p1 : ( Float, Float )
                        p1 =
                            getAt 0 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0.0, 0.0 )

                        p2 : ( Float, Float )
                        p2 =
                            getAt 1 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0.0, 0.0 )
                    in
                    StartPinch (Utils.calcDistance p1 p2)

                else
                    let
                        ( x, y ) =
                            Events.touchCoordinates event
                    in
                    Start state ( round x, round y )
            )

    else
        Events.onMouseDown
            (\event ->
                let
                    ( x, y ) =
                        event.pagePos
                in
                Start state ( round x, round y )
            )


moveingItem : MoveState -> Maybe Item
moveingItem moveState =
    case moveState of
        ItemMove target ->
            case target of
                ItemTarget item ->
                    Just item

                _ ->
                    Nothing

        _ ->
            Nothing


diagramType : Lens Model DiagramType
diagramType =
    Lens .diagramType (\b a -> { a | diagramType = b })


position : Lens Model Position
position =
    ofDiagram |> Compose.lensWithLens diagramOfPosition


isFullscreen : Lens Model Bool
isFullscreen =
    ofDiagram |> Compose.lensWithLens diagramOfIsFullscreen


movePosition : Lens Model Position
movePosition =
    Lens .movePosition (\b a -> { a | movePosition = b })


settings : Lens Model DiagramSettings.Settings
settings =
    Lens .settings (\b a -> { a | settings = b })


showZoomControl : Lens Model Bool
showZoomControl =
    Lens .showZoomControl (\b a -> { a | showZoomControl = b })


windowSize : Lens Model Size
windowSize =
    Lens .windowSize (\b a -> { a | windowSize = b })


text : Lens Model Text
text =
    Lens .text (\b a -> { a | text = b })


size : Model -> Size
size model =
    case ( model.diagramType, model.data ) of
        ( UserStoryMap, DiagramData.UserStoryMap userStoryMap ) ->
            UserStoryMapModel.size model.settings userStoryMap

        ( OpportunityCanvas, _ ) ->
            OpportunityCanvasModel.size model.settings model.items

        ( BusinessModelCanvas, _ ) ->
            BusinessModelCanvasModel.size model.settings model.items

        ( Fourls, _ ) ->
            FourLsModel.size model.settings model.items

        ( StartStopContinue, _ ) ->
            StartStopContinueModel.size model.settings model.items

        ( Kpt, _ ) ->
            KptModel.size model.settings model.items

        ( UserPersona, _ ) ->
            UserPersonaModel.size model.settings model.items

        ( MindMap, DiagramData.MindMap items_ hierarchy_ ) ->
            MindMapModel.size model.settings items_ hierarchy_

        ( EmpathyMap, _ ) ->
            EmpathyMapModel.size model.settings model.items

        ( SiteMap, DiagramData.SiteMap siteMapitems hierarchy_ ) ->
            SiteMapModel.size model.settings siteMapitems hierarchy_

        ( GanttChart, DiagramData.GanttChart (Just gantt) ) ->
            GanttChartModel.size gantt

        ( ImpactMap, DiagramData.MindMap items_ hierarchy_ ) ->
            ImpactMapModel.size model.settings items_ hierarchy_

        ( ErDiagram, _ ) ->
            ERModel.size model.items

        ( Kanban, DiagramData.Kanban kanban ) ->
            KanbanModel.size model.settings kanban

        ( Table, _ ) ->
            TableModel.size model.settings model.items

        ( SequenceDiagram, DiagramData.SequenceDiagram sequenceDiagram ) ->
            SequenceDiagramModel.size model.settings sequenceDiagram

        ( Freeform, DiagramData.FreeForm freeForm ) ->
            FreeFormModel.size model.settings freeForm

        ( UseCaseDiagram, DiagramData.UseCaseDiagram useCaseDiagram ) ->
            UseCaseDiagramModel.size useCaseDiagram

        ( KeyboardLayout, DiagramData.KeyboardLayout keyboardLayout ) ->
            KeyboardLayoutModel.size keyboardLayout

        _ ->
            ( 0, 0 )


updatedText : Model -> Text -> Model
updatedText model text_ =
    { model | text = text_ }


ofDiagram : Lens Model Diagram
ofDiagram =
    Lens .diagram (\b a -> { a | diagram = b })


diagramOfPosition : Lens Diagram Position
diagramOfPosition =
    Lens .position (\b a -> { a | position = b })


diagramOfIsFullscreen : Lens Diagram Bool
diagramOfIsFullscreen =
    Lens .isFullscreen (\b a -> { a | isFullscreen = b })
