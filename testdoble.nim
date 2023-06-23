import uct
import doble
import math
proc partida()=
    echo "Test partida"
    let config=newUctConfig(20,sqrt(2.0)/2)
    var juego = newDobleFromScratch()
    var terminal = false
    while not terminal:
        echo ""
        echo "Turno 1"
        var accion = uct(juego,config,true)
        echo "Accion tomada: " & $accion
        juego.applyAccion(accion)
        echo juego
        terminal=juego.isTerminal()
        if terminal:

            echo juego.reward()
            break
        echo ""
        echo "Turno -1"
        accion = uct(juego,config,true)
        echo "Accion tomada: " & $accion
        juego.applyAccion(accion)
        echo juego
        terminal=juego.isTerminal()
    echo ""
    echo juego.reward()

partida()