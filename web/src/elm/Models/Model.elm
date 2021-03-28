module Models.Model exposing
    ( Menu(..)
    , Model
    , Msg(..)
    , Notification(..)
    , Page(..)
    , SwitchWindow(..)
    , Window
    , modelOfDiagramModel
    , windowOfFullscreen
    , windowOfMoveStart
    , windowOfMoveX
    )

import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import Data.DiagramItem exposing (DiagramItem)
import Data.FileType exposing (FileType)
import Data.LoginProvider exposing (LoginProvider)
import Data.Session exposing (Session, User)
import Data.Title exposing (Title)
import Dialog.Share as Share
import Graphql.Http as GraphQlHttp
import Json.Decode as D
import Models.Diagram as Diagram
import Monocle.Lens exposing (Lens)
import Page.List as DiagramList
import Page.Settings as Settings
import Page.Tags as Tags
import TextUSM.Enum.Diagram as DiagramType
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
    | StartDownload { extension : String, mimeType : String, content : String }
    | Save
    | SaveToRemoteCompleted (Result DiagramItem DiagramItem)
    | SaveToLocalCompleted D.Value
    | SaveToRemote D.Value
    | StartEditTitle
    | Progress Bool
    | EndEditTitle
    | EditTitle String
    | EditText String
    | SignIn LoginProvider
    | SignOut
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HandleVisibilityChange Visibility
    | HandleStartWindowResize Int
    | HandleWindowResize Int
    | HandleAutoCloseNotification Notification
    | HandleCloseNotification
    | HandleAuthStateChanged (Maybe User)
    | ShowNotification Notification
    | SwitchWindow SwitchWindow
    | Shortcuts String
    | GotLocalDiagramJson D.Value
    | ChangePublicStatus Bool
    | ChangePublicStatusCompleted (Result DiagramItem DiagramItem)
    | Load (Result (GraphQlHttp.Error DiagramItem) DiagramItem)
    | CloseFullscreen D.Value
    | UpdateIdToken String
    | HistoryBack
    | EditPassword String
    | EndEditPassword


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
    | Settings
    | Embed DiagramType.Diagram String
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
    , viewPassword : Maybe String
    }


type alias Window =
    { position : Int
    , moveStart : Bool
    , moveX : Int
    , fullscreen : Bool
    }


modelOfDiagramModel : Lens Model Diagram.Model
modelOfDiagramModel =
    Lens .diagramModel (\b a -> { a | diagramModel = b })


windowOfFullscreen : Lens Window Bool
windowOfFullscreen =
    Lens .fullscreen (\b a -> { a | fullscreen = b })


windowOfMoveX : Lens Window Int
windowOfMoveX =
    Lens .moveX (\b a -> { a | moveX = b })


windowOfMoveStart : Lens Window Bool
windowOfMoveStart =
    Lens .moveStart (\b a -> { a | moveStart = b })
