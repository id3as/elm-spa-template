module Tabs.Tables exposing (..)

import Html.App as App
import Html exposing (..)
import Material
import Material.Table as Table
import Material.Options as Options exposing (nop)
import Auth


main : Program Never
main =
    App.program
        { init = ( model, Cmd.none )
        , view = view Auth.none
        , subscriptions = always Sub.none
        , update = update
        }


type alias Model =
    { url : String
    , order : Maybe Table.Order
    , mdl : Material.Model
    }


type alias Item =
    { material : String
    , quantity : Int
    , unitPrice : Float
    }


rotate : Maybe Table.Order -> Maybe Table.Order
rotate order =
    case order of
        Just (Table.Ascending) ->
            Just Table.Descending

        Just (Table.Descending) ->
            Nothing

        Nothing ->
            Just Table.Ascending


type alias Data =
    { material : String
    , quantity : String
    , unitPrice : String
    }


data : List Data
data =
    [ { material = "Acrylic (Transparent)"
      , quantity = "25"
      , unitPrice = "$2.90"
      }
    , { material = "Plywood (Birch)"
      , quantity = "50"
      , unitPrice = "$1.25"
      }
    , { material = "Laminate (Gold on Blue)"
      , quantity = "10"
      , unitPrice = "$2.35"
      }
    ]


model : Model
model =
    { url = "http://ghk.h-cdn.co/assets/16/09/1600x800/landscape-1457107485-gettyimages-512366437.jpg"
    , order = Just Table.Descending
    , mdl = Material.model
    }


type Msg
    = Reorder


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "Msg" msg of
        Reorder ->
            ( { model | order = rotate model.order }, Cmd.none )



-- VIEW


reverse : comparable -> comparable -> Order
reverse x y =
    case compare x y of
        LT ->
            GT

        GT ->
            LT

        EQ ->
            EQ


view : Auth.UserAuth -> Model -> Html Msg
view authdetails model =
    let
        sort =
            case model.order of
                Just (Table.Ascending) ->
                    List.sortBy .material

                Just (Table.Descending) ->
                    List.sortWith (\x y -> reverse (.material x) (.material y))

                Nothing ->
                    identity
    in
        Table.table []
            [ Table.thead []
                [ Table.tr []
                    [ Table.th
                        [ model.order
                            |> Maybe.map Table.sorted
                            |> Maybe.withDefault nop
                        , Table.onClick Reorder
                        ]
                        [ text "Material" ]
                    , Table.th [ Table.numeric ] [ text "Quantity" ]
                    , Table.th [ Table.numeric ] [ text "Unit Price" ]
                    ]
                ]
            , Table.tbody []
                (sort data
                    |> List.indexedMap
                        (\idx item ->
                            Table.tr []
                                [ Table.td [] [ text item.material ]
                                , Table.td [ Table.numeric ] [ text item.quantity ]
                                , Table.td [ Table.numeric ] [ text item.unitPrice ]
                                ]
                        )
                )
            ]
