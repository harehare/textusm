module Api.External.Github.GistInput exposing (File, FileContent, GistInput, encoder)

import Json.Encode as E


type alias File =
    { content : FileContent
    }


type alias FileContent =
    { content : String
    }


type alias GistInput =
    { description : String
    , files : List ( String, File )
    , public : Bool
    }


encoder : GistInput -> E.Value
encoder gist =
    E.object
        [ ( "description", E.string gist.description )
        , ( "files", E.object <| List.map (\( k, v ) -> ( k, fileContentEncorder v.content )) gist.files )
        , ( "public", E.bool gist.public )
        ]


fileContentEncorder : FileContent -> E.Value
fileContentEncorder content =
    E.object
        [ ( "content", E.string content.content )
        ]
