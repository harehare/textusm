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
        |> required "forksUrl" D.string
        |> required "commitsUrl" D.string
        |> required "id" D.string
        |> required "nodeId" D.string
        |> required "gitPullUrl" D.string
        |> required "gitPushUrl" D.string
        |> required "htmlUrl" D.string
        |> required "createdAt" D.string
        |> required "updatedAt" D.string
        |> required "description" D.string
        |> required "comments" D.int
        |> required "commentsUrl" D.string
