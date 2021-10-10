module Models.Snackbar exposing (Snackbar(..), show)


type Snackbar msg
    = Show (Model msg)
    | Hide


type alias Model msg =
    { message : String
    , text : String
    , action : msg
    }


show : Model msg -> Snackbar msg
show model =
    Show model
