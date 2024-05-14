module Types.Item.Parser exposing
    ( Parsed(..)
    , commentLine
    , image
    , imageData
    , markdown
    , parse
    , parser
    , plainText
    , settings
    )

import Constants
import DataUrl
import Parser
    exposing
        ( (|.)
        , (|=)
        , DeadEnd
        , Parser
        , backtrackable
        , chompUntil
        , chompUntilEndOr
        , chompWhile
        , end
        , getChompedString
        , getCol
        , map
        , oneOf
        , run
        , spaces
        , succeed
        , symbol
        )
import Types.Item.Constants as ItemConstants
import Types.Item.Settings as Settings exposing (Settings)
import Types.Item.Value as Value exposing (Value(..))
import Types.Text as Text
import Url


type alias Comment =
    Maybe String


type Parsed
    = Parsed Value Comment (Maybe Settings)


colon : String
colon =
    "{colon}"


parse : String -> Result (List DeadEnd) Parsed
parse text =
    text
        |> String.replace "\\:" colon
        |> String.replace (colon ++ " |") ItemConstants.settingsPrefix
        |> run parser
        |> Result.map
            (\(Parsed value_ comment_ settings_) ->
                Parsed
                    (value_
                        |> Value.map
                            (\text_ ->
                                text_
                                    |> Text.toString
                                    |> String.replace colon "\\:"
                                    |> Text.fromString
                            )
                    )
                    comment_
                    settings_
            )


parser : Parser Parsed
parser =
    oneOf
        [ backtrackable image
        , backtrackable imageData
        , backtrackable commentLine
        , backtrackable markdown
        , plainText
        ]


indent : Parser ( Int, Int )
indent =
    succeed (\indent_ -> ( max 0 (indent_ - 1) // Constants.indentSpace, modBy Constants.indentSpace (indent_ - 1) ))
        |. spaces
        |= getCol


item : Parser String
item =
    (succeed identity
        |. oneOf
            [ chompWhile (\c -> c /= '#' && c /= '|' && c /= ':')
            , chompUntil ItemConstants.settingsPrefix
            , chompUntil ItemConstants.legacySettingsPrefix
            , chompUntilEndOr "\n"
            ]
    )
        |> getChompedString


markdown : Parser Parsed
markdown =
    succeed
        (\( indent_, spaces_ ) text comment_ settings_ ->
            Parsed (Markdown indent_ (Text.fromString (String.repeat spaces_ " " ++ text))) comment_ settings_
        )
        |. spaces
        |= indent
        |. symbol ItemConstants.markdownPrefix
        |= item
        |= oneOf
            [ map Just comment
            , map (\_ -> Nothing) Parser.spaces
            ]
        |= oneOf
            [ settings
            , map (\_ -> Nothing) spaces
            ]
        |. end


image : Parser Parsed
image =
    succeed
        (\( indent_, spaces_ ) text settings_ ->
            case text |> String.trim |> Url.fromString of
                Just u ->
                    Parsed (Image indent_ u) Nothing settings_

                Nothing ->
                    Parsed (PlainText indent_ <| Text.fromString (String.repeat spaces_ " " ++ text)) Nothing settings_
        )
        |. spaces
        |= indent
        |. symbol ItemConstants.imagePrefix
        |= getChompedString
            (oneOf
                [ backtrackable <| chompUntil ItemConstants.settingsPrefix
                , backtrackable <| chompUntil ItemConstants.legacySettingsPrefix
                , backtrackable <| chompUntilEndOr "\n"
                ]
            )
        |= oneOf
            [ settings
            , map (\_ -> Nothing) spaces
            ]


commentLine : Parser Parsed
commentLine =
    succeed
        (\( indent_, _ ) text ->
            Parsed (Comment indent_ (Text.fromString text)) Nothing Nothing
        )
        |. spaces
        |= indent
        |= comment


imageData : Parser Parsed
imageData =
    succeed
        (\( indent_, spaces_ ) text settings_ ->
            case DataUrl.fromString (ItemConstants.imageDataPrefix ++ text |> String.trim) of
                Just u ->
                    Parsed (ImageData indent_ <| u) Nothing settings_

                Nothing ->
                    Parsed (PlainText indent_ <| Text.fromString (String.repeat spaces_ " " ++ text)) Nothing settings_
        )
        |. spaces
        |= indent
        |. symbol ItemConstants.imageDataPrefix
        |= getChompedString
            (oneOf
                [ backtrackable <| chompUntil ItemConstants.settingsPrefix
                , backtrackable <| chompUntil ItemConstants.legacySettingsPrefix
                , backtrackable <| chompUntilEndOr "\n"
                ]
            )
        |= oneOf
            [ settings
            , map (\_ -> Nothing) spaces
            ]


plainText : Parser Parsed
plainText =
    succeed
        (\( indent_, spaces_ ) text comment_ settings_ ->
            Parsed (PlainText indent_ (Text.fromString (String.repeat spaces_ " " ++ text))) comment_ settings_
        )
        |. spaces
        |= indent
        |= item
        |= oneOf
            [ map Just comment
            , map (\_ -> Nothing) Parser.spaces
            ]
        |= oneOf
            [ settings
            , map (\_ -> Nothing) spaces
            ]
        |. end


settings : Parser (Maybe Settings)
settings =
    succeed
        (\text ->
            text |> Settings.fromString
        )
        |. oneOf
            [ symbol ItemConstants.settingsPrefix
            , symbol ItemConstants.legacySettingsPrefix
            ]
        |= (chompUntilEndOr "\n" |> getChompedString)


comment : Parser String
comment =
    symbol ItemConstants.commentPrefix
        |. oneOf
            [ backtrackable <| chompUntil ItemConstants.settingsPrefix
            , backtrackable <| chompUntil ItemConstants.legacySettingsPrefix
            , backtrackable <| chompUntilEndOr "\n"
            ]
        |> getChompedString
        |> map (String.dropLeft 1)
