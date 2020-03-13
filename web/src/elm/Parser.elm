module Parser exposing (parse, parseComment)

import Constants exposing (inputPrefix)
import List.Extra exposing (findIndex, splitAt)
import Maybe.Extra exposing (isJust)


indentSpace : Int
indentSpace =
    4


hasIndent : Int -> String -> Bool
hasIndent indent text =
    let
        lineinputPrefix =
            String.repeat indent inputPrefix
    in
    if indent == 0 then
        String.left 1 text /= " "

    else
        String.startsWith lineinputPrefix text
            && (String.slice (indent * indentSpace) (indent * indentSpace + 1) text /= " ")


parseComment : String -> List ( String, String )
parseComment text =
    String.lines text
        |> List.filter
            (\x ->
                let
                    str =
                        x |> String.trim
                in
                not (String.isEmpty str)
                    && String.startsWith "#" str
            )
        |> List.map
            (\x ->
                let
                    tokens =
                        x
                            |> String.replace "#" ""
                            |> String.trim
                            |> String.split ":"
                in
                case tokens of
                    [ xx, xxx ] ->
                        Just ( xx, String.trim xxx )

                    _ ->
                        Nothing
            )
        |> List.filter
            (\x ->
                isJust x
            )
        |> List.map
            (\x ->
                x |> Maybe.withDefault ( "", "" )
            )


parse : Int -> String -> ( List String, List String )
parse indent text =
    let
        line =
            String.lines text
                |> List.filter
                    (\x ->
                        let
                            str =
                                x |> String.trim
                        in
                        not (String.isEmpty str)
                    )

        tail =
            List.tail line
    in
    case tail of
        Just t ->
            case
                t
                    |> findIndex (hasIndent indent)
            of
                Just xs ->
                    splitAt (xs + 1) line

                Nothing ->
                    ( line, [] )

        Nothing ->
            ( [], [] )
