module Models.Model exposing (Diagram, Download, GithubSettings, Menu(..), Model, Msg(..), Notification(..), Settings, ShareInfo, ShareUrl(..), Window)

import Api
import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import File exposing (File)
import Http
import Models.Diagram as Diagram
import Time exposing (Zone)
import Url


type Msg
    = NoOp
    | Init Viewport
    | UpdateDiagram Diagram.Msg
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
    | SaveToFileSystem
    | SelectLine String
    | StartEditTitle
    | EndEditTitle Int Bool
    | EditTitle String
    | OnShareUrl ShareInfo
    | OnCurrentShareUrl
    | OnVisibilityChange Visibility
    | OnStartWindowResize Int
    | OnWindowResize Int
    | EditSettings
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
    | NewUserStoryMap
    | NewBusinessModelCanvas
    | NewOpportunityCanvas
    | GetDiagrams
    | ShowDiagrams (List Diagram)
    | OpenDiagram Diagram
    | RemoveDiagram Diagram
    | RemovedDiagram Bool
    | GetTimeZone Zone
    | UpdateSettings (String -> Settings) String
    | Shortcuts String
    | ShowHelp


type alias OpenUrl =
    Maybe String


type Notification
    = Info String OpenUrl
    | Error String
    | Warning String OpenUrl


type Menu
    = NewFile
    | Export
    | UserSettings


type alias Model =
    { id : Maybe String
    , key : Nav.Key
    , url : Url.Url
    , diagramModel : Diagram.Model
    , text : String
    , openMenu : Maybe Menu
    , window : Window
    , settings : Settings
    , share : Maybe ShareUrl
    , title : Maybe String
    , notification : Maybe Notification
    , isEditTitle : Bool
    , tabIndex : Int
    , progress : Bool
    , apiConfig : Api.Config
    , isExporting : Bool
    , diagrams : Maybe (List Diagram)
    , timezone : Maybe Zone
    , selectedItem : Maybe Diagram.Item
    }


type alias Window =
    { position : Int
    , moveStart : Bool
    , moveX : Int
    , fullscreen : Bool
    }


type alias Diagram =
    { diagramPath : String
    , id : Maybe String
    , text : String
    , thumbnail : Maybe String
    , title : String
    , updatedAt : Maybe Int
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
    , diagramType : String
    }


type ShareUrl
    = ShareUrl String


type alias Settings =
    { position : Maybe Int
    , font : String
    , diagramId : Maybe String
    , storyMap : Diagram.Settings
    , text : Maybe String
    , title : Maybe String
    , github : Maybe GithubSettings
    }


type alias GithubSettings =
    { owner : String
    , repo : String
    , token : String
    }
