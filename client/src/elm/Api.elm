module Api exposing (Config, Request, Response, Service(..), StoryItem, TaskItem, createRequest, export, getAccessToken)

import Browser.Navigation as Nav
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Figure as FigureModel exposing (Children(..), Item, ItemType(..))
import Task exposing (Task)


type alias Config =
    { apiRoot : String
    }


type alias Request =
    { oauthVerifier : String
    , oauthToken : String
    , name : String
    , release : Int
    , tasks : List TaskItem
    }


type alias Response =
    { total : Int
    , failed : Int
    , successful : Int
    , url : String
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
    | Asana


requestEncoder : Request -> E.Value
requestEncoder req =
    E.object
        [ ( "oauth_verifier", E.string req.oauthVerifier )
        , ( "oauth_token", E.string req.oauthToken )
        , ( "name", E.string req.name )
        , ( "release", E.int req.release )
        , ( "tasks", E.list taskEncoder req.tasks )
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


createRequest : String -> String -> Int -> String -> List Item -> Request
createRequest token code release name items =
    let
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
                                        , comment = item.comment
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
    , release = release
    , tasks = tasks
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

        _ ->
            Task.fail (BadBody "Unsupported service")


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
