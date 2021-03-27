module GraphQL.RequestError exposing (RequestError(..), fromString, toError, toMessage)

import Graphql.Http exposing (Error, HttpError(..), RawError(..))


type RequestError
    = NotFound
    | Forbidden
    | NoAuthorization
    | DecryptionFailed
    | EncryptionFailed
    | Unknown
    | Http HttpError


fromString : String -> RequestError
fromString s =
    case s of
        "RepositoryError: NotFound" ->
            NotFound

        "ServiceError: Forbidden" ->
            Forbidden

        "ServiceError: NoAuthorization" ->
            NoAuthorization

        "ServiceError: DecryptionFailed" ->
            DecryptionFailed

        "ServiceError: EncryptionFailed" ->
            EncryptionFailed

        _ ->
            Unknown


toMessage : RequestError -> String
toMessage e =
    case e of
        NotFound ->
            "Not found"

        Forbidden ->
            "Not authorized"

        NoAuthorization ->
            "Not authorized"

        DecryptionFailed ->
            "Internal server error has occurred"

        EncryptionFailed ->
            "Internal server error has occurred"

        Unknown ->
            "Unknown error has occurred"

        Http httpError ->
            case httpError of
                BadUrl url ->
                    url ++ "is not valid URL"

                Timeout ->
                    "Request timeout"

                NetworkError ->
                    "Network error has occurred"

                BadStatus _ _ ->
                    "Bad request"

                BadPayload _ ->
                    "Bad request"


toError : Error a -> RequestError
toError e =
    case e of
        GraphqlError _ errors ->
            case List.head errors of
                Just h ->
                    fromString h.message

                Nothing ->
                    Unknown

        HttpError httpError ->
            Http httpError
