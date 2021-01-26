module Models.Diagram exposing
    ( Color
    , ColorSettings
    , ContextMenu(..)
    , Data(..)
    , DragStatus(..)
    , Model
    , MoveState(..)
    , MoveTarget(..)
    , Msg(..)
    , SelectedItem
    , Settings
    , Size
    , dragStart
    , fontStyle
    , getTextColor
    , isMoving
    , modelOfDiagramType
    , modelOfFullscreen
    , modelOfPosition
    , modelOfSelectedItem
    , modelOfSettings
    , modelOfShowZoomControl
    , modelOfText
    , settingsOfActivityBackgroundColor
    , settingsOfActivityColor
    , settingsOfBackgroundColor
    , settingsOfFont
    , settingsOfHeight
    , settingsOfLabelColor
    , settingsOfLineColor
    , settingsOfScale
    , settingsOfStoryBackgroundColor
    , settingsOfStoryColor
    , settingsOfTaskBackgroundColor
    , settingsOfTaskColor
    , settingsOfTextColor
    , settingsOfWidth
    , settingsOfZoomControl
    , updatedText
    )

import Browser.Dom exposing (Viewport)
import Data.Color as Color
import Data.FontSize exposing (FontSize)
import Data.FontStyle exposing (FontStyle)
import Data.Item exposing (Item, ItemType(..), Items)
import Data.Position exposing (Position)
import Data.Size as Size
import Data.Text exposing (Text)
import Events
import File exposing (File)
import List.Extra exposing (getAt)
import Models.Views.BusinessModelCanvas exposing (BusinessModelCanvas)
import Models.Views.ER as ER exposing (ErDiagram)
import Models.Views.EmpathyMap exposing (EmpathyMap)
import Models.Views.FourLs exposing (FourLs)
import Models.Views.FreeForm exposing (FreeForm)
import Models.Views.Kanban exposing (Kanban)
import Models.Views.Kpt exposing (Kpt)
import Models.Views.OpportunityCanvas exposing (OpportunityCanvas)
import Models.Views.SequenceDiagram exposing (SequenceDiagram)
import Models.Views.StartStopContinue exposing (StartStopContinue)
import Models.Views.Table exposing (Table)
import Models.Views.UserPersona exposing (UserPersona)
import Models.Views.UserStoryMap exposing (UserStoryMap)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Svg
import TextUSM.Enum.Diagram exposing (Diagram)
import Utils.Utils as Utils


type alias IsDragging =
    Bool


type alias SelectedItem =
    Maybe ( Item, IsDragging )


type alias Model =
    { items : Items
    , data : Data
    , size : Size.Size
    , svg :
        { width : Int
        , height : Int
        , scale : Float
        }
    , moveState : MoveState
    , position : Position
    , movePosition : Position
    , fullscreen : Bool
    , settings : Settings
    , showZoomControl : Bool
    , showMiniMap : Bool
    , touchDistance : Maybe Float
    , diagramType : Diagram
    , text : Text
    , selectedItem : SelectedItem
    , contextMenu : Maybe ( ContextMenu, Position )
    , dragStatus : DragStatus
    , dropDownIndex : Maybe String
    }


modelOfDiagramType : Lens Model Diagram
modelOfDiagramType =
    Lens .diagramType (\b a -> { a | diagramType = b })


modelOfText : Lens Model Text
modelOfText =
    Lens .text (\b a -> { a | text = b })


modelOfShowZoomControl : Lens Model Bool
modelOfShowZoomControl =
    Lens .showZoomControl (\b a -> { a | showZoomControl = b })


modelOfFullscreen : Lens Model Bool
modelOfFullscreen =
    Lens .fullscreen (\b a -> { a | fullscreen = b })


modelOfPosition : Lens Model Position
modelOfPosition =
    Lens .position (\b a -> { a | position = b })


modelOfSettings : Lens Model Settings
modelOfSettings =
    Lens .settings (\b a -> { a | settings = b })


modelOfSelectedItem : Lens Model SelectedItem
modelOfSelectedItem =
    Lens .selectedItem (\b a -> { a | selectedItem = b })


type alias Hierarchy =
    Int


type alias Distance =
    Float


type Data
    = Empty
    | Items Items
    | UserStoryMap UserStoryMap
    | MindMap Items Hierarchy
    | ImpactMap Items Hierarchy
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


type ContextMenu
    = CloseMenu
    | ColorSelectMenu
    | BackgroundColorSelectMenu
    | FontBoldMenu
    | FontItalicMenu


type DragStatus
    = NoDrag
    | DragOver


type MoveState
    = BoardMove
    | ItemMove MoveTarget
    | NotMove


type MoveTarget
    = TableTarget ER.Table
    | ItemTarget Item


type alias Settings =
    { font : String
    , size : Size
    , color : ColorSettings
    , backgroundColor : String
    , zoomControl : Maybe Bool
    , scale : Maybe Float
    }


