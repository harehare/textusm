module Models.Diagram.UserPersona exposing (UserPersona, UserPersonaItem(..), from)

import Models.Item as Item exposing (Item, Items)


type alias UserPersona =
    { name : UserPersonaItem
    , whoAmI : UserPersonaItem
    , threeReasonsToUseYourProduct : UserPersonaItem
    , threeReasonsToBuyYourProduct : UserPersonaItem
    , myInterests : UserPersonaItem
    , myPersonality : UserPersonaItem
    , mySkils : UserPersonaItem
    , myDreams : UserPersonaItem
    , myRelationshipWithTechnology : UserPersonaItem
    }


type UserPersonaItem
    = UserPersonaItem Item


from : Items -> UserPersona
from items =
    UserPersona (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 4 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 5 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 6 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 7 |> Maybe.withDefault Item.new |> UserPersonaItem)
        (items |> Item.getAt 8 |> Maybe.withDefault Item.new |> UserPersonaItem)
