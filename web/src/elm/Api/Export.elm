module Api.Export exposing (Request, Response, Service(..), StoryItem, TaskItem, createRequest, export, getAccessToken)

import Api.Api as Api
import Browser.Navigation as Nav
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import List
import Maybe.Extra exposing (isJust)
import Models.Item as Item exposing (Children, Item, ItemType(..))
import Regex
import Task exposing (Task)
import Url.Builder exposing (crossOrigin)


type alias Request =
    { oauthVerifier : Maybe String
    , oauthToken : String
    , name : String
    , releases : List Release
    , tasks : List TaskItem
    , github : Maybe GithubRequest
    }


type alias Response =
    { total : Int
    , failed : Int
    , successful : Int
    , url : String
    }


type alias Release =
    { name : String
    , period : Maybe String
    }


type alias GithubRequest =
    { owner : String
    , repo : String
    }


type alias TaskItem =
    { name : String
    , comment : Maybe String
    , stories : List StoryItem
    }


type alias StoryItem =
    { name : String
    , comment : Maybe String
    , release : Int
    }


type Service
    = Trello
    | Github


releasePattern : Regex.Regex
releasePattern =
    Maybe.withDefault Regex.never <|
        Regex.fromString "^release[0-9]+$"


dateFormat : Regex.Regex
dateFormat =
    Maybe.withDefault Regex.never <|
        Regex.fromString "^[0-9]{4}-[0-9]{2}-[0-9]{2}"


requestEncoder : Request -> E.Value
requestEncoder req =
    E.object
        [ ( "oauth_verifier", maybe E.string req.oauthVerifier )
        , ( "oauth_token", E.string req.oauthToken )
        , ( "name", E.string req.name )
        , ( "releases", E.list releaseEncoder req.releases )
        , ( "tasks", E.list taskEncoder req.tasks )
        , ( "github", maybe githubEncoder req.github )
        ]


releaseEncoder : Release -> E.Value
releaseEncoder release =
    E.object
        [ ( "name", E.string release.name )
        , ( "period", maybe E.string release.period )
        ]


githubEncoder : GithubRequest -> E.Value
githubEncoder github =
    E.object
        [ ( "owner", E.string github.owner )
        , ( "repo", E.string github.repo )
        ]


taskEncoder : TaskItem -> E.Value
taskEncoder task =
    E.object
        [ ( "name", E.string task.name )
        , ( "comment", maybe E.string task.comment )
        , ( "stories", E.list storyEncoder task.stories )
        ]


storyEncoder : StoryItem -> E.Value
storyEncoder story =
    E.object
        [ ( "name", E.string story.name )
        , ( "comment", maybe E.string story.comment )
        , ( "release", E.int story.release )
        ]


responseDecoder : D.Decoder Response
responseDecoder =
    D.map4 Response
        (D.field "total" D.int)
        (D.field "failed" D.int)
        (D.field "successful" D.int)
        (D.field "url" D.string)


createRelease : List ( String, String ) -> Int -> List Release
createRelease pairs releaseCount =
    let
        items =
            pairs
                |> List.map
                    (\( key, value ) ->
                        if key |> String.toLower |> Regex.contains releasePattern then
                            if Regex.contains dateFormat value then
                                Just
                                    ( key
                                    , { name = key
                                      , period = Just (String.trim value)
                                      }
                                    )

                            else
                                Nothing

                        else
                            Nothing
                    )
                |> List.filter (\x -> isJust x)
                |> List.map (\x -> x |> Maybe.withDefault ( "0", { name = "", period = Nothing } ))

        v =
            items |> List.map (\( x, _ ) -> x)
    in
    (List.range 1 releaseCount
        |> List.map (\x -> "RELEASE" ++ String.fromInt x)
        |> List.filter (\x -> not (List.member x v))
        |> List.map
            (\x ->
                { name = x
                , period = Nothing
                }
            )
    )
        ++ (items
                |> List.map
                    (\( _, releaseItem ) ->
                        releaseItem
                    )
           )


createRequest : String -> Maybe String -> Maybe GithubRequest -> Int -> List ( String, String ) -> String -> List Item -> Request
createRequest token code github release releaseItems name items =
    let
        releases =
            createRelease releaseItems release

        flatten : List Item -> List Item
        flatten x =
            x
                ++ (x
                        |> List.map
                            (\item ->
                                Item.unwrapChildren item.children
                            )
                        |> List.concat
                   )

        tasks =
            List.foldr
                (\x y ->
                    y
                        ++ Item.unwrapChildren x.children
                )
                []
                items
                |> List.filter (\x -> x.itemType == Tasks)
                |> List.map
                    (\item ->
                        let
                            i =
                                Item.unwrapChildren item.children
                        in
                        { name = item.text
                        , comment = item.comment
                        , stories =
                            flatten i
                                |> List.map
                                    (\story ->
                                        { name = story.text
                                        , comment = story.comment
                                        , release =
                                            case story.itemType of
                                                Stories n ->
                                                    n

                                                _ ->
                                                    0
                                        }
                                    )
                        }
                    )
    in
    { oauthVerifier = code
    , oauthToken = token
    , name = name
    , releases = releases
    , tasks = tasks
    , github = github
    }


getAccessToken : String -> Service -> Cmd msg
getAccessToken apiRoot service =
    case service of
        Trello ->
            crossOrigin apiRoot [ "auth", "trello" ] [] |> Nav.load

        _ ->
            Cmd.none


export : String -> Service -> Request -> Task Http.Error Response
export apiRoot service req =
    case service of
        Trello ->
            Api.post Nothing apiRoot [ "export", "trello" ] (Http.jsonBody (requestEncoder req)) (Api.jsonResolver responseDecoder)

        Github ->
            Api.post Nothing apiRoot [ "export", "github" ] (Http.jsonBody (requestEncoder req)) (Api.jsonResolver responseDecoder)
