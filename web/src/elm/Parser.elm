module Parser exposing (parseComment, parseLines)

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
            && (String.slice (indent * indentSpace + 1) (indent * indentSpace + 2) text /= " ")


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
                            if indent > 1 && List.length (Tuple.first itemPair |> List.filter (\i -> not (i |> String.trim |> String.startsWith "#"))) > 1 then
                                Err text

                            else
                                Ok itemPair
                    in
                    result

                Nothing ->
                    Ok ( line, [] )

        Nothing ->
            Ok ( [], [] )
