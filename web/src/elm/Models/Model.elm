module Models.Model exposing
    ( BrowserStatus
    , Menu(..)
    , Model
    , Msg(..)
    , Window
    , WindowState(..)
    , isFullscreen
    , ofIsOnline
    , windowOfMoveStart
    , windowOfMoveX
    , windowOfState
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
import Models.DiagramSettings as DiagramSettings
import Models.Dialog exposing (ConfirmDialog)
import Models.FileType exposing (FileType)
import Models.LoginProvider exposing (LoginProvider)
import Models.Notification exposing (Notification)
import Models.Page exposing (Page)
import Models.Session exposing (Session)
import Models.ShareState exposing (ShareState)
import Models.Snackbar exposing (Snackbar)
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
    | SwitchWindow WindowState
    | Shortcuts String
    | GotLocalDiagramJson D.Value
    | ChangePublicStatus Bool
    | ChangePublicStatusCompleted (Result DiagramItem DiagramItem)
    | Load (Result RequestError DiagramItem)
    | LoadSettings (Result RequestError DiagramSettings.Settings)
    | SaveSettings (Result RequestError DiagramSettings.Settings)
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
    | ShowEditor WindowState
    | NotifyNewVersionAvailable String
    | Reload
    | CloseSnackbar
    | OpenLocalFile
    | OpenedLocalFile ( String, String )
    | SaveLocalFile
    | SavedLocalFile String


type Menu
    = Export
    | HeaderMenu
    | LoginMenu


type WindowState
    = Editor
    | Preview
    | Both
    | Fullscreen


type alias Window =
    { position : Int
    , moveStart : Bool
    , moveX : Int
    , state : WindowState
    }


type alias BrowserStatus =
    { isOnline : Bool
    , isDarkMode : Bool
    , canUseNativeFileSystem : Bool
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
    , currentDiagram : DiagramItem
    , openMenu : Maybe Menu
    , window : Window
    , progress : Bool
    , lang : Lang
    , prevRoute : Maybe Route
    , shareState : ShareState
    , browserStatus : BrowserStatus
    , confirmDialog : ConfirmDialog Msg
    , snackbar : Snackbar Msg
    , notification : Notification
    }


windowOfMoveX : Lens Window Int
windowOfMoveX =
    Lens .moveX (\b a -> { a | moveX = b })


windowOfMoveStart : Lens Window Bool
windowOfMoveStart =
    Lens .moveStart (\b a -> { a | moveStart = b })


windowOfState : Lens Window WindowState
windowOfState =
    Lens .state (\b a -> { a | state = b })


ofIsOnline : Lens BrowserStatus Bool
ofIsOnline =
    Lens .isOnline (\b a -> { a | isOnline = b })


isFullscreen : Window -> Bool
isFullscreen window =
    case window.state of
        Fullscreen ->
            True

        _ ->
            False
