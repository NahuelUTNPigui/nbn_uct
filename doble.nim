import juego

proc newDobleFromScratch*():Tablero=
    var doble= @[@[0,0,0,0]]
    var quien_juega=1
    Tablero(
        tablero:doble,
        quien_juega:quien_juega
    )

proc newDoble*(tablero:seq[int],quien_juega:int):Tablero=
    Tablero(
        tablero : @[tablero],
        quien_juega : quien_juega
    )
proc getState*(j:Tablero):seq[float] =
    var estado=newSeq[float](12)
    for i in countup(0,3):
        if j.tablero[0][i] == 1:
            estado[i] = 1.0
        elif j.tablero[0][i] == -1:
            estado[i+4] = 1.0
        if j.quien_juega==1:
            estado[i+8] = 1.0

    estado
    

proc copia*(j:Tablero):Tablero=
    var doble = newSeq[int](4)
    for i in countup(0,3):
        doble[i] = j.tablero[0][i]
    var quien_juega = j.quien_juega
    newDoble(doble,quien_juega)

proc legalAcciones*(j:Tablero):seq[int]=
    var acciones:seq[int] = @[]
    for i in countup(0,3):
        if j.tablero[0][i] == 0:
            acciones.add(i)
    return acciones

proc applyAccion*(j:var Tablero,idaccion:int)=
    if j.quien_juega==1:
        j.tablero[0][idaccion] = 1
    else:
        j.tablero[0][idaccion] = -1
    if j.quien_juega == 1:
        j.quien_juega = 2
    else:
        j.quien_juega=1

# Saber si el juego termino
proc isTerminal*(j:Tablero):bool=
    var unosSeguidos=0
    var menosUnosSeguidos=0
    var noHayCeros=true
    for i in countup(0,3):
        if j.tablero[0][i] == 1:
            if unosSeguidos == 1:
                return true
            else:
                menosUnosSeguidos = 0
                unosSeguidos = 1
        elif j.tablero[0][i] == -1:
            if menosUnosSeguidos == 1:
                return true
            else:
                unosSeguidos = 0
                menosUnosSeguidos = 1
        else:
            noHayCeros=false
            unosSeguidos=0
            menosUnosSeguidos=0
    if unosSeguidos == 2:
        return true
    elif menosUnosSeguidos == 2:
        return true
    elif noHayCeros:
        return true
    else:
        return false

proc reward*(j:Tablero):int=
    var unosSeguidos=0
    var menosUnosSeguidos=0
    var noHayCeros=true
    for i in countup(0,3):
        if j.tablero[0][i] == 1:
            if unosSeguidos == 1:
                unosSeguidos += 1
                break
            else:
                menosUnosSeguidos = 0
                unosSeguidos = 1
        elif j.tablero[0][i] == -1:
            if menosUnosSeguidos == 1:
                menosUnosSeguidos += 1
                break
            else:
                unosSeguidos = 0
                menosUnosSeguidos = 1
        else:
            noHayCeros=false
            unosSeguidos=0
            menosUnosSeguidos=0
    if unosSeguidos == 2:
        if j.quien_juega == 1:
            return 1
        else:
            return -1
    elif menosUnosSeguidos == 2:
        if j.quien_juega == 1:
            return -1
        else:
            return 1
    elif noHayCeros:
        return 0
