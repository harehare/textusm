module Models.Diagram exposing
    ( ContextMenu(..)
    , ContextMenuProps
    , Distance
    , DragStatus(..)
    , Model
    , MoveState(..)
    , MoveTarget(..)
    , Msg(..)
    , ResizeDirection(..)
    , SelectedItem
    , SelectedItemInfo
    , SvgInfo
    , chooseZoom
    , dragStart
    , moveingItem
    , ofDiagramType
    , ofPosition
    , ofScale
    , ofSettings
    , ofShowZoomControl
    , ofSize
    , ofText
    , size
    , updatedText
    )

import Browser.Dom exposing (Viewport)
import Events
import File exposing (File)
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html.Events.Extra.Wheel as Wheel
import List.Extra exposing (getAt)
import Models.Color as Color
import Models.Diagram.BusinessModelCanvas as BusinessModelCanvasModel
import Models.Diagram.ER as ERModel
import Models.Diagram.EmpathyMap as EmpathyMapModel
import Models.Diagram.FourLs as FourLsModel
import Models.Diagram.FreeForm as FreeFormModel
import Models.Diagram.GanttChart as GanttChartModel
import Models.Diagram.ImpactMap as ImpactMapModel
import Models.Diagram.Kanban as KanbanModel
import Models.Diagram.Kpt as KptModel
import Models.Diagram.MindMap as MindMapModel
import Models.Diagram.OpportunityCanvas as OpportunityCanvasModel
import Models.Diagram.SequenceDiagram as SequenceDiagramModel
import Models.Diagram.SiteMap as SiteMapModel
import Models.Diagram.StartStopContinue as StartStopContinueModel
import Models.Diagram.Table as TableModel
import Models.Diagram.UseCaseDiagram as UseCaseDiagramModel
import Models.Diagram.UserPersona as UserPersonaModel
import Models.Diagram.UserStoryMap as UserStoryMapModel
import Models.DiagramData as DiagramData exposing (DiagramData)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize exposing (FontSize)
import Models.FontStyle exposing (FontStyle)
import Models.Item exposing (Item, Items)
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import Models.Size exposing (Size)
import Models.Text exposing (Text)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Svg.Styled as Svg
import Utils.Utils as Utils


type alias SelectedItem =
    Maybe Item


type alias ContextMenuProps =
    { contextMenu : ContextMenu
    , position : Position
    , displayAllMenu : Bool
    }


type Msg
    = NoOp
    | Init DiagramSettings.Settings Viewport String
    | OnChangeText String
    | ZoomIn Float
    | ZoomOut Float
    | PinchIn Float
    | PinchOut Float
    | Stop
    | Start MoveState Position
    | Move Position
    | MoveTo Position
    | ToggleFullscreen
    | OnResize Int Int
    | StartPinch Distance
    | EditSelectedItem String
    | EndEditSelectedItem Item
    | FitToWindow
    | Select (Maybe SelectedItemInfo)
    | ColorChanged ContextMenu Color.Color
    | SelectContextMenu ContextMenu
    | FontStyleChanged FontStyle
    | DropFiles (List File)
    | LoadFile String
    | ChangeDragStatus DragStatus
    | FontSizeChanged FontSize
    | ToggleDropDownList String
    | ToggleMiniMap
    | ToolbarClick Item


type alias Model =
    { items : Items
    , data : DiagramData
    , size : Size
    , svg : SvgInfo
    , moveState : MoveState
    , position : Position
    , movePosition : Position
    , fullscreen : Bool
    , settings : DiagramSettings.Settings
    , showZoomControl : Bool
    , showMiniMap : Bool
    , touchDistance : Maybe Float
    , diagramType : Diagram
    , text : Text
    , selectedItem : SelectedItem
    , contextMenu : Maybe ContextMenuProps
    , dragStatus : DragStatus
    , dropDownIndex : Maybe String
    , property : Property
    }


ofDiagramType : Lens Model Diagram
ofDiagramType =
    Lens .diagramType (\b a -> { a | diagramType = b })


ofText : Lens Model Text
ofText =
    Lens .text (\b a -> { a | text = b })


ofShowZoomControl : Lens Model Bool
ofShowZoomControl =
    Lens .showZoomControl (\b a -> { a | showZoomControl = b })


