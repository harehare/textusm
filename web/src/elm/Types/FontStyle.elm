module Types.FontStyle exposing (FontStyle(..), apply)


type FontStyle
    = Bold
    | Italic
    | Strikethrough


apply : FontStyle -> String -> String
apply fontStyle text =
    let
        rawText =
            if String.startsWith "md:" text then
                String.dropLeft 3 text
                    |> String.replace "*" ""
                    |> String.replace "~" ""

            else
                text
    in
    case fontStyle of
        Bold ->
            "md:**" ++ rawText ++ "**"

        Italic ->
            "md:*" ++ rawText ++ "*"

        Strikethrough ->
            "md:~~" ++ rawText ++ "~~"
