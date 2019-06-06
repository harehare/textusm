module Models.Model exposing (Download, GithubSettings, Menu(..), Model, Msg(..), Notification(..), Settings, ShareInfo, ShareUrl(..), Window)

import Api
import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import File exposing (File)
import Http
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
    | OnNotification Notification
    | OnAutoCloseNotification Notification
    | OnCloseNotification
    | TabSelect Int
    | Indent
    | GetAccessTokenForTrello
    | ExportGithub
    | Exported (Result Http.Error Api.Response)
    | DoOpenUrl String


type alias OpenUrl =
    Maybe String


type Notification
    = Info String OpenUrl
    | Error String
    | Warning String OpenUrl


type Menu
    = SaveFile
    | OpenFile
    | Export
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
    , notification : Maybe Notification
    , isEditTitle : Bool
    , isEditSettings : Bool
    , tabIndex : Int
    , progress : Bool
    , apiConfig : Api.Config
    , isExporting : Bool
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
    { position : Maybe Int
    , font : String
    , storyMap : Figure.Settings
    , text : Maybe String
    , title : Maybe String
    , github : Maybe GithubSettings
    }


type alias GithubSettings =
    { owner : String
    , repo : String
    , token : String
    }
