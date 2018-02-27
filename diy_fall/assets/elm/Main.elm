module Main exposing (main)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Json.Encode as JE
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket


type alias Model =
    { phxSocket : Phoenix.Socket.Socket Msg
    }


initChannel : String -> Phoenix.Channel.Channel Msg
initChannel channel =
    Phoenix.Channel.init ("games:" ++ channel)


joinChannel :
    Phoenix.Socket.Socket Msg
    -> ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinChannel socket =
    socket
        |> Phoenix.Socket.join (initChannel "test")


initializeSocket : Phoenix.Socket.Socket Msg
initializeSocket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug


socketServer : String
socketServer =
    "ws://172.23.11.170:4000/socket/websocket"


initialModel : Model
initialModel =
    { phxSocket = initializeSocket }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | Show
    | ProcessSocketData JE.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ProcessSocketData data ->
            let
                d =
                    Debug.log "data" data
            in
            ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
            ( { model | phxSocket = phxSocket }
            , Cmd.map PhoenixMsg phxCmd
            )

        JoinChannel ->
            let
                ( phx, msg ) =
                    joinChannel model.phxSocket

                d =
                    Debug.log "phx" phx
            in
            ( { model
                | phxSocket = phx
              }
            , Cmd.map PhoenixMsg msg
            )

        Show ->
            let
                pmsg =
                    push "show" model
                        |> Phoenix.Push.onOk ProcessSocketData
                        |> Phoenix.Push.onError ProcessSocketData

                d =
                    Debug.log "pmsg" pmsg

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push pmsg model.phxSocket
            in
            ( { model
                | phxSocket = phxSocket
              }
            , Cmd.map PhoenixMsg phxCmd
            )


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick JoinChannel ] [ text "Connect Yourself" ]
        , button [ onClick Show ] [ text "Show" ]
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


push : String -> Model -> Phoenix.Push.Push Msg
push fn model =
    Phoenix.Push.init fn "games:test"
        |> Phoenix.Push.withPayload (JE.object [])


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg