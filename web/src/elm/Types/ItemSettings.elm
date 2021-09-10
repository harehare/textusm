module Types.ItemSettings exposing
    ( ItemSettings
    , decoder
    , encoder
    , getBackgroundColor
    , getFontSize
    , getForegroundColor
    , getOffset
    , getOffsetSize
    , new
    , toString
    , withBackgroundColor
    , withFontSize
    , withForegroundColor
    , withOffset
    , withOffsetSize
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E
import Types.Color as Color exposing (Color)
import Types.FontSize as FontSize exposing (FontSize)
import Types.Position as Position exposing (Position)
import Types.Size as Size exposing (Size)


type ItemSettings
    = ItemSettings Settings


type alias Settings =
    { backgroundColor : Maybe Color
    , foregroundColor : Maybe Color
    , fontSize : FontSize
    , offset : Position
    , offsetSize : Maybe Size
    }


new : ItemSettings
new =
    ItemSettings
        { backgroundColor = Nothing
        , foregroundColor = Nothing
        , offset = Position.zero
        , fontSize = FontSize.default
        , offsetSize = Nothing
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


getOffsetSize : ItemSettings -> Maybe Size
getOffsetSize (ItemSettings settings) =
    settings.offsetSize


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


withOffsetSize : Maybe Size -> ItemSettings -> ItemSettings
withOffsetSize offsetSize (ItemSettings settings) =
    ItemSettings { settings | offsetSize = offsetSize }


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
            ++ (case settings.offsetSize of
                    Just size ->
                        [ ( "os", E.list E.int [ Size.getWidth size, Size.getHeight size ] ) ]

                    Nothing ->
                        []
               )


decoder : D.Decoder ItemSettings
decoder =
    D.map ItemSettings
        (D.succeed
            Settings
            |> optional "b" (D.map Just Color.decoder) Nothing
            |> optional "f" (D.map Just Color.decoder) Nothing
            |> optional "s" FontSize.decoder FontSize.default
            |> optional "o" Position.decoder Position.zero
            |> optional "os" (D.map Just Size.decoder) Nothing
        )


toString : ItemSettings -> String
toString settings =
    E.encode 0 (encoder settings)
