module Page.Tags exposing (Model, Msg(..), init, update, view)

import Browser.Dom as Dom
import Events
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (autofocus, class, id, placeholder, style)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (last)
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
    ( Model tags "" Nothing
    , focusInput
    )


focusInput : Cmd Msg
focusInput =
    Task.attempt (\_ -> NoOp)
        (Dom.focus "edit-tag")


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        EditTag tag ->
            ( { model | deleteTag = Nothing, editTag = tag }, Cmd.none )

        AddOrDeleteTag 13 False ->
            if not <| List.member model.editTag model.tags then
                ( { model | editTag = "", tags = model.tags ++ [ model.editTag ] }, focusInput )

            else
                ( model, focusInput )

        AddOrDeleteTag 8 False ->
            case model.deleteTag of
                Just tag ->
                    ( { model | deleteTag = Nothing, tags = List.filter (\t -> tag /= t) model.tags }, focusInput )

                Nothing ->
                    ( { model | deleteTag = last model.tags }, focusInput )

        AddOrDeleteTag _ _ ->
            ( model, focusInput )

        DeleteTag tag ->
            ( { model | deleteTag = Nothing, tags = List.filter (\t -> tag /= t) model.tags }, focusInput )


view : Model -> Html Msg
view model =
    div [ class "tags" ]
        [ div [ class "tag-list" ]
            (List.map (tagView model.deleteTag) (List.filter (String.isEmpty >> not) model.tags)
                ++ [ input
                        [ class "input"
                        , id "edit-tag"
                        , placeholder "ADD TAG"
                        , Events.onKeyDown AddOrDeleteTag
                        , onInput EditTag
                        , autofocus True
                        ]
                        []
                   ]
            )
        ]


tagView : Maybe Tag -> Tag -> Html Msg
tagView deleteTag tag =
    let
        deleteButton =
            div
                [ onClick (DeleteTag tag)
                , style "cursor" "pointer"
                , style "display" "flex"
                , style "align-items" "center"
                ]
                [ Icon.clear 20 ]
    in
    case deleteTag of
        Just t ->
            if t == tag then
                div [ class "tag delete-tag" ] [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]

            else
                div [ class "tag normal-tag" ] [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]

        Nothing ->
            div [ class "tag normal-tag" ] [ div [ style "padding-right" "8px" ] [ text tag ], deleteButton ]
