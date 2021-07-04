module Api.RequestError exposing (RequestError(..), fromString, toError, toMessage)

import Graphql.Http exposing (Error, HttpError(..), RawError(..))
import Message exposing (Message)


type RequestError
    = NotFound
    | Forbidden
    | NoAuthorization
    | DecryptionFailed
    | EncryptionFailed
    | URLExpired
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

        "ServiceError: URLExpired" ->
            URLExpired

        _ ->
            Unknown


toMessage : RequestError -> Message
toMessage e =
    case e of
        NotFound ->
            Message.messageNotFound

        Forbidden ->
            Message.messageNotAuthorized

        NoAuthorization ->
            Message.messageNotAuthorized

        DecryptionFailed ->
            Message.messageInternalServerError

        EncryptionFailed ->
            Message.messageInternalServerError

        URLExpired ->
            Message.messageUrlExpired

        Unknown ->
            Message.messageUnknown

        Http httpError ->
            case httpError of
                BadUrl _ ->
                    Message.messageInvalidUrl

                Timeout ->
                    Message.messageTimeout

                NetworkError ->
                    Message.messageNetworkError

                BadStatus _ _ ->
                    Message.messageBadRequest

                BadPayload _ ->
                    Message.messageBadRequest


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
