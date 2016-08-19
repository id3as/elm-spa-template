module Tabs.Puppies exposing (..)

import Html.App as App
import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (..)
import Material


-- Main


main : Program Never
main =
    App.program
        { init = ( model, Cmd.none )
        , view = view
        , subscriptions = always Sub.none
        , update = update
        }


type alias Model =
    { url : String
    , mdl : Material.Model
    }


model : Model
model =
    { url = "http://ghk.h-cdn.co/assets/16/09/1600x800/landscape-1457107485-gettyimages-512366437.jpg"
    , mdl = Material.model
    }


type Msg
    = Bark


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    let
        _ =
            Debug.log "Action" action
    in
        ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ h2 []
            [ text "Hello" ]
        , img
            [ src "http://ghk.h-cdn.co/assets/16/09/1600x800/landscape-1457107485-gettyimages-512366437.jpg"
            , onClick Bark
            ]
            []
        ]
