module Models.DiagramList exposing (Model, Msg(..))

import Http
import Models.DiagramItem exposing (DiagramItem)
import Models.User exposing (User)
import Time exposing (Zone)



type Msg
    = NoOp
    | Filter (Maybe String)
    | SearchInput String
    | Select DiagramItem
    | Reload
    | Remove DiagramItem
    | RemoveRemote DiagramItem
    | Removed (Result ( DiagramItem, Http.Error ) DiagramItem)
    | GotTimeZone Zone
    | GotLocalDiagrams (List DiagramItem)
    | GotDiagrams (Result ( List DiagramItem, Http.Error ) (List DiagramItem))


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : Maybe (List DiagramItem)
    , selectedType : Maybe String
    , loginUser : Maybe User
    , apiRoot : String
    }
