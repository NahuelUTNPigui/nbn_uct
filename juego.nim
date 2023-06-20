type
    Juego* = ref object of RootObj
        tablero*:seq[seq[int]]
        quien_juega*:int
    
    Tablero* = object
        tablero*:seq[seq[int]]
        quien_juega*:int


proc newTablero(tablero:seq[seq[int]],quien_juega:int):Tablero=
    Tablero(tablero:tablero,quien_juega:quien_juega)

method getState*(j:Juego):seq[float]{.base.} =
    @[]

method copia*(j:Juego):Juego{.base.}=
    echo "Se usa este metodo"
    j

method legalAcciones*(j:Juego):seq[int]{.base.}=
    @[]

method applyAccion*(j:var Juego,idaccion:int){.base.}=
    echo "Implementar"

# Saber si el juego termino
method isTerminal*(j:Juego):int{.base.}=
    0


    