module Data.Jwt exposing (Jwt, decoder, fromString)

import Base64
import Json.Decode as D


type alias Jwt =
    { jti : String
    , sub : String
    , iat : Int
    , exp : Int
    , pas : Bool
    }


fromString : String -> Result String Jwt
fromString text =
    Base64.decode text
        |> Result.andThen
            (\jwtText ->
                case String.split "." jwtText of
                    [ _, v, _ ] ->
                        D.decodeString decoder v
                            |> Result.mapError D.errorToString

                    _ ->
                        Err "invalid jwt"
            )


decoder : D.Decoder Jwt
decoder =
    D.map5 Jwt
        (D.field "jit" D.string)
        (D.field "sub" D.string)
        (D.field "iat" D.int)
        (D.field "exp" D.int)
        (D.field "pas" D.bool)
