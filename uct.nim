import tateti
import juego
# Aca debo importar el juego
## LOs metodos que debe implementar
#[ En vez de juego tablero
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
method isTerminal*(j:Juego):bool{.base.}=
    0
method reward*(j:Juego):int{.base.}=
    0
]#
import tables
import random
import math
import sequtils
randomize()
type
    UctConfig* = object
        num_sims* : int
        c*:float

type
    Nodo = ref object
        # No me gusta pero bue
        estado:Tablero
        puntos:int
        visitas:int
        hijos:Table[int,Nodo]
        accionesDisponibles:seq[int]
        padre:Nodo
        accion:int


proc ucb_score(n:Nodo,config:UctConfig):float=
    if n.visitas == 0:
        return 0
    var score = n.puntos.toFloat/n.visitas.toFloat
    score += config.c * sqrt(2 * ln(n.padre.visitas.toFloat)/n.visitas.toFloat)
    score

proc `$`*(n:Nodo):string=
    var s = "Estado: \n" & $n.estado.tablero & "\n"
    s &= "Quien juega: " & $n.estado.quien_juega & "\n"
    s &= "Accion: " & $n.accion & "\n"
    s &= "Visitas: " & $n.visitas & " and puntos: " & $n.puntos & " \n"
    s &= "Score " & $(n.puntos.toFloat/n.visitas.toFloat) & " \n"
    s


proc newUctConfig*(num_sims:int,c:float):UctConfig=
    UctConfig(num_sims:num_sims,c:c)

proc newNodo(juego:Tablero,padre:Nodo,accion:int):Nodo=
    var accionesDisponibles = juego.legalAcciones()
    var estado = juego
    var puntos = 0
    var visitas = 0
    var hijos = initTable[int,Nodo]()
    Nodo(
        estado:estado,
        puntos:puntos,
        visitas:visitas,
        accionesDisponibles:accionesDisponibles,
        hijos:hijos,
        padre:padre,
        accion:accion
    )


proc esTerminal(n:Nodo):bool=
    return n.estado.isTerminal()

proc fullyExpanded(n:Nodo):bool=
    return n.accionesDisponibles.len == 0


    
    


proc expand(nodo:Nodo,verbose=false):Nodo=
    if verbose:
        echo "  EXPAND"
    let idaccion = sample(nodo.accionesDisponibles)
    nodo.accionesDisponibles= nodo.accionesDisponibles.filter(proc (x:int):bool = x != idaccion)
    #echo "Estado expand"
    var estado=nodo.estado.copia()
    
    if verbose:
        echo "      Padre: " & $nodo.estado.tablero
        #echo repr(nodo.estado.tablero.addr)
    estado.applyAccion(idaccion)    
    #echo estado
    var hijo = newNodo(
        estado,
        nodo,
        idaccion
    )
    if verbose:
        echo "      HIjo: " & $hijo.estado.tablero
        #echo repr(hijo.estado.tablero.addr)
    nodo.hijos[idaccion] = hijo
    hijo

proc bestHijo(nodo:Nodo,config:UctConfig,verbose=false):Nodo=
    var mejorHijo = nodo
    var i = 0
    var mejor_score = -1.0
    #echo "Cantidad hijos"
    #echo nodo.hijos.len
    for idaccion in nodo.hijos.keys:
        let hijo = nodo.hijos[idaccion]
        let score =  hijo.ucb_score(config)
        if i == 0:
            mejorHijo = hijo
            mejor_score = score
        if score < mejor_score:
            mejor_score=score
            mejorHijo = hijo
        
    mejorHijo
   
proc treePolicy(n:Nodo,config:UctConfig,verbose=false):Nodo=
    var v = n
    while not v.esTerminal():
        if not v.fullyExpanded():
            return v.expand(verbose)
        else:
            v = bestHijo(v,config)
    return v

proc defaultPolicy(n:Nodo,verbose=false):int=
    var copia = n.estado.copia()
    var esTerminal = copia.isTerminal()
    if esTerminal:
        return copia.reward()
    while not esTerminal:
        let acciones = copia.legalAcciones()
        let idaccion = sample(acciones)
        copia.applyAccion(idaccion)
        esTerminal = copia.isTerminal()
    let reward = copia.reward()
    return reward

proc backup(n:var Nodo,reward:int)=
    var v = n
    var puntos = -1 * reward
    while not isNil(v):
        v.visitas += 1
        v.puntos += puntos
        puntos *= -1
        v = v.padre



# id de la accion
proc uct*(juego:Tablero,config:UctConfig,verbose=false):int=
    let scratch_game = juego.copia()
    
    var raiz = newNodo(scratch_game,nil,-1)
    #echo raiz
    for iter in countup(1,config.num_sims):
        if verbose:
            echo "Iter: " & $iter
        var nodo = treepolicy(raiz,config,verbose)
        if verbose:
            echo "  nodo:"
            echo "\t" & $nodo
            echo "  Estado Juego: "
            echo "  quien: " & $scratch_game.quien_juega
            echo "  tablero: " & $scratch_game.tablero
        let reward = defaultPolicy(nodo,verbose)
        backup(nodo,reward)
    
    if verbose:        
        echo "EL padre"
        echo raiz
        echo ""
        echo "Los hijos"
        echo raiz.hijos
        echo ""

    return bestHijo(raiz,config,verbose).accion
        
