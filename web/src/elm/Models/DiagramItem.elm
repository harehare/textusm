module Models.DiagramItem exposing (DiagramId, DiagramItem, DiagramUser, decoder, encoder, userDecoder)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)


type alias DiagramId =
    String


type alias DiagramItem =
    { diagramPath : String
    , id : Maybe DiagramId
    , ownerId : Maybe String
    , text : String
    , thumbnail : Maybe String
    , title : String
    , isRemote : Bool
    , isPublic : Bool
    , users : Maybe (List DiagramUser)
    , updatedAt : Maybe Int
    }


type alias DiagramUser =
    { id : String
    , name : String
    , photoURL : String
    , role : String
    , mail : String
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
    D.succeed DiagramItem
        |> required "diagram_path" D.string
        |> required "id" (D.nullable D.string)
        |> required "owner_id" (D.nullable D.string)
        |> required "text" D.string
        |> required "thumbnail" (D.nullable D.string)
        |> required "title" D.string
        |> required "is_remote" D.bool
        |> required "is_public" D.bool
        |> required "users" (D.nullable (D.list userDecoder))
        |> required "updated_at" (D.nullable D.int)


userDecoder : D.Decoder DiagramUser
userDecoder =
    D.map5 DiagramUser
        (D.field "id" D.string)
        (D.field "name" D.string)
        (D.field "photo_url" D.string)
        (D.field "role" D.string)
        (D.field "mail" D.string)
