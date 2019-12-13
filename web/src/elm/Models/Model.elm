module Models.Model exposing (DownloadFileInfo, DownloadInfo, FileType(..), Menu(..), Model, Msg(..), Notification(..), ShareInfo, ShareUrl(..), Window, canWrite)

import Api.Diagram exposing (AddUserResponse, UpdateUserResponse)
import Api.UrlShorter
import Browser
import Browser.Dom exposing (Viewport)
import Browser.Events exposing (Visibility)
import Browser.Navigation as Nav
import File exposing (File)
import Http
import List.Extra as ListEx
import Maybe.Extra as MaybeEx
import Models.Diagram as Diagram
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramList as DiagramList
import Models.DiagramType exposing (DiagramType)
import Models.Settings exposing (EditorSettings, Settings)
import Models.User exposing (User)
import Route as Route
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
    | Saved (Result Http.Error DiagramItem)
    | SaveToFileSystem
    | SaveToRemote DiagramItem
    | StartEditTitle
    | Progress Bool
    | EndEditTitle Int Bool
    | EditTitle String
    | OnShareUrl ShareInfo
    | OnCurrentShareUrl
    | Login
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
    | GetShortUrl (Result Http.Error Api.UrlShorter.Response)
      -- Diagram type
    | New DiagramType
    | GetDiagrams
    | Opened (Result ( DiagramItem, Http.Error ) DiagramItem)
    | UpdateSettings (String -> Settings) String
    | Shortcuts String
    | SelectAll String
      -- SharingDialog
    | CancelSharing
    | InviteUser
    | EditInviteMail String
    | UpdateRole String String
    | UpdatedRole (Result Http.Error UpdateUserResponse)
    | AddUser (Result Http.Error AddUserResponse)
    | DeleteUser String
    | DeletedUser (Result Http.Error String)
    | LoadUsers (Result Http.Error DiagramItem)
    | ToggleDropDownList String
    | NavRoute Route.Route


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
    , inviteMailAddress : Maybe String
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
    , x : Int
    , y : Int
    , diagramType : String
    }


type alias ShareInfo =
    { title : Maybe String
    , text : String
    , diagramType : String
    }


type ShareUrl
    = ShareUrl String


canWrite : Maybe DiagramItem -> Maybe User -> Bool
canWrite currentDiagram currentUser =
    let
        isRemote =
            case currentDiagram of
                Just d ->
                    d.isRemote

                Nothing ->
                    False

        loginUser =
            currentUser
                |> Maybe.withDefault
                    { displayName = ""
                    , email = ""
                    , photoURL = ""
                    , idToken = ""
                    , id = ""
                    }

        ownerId =
            currentDiagram
                |> Maybe.map (\x -> x.ownerId)
                |> MaybeEx.join
                |> Maybe.withDefault ""

        roleUser =
            currentDiagram
                |> Maybe.map (\x -> x.users)
                |> MaybeEx.join
                |> Maybe.map
                    (\u ->
                        ListEx.find (\x -> loginUser.id == x.id) u
                    )
                |> MaybeEx.join
                |> Maybe.withDefault
                    { id = ""
                    , name = ""
                    , photoURL = ""
                    , role = ""
                    , mail = ""
                    }
    in
    not isRemote || MaybeEx.isNothing currentDiagram || loginUser.id == ownerId || roleUser.role == "Editor"
