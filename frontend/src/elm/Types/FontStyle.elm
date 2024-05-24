module Types.FontStyle exposing (FontStyle(..), apply)

import Constants


type FontStyle
    = Bold
    | Italic
    | Strikethrough


apply : FontStyle -> String -> String
apply fontStyle text =
    let
        rawText : String
        rawText =
            if String.startsWith Constants.markdownPrefix text then
                String.dropLeft 3 text
                    |> String.replace "*" ""
                    |> String.replace "~" ""

            else
                text
    in
    case fontStyle of
        Bold ->
            Constants.markdownPrefix ++ "**" ++ rawText ++ "**"

        Italic ->
            Constants.markdownPrefix ++ "*" ++ rawText ++ "*"

        Strikethrough ->
            Constants.markdownPrefix ++ "~~" ++ rawText ++ "~~"
