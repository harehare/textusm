module Events.Wheel exposing (Event, onWheel)

import Events
import Html.Styled as Html
import Html.Styled.Events as Events
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)


type alias Event =
    { deltaY : Float
    , deltaX : Maybe Float
    , deltaZ : Maybe Float
    }


eventDecoder : D.Decoder Event
eventDecoder =
    D.succeed Event
        |> required "deltaY" D.float
        |> optional "deltaX" (D.map Just D.float) Nothing
        |> optional "deltaZ" (D.map Just D.float) Nothing


onWheel : (Event -> msg) -> Html.Attribute msg
onWheel msg =
    Events.preventDefaultOn "wheel" (D.map Events.alwaysPreventDefaultOn (D.map msg eventDecoder))
