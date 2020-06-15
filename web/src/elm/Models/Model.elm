module Models.Model exposing (DownloadFileInfo, DownloadInfo, LoginProvider(..), Menu(..), Model, Msg(..), Notification(..), Page(..), ShareInfo, SwitchWindow(..), Window)

import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import Data.DiagramItem exposing (DiagramItem)
import Data.FileType exposing (FileType)
import Data.Session exposing (Session, User)
import Data.Title exposing (Title)
import Graphql.Http as Http
import Http as Http2
import Models.Diagram as Diagram
import Page.List as DiagramList
import Page.Settings as Settings
import Page.Share as Share
import Page.Tags as Tags
import Translations exposing (Lang)
import Url


type Msg
    = NoOp
    | Init Viewport
    | UpdateDiagram Diagram.Msg
    | UpdateDiagramList DiagramList.Msg
    | UpdateShare Share.Msg
    | UpdateSettings Settings.Msg
    | UpdateTags Tags.Msg
    | OpenMenu Menu
    | Stop
    | CloseMenu
    | Download FileType
    | DownloadCompleted ( Int, Int )
    | StartDownload DownloadFileInfo
    | Save
    | SaveToRemoteCompleted (Result DiagramItem DiagramItem)
    | SaveToLocalCompleted String
    | SaveToRemote String
    | StartEditTitle
    | Progress Bool
    | EndEditTitle Int Bool
    | EditTitle String
    | OnShareUrl ShareInfo
    | SignIn LoginProvider
    | SignOut
    | OnVisibilityChange Visibility
    | OnStartWindowResize Int
    | OnWindowResize Int
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OnEncodeShareText String
    | OnDecodeShareText String
    | OnNotification Notification
    | OnAutoCloseNotification Notification
    | OnCloseNotification
    | OnAuthStateChanged (Maybe User)
    | SwitchWindow SwitchWindow
    | GetShortUrl (Result Http2.Error String)
    | Shortcuts String
    | GotLocalDiagramJson String
    | Load (Result (Http.Error DiagramItem) DiagramItem)


type LoginProvider
    = Google
    | Github


type Notification
    = Info String
    | Error String
    | Warning String


type Menu
    = Export
    | HeaderMenu
    | LoginMenu


type SwitchWindow
    = Left
    | Right


type Page
    = Main
    | New
    | Help
    | List
    | Tags Tags.Model
    | Share
    | Settings
    | Embed String String String
    | NotFound


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , page : Page
    , diagramModel : Diagram.Model
    , diagramListModel : DiagramList.Model
    , settingsModel : Settings.Model
    , shareModel : Share.Model
    , session : Session
    , currentDiagram : Maybe DiagramItem
    , openMenu : Maybe Menu
    , window : Window
    , title : Title
    , notification : Maybe Notification
    , switchWindow : SwitchWindow
    , progress : Bool
    , apiRoot : String
    , lang : Lang
    }


type alias Window =
    { position : Int
    , moveStart : Bool
    , moveX : Int
    , fullscreen : Bool
    }


type alias DownloadFileInfo =
    { extension : String
    , mimeType : String
    , content : String
    }


type alias DownloadInfo =
    { width : Int
    , height : Int
    , id : String
    , title : String
    , text : String
    , x : Float
    , y : Float
    , diagramType : String
    }


type alias ShareInfo =
    { title : Maybe String
    , text : String
    , diagramType : String
    }
