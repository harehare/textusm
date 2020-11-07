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
    , fontStyle
    , getTextColor
    , isMoving
    , settingsOfActivityBackgroundColor
    , settingsOfActivityColor
    , settingsOfBackgroundColor
    , settingsOfFont
    , settingsOfHeight
    , settingsOfLabelColor
    , settingsOfLineColor
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
import Data.FontStyle exposing (FontStyle)
import Data.Item exposing (Item, ItemType(..), Items)
import Data.Position exposing (Position)
import Data.Size as Size
import Data.Text exposing (Text)
import File exposing (File)
import Html5.DragDrop as DragDrop
import Models.Views.BusinessModelCanvas exposing (BusinessModelCanvas)
import Models.Views.ER as ER exposing (ErDiagram)
import Models.Views.EmpathyMap exposing (EmpathyMap)
import Models.Views.FourLs exposing (FourLs)
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
import TextUSM.Enum.Diagram exposing (Diagram)


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
    , touchDistance : Maybe Float
    , diagramType : Diagram
    , text : Text
    , matchParent : Bool
    , selectedItem : SelectedItem
    , dragDrop : DragDrop.Model Int Int
    , contextMenu : Maybe ( ContextMenu, Position )
    , dragStatus : DragStatus
    }


type alias Hierarchy =
    Int


type alias CountByHierarchy =
    List Int


type alias CountByTasks =
    List Int


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
    | DragDropMsg (DragDrop.Msg Int Int)
    | MoveItem ( Int, Int )
    | FitToWindow
    | Select (Maybe ( Item, Position ))
    | OnColorChanged ContextMenu Color.Color
    | OnSelectContextMenu ContextMenu
    | OnFontStyleChanged FontStyle
    | OnDropFiles (List File)
    | OnLoadFiles (List String)
    | ChangeDragStatus DragStatus


getTextColor : ColorSettings -> String
getTextColor settings =
    settings.text |> Maybe.withDefault "#111111"


settingsOfFont : Lens Settings String
settingsOfFont =
    Lens .font (\b a -> { a | font = b })


settingsOfZoomControl : Lens Settings (Maybe Bool)
settingsOfZoomControl =
    Lens .zoomControl (\b a -> { a | zoomControl = b })


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
