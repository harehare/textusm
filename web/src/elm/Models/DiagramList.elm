module Models.DiagramList exposing (Model, Msg(..))

import GraphQL.Models.DiagramItem exposing (DiagramItem)
import Graphql.Http as Http
import Models.PotentialData exposing (Pot)
import Models.User exposing (User)
import Time exposing (Zone)


type Msg
    = NoOp
    | Filter (Maybe String)
    | SearchInput String
    | Select DiagramItem
    | Reload
    | Remove DiagramItem
    | RemoveRemote String
    | Removed (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | GotTimeZone Zone
    | GotLocalDiagramJson String
    | GotDiagrams (Result ( List DiagramItem, Http.Error (List (Maybe DiagramItem)) ) (List DiagramItem))
    | LoadNextPage Int


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : Pot (List DiagramItem)
    , selectedType : Maybe String
    , loginUser : Maybe User
    , apiRoot : String
    , pageNo : Int
    , hasMorePage : Bool
    , isLoading : Bool
    }
