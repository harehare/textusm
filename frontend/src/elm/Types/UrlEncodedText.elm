module Types.UrlEncodedText exposing (UrlEncodedText, fromString, toString, toText)

import Types.Text as Text exposing (Text)
import Url


type UrlEncodedText
    = UrlEncodedText Text


fromString : String -> Maybe UrlEncodedText
fromString text =
    text
        |> Url.percentDecode
        |> Maybe.map Text.fromString
        |> Maybe.map UrlEncodedText


toString : UrlEncodedText -> String
toString (UrlEncodedText text) =
    text
        |> Text.toString
        |> Url.percentEncode


toText : UrlEncodedText -> Text
toText (UrlEncodedText text) =
    text
        |> Text.map (String.replace "\u{000D}\n" "\n")
        |> Text.map (String.replace "\n" "\n")
        |> Text.map (String.replace "+" " ")
