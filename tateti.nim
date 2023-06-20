import juego
import sequtils
type 
    Tateti = ref object of Juego
        #[ 1 cruz,-1 circulo
            1.0.0
            0.-1.1
            -1.0.0
        ]#
        #tablero:seq[seq[int]]
        # 1 es cruz ,-1 circulo
        #quien_juega:int


proc `$`*(t:Tablero):string=
    var s ="Quien juega: " & $t.quien_juega & "\n"
    s &= $t.tablero
    s


proc newTateti(tablero:seq[seq[int]],quien_juega=1):Tablero=
    Tablero(tablero:tablero,quien_juega:quien_juega)


proc newTatetiFromScratch*():Tablero=
    
    var tablero = newSeq[seq[int]](3)
    
    for i in countup(0,2):
        tablero[i] = newSeq[int](3)
    
    newTateti(tablero)

proc getState*(t:Tablero):seq[float]=
    # primero 9 para cruz otros 9 para circulo y los otrs 9 para el jugador
    var estado=newSeq[float](27)
    var i = 0
    for fila in t.tablero:
        for col in fila:
            if col == 1:
                estado[i] = 1
            elif col == -1:
                estado[i+9] = 1
            i+=1
    if t.quien_juega == 1:
        for j in countup(0,8):
            estado[j+18] = 1
    return estado


proc copia*(t:Tablero):Tablero=
    var nuevo_tablero = newSeq[seq[int]](3)
    for i in countup(0,2):
        nuevo_tablero[i] = newSeq[int](3)
        for j in countup(0,2):
            nuevo_tablero[i][j] = t.tablero[i][j]
    newTateti(nuevo_tablero,t.quien_juega)


proc getTablero*(ju:Tablero):seq[seq[int]]=
    var nuevo_tablero = newSeq[seq[int]](3)
    for i in countup(0,2):
        nuevo_tablero[i] = newSeq[int](3)
        for j in countup(0,2):
            nuevo_tablero[i][j] = ju.tablero[i][j]
    nuevo_tablero

proc getQuienJuega*(j:Tablero):int=
    j.quien_juega


proc applyAccion*(t: var Tablero,idaccion:int)=
    var id = 0
    for i in countup(0,2):
        for j in countup(0,2):
            if id == idaccion:
                if t.quien_juega==1 :
                    t.tablero[i][j] = 1
                    t.quien_juega = -1
                else:
                    t.tablero[i][j] = -1
                    t.quien_juega = 1
            id += 1
    

proc isHorizontalLine(t:Tablero,fila:int):int=
    let ceros = any(t.tablero[fila],proc(x:int):bool = x == 0)
    if ceros:
        return 0
    var esCruz = t.tablero[fila][0] == 1 
    for j in t.tablero[fila]:
        if esCruz:
            if j != 1:
                return 0
        else:
            if j == 1:
                return 0
    if t.quien_juega == -1:
        if esCruz:
            return -1
        else:
            return 1
    else:
        if esCruz:
            return 1
        else:
            return -1
    
proc isVerticalLine*(t:Tablero,col:int):int=
    var hayCeros=false
    for i in countup(0,2):
        if t.tablero[i][col] == 0:
            hayCeros=true
            break
    if hayCeros:
        return 0
    var esCruz = t.tablero[0][col] == 1 
    for j in countup(0,2):
        if esCruz:
            if t.tablero[j][col] != 1:
                return 0
        else:
            if t.tablero[j][col] == 1:
                return 0
    if t.quien_juega == -1:
        if esCruz:
            return -1
        else:
            return 1
    else:
        if esCruz:
            return 1
        else:
            return -1

proc isDiagonalLines(t:Tablero):int=
    var esCero1 = false
    var esCero2 = false
    for i in countup(0,2):
        if not esCero1:
            if t.tablero[i][i] == 0 :
                esCero1 = true
        if not esCero2:
            if t.tablero[i][2-i] == 0 :
                esCero2 = true
    if esCero1 and esCero2:
        #echo "Ambos son ceros"
        return 0
    if not esCero1:
        var esCruz1= t.tablero[0][0] == 1
        for i in countup(0,2):
            #echo t.tablero[i][i]
            if esCruz1:
                if t.tablero[i][i] != 1:
                    return 0
            else:
                if t.tablero[i][i] == 1:
                    return 0
        if t.quien_juega == -1:
            if esCruz1:
                return -1
            else:
                return 1
        else:
            if esCruz1:
                return -1
            else:
                return 1
    if not esCero2:
        var esCruz2= t.tablero[0][2] == 1
        for i in countup(0,2):
            if esCruz2:
                if t.tablero[i][2-i] != 1:
                    return 0
            else:
                if t.tablero[i][2-i] == 1:
                    return 0
        if t.quien_juega == -1:

            if esCruz2:
                return -1
            else:
                return 1
        else:
            if esCruz2:
                return 1
            else:
                return -1


proc isTerminal*(t:Tablero):bool=
    var hayCeros=false
    for i in countup(0,2):
        var res = isHorizontalLine(t,i)
        if res != 0:
            return true
        res = isVerticalLine(t,i)
        if res != 0 :
            return true
        for j in countup(0,2):
            if t.tablero[i][j]==0:
                hayCeros = true
    var res = isDiagonalLines(t)
    if res != 0:
        return true
    if not hayCeros:
        return true
    return false

proc reward*(t:Tablero):int=
    for i in countup(0,2):
        var res = isHorizontalLine(t,i)
        if res != 0:
            return res
        res = isVerticalLine(t,i)
        if res != 0 :
            return res
    var res = isDiagonalLines(t)
    return res

proc legalAcciones*(t:Tablero):seq[int]=
    if t.isTerminal():
        return @[]
    var acciones = newSeq[int](0)
    var id=0 
    for fila in t.tablero:
        for col in fila:
            if col == 0:
                acciones.add(id)
            id += 1
    acciones

    



