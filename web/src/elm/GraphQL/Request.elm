module GraphQL.Request exposing (bookmark, delete, item, items, publicItem, save, share, shareCondition, shareItem)

import Data.DiagramItem exposing (DiagramItem)
import Data.Email as Email exposing (Email)
import Data.IdToken as IdToken exposing (IdToken)
import Data.IpAddress as IpAddress exposing (IpAddress)
import GraphQL.Mutation as Mutation
import GraphQL.Query as Query
import Graphql.Http as Http
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Task exposing (Task)
import TextUSM.InputObject exposing (InputItem)
import Url.Builder exposing (crossOrigin)


type alias RequestInfo =
    { idToken : Maybe IdToken
    , url : String
    }


graphQLUrl : RequestInfo -> String
graphQLUrl req =
    crossOrigin req.url [ "graphql" ] []


item : RequestInfo -> String -> Task (Http.Error DiagramItem) DiagramItem
item req id =
    Query.item id False
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


publicItem : RequestInfo -> String -> Task (Http.Error DiagramItem) DiagramItem
publicItem req id =
    Query.item id True
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


items : RequestInfo -> ( Int, Int ) -> { isPublic : Bool, isBookmark : Bool } -> Task (Http.Error (List (Maybe DiagramItem))) (List (Maybe DiagramItem))
items req ( offset, limit ) params =
    Query.items ( offset, limit ) params
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


shareItem : RequestInfo -> String -> Maybe String -> Task (Http.Error DiagramItem) DiagramItem
shareItem req id password =
    Query.shareItem id password
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


shareCondition : RequestInfo -> String -> Task (Http.Error (Maybe Query.ShareCondition)) (Maybe Query.ShareCondition)
shareCondition req id =
    Query.shareCondition id
        |> Http.queryRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


save : RequestInfo -> InputItem -> Bool -> Task (Http.Error DiagramItem) DiagramItem
save req input isPublic =
    Mutation.save input isPublic
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


delete : RequestInfo -> String -> Bool -> Task (Http.Error String) String
delete req itemID isPublic =
    Mutation.delete itemID isPublic
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


bookmark : RequestInfo -> String -> Bool -> Task (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem)
bookmark req itemID isBookmark =
    Mutation.bookmark itemID isBookmark
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


share : RequestInfo -> String -> Int -> Maybe String -> List IpAddress -> List Email -> Task (Http.Error String) String
share req itemID expSecond password allowIPList allowEmailList =
    Mutation.share
        { itemID = itemID
        , expSecond = Present expSecond
        , password =
            case password of
                Just p ->
                    Present p

                Nothing ->
                    Null
        , allowIPList = Present <| List.map IpAddress.toString allowIPList
        , allowEmailList = Present <| List.map Email.toString allowEmailList
        }
        |> Http.mutationRequest (graphQLUrl req)
        |> authHeaders req.idToken
        |> Http.toTask


authHeaders : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
authHeaders idToken =
    case idToken of
        Just t ->
            Http.withHeader "Authorization" <| IdToken.unwrap t

        Nothing ->
            Http.withOperationName ""
