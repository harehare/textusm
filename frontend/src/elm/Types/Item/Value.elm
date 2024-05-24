module Types.Item.Value exposing
    ( Value(..)
    , empty
    , getIndent
    , isComment
    , isImage
    , isImageData
    , isMarkdown
    , map
    , toDisplayString
    , toFullString
    , toString
    , toTrimedString
    , update
    )

import Constants
import DataUrl exposing (DataUrl)
import Types.Text as Text exposing (Text)
import Url exposing (Url)


type Value
    = Markdown Int Text
    | Image Int Url
    | ImageData Int DataUrl
    | PlainText Int Text
    | Comment Int Text


map : (Text -> Text) -> Value -> Value
map f value =
    case value of
        Markdown indent text ->
            Markdown indent (f text)

        PlainText indent text ->
            PlainText indent (f text)

        _ ->
            value


isImage : Value -> Bool
isImage value =
    case value of
        Image _ _ ->
            True

        _ ->
            False


isMarkdown : Value -> Bool
isMarkdown value =
    case value of
        Markdown _ _ ->
            True

        _ ->
            False


isComment : Value -> Bool
isComment value =
    case value of
        Comment _ _ ->
            True

        _ ->
            False


isImageData : Value -> Bool
isImageData value =
    case value of
        ImageData _ _ ->
            True

        _ ->
            False


empty : Value
empty =
    PlainText 0 Text.empty


space : Int -> String
space indent =
    String.repeat indent Constants.inputPrefix


update : Value -> String -> Value
update value text =
    case value of
        Markdown indent _ ->
            let
                rawText : String
                rawText =
                    if String.startsWith Constants.markdownPrefix text then
                        String.dropLeft 3 text

                    else
                        text
            in
            Markdown indent <| Text.fromString rawText

        Image indent _ ->
            case Url.fromString text of
                Just u ->
                    Image indent u

                Nothing ->
                    PlainText indent <| Text.fromString text

        ImageData indent _ ->
            case DataUrl.fromString text of
                Just u ->
                    ImageData indent <| u

                Nothing ->
                    PlainText indent <| Text.fromString text

        Comment indent _ ->
            Comment indent <| Text.fromString text

        PlainText indent _ ->
            PlainText indent <| Text.fromString text


toFullString : Value -> String
toFullString value =
    case value of
        Markdown indent text ->
            space indent ++ Constants.markdownPrefix ++ Text.toString text

        Image indent text ->
            space indent ++ Constants.imagePrefix ++ Url.toString text

        ImageData indent text ->
            space indent ++ Constants.imageDataPrefix ++ DataUrl.toString text

        Comment indent text ->
            space indent ++ Constants.commentPrefix ++ Text.toString text

        PlainText indent text ->
            space indent ++ Text.toString text


toTrimedString : Value -> String
toTrimedString value =
    case value of
        Markdown _ text ->
            Constants.markdownPrefix ++ (Text.toString text |> String.trim)

        Image _ text ->
            Constants.imagePrefix ++ Url.toString text

        ImageData _ text ->
            Constants.imageDataPrefix ++ DataUrl.toString text

        Comment _ text ->
            Constants.commentPrefix ++ Text.toString text

        PlainText _ text ->
            Text.toString text


toString : Value -> String
toString value =
    case value of
        Markdown _ text ->
            Text.toString text |> String.replace "\\n" "\n"

        Image _ text ->
            Url.toString text

        ImageData _ text ->
            DataUrl.toString text

        Comment _ text ->
            Text.toString text

        PlainText _ text ->
            Text.toString text


toDisplayString : Value -> String
toDisplayString value =
    toString value |> String.replace "\\:" ":"


getIndent : Value -> Int
getIndent value =
    case value of
        Markdown i _ ->
            i

        Image i _ ->
            i

        ImageData i _ ->
            i

        Comment i _ ->
            i

        PlainText i _ ->
            i
