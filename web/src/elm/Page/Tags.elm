module Page.Tags exposing (Model, Msg(..), init, update, view)

import Browser.Dom as Dom
import Events
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (autofocus, class, id, placeholder, style)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (last)
import Return as Return exposing (Return)
import Task
import Views.Icon as Icon


type alias Tag =
    String


type alias Model =
    { tags : List Tag
    , editTag : Tag
    , deleteTag : Maybe Tag
    }


type Msg
    = NoOp
    | EditTag Tag
    | AddOrDeleteTag Int Bool
    | DeleteTag String


init : List Tag -> ( Model, Cmd Msg )
init tags =
    Return.singleton (Model tags "" Nothing)


focusInput : Model -> Return Msg Model
focusInput model =
    Return.return model
        (Task.attempt (\_ -> NoOp)
            (Dom.focus "edit-tag")
        )


update : Msg -> Return.ReturnF Msg Model
update msg =
    case msg of
        NoOp ->
            Return.zero

        EditTag tag ->
            Return.andThen (\m -> Return.singleton { m | deleteTag = Nothing, editTag = tag })

        AddOrDeleteTag 13 False ->
            Return.andThen
                (\m ->
                    if not <| List.member m.editTag m.tags then
                        Return.singleton { m | editTag = "", tags = m.tags ++ [ m.editTag ] }
                            |> Return.andThen focusInput

                    else
                        focusInput m
                )

        AddOrDeleteTag 8 False ->
            Return.andThen
                (\m ->
                    case m.deleteTag of
                        Just tag ->
                            Return.singleton { m | deleteTag = Nothing, tags = List.filter (\t -> tag /= t) m.tags }
                                |> Return.andThen focusInput

                        Nothing ->
                            Return.singleton { m | deleteTag = last m.tags }
                                |> Return.andThen focusInput
                )

        AddOrDeleteTag _ _ ->
            Return.andThen focusInput

        DeleteTag tag ->
            Return.andThen (\m -> Return.singleton { m | deleteTag = Nothing, tags = List.filter (\t -> tag /= t) m.tags })
                >> Return.andThen focusInput


view : Model -> Html Msg
view model =
    div
        [ class "w-full"
        , class "bg-default"
        , class "h-content"
        , class "text-color"
        ]
        [ div
            [ class "flex"
            , class "items-center"
            , class "flex-wrap"
            , class "w-full"
            , class "h-14"
            , class "border-main"
            , style "adding" "8px"
            ]
          <|
            List.map (tagView model.deleteTag) (List.filter (String.isEmpty >> not) model.tags)
                ++ [ input
                        [ class "input"
                        , id "edit-tag"
                        , style "width" "150px"
                        , style "background-color" "transparent"
                        , placeholder "ADD TAG"
                        , Events.onKeyDown AddOrDeleteTag
                        , onInput EditTag
                        , autofocus True
                        ]
                        []
                   ]
        ]


tagView : Maybe Tag -> Tag -> Html Msg
tagView deleteTag tag =
    let
        deleteButton =
            div
                [ onClick (DeleteTag tag)
                , class "flex"
                , class "items-center"
                , style "cursor" "pointer"
                ]
                [ Icon.clear "#333" 20 ]
    in
    case deleteTag of
        Just t ->
            if t == tag then
                viewTag "bg-error" [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]

            else
                viewTag "bg-activity" [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]

        Nothing ->
            viewTag "bg-activity" [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]


viewTag : String -> List (Html msg) -> Html msg
viewTag css children =
    div
        [ class "flex"
        , class "text-center"
        , class "text-color"
        , class "m-sm"
        , class "rounded"
        , class css
        , class "items-center"
        , style "padding" "8px 16px"
        ]
        children
