module Api exposing (Config, Request, Response, Service(..), StoryItem, TaskItem, createRequest, errorToString, export, getAccessToken)

import Browser.Navigation as Nav
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import List
import Maybe.Extra exposing (isJust)
import Models.Diagram as DiagramModel exposing (Children(..), Item, ItemType(..))
import Regex
import Task exposing (Task)


type alias Config =
    { apiRoot : String
    }


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
            items |> List.map (\( x, y ) -> x)
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
                    (\( count, releaseItem ) ->
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
                                case item.children of
                                    Children [] ->
                                        []

                                    Children c ->
                                        flatten c
                            )
                        |> List.concat
                   )

        tasks =
            List.foldr
                (\x y ->
                    y
                        ++ (case x.children of
                                Children [] ->
                                    []

                                Children c ->
                                    c
                           )
                )
                []
                items
                |> List.filter (\x -> x.itemType == Tasks)
                |> List.map
                    (\item ->
                        let
                            (Children i) =
                                item.children
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


getAccessToken : Config -> Service -> Cmd msg
getAccessToken config service =
    case service of
        Trello ->
            Nav.load (config.apiRoot ++ "/auth/trello")

        _ ->
            Cmd.none


export : Config -> Service -> Request -> Task Http.Error Response
export config service req =
    case service of
        Trello ->
            post (config.apiRoot ++ "/create/trello") req

        Github ->
            post (config.apiRoot ++ "/create/github") req


post : String -> Request -> Task Http.Error Response
post path req =
    Http.task
        { method = "POST"
        , headers =
            [ Http.header "Content-Type" "application/json"
            ]
        , url = path
        , body = Http.jsonBody (requestEncoder req)
        , resolver = jsonResolver responseDecoder
        , timeout = Nothing
        }


jsonResolver : D.Decoder a -> Http.Resolver Http.Error a
jsonResolver decoder =
    Http.stringResolver <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata body ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ metadata body ->
                    case D.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (D.errorToString err))


errorToString : Http.Error -> String
errorToString err =
    case err of
        BadUrl url ->
            "Invalid url " ++ url

        Timeout ->
            "Timeout error. Please try again later."

        NetworkError ->
            "Network error. Please try again later."

        _ ->
            "Internal server error. Please try again later."
