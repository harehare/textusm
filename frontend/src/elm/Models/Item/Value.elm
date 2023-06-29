module Models.Item.Value exposing
    ( Value
    , empty
    , fromString
    , getIndent
    , isComment
    , isImage
    , isImageData
    , isMarkdown
    , toFullString
    , toString
    , update
    )

import Constants
import DataUrl exposing (DataUrl)
import List.Extra as ListEx
import Models.Text as Text exposing (Text)
import Url exposing (Url)


type Value
    = Markdown Int Text
    | Image Int Url
    | ImageData Int DataUrl
    | PlainText Int Text
    | Comment Int Text


markdownPrefix : String
markdownPrefix =
    "md:"


imagePrefix : String
imagePrefix =
    "image:"


imageDataPrefix : String
imageDataPrefix =
    "data:image/"


commentPrefix : String
commentPrefix =
    "#"


hasPrefix : String -> String -> Bool
hasPrefix text p =
    text |> String.trim |> String.toLower |> String.startsWith p


hasImagePrefix : String -> Bool
hasImagePrefix text =
    hasPrefix text imagePrefix


hasImageDataPrefix : String -> Bool
hasImageDataPrefix text =
    hasPrefix text imageDataPrefix


hasMarkdownPrefix : String -> Bool
hasMarkdownPrefix text =
    hasPrefix text markdownPrefix


hasCommentPrefix : String -> Bool
hasCommentPrefix text =
    hasPrefix text commentPrefix


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


dropPrefix : String -> String -> String
dropPrefix p text =
    String.dropLeft (String.length p) text


space : Int -> String
space indent =
    String.repeat indent Constants.inputPrefix


update : Value -> String -> Value
update value text =
    case value of
        Markdown indent _ ->
            Markdown indent <| Text.fromString text

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


fromString : String -> Value
fromString text =
    let
        indent : Int
        indent =
            (getSpacePrefix text |> String.length) // Constants.indentSpace
    in
    if hasMarkdownPrefix text then
        Markdown indent <| Text.fromString <| String.replace "\n" "\\n" <| dropPrefix markdownPrefix <| String.trim text

    else if hasImagePrefix text then
        let
            url : String
            url =
                String.trim <| dropPrefix imagePrefix <| String.trim text
        in
        case Url.fromString url of
            Just u ->
                Image indent u

            Nothing ->
                PlainText indent <| Text.fromString <| String.trim text

    else if hasImageDataPrefix text then
        let
            url : String
            url =
                String.trim <| dropPrefix imageDataPrefix <| String.trim text
        in
        case DataUrl.fromString url of
            Just u ->
                ImageData indent u

            Nothing ->
                PlainText indent <| Text.fromString <| String.trim text

    else if hasCommentPrefix text then
        Comment indent <| Text.fromString <| dropPrefix commentPrefix <| String.trim text

    else
        PlainText indent <| Text.fromString <| String.trim text


toFullString : Value -> String
toFullString value =
    case value of
        Markdown indent text ->
            space indent ++ markdownPrefix ++ Text.toString text

        Image indent text ->
            space indent ++ imagePrefix ++ Url.toString text

        ImageData indent text ->
            space indent ++ imageDataPrefix ++ DataUrl.toString text

        Comment indent text ->
            space indent ++ commentPrefix ++ Text.toString text

        PlainText indent text ->
            space indent ++ Text.toString text


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


getSpacePrefix : String -> String
getSpacePrefix text =
    (text
        |> String.toList
        |> ListEx.takeWhile (\c -> c == ' ')
        |> List.length
        |> String.repeat
    )
        " "
