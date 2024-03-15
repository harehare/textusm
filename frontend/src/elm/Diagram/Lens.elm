module Diagram.Lens exposing (text)

import Diagram.Types exposing (Model)
import Monocle.Lens exposing (Lens)
import Types.Text exposing (Text)


text : Lens Model Text
text =
    Lens .text (\b a -> { a | text = b })
