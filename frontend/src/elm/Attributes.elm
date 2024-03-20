module Attributes exposing (dataTestId)

import Html.Styled as Html
import Html.Styled.Attributes as Attrs


dataTestId : String -> Html.Attribute msg
dataTestId name =
    Attrs.attribute "data-test-id" name
