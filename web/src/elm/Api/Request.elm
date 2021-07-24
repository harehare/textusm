module Api.Request exposing
    ( bookmark
    , delete
    , deleteGist
    , gistItem
    , gistItems
    , item
    , items
    , publicItem
    , save
    , saveGist
    , share
    , shareCondition
    , shareItem
    )

import Api.External.Github.Request as GithubRequest exposing (AccessToken, GistId)
import Api.Mutation as Mutation
import Api.Query as Query
import Api.RequestError as RequestError exposing (RequestError, toError)
import Dict
import Env
import Graphql.Http as Http
import Graphql.InputObject exposing (InputGistItem, InputItem)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar exposing (GistIdScalar(..), ItemIdScalar(..))
import Task exposing (Task)
import Types.DiagramId as DiagramId
import Types.DiagramItem exposing (DiagramItem)
import Types.Email as Email exposing (Email)
import Types.IdToken as IdToken exposing (IdToken)
import Types.IpAddress as IpAddress exposing (IpAddress)
import Types.Text as Text
import Types.Title as Title
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
                            let
                                content =
                                    Dict.fromList gist.files
                                        |> Dict.get (Title.toString x.title)
                                        |> Maybe.map .content
                                        |> Maybe.withDefault ""
                            in
                            { x | id = Just <| DiagramId.fromString gist.id, text = Text.fromString content }
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


saveGist : Maybe IdToken -> AccessToken -> InputGistItem -> String -> Task RequestError DiagramItem
saveGist idToken accessToken input content =
    let
        gistInput =
            { description = Nothing
            , files = [ ( input.title, { content = content } ) ]
            , public = False
            }

        saveTask =
            Task.andThen
                (\gist ->
                    Mutation.saveGist
                        { input | id = Present <| GistIdScalar gist.id }
                        |> Http.mutationRequest graphQLUrl
                        |> authHeaders idToken
                        |> Http.toTask
                        |> Task.mapError toError
                )
    in
    case input.id of
        Null ->
            GithubRequest.createGist accessToken gistInput
                |> Task.mapError RequestError.fromHttpError
                |> saveTask

        Present (GistIdScalar id_) ->
            GithubRequest.updateGist accessToken id_ gistInput
                |> Task.mapError RequestError.fromHttpError
                |> saveTask

        _ ->
            Task.fail RequestError.InvalidParameter


deleteGist : Maybe IdToken -> AccessToken -> GistId -> Task RequestError String
deleteGist idToken accessToken gistId =
    GithubRequest.deleteGist accessToken gistId
        |> Task.mapError RequestError.fromHttpError
        |> Task.andThen
            (\_ ->
                Mutation.deleteGist gistId
                    |> Http.mutationRequest graphQLUrl
                    |> authHeaders idToken
                    |> Http.toTask
                    |> Task.map (\(GistIdScalar id) -> id)
                    |> Task.mapError toError
            )


authHeaders : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
authHeaders idToken =
    case idToken of
        Just t ->
            Http.withHeader "Authorization" <| IdToken.unwrap t

        Nothing ->
            Http.withOperationName ""
