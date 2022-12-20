module Models.Image exposing (Image, from, isDataUrl, isUrl, toUrl)

import Models.Item as Item exposing (Item)


type Image
    = Url String
    | DataUrl String


isUrl : Image -> Bool
isUrl image =
    case image of
        Url _ ->
            True

        _ ->
            False


isDataUrl : Image -> Bool
isDataUrl image =
    case image of
        DataUrl _ ->
            True

        _ ->
            False


toUrl : Image -> String
toUrl image =
    case image of
        Url u ->
            u

        DataUrl u ->
            u


from : Item -> Maybe Image
from item =
    if Item.isUrl item then
        Just <| Url <| Item.getTextOnly <| item

    else if Item.isDataUrl item then
        Just <| DataUrl <| Item.getTextOnly item

    else
        Nothing
