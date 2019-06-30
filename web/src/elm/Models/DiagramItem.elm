module Models.DiagramItem exposing (DiagramId, DiagramItem, decoder, encoder)

import Json.Decode as D
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)


type alias DiagramId =
    String


type alias DiagramItem =
    { diagramPath : String
    , id : Maybe DiagramId
    , text : String
    , thumbnail : Maybe String
    , title : String
    , isRemote : Bool
    , isPublic : Bool
    , updatedAt : Maybe Int
    }


encoder : DiagramItem -> E.Value
encoder diagram =
    E.object
        [ ( "diagram_path", E.string diagram.diagramPath )
        , ( "id", maybe E.string diagram.id )
        , ( "text", E.string diagram.text )
        , ( "thumbnail", maybe E.string diagram.thumbnail )
        , ( "title", E.string diagram.title )
        , ( "is_public", E.bool diagram.isPublic )
        ]


decoder : D.Decoder DiagramItem
decoder =
    D.map8 DiagramItem
        (D.field "diagram_path" D.string)
        (D.maybe (D.field "id" D.string))
        (D.field "text" D.string)
        (D.maybe (D.field "thumbnail" D.string))
        (D.field "title" D.string)
        (D.field "is_remote" D.bool)
        (D.field "is_public" D.bool)
        (D.maybe (D.field "updated_at" D.int))
