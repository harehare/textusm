module Models.Jwt exposing (Jwt, fromString)

import Base64
import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import UrlBase64


type alias Jwt =
    { exp : Int
    , iat : Int
    , jti : String
    , sub : String
    , checkPassword : Bool
    , checkEmail : Bool
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
    D.succeed Jwt
        |> required "exp" D.int
        |> required "iat" D.int
        |> required "jti" D.string
        |> required "sub" D.string
        |> required "check_password" D.bool
        |> required "check_email" D.bool
