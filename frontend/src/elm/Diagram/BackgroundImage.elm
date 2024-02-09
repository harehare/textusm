module Diagram.BackgroundImage exposing (BackgroundImage, fromString, toString)

import DataUrl exposing (DataUrl)
import Url exposing (Url)


type BackgroundImage
    = BackgroundImageUrl Url
    | BackgroundImageDataUrl DataUrl


fromString : String -> Maybe BackgroundImage
fromString s =
    if String.startsWith "http" <| String.trim s then
        Url.fromString s |> Maybe.map BackgroundImageUrl

    else if String.startsWith "data:image" <| String.trim s then
        DataUrl.fromString s |> Maybe.map BackgroundImageDataUrl

    else
        Nothing


toString : BackgroundImage -> String
toString image =
    case image of
        BackgroundImageUrl u ->
            Url.toString u

        BackgroundImageDataUrl u ->
            DataUrl.toString u
