module Data.ItemSettings exposing (ItemSettings, decoder, encoder, new)

import Data.Position as Position exposing (Position)
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)


type ItemSettings
    = ItemSettings Settings


type alias Settings =
    { backgroundColor : Maybe String
    , foregroundColor : Maybe String
    , offset : Position
    }


new : ItemSettings
new =
    ItemSettings
        { backgroundColor = Nothing
        , foregroundColor = Nothing
        , offset = Position.zero
        }


encoder : ItemSettings -> E.Value
encoder (ItemSettings settings) =
    E.object
        [ ( "bg", maybe E.string settings.backgroundColor )
        , ( "fg", maybe E.string settings.foregroundColor )
        , ( "offset", E.list E.int [ Position.getX settings.offset, Position.getY settings.offset ] )
        ]


decoder : D.Decoder ItemSettings
decoder =
    D.map ItemSettings
        (D.succeed
            Settings
            |> optional "bg" (D.map Just D.string) Nothing
            |> optional "fg" (D.map Just D.string) Nothing
            |> required "offset" Position.decoder
        )
