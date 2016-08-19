module Main exposing (main)

import Html.App as App
import Html exposing (..)
import Material
import Material.Scheme
import Material.Color as Color
import Material.Options as Options exposing (css, when)
import Material.Typography as Typography
import Material.Layout as Layout
import Material.Helpers exposing (lift)
import Navigation
import RouteUrl as Routing
import Tabs.Puppies
import Tabs.Tables
import Tabs.Logon
import Tabs.Encoders
import Array exposing (Array)
import Dict exposing (Dict)
import String
import Auth
import Utils


-- MODEL


type alias Model =
    { selectedTab : Int
    , userAuth : Auth.UserAuth
    , desiredTab : Int
    , tabPuppies : Tabs.Puppies.Model
    , tabTables : Tabs.Tables.Model
    , tabLogon : Tabs.Logon.Model
    , tabEncoders : Tabs.Encoders.Model
    , tabInfos : List TabInfo
    , mdl : Material.Model
    }


model : Model
model =
    { mdl = Material.model
    , selectedTab = 0
    , desiredTab = 0
    , userAuth = Auth.none
    , tabPuppies = Tabs.Puppies.model
    , tabTables = Tabs.Tables.model
    , tabLogon = Tabs.Logon.model
    , tabEncoders = Tabs.Encoders.model
    , tabInfos = tabInfos
    }



-- ACTION, UPDATE


type Msg
    = Mdl (Material.Msg Msg)
    | EncodersMsg Tabs.Encoders.Msg
    | PuppiesMsg Tabs.Puppies.Msg
    | TablesMsg Tabs.Tables.Msg
    | LogonMsg Tabs.Logon.Msg
    | SelectTab Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectTab tab ->
            -- Does this user have permission to transition to the desired
            -- tab?  If not then redirect to Logon
            let
                requiredRole =
                    Array.get tab tabPermissions |> Maybe.withDefault Auth.None
            in
                if requiredRole == Auth.None then
                    ( { model
                        | selectedTab = tab
                        , desiredTab = tab
                      }
                    , Cmd.none
                    )
                else
                    case List.member requiredRole model.userAuth.roles of
                        True ->
                            ( { model
                                | selectedTab = tab
                                , desiredTab = tab
                              }
                            , Cmd.none
                            )

                        -- Redirect to the logon page
                        False ->
                            ( { model
                                | selectedTab = Utils.indexOf "Logon" tabTitles |> Maybe.withDefault 0
                                , desiredTab = tab
                              }
                            , Cmd.none
                            )

        LogonMsg childMsg ->
            -- The logon module makes its auth message public. As a child convenience, we remember the auth state
            -- and pass it to all child view functions.  If we have a successful logon then we also check whether the
            -- selected tab is the same as the desired tab and generate a tab transition if not...
            let
                ( ourModel, ourCommand ) =
                    rememberAuthAndMaybeChangeTabs childMsg model
            in
                let
                    ( newChildModel, newChildCommand ) =
                        Tabs.Logon.update childMsg ourModel.tabLogon
                in
                    { ourModel | tabLogon = newChildModel } ! [ (Cmd.map LogonMsg newChildCommand), ourCommand ]

        -- Boilerplate: Mdl action handler.
        Mdl msg' ->
            Material.update msg' model

        -- Boilerplate msg wrapper / router for each of the tabs
        -- the below is exactly the same as the ones that follow (using elm-mdl's lift
        -- helper function) but I find it far more readable.
        -- Brevity vs. clarity - take your pick
        TablesMsg childMsg ->
            let
                ( newChildModel, newChildCommand ) =
                    Tabs.Tables.update childMsg model.tabTables
            in
                ( { model | tabTables = newChildModel }, Cmd.map TablesMsg newChildCommand )

        EncodersMsg childMsg ->
            lift .tabEncoders (\m childModel -> { m | tabEncoders = childModel }) EncodersMsg Tabs.Encoders.update childMsg model

        PuppiesMsg childMsg ->
            lift .tabPuppies (\m childModel -> { m | tabPuppies = childModel }) PuppiesMsg Tabs.Puppies.update childMsg model


