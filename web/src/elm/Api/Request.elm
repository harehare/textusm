module Api.Request exposing
    ( bookmark
    , delete
    , gistItem
    , gistItems
    , item
    , items
    , publicItem
    , save
    , share
    , shareCondition
    , shareItem
    )

import Api.External.Github.Request as GithubRequest exposing (AccessToken, GistId)
import Api.Mutation as Mutation
import Api.Query as Query
import Api.RequestError as RequestError exposing (RequestError, toError)
import Env
import Graphql.Http as Http
import Graphql.InputObject exposing (InputGistItem, InputItem)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar exposing (ItemIdScalar(..))
import Task exposing (Task)
import Types.DiagramId as DiagramId
import Types.DiagramItem exposing (DiagramItem)
import Types.Email as Email exposing (Email)
import Types.IdToken as IdToken exposing (IdToken)
import Types.IpAddress as IpAddress exposing (IpAddress)
import Url.Builder exposing (crossOrigin)


graphQLUrl : String
graphQLUrl =
    crossOrigin Env.apiRoot [ "graphql" ] []


item : Maybe IdToken -> String -> Task RequestError DiagramItem
item idToken id =
    Query.item id False
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


publicItem : Maybe IdToken -> String -> Task RequestError DiagramItem
publicItem idToken id =
    Query.item id True
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


items : Maybe IdToken -> ( Int, Int ) -> { isPublic : Bool, isBookmark : Bool } -> Task RequestError (List (Maybe DiagramItem))
items idToken ( offset, limit ) params =
    Query.items ( offset, limit ) params
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


shareItem : Maybe IdToken -> String -> Maybe String -> Task RequestError DiagramItem
shareItem idToken id password =
    Query.shareItem id password
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


shareCondition : Maybe IdToken -> String -> Task RequestError (Maybe Query.ShareCondition)
shareCondition idToken id =
    Query.shareCondition id
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


save : Maybe IdToken -> InputItem -> Bool -> Task RequestError DiagramItem
save idToken input isPublic =
    Mutation.save input isPublic
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


delete : Maybe IdToken -> String -> Bool -> Task RequestError String
delete idToken itemID isPublic =
    Mutation.delete itemID isPublic
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.map (\(ItemIdScalar id) -> id)
        |> Task.mapError toError


bookmark : Maybe IdToken -> String -> Bool -> Task RequestError (Maybe DiagramItem)
bookmark idToken itemID isBookmark =
    Mutation.bookmark itemID isBookmark
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


share :
    { idToken : Maybe IdToken
    , itemID : String
    , expSecond : Int
    , password : Maybe String
    , allowIPList : List IpAddress
    , allowEmailList : List Email
    }
    -> Task RequestError String
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
        |> Task.mapError toError


gistItem : Maybe IdToken -> AccessToken -> GistId -> Task RequestError DiagramItem
gistItem idToken accessToken gistId =
    GithubRequest.getGist accessToken gistId
        |> Task.mapError RequestError.fromHttpError
        |> Task.andThen
            (\gist ->
                Query.gistItem gistId
                    |> Http.queryRequest graphQLUrl
                    |> authHeaders idToken
                    |> Http.toTask
                    |> Task.map
                        (\x ->
                            { x | id = Just <| DiagramId.fromString gist.id }
                        )
                    |> Task.mapError toError
            )


gistItems : Maybe IdToken -> ( Int, Int ) -> Task RequestError (List (Maybe DiagramItem))
gistItems idToken ( offset, limit ) =
    Query.gistItems ( offset, limit )
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


authHeaders : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
authHeaders idToken =
    case idToken of
        Just t ->
            Http.withHeader "Authorization" <| IdToken.unwrap t

        Nothing ->
            Http.withOperationName ""
