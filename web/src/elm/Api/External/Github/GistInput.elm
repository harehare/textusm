module Api.External.Github.GistInput exposing (GistInput, encoder)

import Json.Encode as E


type alias GistInput =
    { accept : String
    , description : String
    , files : List ( String, File )
    , public : Bool
    }


type alias File =
    { content : String
    }


encoder : GistInput -> E.Value
encoder gist =
    E.object
        [ ( "accept", E.string gist.accept )
        , ( "description", E.string gist.description )
        , ( "file", E.object <| List.map (\( k, v ) -> ( k, E.string v.content )) gist.files )
        , ( "public", E.bool gist.public )
        ]
