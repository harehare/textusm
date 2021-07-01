module Types.IpAddress exposing (IpAddress, fromString, localhost, toString)


type IpAddress
    = IpAddress Int Int Int Int (Maybe Int)


localhost : IpAddress
localhost =
    IpAddress 127 0 0 1 Nothing


fromString : String -> Maybe IpAddress
fromString s =
    case ipParts s of
        ( [ Just p1, Just p2, Just p3, Just p4 ], Just cidr ) ->
            Just <| IpAddress p1 p2 p3 p4 (Just cidr)

        ( [ Just p1, Just p2, Just p3, Just p4 ], Nothing ) ->
            Just <| IpAddress p1 p2 p3 p4 Nothing

        _ ->
            Nothing


toString : IpAddress -> String
toString ip =
    case ip of
        IpAddress p1 p2 p3 p4 (Just cidr) ->
            String.fromInt p1 ++ "." ++ String.fromInt p2 ++ "." ++ String.fromInt p3 ++ "." ++ String.fromInt p4 ++ "/" ++ String.fromInt cidr

        IpAddress p1 p2 p3 p4 Nothing ->
            String.fromInt p1 ++ "." ++ String.fromInt p2 ++ "." ++ String.fromInt p3 ++ "." ++ String.fromInt p4


ipParts : String -> ( List (Maybe Int), Maybe Int )
ipParts ipString =
    let
        ipParse ip =
            String.split "." ip
                |> List.map String.toInt
                |> List.map
                    (\i ->
                        Maybe.andThen
                            (\x ->
                                if x > 255 || x < 0 then
                                    Nothing

                                else
                                    Just x
                            )
                            i
                    )
    in
    case String.split "/" ipString of
        [ ip, cidr ] ->
            ( ipParse ip
            , cidr
                |> String.toInt
                |> Maybe.andThen
                    (\x ->
                        if x > 32 || x < 0 then
                            Nothing

                        else
                            Just x
                    )
            )

        _ ->
            ( ipParse ipString, Nothing )
