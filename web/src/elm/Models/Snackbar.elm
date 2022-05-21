module Models.Snackbar exposing (Model, Snackbar(..))


type alias Model msg =
    { message : String
    , text : String
    , action : msg
    }


type Snackbar msg
    = Show (Model msg)
    | Hide
