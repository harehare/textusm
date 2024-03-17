module Api.Http.UsableFontList exposing (usableFontList)

import Api.Http.Request as HttpRequest
import Api.RequestError as RequestError exposing (RequestError)
import Env
import Json.Decode as D
import Message exposing (Lang)
import Platform exposing (Task)
import Task
import Types.Font as Font exposing (Font)
import Url.Builder


usableFontList : Lang -> Task RequestError (List Font)
usableFontList lang =
    HttpRequest.jsonResolver (D.list D.string)
        |> HttpRequest.get
            { url = Env.apiRoot
            , path = [ "api", "v1", "settings", "usable-font-list" ]
            , query = [ Url.Builder.string "lang" (Message.toLangString lang) ]
            , headers = []
            }
        |> Task.map (List.map Font.googleFont)
        |> Task.mapError RequestError.fromHttpError
