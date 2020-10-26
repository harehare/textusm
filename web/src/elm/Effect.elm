module Effect exposing (focus)

import Browser.Dom as Dom
import Return exposing (Return)
import Task


focus : msg -> String -> model -> Return msg model
focus msg id model =
    Return.return model
        (Task.attempt (\_ -> msg)
            (Dom.focus id)
        )
