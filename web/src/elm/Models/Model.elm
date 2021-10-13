module Models.Model exposing
    ( Menu(..)
    , Model
    , Msg(..)
    , SwitchWindow(..)
    , Window
    , windowOfFullscreen
    , windowOfMoveStart
    , windowOfMoveX
    , windowOfShowEditor
    )

import Api.RequestError exposing (RequestError)
import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import Dialog.Share as Share
import Json.Decode as D
import Message exposing (Lang, Message)
import Models.Diagram as Diagram
import Models.DiagramItem exposing (DiagramItem)
import Models.Dialog exposing (ConfirmDialog)
import Models.FileType exposing (FileType)
import Models.LoginProvider exposing (LoginProvider)
import Models.Notification exposing (Notification)
import Models.Page exposing (Page)
import Models.Session exposing (Session)
import Models.ShareState exposing (ShareState)
import Models.Snackbar exposing (Snackbar)
import Models.Title exposing (Title)
import Monocle.Lens exposing (Lens)
import Page.List as DiagramList
import Page.Settings as Settings
import Route exposing (Route)
import Url


type Msg
    = NoOp
    | Init Viewport
    | UpdateDiagram Diagram.Msg
    | UpdateDiagramList DiagramList.Msg
    | UpdateShare Share.Msg
    | UpdateSettings Settings.Msg
    | OpenMenu Menu
    | MoveStop
    | CloseMenu
    | Download FileType
    | DownloadCompleted ( Int, Int )
    | StartDownload { extension : String, mimeType : String, content : String }
    | Save
    | SaveToRemoteCompleted (Result RequestError DiagramItem)
    | SaveToLocalCompleted D.Value
    | SaveToRemote D.Value
    | StartEditTitle
    | Progress Bool
    | EndEditTitle
    | EditTitle String
    | SignIn LoginProvider
    | SignOut
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | HandleVisibilityChange Visibility
    | HandleStartWindowResize Int
    | HandleWindowResize Int
    | HandleAutoCloseNotification Notification
    | HandleCloseNotification
    | HandleAuthStateChanged (Maybe D.Value)
    | ShowNotification Notification
    | SwitchWindow SwitchWindow
    | Shortcuts String
    | GotLocalDiagramJson D.Value
    | ChangePublicStatus Bool
    | ChangePublicStatusCompleted (Result DiagramItem DiagramItem)
    | Load (Result RequestError DiagramItem)
    | LoadSettings (Result RequestError Diagram.Settings)
    | SaveSettings (Result RequestError Diagram.Settings)
    | CallApi (Result Message ())
    | CloseFullscreen
    | UpdateIdToken String
    | EditPassword String
    | EndEditPassword
    | LoadWithPassword (Result RequestError DiagramItem)
    | MoveTo Route
    | CloseDialog
    | GotGithubAccessToken { cmd : String, accessToken : Maybe String }
    | ChangeNetworkState Bool
    | ShowEditor Bool
    | NotifyNewVersionAvailable String
    | Reload
    | CloseSnackbar


type Menu
    = Export
    | HeaderMenu
    | LoginMenu


type SwitchWindow
    = Left
    | Right


type alias Window =
    { position : Int
    , moveStart : Bool
    , moveX : Int
    , fullscreen : Bool
    , showEditor : Bool
    }


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
    , switchWindow : SwitchWindow
    , progress : Bool
    , confirmDialog : ConfirmDialog Msg
    , lang : Lang
    , prevRoute : Maybe Route
    , shareState : ShareState
    , isOnline : Bool
    , isDarkMode : Bool
    , snackbar : Snackbar Msg
    , notification : Notification
    }


windowOfShowEditor : Lens Window Bool
windowOfShowEditor =
    Lens .showEditor (\b a -> { a | showEditor = b })


windowOfFullscreen : Lens Window Bool
windowOfFullscreen =
    Lens .fullscreen (\b a -> { a | fullscreen = b })


windowOfMoveX : Lens Window Int
windowOfMoveX =
    Lens .moveX (\b a -> { a | moveX = b })


windowOfMoveStart : Lens Window Bool
windowOfMoveStart =
    Lens .moveStart (\b a -> { a | moveStart = b })
