module Api.External.Github.Gist exposing (File, Gist, decoder)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)


type alias File =
    { filename : String
    , type_ : String
    , language : Maybe String
    , rawUrl : String
    , size : Int
    , truncated : Bool
    , content : String
    }


type alias Gist =
    { url : String
    , forksUrl : String
    , commitsUrl : String
    , id : String
    , nodeId : String
    , gitPullUrl : String
    , gitPushUrl : String
    , htmlUrl : String
    , files : List ( String, File )
    , createdAt : String
    , updatedAt : String
    , description : String
    , comments : Int
    , commentsUrl : String
    }


decoder : D.Decoder Gist
decoder =
    D.succeed Gist
        |> required "url" D.string
        |> required "forks_url" D.string
        |> required "commits_url" D.string
        |> required "id" D.string
        |> required "node_id" D.string
        |> required "git_pull_url" D.string
        |> required "git_push_url" D.string
        |> required "html_url" D.string
        |> required "files" (D.keyValuePairs fileDecoder)
        |> required "created_at" D.string
        |> required "updated_at" D.string
        |> required "description" D.string
        |> required "comments" D.int
        |> required "comments_url" D.string


fileDecoder : D.Decoder File
fileDecoder =
    D.succeed File
        |> required "filename" D.string
        |> required "type" D.string
        |> optional "language" (D.map Just D.string) Nothing
        |> required "raw_url" D.string
        |> required "size" D.int
        |> required "truncated" D.bool
        |> required "content" D.string
