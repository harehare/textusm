module Models.Model exposing (DownloadFileInfo, DownloadInfo, FileType(..), LoginProvider(..), Menu(..), Model, Msg(..), Notification(..), ShareInfo, ShareUrl(..), Window)

import Api.UrlShorter
import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import File exposing (File)
import GraphQL.Models.DiagramItem exposing (DiagramItem)
import Graphql.Http as Http
import Http as Http2
import Models.Diagram as Diagram
import Models.DiagramList as DiagramList
import Models.Settings exposing (Settings)
import Models.User exposing (User)
import Route as Route
import TextUSM.Enum.Diagram exposing (Diagram)
import Url


type Msg
    = NoOp
    | Init Viewport
    | UpdateDiagram Diagram.Msg
    | UpdateDiagramList DiagramList.Msg
    | OpenMenu Menu
    | Stop
    | CloseMenu
    | Download FileType
    | DownloadCompleted ( Int, Int )
    | StartDownload DownloadFileInfo
    | FileSelect
    | FileSelected File
    | FileLoaded String
    | Save
    | Saved (Result (Http.Error DiagramItem) DiagramItem)
    | SaveToFileSystem
    | SaveToRemote String
    | StartEditTitle
    | Progress Bool
    | EndEditTitle Int Bool
    | EditTitle String
    | OnShareUrl ShareInfo
    | OnCurrentShareUrl
    | Login LoginProvider
    | Logout
    | OnVisibilityChange Visibility
    | OnStartWindowResize Int
    | OnWindowResize Int
    | ApplySettings Settings
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OnEncodeShareText String
    | OnDecodeShareText String
    | OnNotification Notification
    | OnAutoCloseNotification Notification
    | OnCloseNotification
    | OnAuthStateChanged (Maybe User)
    | WindowSelect Int
    | GetShortUrl (Result Http2.Error Api.UrlShorter.Response)
      -- Diagram type
    | New Diagram
    | GetDiagrams
    | UpdateSettings (String -> Settings) String
    | Shortcuts String
    | SelectAll String
    | ToggleDropDownList String
    | NavRoute Route.Route


type LoginProvider
    = Google
    | Github


type FileType
    = Png
    | Svg
    | Pdf
    | HTML


type Notification
    = Info String
    | Error String
    | Warning String


type Menu
    = NewFile
    | Export
    | UserSettings
    | HeaderMenu
    | LoginMenu


type alias Model =
    { id : Maybe String
    , text : String
    , currentDiagram : Maybe DiagramItem
    , key : Nav.Key
    , url : Url.Url
    , diagramModel : Diagram.Model
    , diagramListModel : DiagramList.Model
    , openMenu : Maybe Menu
    , window : Window
    , settings : Settings
    , share : Maybe ShareUrl
    , embed : Maybe String
    , title : Maybe String
    , notification : Maybe Notification
    , isEditTitle : Bool
    , editorIndex : Int
    , progress : Bool
    , apiRoot : String
    , loginUser : Maybe User
    , dropDownIndex : Maybe String
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


type ShareUrl
    = ShareUrl String
