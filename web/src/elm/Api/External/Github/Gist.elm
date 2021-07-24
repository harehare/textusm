module Api.External.Github.Gist exposing (Gist, decoder)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)


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


type alias File =
    { filename : String
    , type_ : String
    , language : String
    , raw_url : String
    , size : Int
    , truncated : Bool
    , content : String
    }


decoder : D.Decoder Gist
decoder =
    D.succeed Gist
        |> required "url" D.string
        |> required "forksUrl" D.string
        |> required "commitsUrl" D.string
        |> required "id" D.string
        |> required "nodeId" D.string
        |> required "gitPullUrl" D.string
        |> required "gitPushUrl" D.string
        |> required "htmlUrl" D.string
        |> required "files" (D.keyValuePairs fileDecoder)
        |> required "createdAt" D.string
        |> required "updatedAt" D.string
        |> required "description" D.string
        |> required "comments" D.int
        |> required "commentsUrl" D.string


fileDecoder : D.Decoder File
fileDecoder =
    D.succeed File
        |> required "filename" D.string
        |> required "type" D.string
        |> required "language" D.string
        |> required "raw_url" D.string
        |> required "size" D.int
        |> required "truncated" D.bool
        |> required "content" D.string
