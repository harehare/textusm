module Types.Item.Parser exposing (Parsed(..), commentLine, image, imageData, markdown, parse, plainText, settings)

import Constants
import DataUrl
import Parser
    exposing
        ( (|.)
        , (|=)
        , Parser
        , chompUntilEndOr
        , end
        , getChompedString
        , getCol
        , map
        , oneOf
        , spaces
        , succeed
        , symbol
        )
import Types.Item.Constants as ItemConstants
import Types.Item.Settings as Settings exposing (Settings)
import Types.Item.Value exposing (Value(..))
import Types.Text as Text
import Url


type alias Comment =
    Maybe String


type Parsed
    = Parsed Value Comment (Maybe Settings)


parse : Parser Parsed
parse =
    succeed Parsed
        |= oneOf
            [ markdown
            , image
            , imageData
            , commentLine
            , plainText
            ]
        |= oneOf
            [ map Just comment
            , map (\_ -> Nothing) spaces
            ]
        |= oneOf
            [ settings
            , map (\_ -> Nothing) spaces
            ]
        |. end


indent : Parser ( Int, Int )
indent =
    succeed (\indent_ -> ( indent_ // Constants.indentSpace, modBy Constants.indentSpace (indent_ - 1) ))
        |. spaces
        |= getCol


item : Parser String
item =
    succeed identity
        |. oneOf
            [ chompUntilEndOr ItemConstants.commentPrefix
            , chompUntilEndOr ItemConstants.settingsPrefix
            , chompUntilEndOr ItemConstants.legacySettingsPrefix
            ]
        |> getChompedString


markdown : Parser Value
markdown =
    succeed (\( indent_, spaces_ ) text -> Markdown indent_ (Text.fromString (String.repeat spaces_ " " ++ text)))
        |. spaces
        |= indent
        |. symbol ItemConstants.markdownPrefix
        |= item


image : Parser Value
image =
    succeed
        (\( indent_, spaces_ ) text ->
            case Url.fromString text of
                Just u ->
                    Image indent_ u

                Nothing ->
                    PlainText indent_ <| Text.fromString (String.repeat spaces_ " " ++ text)
        )
        |. spaces
        |= indent
        |. symbol ItemConstants.imagePrefix
        |= item


commentLine : Parser Value
commentLine =
    succeed
        (\( indent_, spaces_ ) text ->
            Comment indent_ (Text.fromString (String.repeat spaces_ " " ++ text))
        )
        |. spaces
        |= indent
        |= comment


imageData : Parser Value
imageData =
    succeed
        (\( indent_, spaces_ ) text ->
            case DataUrl.fromString (ItemConstants.imageDataPrefix ++ text) of
                Just u ->
                    ImageData indent_ <| u

                Nothing ->
                    PlainText indent_ <| Text.fromString (String.repeat spaces_ " " ++ text)
        )
        |. spaces
        |= indent
        |. symbol ItemConstants.imageDataPrefix
        |= item


plainText : Parser Value
plainText =
    succeed
        (\( indent_, spaces_ ) text ->
            PlainText indent_ (Text.fromString (String.repeat spaces_ " " ++ text))
        )
        |. spaces
        |= indent
        |= item


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
            [ chompUntilEndOr ItemConstants.settingsPrefix
            , chompUntilEndOr ItemConstants.legacySettingsPrefix
            ]
        |> getChompedString
        |> map (String.dropLeft 1)
