module Parser exposing (parseLines)

import Constants exposing (inputPrefix)
import List.Extra exposing (findIndex, splitAt)


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
            && (String.slice (indent * indentSpace + 1) (indent * indentSpace + 2) text /= " ")


parseLines : Int -> String -> Result String ( List String, List String )
parseLines indent text =
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
                            && not (String.startsWith "#" str)
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
                    let
                        itemPair =
                            splitAt (xs + 1) line

                        result =
                            if indent > 1 && List.length (Tuple.first itemPair) > 1 then
                                Err text

                            else
                                Ok itemPair
                    in
                    result

                Nothing ->
                    Ok ( line, [] )

        Nothing ->
            Ok ( [], [] )