rememberAuthAndMaybeChangeTabs : Tabs.Logon.Msg -> Model -> ( Model, Cmd Msg )
rememberAuthAndMaybeChangeTabs logonMsg model =
    case logonMsg of
        Tabs.Logon.PostSucceed userAuth ->
            let
                ourCommand' =
                    if model.selectedTab == model.desiredTab then
                        Cmd.none
                    else
                        Utils.msg2cmd (SelectTab model.desiredTab)
            in
                ( { model | userAuth = userAuth }, ourCommand' )

        _ ->
            ( model, Cmd.none )



-- Separate public and private messages?
-- Security / cookies as a generic thing
-- TAB SETUP


type alias ViewFunc =
    Model -> Html Msg


type TI
    = TI TabInfo


type alias TabInfo =
    { tabName : String
    , tabUrl : String
    , requiredRole : Auth.Role
    }


type alias Tab =
    { info : TabInfo
    , tabViewMap : ViewFunc
    }


tabList =
    [ { info = { tabName = "Tables", tabUrl = "tables", requiredRole = Auth.User }, tabViewMap = tableTabViewMap }
    , { info = { tabName = "Puppies", tabUrl = "puppies", requiredRole = Auth.Admin }, tabViewMap = .tabPuppies >> Tabs.Puppies.view >> App.map PuppiesMsg }
    , { info = { tabName = "Encoders", tabUrl = "encoders", requiredRole = Auth.User }, tabViewMap = .tabEncoders >> Tabs.Encoders.view >> App.map EncodersMsg }
    , { info = logonTabInfo, tabViewMap = logonTabViewMap2 }
    ]


tabInfos =
    List.map .info tabList


tabInfoArray =
    Array.fromList tabInfos


logonTabInfo =
    { tabName = "Logon", tabUrl = "logon", requiredRole = Auth.None }


noContext modelFunc =
    \context model -> modelFunc model


tabArray =
    Array.fromList tabList


tabName index =
    Array.get index tabInfoArray |> Maybe.withDefault logonTabInfo |> .tabName



--tabIndexByName : String -> Int
--tabIndexByName =
--    Dict.fromList <| List.indexedMap (\idx tab -> ( tab.tabName, idx )) tabList


logonTabViewMap2 model =
    let
        viewWithInjectedArgs =
            Tabs.Logon.view (model.selectedTab /= model.desiredTab) (tabName model.desiredTab) Auth.Admin
    in
        .tabLogon model |> viewWithInjectedArgs |> App.map LogonMsg


logonTabViewMap : Model -> Html Msg
logonTabViewMap model =
    -- the logon tab needs to know what our intended tab name and Role is so it can display that to the user if they are redirected there...
    let
        requiredRole =
            Auth.User

        desiredTabInfo =
            Debug.log "dTI" tabArray

        _ =
            Debug.log "Model" (model.selectedTab /= model.desiredTab)

        --Array.get model.desiredTab tabPermissions |> Maybe.withDefault Auth.None
    in
        Tabs.Logon.view (model.selectedTab /= model.desiredTab) "fred" requiredRole model.tabLogon |> App.map LogonMsg



--logonTabViewMap : Model -> Html Msg
--logonTabViewMap model =
--    -- the logon tab needs to know what our intended tab name and Role is so it can display that to the user if they are redirected there...
--    let
--        desiredTabInfo =
--            Array.get model.desiredTab tabArray |> Maybe.withDefault logonTabInfo
--    in
--        Tabs.Logon.view (model.selectedTab == model.desiredTab) desiredTabInfo.tabName desiredTabInfo.requiredRole model.tabLogon |> App.map LogonMsg


tableTabViewMap : Model -> Html Msg
tableTabViewMap model =
    --inject authDetails into tables tab view calls
    Tabs.Tables.view model.userAuth model.tabTables |> App.map TablesMsg



-- tabs helpers


tabTitles : List String
tabTitles =
    List.map .tabName tabInfos


tabTitlesHTML : List (Html a)
tabTitlesHTML =
    List.map text tabTitles


tabUrls : Array String
tabUrls =
    List.map .tabUrl tabInfos |> Array.fromList


tabPermissions =
    List.map .requiredRole tabInfos |> Array.fromList


tabViews : Array (ViewFunc)
tabViews =
    List.map .tabViewMap tabList |> Array.fromList


urlTabs : Dict String Int
urlTabs =
    List.indexedMap (\idx tabInfo -> ( .tabUrl tabInfo, idx )) tabInfos |> Dict.fromList


e404 : ViewFunc
e404 _ =
    div []
        [ Options.styled Html.h1
            [ Options.cs "mdl-typography--display-4"
            , Typography.center
            ]
            [ text "404" ]
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        currentTab =
            (Array.get model.selectedTab tabViews |> Maybe.withDefault e404) model
    in
        Material.Scheme.topWithScheme Color.Teal Color.Red <|
            Layout.render Mdl
                model.mdl
                [ Layout.selectedTab model.selectedTab
                , Layout.fixedHeader
                , Layout.onSelectTab SelectTab
                ]
                { header = header model
                , drawer = []
                , tabs = ( tabTitlesHTML, [ Color.background (Color.color Color.Teal Color.S400) ] )
                , main = [ currentTab ]
                }


header : Model -> List (Html Msg)
header model =
    [ Layout.row []
        [ Layout.title [] [ text "Elm Encoder" ]
        , Layout.spacer
        , Layout.navigation []
            [ Layout.link [ Layout.href "http://www.id3as.co.uk" ]
                [ span [] [ text "id3as" ] ]
            ]
        ]
    ]


urlOf : Model -> String
urlOf model =
    "#" ++ (Array.get model.selectedTab tabUrls |> Maybe.withDefault "")


delta2url : Model -> Model -> Maybe Routing.UrlChange
delta2url model1 model2 =
    if model1.selectedTab /= model2.selectedTab then
        { entry = Routing.NewEntry
        , url = urlOf model2
        }
            |> Just
    else
        Nothing


location2messages : Navigation.Location -> List Msg
location2messages location =
    [ case String.dropLeft 1 location.hash of
        "" ->
            SelectTab 0

        x ->
            Dict.get x urlTabs
                |> Maybe.withDefault -1
                |> SelectTab
    ]


main : Program Never
main =
    Routing.program
        { delta2url = delta2url
        , location2messages = location2messages
        , init =
            ( { model
                | mdl =
                    Layout.setTabsWidth 2124 model.mdl
                    {- elm gives us no way to measure the actual width of tabs. We
                       hardwire it. If you add a tab, remember to update this. Find the
                       new value using:

                       document.getElementsByClassName("mdl-layout__tab-bar")[0].scrollWidth
                    -}
              }
            , Material.init Mdl
            )
        , view = view
        , subscriptions = \model -> Sub.none
        , update = update
        }
