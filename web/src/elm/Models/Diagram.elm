module Models.Diagram exposing (Color, ColorSettings, Model, Msg(..), Point, Settings, Size, UsmSvg, fontStyle, getTextColor, settingsOfActivityBackgroundColor, settingsOfActivityColor, settingsOfBackgroundColor, settingsOfFont, settingsOfHeight, settingsOfLabelColor, settingsOfLineColor, settingsOfStoryBackgroundColor, settingsOfStoryColor, settingsOfTaskBackgroundColor, settingsOfTaskColor, settingsOfTextColor, settingsOfWidth, settingsOfZoomControl)

import Browser.Dom exposing (Viewport)
import Html5.DragDrop as DragDrop
import Models.Item exposing (Item, ItemType(..))
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import TextUSM.Enum.Diagram exposing (Diagram)


type alias Model =
    { items : List Item
    , labels : List String
    , hierarchy : Int
    , width : Int
    , height : Int
    , countByHierarchy : List Int
    , countByTasks : List Int
    , svg : UsmSvg
    , moveStart : Bool
    , x : Int
    , y : Int
    , moveX : Int
    , moveY : Int
    , fullscreen : Bool
    , settings : Settings
    , error : Maybe String
    , showZoomControl : Bool
    , touchDistance : Maybe Float
    , diagramType : Diagram
    , text : Maybe String
    , matchParent : Bool
    , selectedItem : Maybe Item
    , dragDrop : DragDrop.Model Int Int
    }


type alias UsmSvg =
    { width : Int
    , height : Int
    , scale : Float
    }


type alias Settings =
    { font : String
    , size : Size
    , color : ColorSettings
    , backgroundColor : String
    , zoomControl : Maybe Bool
    }


fontStyle : Settings -> String
fontStyle settings =
    "'" ++ settings.font ++ "', sans-serif"


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


type alias Point =
    { x : Int
    , y : Int
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
    | Start Int Int
    | Move Int Int
    | MoveTo Int Int
    | ToggleFullscreen
    | OnResize Int Int
    | StartPinch Float
    | ItemClick Item
    | DeselectItem
    | ItemDblClick Item
    | EditSelectedItem String
    | EndEditSelectedItem Item Int Bool
    | DragDropMsg (DragDrop.Msg Int Int)
    | MoveItem ( Int, Int )


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
    Lens .activity (\b a -> { a | task = b })


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