isMoving : MoveState -> Bool
isMoving moveState =
    case moveState of
        NotMove ->
            False

        _ ->
            True


fontStyle : Settings -> String
fontStyle settings =
    "'" ++ settings.font ++ "', sans-serif"


updatedText : Model -> Text -> Model
updatedText model text =
    { model | text = text }


type alias ColorSettings =
    { activity : Color
    , task : Color
    , story : Color
    , line : String
    , label : String
    , text : Maybe String
    }


type alias Color =
    { color : String
    , backgroundColor : String
    }


type alias Size =
    { width : Int
    , height : Int
    }


type Msg
    = NoOp
    | Init Settings Viewport String
    | OnChangeText String
    | ZoomIn
    | ZoomOut
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
    | EndEditSelectedItem Item Int Bool
    | FitToWindow
    | Select (Maybe ( Item, Position ))
    | ColorChanged ContextMenu Color.Color
    | SelectContextMenu ContextMenu
    | FontStyleChanged FontStyle
    | DropFiles (List File)
    | LoadFiles (List String)
    | ChangeDragStatus DragStatus
    | FontSizeChanged FontSize
    | ToggleDropDownList String
    | ToggleMiniMap


getTextColor : ColorSettings -> String
getTextColor settings =
    settings.text |> Maybe.withDefault "#111111"


settingsOfFont : Lens Settings String
settingsOfFont =
    Lens .font (\b a -> { a | font = b })


settingsOfZoomControl : Lens Settings (Maybe Bool)
settingsOfZoomControl =
    Lens .zoomControl (\b a -> { a | zoomControl = b })


settingsOfScale : Lens Settings (Maybe Float)
settingsOfScale =
    Lens .scale (\b a -> { a | scale = b })


settingsOfBackgroundColor : Lens Settings String
settingsOfBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


settingsOfSize : Lens Settings Size
settingsOfSize =
    Lens .size (\b a -> { a | size = b })


settingsOfWidth : Lens Settings Int
settingsOfWidth =
    Compose.lensWithLens sizeOfWidth settingsOfSize


settingsOfHeight : Lens Settings Int
settingsOfHeight =
    Compose.lensWithLens sizeOfHeight settingsOfSize


settingsOfLineColor : Lens Settings String
settingsOfLineColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfLine


settingsOfTextColor : Optional Settings String
settingsOfTextColor =
    settingsOfColor
        |> Compose.lensWithOptional colorSettingsOfText


settingsOfLabelColor : Lens Settings String
settingsOfLabelColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfLabel


settingsOfActivityColor : Lens Settings String
settingsOfActivityColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfColor


settingsOfTaskColor : Lens Settings String
settingsOfTaskColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfColor


settingsOfStoryColor : Lens Settings String
settingsOfStoryColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfColor


settingsOfActivityBackgroundColor : Lens Settings String
settingsOfActivityBackgroundColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfBackgroundColor


settingsOfTaskBackgroundColor : Lens Settings String
settingsOfTaskBackgroundColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfBackgroundColor


settingsOfStoryBackgroundColor : Lens Settings String
settingsOfStoryBackgroundColor =
    settingsOfColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfBackgroundColor


settingsOfColor : Lens Settings ColorSettings
settingsOfColor =
    Lens .color (\b a -> { a | color = b })


colorOfColor : Lens Color String
colorOfColor =
    Lens .color (\b a -> { a | color = b })


colorOfBackgroundColor : Lens Color String
colorOfBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


colorSettingsOfActivity : Lens ColorSettings Color
colorSettingsOfActivity =
    Lens .activity (\b a -> { a | activity = b })


colorSettingsOfTask : Lens ColorSettings Color
colorSettingsOfTask =
    Lens .task (\b a -> { a | task = b })


colorSettingsOfStory : Lens ColorSettings Color
colorSettingsOfStory =
    Lens .story (\b a -> { a | story = b })


colorSettingsOfLine : Lens ColorSettings String
colorSettingsOfLine =
    Lens .line (\b a -> { a | line = b })


colorSettingsOfLabel : Lens ColorSettings String
colorSettingsOfLabel =
    Lens .label (\b a -> { a | label = b })


colorSettingsOfText : Optional ColorSettings String
colorSettingsOfText =
    Optional .text (\b a -> { a | text = Just b })


sizeOfWidth : Lens Size Int
sizeOfWidth =
    Lens .width (\b a -> { a | width = b })


sizeOfHeight : Lens Size Int
sizeOfHeight =
    Lens .height (\b a -> { a | height = b })


dragStart : MoveState -> Bool -> Svg.Attribute Msg
dragStart state isPhone =
    if isPhone then
        Events.onTouchStart
            (\event ->
                if List.length event.changedTouches > 1 then
                    let
                        p1 =
                            getAt 0 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )

                        p2 =
                            getAt 1 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )
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
