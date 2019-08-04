module Models.Model exposing (Download, GithubSettings, Menu(..), Model, Msg(..), Notification(..), Settings, ShareInfo, ShareUrl(..), Window, canWrite)

import Api.Diagram as DiagramAPI exposing (AddUserResponse, UpdateUserResponse)
import Api.Export
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
import Models.DiagramItem exposing (DiagramItem, DiagramUser)
import Models.User exposing (User)
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
    | Save
    | Saved (Result Http.Error DiagramItem)
    | Removed (Result ( DiagramItem, Http.Error ) DiagramItem)
    | SaveToFileSystem
    | SaveToRemote DiagramItem
    | StartEditTitle
    | EndEditTitle Int Bool
    | EditTitle String
    | OnShareUrl ShareInfo
    | OnCurrentShareUrl
    | Login
    | Logout
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
    | OnAuthStateChanged (Maybe User)
    | WindowSelect Int
    | GetAccessTokenForTrello
    | GetAccessTokenForGitHub
    | ExportGitHub String
    | Exported (Result Http.Error Api.Export.Response)
    | GetShortUrl (Result Http.Error Api.UrlShorter.Response)
    | DoOpenUrl String
      -- Diagram type
    | NewUserStoryMap
    | NewBusinessModelCanvas
    | NewOpportunityCanvas
    | NewFourLs
    | NewStartStopContinue
    | NewCostBenfitAnalysis
    | NewUserPersona
    | NewKpt
    | GetDiagrams
    | LoadLocalDiagrams (List DiagramItem)
    | LoadDiagrams (Result ( List DiagramItem, Http.Error ) (List DiagramItem))
    | Open DiagramItem
    | Opened (Result ( DiagramItem, Http.Error ) DiagramItem)
    | RemoveDiagram DiagramItem
    | RemoveRemoteDiagram DiagramItem
    | RemovedDiagram ( DiagramItem, Bool )
    | GotTimeZone Zone
    | UpdateSettings (String -> Settings) String
    | Shortcuts String
    | ShowHelp
    | OnChangeNetworkStatus Bool
    | HistoryBack
    | MoveTo String
    | MoveToBack
    | Search String
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
    | HeaderMenu


type alias Model =
    { -- current file
      id : Maybe String
    , text : String
    , currentDiagram : Maybe DiagramItem

    --
    , key : Nav.Key
    , url : Url.Url
    , diagramModel : Diagram.Model
    , openMenu : Maybe Menu
    , window : Window
    , settings : Settings
    , share : Maybe ShareUrl
    , embed : Maybe String
    , title : Maybe String
    , notification : Maybe Notification
    , isEditTitle : Bool
    , tabIndex : Int
    , progress : Bool
    , apiRoot : String
    , diagrams : Maybe (List DiagramItem)
    , timezone : Maybe Zone
    , loginUser : Maybe User
    , isOnline : Bool
    , searchQuery : Maybe String
    , inviteMailAddress : Maybe String
    , modified : Bool
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
    }


canWrite : Model -> Bool
canWrite model =
    let
        isRemote =
            case model.currentDiagram of
                Just d ->
                    d.isRemote

                Nothing ->
                    False

        loginUser =
            model.loginUser
                |> Maybe.withDefault
                    { displayName = ""
                    , email = ""
                    , photoURL = ""
                    , idToken = ""
                    , id = ""
                    }

        ownerId =
            model.currentDiagram
                |> Maybe.map (\x -> x.ownerId)
                |> MaybeEx.join
                |> Maybe.withDefault ""

        roleUser =
            model.currentDiagram
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
    not isRemote || MaybeEx.isNothing model.currentDiagram || loginUser.id == ownerId || roleUser.role == "Editor"
