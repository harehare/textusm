module Diagram.UserPersona.View exposing (docs, view)

import Constants
import Diagram.Types exposing (SelectedItem, SelectedItemInfo)
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.UserPersona.Types as UserPersonaModel exposing (UserPersonaItem(..))
import Diagram.View.Canvas as Canvas
import Diagram.View.Views as Views
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Models.Item as Item exposing (Item, Items)
import Models.Property as Property exposing (Property)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Utils.Utils as Utils
import Views.Empty as Empty


view :
    { items : Items
    , data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { data, settings, items, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.UserPersona u ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight settings items

                (UserPersonaItem myDreams) =
                    u.myDreams

                (UserPersonaItem myInterests) =
                    u.myInterests

                (UserPersonaItem myPersonality) =
                    u.myPersonality

                (UserPersonaItem myRelationshipWithTechnology) =
                    u.myRelationshipWithTechnology

                (UserPersonaItem mySkils) =
                    u.mySkils

                (UserPersonaItem name) =
                    u.name

                (UserPersonaItem threeReasonsToBuyYourProduct) =
                    u.threeReasonsToBuyYourProduct

                (UserPersonaItem threeReasonsToUseYourProduct) =
                    u.threeReasonsToUseYourProduct

                (UserPersonaItem whoAmI) =
                    u.whoAmI
            in
            Svg.g
                []
                [ Lazy.lazy Canvas.viewImage
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( 0, 0 )
                    , item = name
                    , onSelect = onSelect
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth - Constants.canvasOffset, 0 )
                    , selectedItem = selectedItem
                    , item = whoAmI
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( round (toFloat Constants.itemWidth * 1.5) - Constants.canvasOffset * 2, itemHeight - Constants.canvasOffset )
                    , position = ( round (toFloat Constants.itemWidth * 2) - Constants.canvasOffset * 2, 0 )
                    , selectedItem = selectedItem
                    , item = threeReasonsToUseYourProduct
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( round (toFloat Constants.itemWidth * 1.5) - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( round (toFloat Constants.itemWidth * 3.5) - Constants.canvasOffset * 4, 0 )
                    , selectedItem = selectedItem
                    , item = threeReasonsToBuyYourProduct
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( 0, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = myInterests
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = myPersonality
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth * 2 - Constants.canvasOffset * 2, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = mySkils
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = myDreams
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth * 4 - Constants.canvasOffset * 4, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = myRelationshipWithTechnology
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                ]

        _ ->
            Empty.view


docs : Chapter x
docs =
    Chapter.chapter "UserPersona"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { items = Item.empty
                    , data =
                        DiagramData.UserPersona <|
                            UserPersonaModel.from <|
                                (DiagramType.defaultText DiagramType.UserPersona |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
