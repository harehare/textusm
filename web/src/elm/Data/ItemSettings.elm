module Data.ItemSettings exposing
    ( ItemSettings
    , decoder
    , encoder
    , getBackgroundColor
    , getFontSize
    , getForegroundColor
    , getOffset
    , new
    , toString
    , withBackgroundColor
    , withFontSize
    , withForegroundColor
    , withOffset
    )

import Data.Color as Color exposing (Color)
import Data.FontSize as FontSize exposing (FontSize)
import Data.Position as Position exposing (Position)
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E


type ItemSettings
    = ItemSettings Settings


type alias Settings =
    { backgroundColor : Maybe Color
    , foregroundColor : Maybe Color
    , offset : Position
    , fontSize : FontSize
    }


new : ItemSettings
new =
    ItemSettings
        { backgroundColor = Nothing
        , foregroundColor = Nothing
        , offset = Position.zero
        , fontSize = FontSize.default
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


getFontSize : ItemSettings -> FontSize
getFontSize (ItemSettings settings) =
    settings.fontSize


withBackgroundColor : Maybe Color -> ItemSettings -> ItemSettings
withBackgroundColor bg (ItemSettings settings) =
    ItemSettings { settings | backgroundColor = bg }


withForegroundColor : Maybe Color -> ItemSettings -> ItemSettings
withForegroundColor fg (ItemSettings settings) =
    ItemSettings { settings | foregroundColor = fg }


withOffset : Position -> ItemSettings -> ItemSettings
withOffset position (ItemSettings settings) =
    ItemSettings { settings | offset = position }


withFontSize : FontSize -> ItemSettings -> ItemSettings
withFontSize fontSize (ItemSettings settings) =
    ItemSettings { settings | fontSize = fontSize }


encoder : ItemSettings -> E.Value
encoder (ItemSettings settings) =
    E.object <|
        (case settings.backgroundColor of
            Just color ->
                [ ( "b", E.string <| Color.toString color ) ]

            Nothing ->
                []
        )
            ++ (case settings.foregroundColor of
                    Just color ->
                        [ ( "f", E.string <| Color.toString color ) ]

                    Nothing ->
                        []
               )
            ++ (if settings.offset == Position.zero then
                    []

                else
                    [ ( "o", E.list E.int [ Position.getX settings.offset, Position.getY settings.offset ] ) ]
               )
            ++ (if FontSize.unwrap settings.fontSize == FontSize.unwrap FontSize.default then
                    []

                else
                    [ ( "s", E.int <| FontSize.unwrap settings.fontSize ) ]
               )


decoder : D.Decoder ItemSettings
decoder =
    D.map ItemSettings
        (D.succeed
            Settings
            |> optional "b" (D.map Just Color.decoder) Nothing
            |> optional "f" (D.map Just Color.decoder) Nothing
            |> optional "o" Position.decoder Position.zero
            |> optional "s" FontSize.decoder FontSize.default
        )


toString : ItemSettings -> String
toString settings =
    E.encode 0 (encoder settings)
