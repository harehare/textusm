module Models.ItemSettings exposing
    ( ItemSettings
    , decoder
    , fromString
    , getBackgroundColor
    , getFontSize
    , getForegroundColor
    , getOffset
    , getOffsetSize
    , legacyDecoder
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
import Models.Color as Color exposing (Color)
import Models.FontSize as FontSize exposing (FontSize)
import Models.Position as Position exposing (Position)
import Models.Size as Size exposing (Size)


type ItemSettings
    = ItemSettings Settings


fromString : String -> Maybe ItemSettings
fromString text =
    let
        itemSettings =
            D.decodeString decoder text

        legacyItemStrings =
            D.decodeString legacyDecoder text
    in
    case ( itemSettings, legacyItemStrings ) of
        ( Ok s1, Ok s2 ) ->
            Just <|
                ItemSettings <|
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


legacyDecoder : D.Decoder ItemSettings
legacyDecoder =
    D.map ItemSettings
        (D.succeed
            Settings
            |> optional "b" (D.map Just Color.decoder) Nothing
            |> optional "f" (D.map Just Color.decoder) Nothing
            |> optional "s" FontSize.decoder FontSize.default
            |> optional "o" Position.decoder Position.zero
            |> optional "os" (D.map Just Size.decoder) Nothing
        )


decoder : D.Decoder ItemSettings
decoder =
    D.map ItemSettings
        (D.succeed
            Settings
            |> optional "bg" (D.map Just Color.decoder) Nothing
            |> optional "fg" (D.map Just Color.decoder) Nothing
            |> optional "font_size" FontSize.decoder FontSize.default
            |> optional "pos" Position.decoder Position.zero
            |> optional "size" (D.map Just Size.decoder) Nothing
        )


getBackgroundColor : ItemSettings -> Maybe Color
getBackgroundColor (ItemSettings settings) =
    settings.backgroundColor


getFontSize : ItemSettings -> FontSize
getFontSize (ItemSettings settings) =
    settings.fontSize


getForegroundColor : ItemSettings -> Maybe Color
getForegroundColor (ItemSettings settings) =
    settings.foregroundColor


getOffset : ItemSettings -> Position
getOffset (ItemSettings settings) =
    settings.offset


getOffsetSize : ItemSettings -> Maybe Size
getOffsetSize (ItemSettings settings) =
    settings.offsetSize


new : ItemSettings
new =
    ItemSettings
        { backgroundColor = Nothing
        , foregroundColor = Nothing
        , fontSize = FontSize.default
        , offset = Position.zero
        , offsetSize = Nothing
        }


toString : ItemSettings -> String
toString settings =
    E.encode 0 (encoder settings)


withBackgroundColor : Maybe Color -> ItemSettings -> ItemSettings
withBackgroundColor bg (ItemSettings settings) =
    ItemSettings { settings | backgroundColor = bg }


withFontSize : FontSize -> ItemSettings -> ItemSettings
withFontSize fontSize (ItemSettings settings) =
    ItemSettings { settings | fontSize = fontSize }


withForegroundColor : Maybe Color -> ItemSettings -> ItemSettings
withForegroundColor fg (ItemSettings settings) =
    ItemSettings { settings | foregroundColor = fg }


withOffset : Position -> ItemSettings -> ItemSettings
withOffset position (ItemSettings settings) =
    ItemSettings { settings | offset = position }


withOffsetSize : Maybe Size -> ItemSettings -> ItemSettings
withOffsetSize offsetSize (ItemSettings settings) =
    ItemSettings { settings | offsetSize = offsetSize }


encoder : ItemSettings -> E.Value
encoder (ItemSettings settings) =
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


type alias Settings =
    { backgroundColor : Maybe Color
    , foregroundColor : Maybe Color
    , fontSize : FontSize
    , offset : Position
    , offsetSize : Maybe Size
    }
