module Models.Snackbar exposing (Model, Snackbar(..))


type Snackbar msg
    = Show (Model msg)
    | Hide


type alias Model msg =
    { message : String
    , text : String
    , action : msg
    }
