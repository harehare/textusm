module Models.Model exposing (Download, MapType(..), Menu(..), Model, Msg(..), Settings, ShareInfo, ShareUrl(..), Window)

import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import File exposing (File)
import Models.Figure as Figure
import Url


type Msg
    = NoOp
    | Init Viewport
    | UpdateFigure Figure.Msg
    | OpenMenu Menu
    | Stop
    | CloseMenu
    | DownloadPng
    | DownloadSvg
    | StartDownloadSvg String
    | FileSelect
    | FileSelected File
    | FileLoaded String
    | SaveToLocal
    | SelectLine String
    | StartEditTitle
    | EndEditTitle Int Bool
    | EditTitle String
    | OnShareUrl
    | OnVisibilityChange Visibility
    | OnStartWindowResize Int
    | OnWindowResize Int
    | ToggleSettings
    | ApplySettings Settings
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OnEncodeShareText String
    | OnDecodeShareText String
    | OnNotification String
    | OnCloseNotification
    | TabSelect Int
    | Indent


type MapType
    = UserStoryMapping
    | MindMap


type Menu
    = Export
    | OpenFile
    | SaveFile
    | UserSettings


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , figureModel : Figure.Model
    , text : String
    , openMenu : Maybe Menu
    , window : Window
    , settings : Settings
    , share : Maybe ShareUrl
    , title : Maybe String
    , notification : Maybe String
    , isEditTitle : Bool
    , isEditSettings : Bool
    , mapType : MapType
    , tabIndex : Int
    , progress : Bool
    }


type alias Window =
    { position : Int
    , moveStart : Bool
    , moveX : Int
    , fullscreen : Bool
    }


type alias Download =
    { width : Int
    , height : Int
    , id : String
    , title : String
    }


type alias ShareInfo =
    { title : Maybe String
    , text : String
    }


type ShareUrl
    = ShareUrl String


type alias Settings =
    { font : String
    , position : Int
    , text : String
    , title : String
    , storyMap : Figure.Settings
    }