ofPosition : Lens Model Position
ofPosition =
    Lens .position (\b a -> { a | position = b })


ofSettings : Lens Model DiagramSettings.Settings
ofSettings =
    Lens .settings (\b a -> { a | settings = b })


ofSvg : Lens Model SvgInfo
ofSvg =
    Lens .svg (\b a -> { a | svg = b })


svgOfScale : Lens SvgInfo Float
svgOfScale =
    Lens .scale (\b a -> { a | scale = b })


ofScale : Lens Model Float
ofScale =
    ofSvg |> Compose.lensWithLens svgOfScale


ofSize : Lens Model Size
ofSize =
    Lens .size (\b a -> { a | size = b })


type alias Distance =
    Float


type ContextMenu
    = CloseMenu
    | ColorSelectMenu
    | BackgroundColorSelectMenu


type DragStatus
    = NoDrag
    | DragOver


type MoveState
    = BoardMove
    | ItemMove MoveTarget
    | ItemResize Item ResizeDirection
    | MiniMapMove
    | NotMove


type MoveTarget
    = TableTarget ERModel.Table
    | ItemTarget Item


type ResizeDirection
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Top
    | Bottom
    | Left
    | Right


moveingItem : Model -> Maybe Item
moveingItem model =
    case model.moveState of
        ItemMove target ->
            case target of
                ItemTarget item ->
                    Just item

                _ ->
                    Nothing

        _ ->
            Nothing


updatedText : Model -> Text -> Model
updatedText model text =
    { model | text = text }


type alias SvgInfo =
    { width : Int
    , height : Int
    , scale : Float
    }


type alias SelectedItemInfo =
    { item : Item
    , position : Position
    , displayAllMenu : Bool
    }


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


chooseZoom : Float -> Wheel.Event -> Msg
chooseZoom ratio wheelEvent =
    if wheelEvent.deltaY > 0 then
        ZoomOut ratio

    else
        ZoomIn ratio


size : Model -> Size
size model =
    case ( model.diagramType, model.data ) of
        ( Fourls, _ ) ->
            FourLsModel.size model.settings model.items

        ( EmpathyMap, _ ) ->
            EmpathyMapModel.size model.settings model.items

        ( OpportunityCanvas, _ ) ->
            OpportunityCanvasModel.size model.settings model.items

        ( BusinessModelCanvas, _ ) ->
            BusinessModelCanvasModel.size model.settings model.items

        ( Kpt, _ ) ->
            KptModel.size model.settings model.items

        ( StartStopContinue, _ ) ->
            StartStopContinueModel.size model.settings model.items

        ( UserPersona, _ ) ->
            UserPersonaModel.size model.settings model.items

        ( ErDiagram, _ ) ->
            ERModel.size model.items

        ( MindMap, DiagramData.MindMap items_ hierarchy_ ) ->
            MindMapModel.size model.settings items_ hierarchy_

        ( Table, _ ) ->
            TableModel.size model.settings model.items

        ( SiteMap, DiagramData.SiteMap siteMapitems hierarchy_ ) ->
            SiteMapModel.size model.settings siteMapitems hierarchy_

        ( UserStoryMap, DiagramData.UserStoryMap userStoryMap ) ->
            UserStoryMapModel.size model.settings userStoryMap

        ( ImpactMap, DiagramData.ImpactMap items_ hierarchy_ ) ->
            ImpactMapModel.size model.settings items_ hierarchy_

        ( GanttChart, DiagramData.GanttChart (Just gantt) ) ->
            GanttChartModel.size gantt

        ( Kanban, DiagramData.Kanban kanban ) ->
            KanbanModel.size model.settings kanban

        ( SequenceDiagram, DiagramData.SequenceDiagram sequenceDiagram ) ->
            SequenceDiagramModel.size model.settings sequenceDiagram

        ( Freeform, DiagramData.FreeForm freeForm ) ->
            FreeFormModel.size model.settings freeForm

        ( UseCaseDiagram, DiagramData.UseCaseDiagram useCaseDiagram ) ->
            UseCaseDiagramModel.size useCaseDiagram

        _ ->
            ( 0, 0 )
