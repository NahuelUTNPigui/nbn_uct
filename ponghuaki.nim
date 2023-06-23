import juego
proc newPongHuaKi*(tablero:seq[seq[int]],quien_juega:int):Tablero=
    Tablero(tablero:tablero,quien_juega:quien_juega)

proc newPongHuaKiFromSchatch*():Tablero=
    var tablero = @[
        @[1,0,1],
        @[-1,0,-1]
    ]
    var quien_juega=1
    newPongHuaKi(tablero,quien_juega)

proc getState*(jueg:Tablero):seq[float] =
    var estado=newSeq[float](15)
    var idx=0
    for i in countup(0,1):
        for j in countup(0,2):
            if i != 1 and j!=1:
                if jueg.tablero[i][j] == 1:
                    estado[idx]=1.0
                if jueg.tablero[i][j] == -1:
                    estado[idx+5]=1.0
                idx += 1
    if jueg.quien_juega==1:
        for i in countup(0,4):
            estado[idx+10]=1.0
    estado

proc copia*(jueg:Tablero):Tablero=
    var tablero = @[
        @[0,0,0],
        @[0,0,0]
    ]
    for i in countup(0,1):
        for j in countup(0,2):
            tablero[i][j] =jueg.tablero[i][j]
    newPongHuaKi(tablero,jueg.quien_juega)

proc legalAcciones*(j:Tablero):seq[int]=
    # Las acciones
    var acciones = newSeq[int]()
    #0
    let c00 = j.tablero[0][0]
    #1
    let c02 = j.tablero[0][2]
    #2
    let c11 = j.tablero[0][1]
    #3
    let c20 = j.tablero[1][0]
    #4
    let c22 = j.tablero[1][2]
    if c00 == 1:
        if c11 == 0:
            acciones.add(02)
        if c20 == 0:
            acciones.add(03)
    if c02 == 1:
        if c11 == 0:
            acciones.add(12)
        if c22 == 0:
            acciones.add(14)
    if c11 == 1:
        if c00 == 0:
            acciones.add(20)
        if c02 == 0:
            acciones.add(21)
        if c20 == 0:
            acciones.add(23)
        if c22 == 0:
            acciones.add(24)
    if c20 == 1:
        if c00 == 0:
            acciones.add(30)
        if c11 == 0:
            acciones.add(32)
        if c22 == 0:
            acciones.add(34)
    if c22 == 1:
        if c02 == 0:
            acciones.add(41)
        if c11 == 0:
            acciones.add(42)
        if c20 == 0:
            acciones.add(43)
    acciones



proc applyAccion*(j:var Tablero,idaccion:int)=
    let origen = idaccion div 10
    let destino = idaccion mod 10
    for i in countup(0,1):
        for jdx in countup(0,2):
            if j.tablero[i][jdx] == 1:
                
                j.tablero[i][jdx] = -1
            elif j.tablero[i][jdx] == -1:
                j.tablero[i][jdx] = 1
    case origen:
        of 0:
            j.tablero[0][0]=0
        of 1:
            j.tablero[0][2]=0
        of 2:
            j.tablero[0][1]=0
        of 3:
            j.tablero[1][0]=0
        else:
            j.tablero[1][2]=0
    case destino:
        of 0:
            j.tablero[0][0] = -1
        of 1:
            j.tablero[0][2] = -1
        of 2:
            j.tablero[0][1] = -1
        of 3:
            j.tablero[1][0] = -1
        else:
            j.tablero[1][2] = -1
    
    if j.quien_juega==1:
        j.quien_juega=2
    else:
        j.quien_juega=1
                
proc cambiarVista*(j:Tablero):Tablero=
    var tablero = @[
        @[0,0,0],
        @[0,0,0]
    ]
    for i in countup(0,1):
        for jdx in countup(0,2):
            if i != 1 and jdx!=1:
                if j.tablero[i][jdx] == 1:
                    tablero[i][jdx] = -1
                if j.tablero[i][jdx] == -1:
                    tablero[i][jdx] = 1
    var quien_juega = 1
    if j.quien_juega==1:
        quien_juega=2
    newPongHuaKi(tablero,quien_juega)
# Saber si el juego termino
proc isTerminal*(j:Tablero):bool=
    let acccions= j.legalAcciones()
    return acccions.len == 0
proc reward*(j:Tablero):int=
    -1