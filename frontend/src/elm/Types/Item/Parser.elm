module Types.Item.Parser exposing
    ( Comment
    , Parsed(..)
    , commentLine
    , image
    , imageData
    , markdown
    , parse
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


pipe : String
pipe =
    "{pipe}"


parse : String -> Result (List DeadEnd) Parsed
parse text =
    text
        |> String.replace "\\:" colon
        |> String.replace "\\|" pipe
        |> String.replace (colon ++ " |") Constants.settingsPrefix
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
                                    |> String.replace pipe "\\|"
                                    |> Text.fromString
                            )
                    )
                    comment_
                    settings_
            )


parser : Parser Parsed
parser =
    oneOf
        [ image
        , imageData
        , commentLine
        , markdown
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
            , chompUntil Constants.settingsPrefix
            , chompUntil Constants.legacySettingsPrefix
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
        |. backtrackable spaces
        |= indent
        |. symbol Constants.markdownPrefix
        |= item
        |= oneOf
            [ map Just comment
            , map (\_ -> Nothing) spaces
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
        |. backtrackable spaces
        |= indent
        |. symbol Constants.imagePrefix
        |= getChompedString
            (oneOf
                [ backtrackable <| chompUntil Constants.settingsPrefix
                , backtrackable <| chompUntil Constants.legacySettingsPrefix
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
        |. backtrackable spaces
        |= indent
        |= comment


imageData : Parser Parsed
imageData =
    succeed
        (\( indent_, spaces_ ) text settings_ ->
            case DataUrl.fromString (Constants.imageDataPrefix ++ text |> String.trim) of
                Just u ->
                    Parsed (ImageData indent_ <| u) Nothing settings_

                Nothing ->
                    Parsed (PlainText indent_ <| Text.fromString (String.repeat spaces_ " " ++ text)) Nothing settings_
        )
        |. backtrackable spaces
        |= indent
        |. symbol Constants.imageDataPrefix
        |= getChompedString
            (oneOf
                [ backtrackable <| chompUntil Constants.settingsPrefix
                , backtrackable <| chompUntil Constants.legacySettingsPrefix
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
            , map (\_ -> Nothing) spaces
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
            [ symbol Constants.settingsPrefix
            , symbol Constants.legacySettingsPrefix
            ]
        |= (chompUntilEndOr "\n" |> getChompedString)


comment : Parser String
comment =
    symbol Constants.commentPrefix
        |. oneOf
            [ backtrackable <| chompUntil Constants.settingsPrefix
            , backtrackable <| chompUntil Constants.legacySettingsPrefix
            , backtrackable <| chompUntilEndOr "\n"
            ]
        |> getChompedString
        |> map (String.dropLeft 1)
