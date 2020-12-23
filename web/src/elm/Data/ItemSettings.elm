module Data.ItemSettings exposing
    ( ItemSettings
    , decoder
    , encoder
    , getBackgroundColor
    , getForegroundColor
    , getOffset
    , new
    , withBackgroundColor
    , withForegroundColor
    , withPosition
    , toString
    )

import Data.Color as Color exposing (Color)
import Data.Position as Position exposing (Position)
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)


type ItemSettings
    = ItemSettings Settings


type alias Settings =
    { backgroundColor : Maybe Color
    , foregroundColor : Maybe Color
    , offset : Position
    }


new : ItemSettings
new =
    ItemSettings
        { backgroundColor = Nothing
        , foregroundColor = Nothing
        , offset = Position.zero
        }


getBackgroundColor : ItemSettings -> Maybe Color
getBackgroundColor (ItemSettings settings) =
    settings.backgroundColor


getForegroundColor : ItemSettings -> Maybe Color
getForegroundColor (ItemSettings settings) =
    settings.foregroundColor


getOffset : ItemSettings -> Position
getOffset (ItemSettings settings) =
    settings.offset


withBackgroundColor : Maybe Color -> ItemSettings -> ItemSettings
withBackgroundColor bg (ItemSettings settings) =
    ItemSettings { settings | backgroundColor = bg }


withForegroundColor : Maybe Color -> ItemSettings -> ItemSettings
withForegroundColor fg (ItemSettings settings) =
    ItemSettings { settings | foregroundColor = fg }


withPosition : Position -> ItemSettings -> ItemSettings
withPosition position (ItemSettings settings) =
    ItemSettings { settings | offset = position }


encoder : ItemSettings -> E.Value
encoder (ItemSettings settings) =
    E.object
        [ ( "bg", maybe E.string (Maybe.andThen (\c -> Just <| Color.toString c) settings.backgroundColor) )
        , ( "fg", maybe E.string (Maybe.andThen (\c -> Just <| Color.toString c) settings.foregroundColor) )
        , ( "offset", E.list E.int [ Position.getX settings.offset, Position.getY settings.offset ] )
        ]


decoder : D.Decoder ItemSettings
decoder =
    D.map ItemSettings
        (D.succeed
            Settings
            |> optional "bg" (D.map Just Color.decoder) Nothing
            |> optional "fg" (D.map Just Color.decoder) Nothing
            |> required "offset" Position.decoder
        )


toString : ItemSettings -> String
toString settings =
    E.encode 0 (encoder settings)
