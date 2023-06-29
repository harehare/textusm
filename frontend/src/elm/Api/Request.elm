module Api.Request exposing
    ( allItems
    , bookmark
    , delete
    , deleteGist
    , gistItem
    , gistItems
    , item
    , items
    , publicItem
    , save
    , saveGist
    , saveSettings
    , settings
    , share
    , shareCondition
    , shareItem
    )

import Api.External.Github.GistInput exposing (GistInput)
import Api.External.Github.Request as GithubRequest exposing (AccessToken)
import Api.Graphql.Mutation as Mutation
import Api.Graphql.Query as Query
import Api.RequestError as RequestError exposing (RequestError, toError)
import Dict
import Env
import Graphql.Http as Http
import Graphql.InputObject exposing (InputGistItem, InputItem, InputSettings)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar
import Models.Diagram.Id as DiagramId exposing (DiagramId)
import Models.Diagram.Item exposing (DiagramItem)
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type exposing (DiagramType)
import Models.Duration as Duration exposing (Duration)
import Models.Email as Email exposing (Email)
import Models.IdToken as IdToken exposing (IdToken)
import Models.IpAddress as IpAddress exposing (IpAddress)
import Models.Text as Text
import Models.Title as Title
import Task exposing (Task)
import Url.Builder exposing (crossOrigin)


allItems : Maybe IdToken -> ( Int, Int ) -> Task RequestError (Maybe (List DiagramItem))
allItems idToken ( offset, limit ) =
    Query.allItems ( offset, limit )
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


bookmark : Maybe IdToken -> String -> Bool -> Task RequestError (Maybe DiagramItem)
bookmark idToken itemID isBookmark =
    Mutation.bookmark itemID isBookmark
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


delete : Maybe IdToken -> DiagramId -> Bool -> Task RequestError String
delete idToken itemID isPublic =
    Mutation.delete (DiagramId.toString itemID) isPublic
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.map (\(Graphql.Scalar.Id id) -> id)
        |> Task.mapError toError


deleteGist : Maybe IdToken -> AccessToken -> DiagramId -> Task RequestError String
deleteGist idToken accessToken gistId =
    GithubRequest.deleteGist accessToken gistId
        |> Task.mapError RequestError.fromHttpError
        |> Task.andThen
            (\_ ->
                Mutation.deleteGist (DiagramId.toString gistId)
                    |> Http.mutationRequest graphQLUrl
                    |> authHeaders idToken
                    |> Http.toTask
                    |> Task.map (\(Graphql.Scalar.Id id) -> id)
                    |> Task.mapError toError
            )


gistItem : Maybe IdToken -> AccessToken -> DiagramId -> Task RequestError DiagramItem
gistItem idToken accessToken gistId =
    GithubRequest.getGist accessToken gistId
        |> Task.mapError RequestError.fromHttpError
        |> Task.andThen
            (\gist ->
                Query.gistItem (DiagramId.toString gistId)
                    |> Http.queryRequest graphQLUrl
                    |> authHeaders idToken
                    |> Http.toTask
                    |> Task.map
                        (\x ->
                            let
                                content : String
                                content =
                                    Dict.fromList gist.files
                                        |> Dict.get (Title.toString x.title)
                                        |> Maybe.map .content
                                        |> Maybe.withDefault ""
                            in
                            { x
                                | id = Just <| DiagramId.fromString gist.id
                                , text = Text.fromString content
                            }
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


item : Maybe IdToken -> String -> Task RequestError DiagramItem
item idToken id =
    Query.item id False
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


publicItem : Maybe IdToken -> String -> Task RequestError DiagramItem
publicItem idToken id =
    Query.item id True
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


saveGist : Maybe IdToken -> AccessToken -> InputGistItem -> String -> Task RequestError DiagramItem
saveGist idToken accessToken input content =
    let
        gistInput : GistInput
        gistInput =
            { description = "This text is created by TextUSM"
            , files = [ ( input.title, { content = { content = content } } ) ]
            , public = False
            }

        saveTask : { a | id : String, url : String } -> Task RequestError DiagramItem
        saveTask =
            \gist ->
                Mutation.saveGist
                    { input | id = Present <| Graphql.Scalar.Id gist.id, url = gist.url }
                    |> Http.mutationRequest graphQLUrl
                    |> authHeaders idToken
                    |> Http.toTask
                    |> Task.mapError toError
    in
    case input.id of
        Present (Graphql.Scalar.Id id_) ->
            GithubRequest.updateGist accessToken id_ gistInput
                |> Task.mapError RequestError.fromHttpError
                |> Task.andThen saveTask

        Null ->
            GithubRequest.createGist accessToken gistInput
                |> Task.mapError RequestError.fromHttpError
                |> Task.andThen saveTask

        _ ->
            GithubRequest.createGist accessToken gistInput
                |> Task.mapError RequestError.fromHttpError
                |> Task.andThen saveTask


saveSettings : Maybe IdToken -> DiagramType -> InputSettings -> Task RequestError DiagramSettings.Settings
saveSettings idToken diagram input =
    Mutation.saveSettings diagram input
        |> Http.mutationRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


settings : Maybe IdToken -> DiagramType -> Task RequestError DiagramSettings.Settings
settings idToken diagram =
    Query.settings diagram
        |> Http.queryRequest graphQLUrl
        |> authHeaders idToken
        |> Http.toTask
        |> Task.mapError toError


share :
    { idToken : Maybe IdToken
    , itemID : String
    , expSecond : Duration
    , password : Maybe String
    , allowIPList : List IpAddress
    , allowEmailList : List Email
    }
    -> Task RequestError String
share { idToken, itemID, expSecond, password, allowIPList, allowEmailList } =
    Mutation.share
        { itemID = Graphql.Scalar.Id itemID
        , expSecond = Present <| Duration.toInt expSecond
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


shareCondition : Maybe IdToken -> String -> Task RequestError (Maybe Query.ShareCondition)
shareCondition idToken id =
    Query.shareCondition id
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


authHeaders : Maybe IdToken -> Http.Request decodesTo -> Http.Request decodesTo
authHeaders idToken =
    case idToken of
        Just t ->
            Http.withHeader "Authorization" <| IdToken.unwrap t

        Nothing ->
            Http.withOperationName ""


graphQLUrl : String
graphQLUrl =
    crossOrigin Env.apiRoot [ "graphql" ] []
