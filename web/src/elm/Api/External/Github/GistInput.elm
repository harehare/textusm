module Api.External.Github.GistInput exposing (GistInput, encoder)

import Json.Encode as E
import Json.Encode.Extra exposing (maybe)


type alias GistInput =
    { description : Maybe String
    , files : List ( String, File )
    , public : Bool
    }


type alias File =
    { content : String
    }


encoder : GistInput -> E.Value
encoder gist =
    E.object
        [ ( "description", maybe E.string gist.description )
        , ( "file", E.object <| List.map (\( k, v ) -> ( k, E.string v.content )) gist.files )
        , ( "public", E.bool gist.public )
        ]
