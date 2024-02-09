module Models.Model exposing
    ( BrowserStatus
    , Menu(..)
    , Model
    , Msg(..)
    , ofIsOnline
    )

import Api.RequestError exposing (RequestError)
import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import Diagram.Item exposing (DiagramItem)
import Diagram.Settings as DiagramSettings
import Diagram.Type exposing (DiagramType)
import Dialog.Share as Share
import Json.Decode as D
import Message exposing (Lang, Message)
import Models.Diagram as Diagram
import Models.Dialog exposing (ConfirmDialog)
import Models.Export.Diagram exposing (Export)
import Models.Hotkey exposing (Hotkey)
import Models.LoginProvider exposing (LoginProvider)
import Models.Notification exposing (Notification)
import Models.Page exposing (Page)
import Models.Session exposing (Session)
import Models.SettingsCache exposing (SettingsCache)
import Models.ShareState exposing (ShareState)
import Models.Snackbar exposing (Snackbar)
import Models.Theme exposing (Theme)
import Models.Window exposing (Window)
import Monocle.Lens exposing (Lens)
import Page.List as DiagramList
import Page.Settings as Settings
import Route exposing (Route)
import Url


type alias BrowserStatus =
    { isOnline : Bool
    , isDarkMode : Bool
    , canUseClipboardItem : Bool
    , canUseNativeFileSystem : Bool
    }


type Menu
    = Export
    | HeaderMenu
    | LoginMenu


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
    , settingsCache : SettingsCache
    , theme : Theme
    }


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
    | Copied (Result RequestError DiagramItem)
    | ChangeDiagramType DiagramType
    | ChangePublicStatus Bool
    | ChangePublicStatusCompleted (Result DiagramItem DiagramItem)
    | CallApi (Result Message ())
    | CloseFullscreen
    | ChangeNetworkState Bool
    | Download Export
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
    | SwitchWindow Window
    | Hotkey (Maybe Hotkey)
    | GotLocalDiagramJson D.Value
    | GotLocalDiagramJsonForCopy D.Value
    | Load (Result RequestError DiagramItem)
    | LoadSettings (Result RequestError DiagramSettings.Settings)
    | LoadSettingsFromLocal D.Value
    | SaveDiagramSettings (Result RequestError DiagramSettings.Settings)
    | UpdateIdToken String
    | EditPassword String
    | EndEditPassword
    | LoadWithPassword (Result RequestError DiagramItem)
    | MoveTo Route
    | CloseDialog
    | GotGithubAccessToken { cmd : String, accessToken : Maybe String }
    | ShowEditor Window
    | NotifyNewVersionAvailable String
    | Reload
    | CloseSnackbar
    | OpenCurrentFile
    | OpenLocalFile
    | OpenedLocalFile ( String, String )
    | SaveLocalFile
    | SavedLocalFile String


ofIsOnline : Lens BrowserStatus Bool
ofIsOnline =
    Lens .isOnline (\b a -> { a | isOnline = b })
