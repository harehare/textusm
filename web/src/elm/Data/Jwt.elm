module Data.Jwt exposing (Jwt, decoder, fromString)

import Base64
import Json.Decode as D
import UrlBase64


type alias Jwt =
    { exp : Int
    , iat : Int
    , jti : String
    , sub : String
    , pas : Bool
    }


fromString : String -> Maybe Jwt
fromString text =
    case String.split "." text of
        [ _, v, _ ] ->
            UrlBase64.decode Base64.decode v
                |> Result.andThen (\j -> D.decodeString decoder j |> Result.mapError D.errorToString)
                |> Result.toMaybe

        _ ->
            Nothing


decoder : D.Decoder Jwt
decoder =
    D.map5 Jwt
        (D.field "exp" D.int)
        (D.field "iat" D.int)
        (D.field "jti" D.string)
        (D.field "sub" D.string)
        (D.field "pas" D.bool)
