module Tabs.Encoders exposing (Model, Msg, model, update, view)

import Html.App as App
import Html exposing (..)
import String
import Html.Attributes exposing (..)
import Material
import Material.Options as Options exposing (nop)
import Material.Toggles as Toggles
import Material.Card as Card
import Material.Color as Color
import Material.Grid as Grid
import Material.Table as Table
import Utils


main : Program Never
main =
    App.program
        { init = ( model, Cmd.none )
        , view = view
        , subscriptions = always Sub.none
        , update = update
        }



-- Model


type alias Model =
    { displayStyle : DisplayStyle
    , encoders : List Encoder
    , mdl : Material.Model
    }


type alias Encoder =
    { id : String
    , name : String
    , source : Source
    , outputs : List Output
    }


type DisplayStyle
    = DisplayTable
    | DisplayCards


type Source
    = Udp UdpDetails


type alias UdpDetails =
    { ipAddr : String
    , ipPort : Int
    }


type alias Output =
    { name : String
    , width : Int
    , height : Int
    }


model : Model
model =
    { displayStyle = DisplayCards
    , encoders = dummyEncoders 5
    , mdl = Material.model
    }


dummyEncoders count =
    List.indexedMap (\idx _ -> dummyEncoder idx) [1..count]


dummyEncoder index =
    { id = "6ec656a88cf8fa699d7e3f4ad4fb0167"
    , name = "Dummy encoder " ++ (toString index)
    , source =
        Udp
            { ipAddr = "127.0.0.1"
            , ipPort = 333 + index
            }
    , outputs =
        [ { name = "1080p"
          , width = 1920
          , height = 1088
          }
        , { name = "720p"
          , width = 1280
          , height = 720
          }
        , { name = "480p"
          , width = 850
          , height = 480
          }
        ]
    }


type Msg
    = MDL (Material.Msg Msg)
    | SetDisplayStyle DisplayStyle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MDL action' ->
            Material.update action' model

        SetDisplayStyle displayStyle ->
            ( { model | displayStyle = displayStyle }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ style [ ( "margin-left", "20px" ) ] ]
        [ h4 [] [ text "Encoders" ]
        , div []
            [ Toggles.radio MDL
                [ 0 ]
                model.mdl
                [ Toggles.value (model.displayStyle == DisplayCards)
                , Toggles.group "DisplayStyle"
                , Toggles.ripple
                , Toggles.onClick (SetDisplayStyle DisplayCards)
                ]
                [ text "Cards" ]
            , Toggles.radio MDL
                [ 1 ]
                model.mdl
                [ Toggles.value (model.displayStyle == DisplayTable)
                , Toggles.group "MyRadioGroup"
                , Toggles.ripple
                , Toggles.onClick (SetDisplayStyle DisplayTable)
                ]
                [ text "Table" ]
            ]
        , case model.displayStyle of
            DisplayCards ->
                viewEncodersCards model.encoders

            DisplayTable ->
                viewEncodersTable model.encoders
          -- Debug dump of model withouth the mdl clutter
        , Utils.debugDumpModel model
        ]


viewEncodersTable encoders =
    div []
        [ Table.table []
            [ Table.thead []
                [ Table.tr [] <|
                    List.map
                        (\colName -> Table.th [] [ text colName ])
                        [ "Name", "Id", "Source", "Outputs" ]
                ]
            , Table.tbody []
                (encoders
                    |> List.map
                        (\encoder ->
                            Table.tr
                                []
                                [ Table.td noPadding [ text encoder.name ]
                                , Table.td noPadding [ text encoder.id ]
                                , Table.td noPadding
                                    [ case encoder.source of
                                        Udp details ->
                                            text <| "UDP " ++ details.ipAddr ++ ":" ++ (details.ipPort |> toString)
                                    ]
                                , Table.td noPadding <| [ text (String.join ", " <| List.map (.name) encoder.outputs) ]
                                ]
                        )
                )
            ]
        ]


viewEncodersCards encoders =
    div
        [ style
            [ ( "flex-direction", "row" )
            , ( "display", "flex" )
            , ( "flex-wrap", " wrap" )
            , ( "margin-left", "20px" )
            ]
        ]
    <|
        List.map viewEncoderCards encoders


viewEncoderCards encoder =
    Card.view
        [ Color.background (Color.color Color.DeepPurple Color.S300)
        , Options.css "margin" "4px 8px 4px 0px"
        , Options.css "width" "400px"
        ]
        [ Card.title
            [ Options.css "align-content" "flex-start"
            , Options.css "align-items" "flex-start"
            , Options.css "justify-content" "space-between"
            ]
            [ Card.head [ Color.text Color.white ] [ text encoder.name ]
            , Card.subhead [ Color.text Color.white ] [ text <| "Id: " ++ encoder.id ]
            ]
        , Card.text []
            [ Grid.grid []
                [ Grid.cell [ Grid.size Grid.All 4 ]
                    [ h4 [] [ text "Source" ]
                    , viewSourceCards encoder.source
                    ]
                , Grid.cell [ Grid.size Grid.All 6 ]
                    [ h4 [] [ text "Outputs" ]
                    , viewOutputsCards encoder.outputs
                    ]
                ]
            ]
        ]


viewSourceCards source =
    case source of
        Udp udpDetails ->
            div []
                [ text <| udpDetails.ipAddr ++ ":" ++ (toString udpDetails.ipPort) ]


viewOutputsCards outputs =
    Table.table []
        [ Table.thead []
            [ Table.tr []
                [ Table.th [] [ text "Name" ]
                , Table.th [] [ text "Width" ]
                , Table.th [] [ text "Height" ]
                ]
            ]
        , Table.tbody []
            (outputs
                |> List.map
                    (\output ->
                        Table.tr
                            []
                            [ Table.td noPadding [ text output.name ]
                            , Table.td noPaddingNumeric [ text <| toString output.width ]
                            , Table.td noPaddingNumeric [ text <| toString output.height ]
                            ]
                    )
            )
        ]


noPadding =
    [ Options.css "padding-top" "1px"
    , Options.css "padding-bottom" "1px"
    ]


noPaddingNumeric =
    noPadding ++ [ Table.numeric ]
