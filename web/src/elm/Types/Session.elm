module Types.Session exposing
    ( Session
    , User
    , decoder
    , getIdToken
    , getUser
    , guest
    , isGuest
    , isSignedIn
    , signIn
    , updateIdToken
    , isGithubUser
    , isGoogleUser
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Types.IdToken as IdToken exposing (IdToken)
import Types.LoginProvider as LoginProvider exposing (LoginProvider)


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


isGuest : Session -> Bool
isGuest session =
    case session of
        SignedIn _ ->
            False

        Guest ->
            True


isGithubUser: Session -> Bool
isGithubUser session =
    case session of
        SignedIn user ->
            LoginProvider.isGithubLogin user.loginProvider

        Guest ->
            False


isGoogleUser: Session -> Bool
isGoogleUser session =
    case session of
        SignedIn user ->
            LoginProvider.isGoogleLogin user.loginProvider

        Guest ->
            False


isSignedIn : Session -> Bool
isSignedIn session =
    case session of
        SignedIn _ ->
            True

        Guest ->
            False


guest : Session
guest =
    Guest


signIn : User -> Session
signIn user =
    SignedIn user


getUser : Session -> Maybe User
getUser session =
    case session of
        SignedIn u ->
            Just u

        Guest ->
            Nothing


getIdToken : Session -> Maybe IdToken
getIdToken session =
    case session of
        SignedIn user ->
            Just <| IdToken.fromString user.idToken

        Guest ->
            Nothing


updateIdToken : Session -> IdToken -> Session
updateIdToken session idToken =
    case session of
        SignedIn user ->
            SignedIn { user | idToken = IdToken.unwrap idToken }

        Guest ->
            Guest


decoder : D.Decoder User
decoder =
    D.succeed User
        |> required "displayName" D.string
        |> required "email" D.string
        |> required "photoURL" D.string
        |> required "idToken" D.string
        |> required "id" D.string
        |> required "loginProvider" LoginProvider.decoder
