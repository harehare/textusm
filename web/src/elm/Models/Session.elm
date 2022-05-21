module Models.Session exposing
    ( Session(..)
    , User
    , decoder
    , getAccessToken
    , getIdToken
    , getUser
    , guest
    , isGithubUser
    , isGuest
    , isSignedIn
    , signIn
    , updateAccessToken
    , updateIdToken
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Models.IdToken as IdToken exposing (IdToken)
import Models.LoginProvider as LoginProvider exposing (LoginProvider)


type Session
    = SignedIn User
    | Guest


type alias User =
    { displayName : String
    , email : String
    , photoURL : String
    , idToken : String
    , id : String
    , loginProvider : LoginProvider
    }


decoder : D.Decoder User
decoder =
    D.succeed User
        |> required "displayName" D.string
        |> required "email" D.string
        |> required "photoURL" D.string
        |> required "idToken" D.string
        |> required "id" D.string
        |> required "loginProvider" LoginProvider.decoder


getAccessToken : Session -> Maybe String
getAccessToken session =
    case getUser session |> Maybe.map .loginProvider of
        Just (LoginProvider.Github (Just a)) ->
            Just a

        _ ->
            Nothing


getIdToken : Session -> Maybe IdToken
getIdToken session =
    case session of
        SignedIn user ->
            Just <| IdToken.fromString user.idToken

        Guest ->
            Nothing


getUser : Session -> Maybe User
getUser session =
    case session of
        SignedIn u ->
            Just u

        Guest ->
            Nothing


guest : Session
guest =
    Guest


isGithubUser : Session -> Bool
isGithubUser session =
    case session of
        SignedIn user ->
            LoginProvider.isGithubLogin user.loginProvider

        Guest ->
            False


isGuest : Session -> Bool
isGuest session =
    case session of
        SignedIn _ ->
            False

        Guest ->
            True


isSignedIn : Session -> Bool
isSignedIn session =
    case session of
        SignedIn _ ->
            True

        Guest ->
            False


signIn : User -> Session
signIn user =
    SignedIn user


updateAccessToken : Session -> String -> Session
updateAccessToken session accessToken =
    case session of
        SignedIn user ->
            case user.loginProvider of
                LoginProvider.Github _ ->
                    let
                        privider : LoginProvider
                        privider =
                            LoginProvider.Github (Just accessToken)
                    in
                    SignedIn { user | loginProvider = privider }

                _ ->
                    session

        Guest ->
            Guest


updateIdToken : Session -> IdToken -> Session
updateIdToken session idToken =
    case session of
        SignedIn user ->
            SignedIn { user | idToken = IdToken.unwrap idToken }

        Guest ->
            Guest
