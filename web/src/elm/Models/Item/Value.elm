module Models.Item.Value exposing
    ( Value
    , empty
    , fromString
    , getIndent
    , isCooment
    , isImage
    , isImageData
    , isMarkdown
    , toFullString
    , toString
    )

import Constants
import List.Extra as ListEx
import Models.Text as Text exposing (Text)


type Value
    = Markdown Int Text
    | Image Int Text
    | ImageData Int Text
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
hasPrefix text prefix =
    text |> String.trim |> String.toLower |> String.startsWith prefix


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


isCooment : Value -> Bool
isCooment value =
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
dropPrefix prefix text =
    String.dropLeft (String.length prefix) text


space : Int -> String
space indent =
    String.repeat indent Constants.inputPrefix


fromString : String -> Value
fromString text =
    let
        indent =
            (getSpacePrefix text |> String.length) // Constants.indentSpace
    in
    if hasMarkdownPrefix text then
        Markdown indent <| Text.fromString <| dropPrefix markdownPrefix <| String.trim text

    else if hasImagePrefix text then
        Image indent <| Text.fromString <| dropPrefix imagePrefix <| String.trim text

    else if hasImageDataPrefix text then
        ImageData indent <| Text.fromString <| dropPrefix imageDataPrefix <| String.trim text

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
            space indent ++ imagePrefix ++ Text.toString text

        ImageData indent text ->
            space indent ++ imageDataPrefix ++ Text.toString text

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
            Text.toString text

        ImageData _ text ->
            Text.toString text

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
