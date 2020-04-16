module Models.DiagramList exposing (FilterCondition(..), FilterValue(..), Model, Msg(..))

import GraphQL.Models.DiagramItem exposing (DiagramItem)
import Graphql.Http as Http
import Models.Session exposing (Session)
import RemoteData exposing (WebData)
import TextUSM.Enum.Diagram exposing (Diagram)
import Time exposing (Zone)


type Msg
    = NoOp
    | Filter FilterCondition
    | SearchInput String
    | Select DiagramItem
    | Reload
    | Remove DiagramItem
    | Bookmark DiagramItem
    | RemoveRemote String
    | Removed (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | Bookmarked (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | GotTimeZone Zone
    | GotLocalDiagramJson String
    | GotDiagrams (Result ( List DiagramItem, Http.Error (List (Maybe DiagramItem)) ) (List DiagramItem))
    | LoadNextPage Int


type FilterValue
    = FilterAll
    | FilterBookmark
    | FilterValue Diagram


type FilterCondition
    = FilterCondition FilterValue (DiagramItem -> Bool)


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : WebData (List DiagramItem)
    , filterCondition : FilterCondition
    , session : Session
    , apiRoot : String
    , pageNo : Int
    , hasMorePage : Bool
    }
