module Models.Item.Settings exposing
    ( Settings
    , decoder
    , fromString
    , getBackgroundColor
    , getFontSize
    , getForegroundColor
    , getOffset
    , getOffsetSize
    , new
    , resetOffset
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
import Models.Color as Color exposing (Color)
import Models.FontSize as FontSize exposing (FontSize)
import Models.Position as Position exposing (Position)
import Models.Size as Size exposing (Size)


type Settings
    = Settings SettingsValue


type alias SettingsValue =
    { backgroundColor : Maybe Color
    , foregroundColor : Maybe Color
    , fontSize : FontSize
    , offset : Position
    , offsetSize : Maybe Size
    }


resetOffset : Settings -> Settings
resetOffset (Settings settings) =
    Settings { settings | offset = Position.zero, offsetSize = Nothing }


fromString : String -> Maybe Settings
fromString text =
    let
        itemSettings : Result D.Error Settings
        itemSettings =
            D.decodeString decoder text

        legacyItemStrings : Result D.Error Settings
        legacyItemStrings =
            D.decodeString legacyDecoder text
    in
    case ( itemSettings, legacyItemStrings ) of
        ( Ok s1, Ok s2 ) ->
            Just <|
                Settings <|
                    { backgroundColor =
                        case ( getBackgroundColor s1, getBackgroundColor s2 ) of
                            ( Just b, _ ) ->
                                Just b

                            ( _, Just b ) ->
                                Just b

                            _ ->
                                Nothing
                    , foregroundColor =
                        case ( getForegroundColor s1, getForegroundColor s2 ) of
                            ( Just f, _ ) ->
                                Just f

                            ( _, Just f ) ->
                                Just f

                            _ ->
                                Nothing
                    , fontSize =
                        if (getFontSize s1 |> FontSize.toInt) /= (FontSize.default |> FontSize.toInt) then
                            getFontSize s1

                        else
                            getFontSize s2
                    , offset =
                        if getOffset s1 /= Position.zero then
                            getOffset s1

                        else
                            getOffset s2
                    , offsetSize =
                        case ( getOffsetSize s1, getOffsetSize s2 ) of
                            ( Just s, _ ) ->
                                Just s

                            ( _, Just s ) ->
                                Just s

                            _ ->
                                Nothing
                    }

        _ ->
            Nothing


legacyDecoder : D.Decoder Settings
legacyDecoder =
    D.map Settings
        (D.succeed
            SettingsValue
            |> optional "b" (D.map Just Color.decoder) Nothing
            |> optional "f" (D.map Just Color.decoder) Nothing
            |> optional "s" FontSize.decoder FontSize.default
            |> optional "o" Position.decoder Position.zero
            |> optional "os" (D.map Just Size.decoder) Nothing
        )


decoder : D.Decoder Settings
decoder =
    D.map Settings
        (D.succeed
            SettingsValue
            |> optional "bg" (D.map Just Color.decoder) Nothing
            |> optional "fg" (D.map Just Color.decoder) Nothing
            |> optional "font_size" FontSize.decoder FontSize.default
            |> optional "pos" Position.decoder Position.zero
            |> optional "size" (D.map Just Size.decoder) Nothing
        )


getBackgroundColor : Settings -> Maybe Color
getBackgroundColor (Settings settings) =
    settings.backgroundColor


getFontSize : Settings -> FontSize
getFontSize (Settings settings) =
    settings.fontSize


getForegroundColor : Settings -> Maybe Color
getForegroundColor (Settings settings) =
    settings.foregroundColor


getOffset : Settings -> Position
getOffset (Settings settings) =
    settings.offset


getOffsetSize : Settings -> Maybe Size
getOffsetSize (Settings settings) =
    settings.offsetSize


new : Settings
new =
    Settings
        { backgroundColor = Nothing
        , foregroundColor = Nothing
        , fontSize = FontSize.default
        , offset = Position.zero
        , offsetSize = Nothing
        }


toString : Settings -> String
toString settings =
    E.encode 0 (encoder settings)


withBackgroundColor : Maybe Color -> Settings -> Settings
withBackgroundColor bg (Settings settings) =
    Settings { settings | backgroundColor = bg }


withFontSize : FontSize -> Settings -> Settings
withFontSize fontSize (Settings settings) =
    Settings { settings | fontSize = fontSize }


withForegroundColor : Maybe Color -> Settings -> Settings
withForegroundColor fg (Settings settings) =
    Settings { settings | foregroundColor = fg }


withOffset : Position -> Settings -> Settings
withOffset position (Settings settings) =
    Settings { settings | offset = position }


withOffsetSize : Maybe Size -> Settings -> Settings
withOffsetSize offsetSize (Settings settings) =
    Settings { settings | offsetSize = offsetSize }


encoder : Settings -> E.Value
encoder (Settings settings) =
    E.object <|
        (case settings.backgroundColor of
            Just color ->
                [ ( "bg", E.string <| Color.toString color ) ]

            Nothing ->
                []
        )
            ++ (case settings.foregroundColor of
                    Just color ->
                        [ ( "fg", E.string <| Color.toString color ) ]

                    Nothing ->
                        []
               )
            ++ (if settings.offset == Position.zero then
                    []

                else
                    [ ( "pos", E.list E.int [ Position.getX settings.offset, Position.getY settings.offset ] ) ]
               )
            ++ (if FontSize.unwrap settings.fontSize == FontSize.unwrap FontSize.default then
                    []

                else
                    [ ( "font_size", E.int <| FontSize.unwrap settings.fontSize ) ]
               )
            ++ (case settings.offsetSize of
                    Just size ->
                        [ ( "size", E.list E.int [ Size.getWidth size, Size.getHeight size ] ) ]

                    Nothing ->
                        []
               )
