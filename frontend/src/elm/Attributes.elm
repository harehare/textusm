module Attributes exposing (dataTest)

import Html.Styled as Html
import Html.Styled.Attributes as Attrs


dataTest : String -> Html.Attribute msg
dataTest name =
    Attrs.attribute "data-test" name
