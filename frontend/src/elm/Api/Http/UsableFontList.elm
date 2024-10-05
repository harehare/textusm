module Api.Http.UsableFontList exposing (usableFontList)

import Api.Http.Request as HttpRequest
import Api.RequestError as RequestError exposing (RequestError)
import Dict
import Json.Decode as D
import Message exposing (Lang)
import Platform exposing (Task)
import Task
import Types.Font as Font exposing (Font)


usableFontList : Lang -> Task RequestError (List Font)
usableFontList lang =
    HttpRequest.jsonResolver (D.dict (D.list D.string))
        |> HttpRequest.getFile
            { url = "/"
            , path = [ "fontlist.json" ]
            , query = []
            , headers = []
            }
        |> Task.map
            (\fontlist ->
                let
                    allFontList : List String
                    allFontList =
                        Dict.get "all" fontlist |> Maybe.withDefault []

                    langFontList : List String
                    langFontList =
                        Dict.get (Message.toLangString lang) fontlist |> Maybe.withDefault []
                in
                List.concat [ allFontList, langFontList ] |> List.map Font.googleFont
            )
        |> Task.mapError RequestError.fromHttpError
