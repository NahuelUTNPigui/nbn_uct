
import tateti

import uct
import math

proc testsimple()=
    var t = newTatetiFromScratch()
    let t2 =  t.copia()
    echo t.getState()
    echo t.legalAcciones()
    echo "HOrizontales"
    t.applyAccion(0)
    
    echo t2.getState()
    echo t.getState()
    echo t.legalAcciones()
    
    t.applyAccion(3)
    t.applyAccion(1)
    t.applyAccion(4)
    t.applyAccion(8)
    
    echo t.getState()
    echo t.isTerminal()
    echo "Verticales"
    t = newTatetiFromScratch()
    t.applyAccion(0)
    t.applyAccion(1)
    t.applyAccion(3)
    t.applyAccion(4)
    t.applyAccion(2)
    t.applyAccion(7)
    echo t
    echo t.isTerminal()
    echo "Diagonal"
    t = newTatetiFromScratch()
    t.applyAccion(0)
    t.applyAccion(4)
    t.applyAccion(1)
    t.applyAccion(2)
    t.applyAccion (5)
    t.applyAccion(6)
    t.applyAccion(7)
    echo t
    echo t.isTerminal

proc testsimple2()=
    var t = newTatetiFromScratch()
    t.applyAccion(2)
    t.applyAccion(1)
    t.applyAccion(4)
    t.applyAccion(5)
    t.applyAccion(6)
    echo t
    echo t.isTerminal()
    echo t.reward
proc testuct()=
    echo "Test UCT"
    let config=newUctConfig(100,sqrt(2.0)/2)
    var juego = newTatetiFromScratch()
    echo juego
    echo "uct"
    echo "Turno cruz"
    var accion = uct(juego,config,false)
    echo "  La accion de cruz: " & $accion
    juego.applyAccion(accion)
    echo juego
    echo "TUrno ciruclo"
    accion = uct(juego,config,false)
    echo "  La accion de circulo: " & $accion
    juego.applyAccion(accion)
    echo juego

proc partida()=
    echo "Test partida"
    let config=newUctConfig(100,sqrt(2.0)/2)
    var juego = newTatetiFromScratch()
    var terminal = false
    while not terminal:
        echo ""
        echo "Turno cruz"
        var accion = uct(juego,config,false)
        echo "Accion tomada: " & $accion
        juego.applyAccion(accion)
        echo juego
        terminal=juego.isTerminal()
        if terminal:

            echo juego.reward()
            break
        echo ""
        echo "Turno CIRCULO"
        accion = uct(juego,config,false)
        echo "Accion tomada: " & $accion
        juego.applyAccion(accion)
        echo juego
        terminal=juego.isTerminal()
    echo ""
    echo juego.reward()


#testsimple2()
#testuct()
partida()
