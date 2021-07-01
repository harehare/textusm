module Api.Request exposing (bookmark, delete, item, items, publicItem, save, share, shareCondition, shareItem)

import Api.Mutation as Mutation
import Api.Query as Query
import Api.RequestError exposing (RequestError, toError)
import Env
import Graphql.Http as Http
import Graphql.InputObject exposing (InputItem)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar exposing (ItemIdScalar(..))
import Task exposing (Task)
import Types.DiagramItem exposing (DiagramItem)
import Types.Email as Email exposing (Email)
import Types.IdToken as IdToken exposing (IdToken)
import Types.IpAddress as IpAddress exposing (IpAddress)
import Url.Builder exposing (crossOrigin)


graphQLUrl : String
graphQLUrl =
    crossOrigin Env.apiRoot [ "graphql" ] []


item : Maybe IdToken -> String -> Task (Http.Error DiagramItem) DiagramItem
item idToken id =
    Query.item id False
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


publicItem : Maybe IdToken -> String -> Task (Http.Error DiagramItem) DiagramItem
publicItem idToken id =
    Query.item id True
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


items : Maybe IdToken -> ( Int, Int ) -> { isPublic : Bool, isBookmark : Bool } -> Task (Http.Error (List (Maybe DiagramItem))) (List (Maybe DiagramItem))
items idToken ( offset, limit ) params =
    Query.items ( offset, limit ) params
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


shareItem : Maybe IdToken -> String -> Maybe String -> Task (Http.Error DiagramItem) DiagramItem
shareItem idToken id password =
    Query.shareItem id password
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


shareCondition : Maybe IdToken -> String -> Task (Http.Error (Maybe Query.ShareCondition)) (Maybe Query.ShareCondition)
shareCondition idToken id =
    Query.shareCondition id
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


save : Maybe IdToken -> InputItem -> Bool -> Task (Http.Error DiagramItem) DiagramItem
save idToken input isPublic =
    Mutation.save input isPublic
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


delete : Maybe IdToken -> String -> Bool -> Task RequestError String
delete idToken itemID isPublic =
    Mutation.delete itemID isPublic
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.map (\(ItemIdScalar id) -> id)
        |> Task.mapError toError


bookmark : Maybe IdToken -> String -> Bool -> Task (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem)
bookmark idToken itemID isBookmark =
    Mutation.bookmark itemID isBookmark
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


share :
    { idToken : Maybe IdToken
    , itemID : String
    , expSecond : Int
    , password : Maybe String
    , allowIPList : List IpAddress
    , allowEmailList : List Email
    }
    -> Task (Http.Error String) String
share { idToken, itemID, expSecond, password, allowIPList, allowEmailList } =
    Mutation.share
        { itemID = ItemIdScalar itemID
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
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask


authHeaders : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
authHeaders idToken =
    case idToken of
        Just t ->
            Http.withHeader "Authorization" <| IdToken.unwrap t

        Nothing ->
            Http.withOperationName ""
