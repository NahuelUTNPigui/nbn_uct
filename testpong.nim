import uct
import ponghuaki
import math
import random
randomize()
proc partida()=
    echo "Test partida"
    let config=newUctConfig(30,sqrt(2.0)/2)
    var juego = newPongHuaKiFromSchatch()
    echo juego
    var terminal = false
    while not terminal:
        echo ""
        echo "Turno 1"
        
        var accion = uct(juego,config,false)
        echo "Accion tomada: " & $accion
        juego.applyAccion(accion)
        echo "Juego"
        echo juego
        echo ""
        echo "Turno otro"
        terminal=juego.isTerminal()
        if terminal:
            echo "Perdio otro"
            echo juego.reward()
            break
        
        accion = sample(juego.legalAcciones())
        echo "Accion tomada: " & $accion
        echo "Juego"
        juego.applyAccion(accion)
        echo juego
        terminal=juego.isTerminal()

    echo "Perdio 1"
    echo juego.reward()
partida()