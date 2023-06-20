import manu
import random
import math
import std/sequtils
#import parseutils
randomize()
#Clases
type
    Peso = object
        valor : float
        valido: bool
    RedNBN2 = object
        config :seq[seq[int]]
        padres :seq[seq[int]]
        pesos_inputs:seq[seq[Peso]]
        pesos_deltas:seq[seq[Peso]]
        output_neurons:seq[int]
        dummies:int
        cantidad_pesos:int
        activ:proc(x:float):float
        der_activ:proc(x:float):float
proc makeRandomSeqPesos(M,N:int):seq[seq[Peso]]=
    var seqPeso:seq[seq[Peso]] = @[]
    for i in countup(0,M-1,1):
        var fila:seq[Peso]= @[]
        for j in countup(0,N-1,1):
            fila.add(Peso(valor:rand(1.0)*2 - 1.0,valido:false))
        seqPeso.add(fila)
    seqPeso
proc setParent(padres: var seq[seq[int]],son:int,big_father:int,config:seq[seq[int]],dummies:int)=
    let linea = config[son-dummies]
    for son_son in linea:
        if son_son != son and son_son >= dummies:
            if not any(padres[son_son-dummies],proc(x:int):bool=x==big_father):
                setParent(padres,son_son,big_father,config,dummies)
    if not any(padres[son-dummies],proc(x:int):bool=x==big_father):    
        padres[son-dummies].add(big_father)
proc isParent(padres:seq[seq[int]],son:int,big_father:int,dummies:int):bool=
    any(padres[son-dummies],proc(x:int):bool=x==big_father)

proc toStringPesosMtx(mtx:seq[seq[Peso]]):string=
    var s = ""
    for f_i in countup(0,mtx.len-1,1):
        
        s &= "\n[ "
        for c_j in countup(0,mtx[0].len-1,1):
            s &= "| "
            if mtx[f_i][c_j].valido: s &= $round(mtx[f_i][c_j].valor,2) else: s &= "cero"
            s &= " |"
        s &= " ]"
    s


proc newRedNBN2*(dummies:int,config:seq[seq[int]],output_neurons:seq[int]):RedNBN2=
    var pesos_inputs=makeRandomSeqPesos(config.len,dummies+1)
    var pesos_deltas=makeRandomSeqPesos(config.len,config.len)
    var padres=newSeq[seq[int]](config.len)
    var j=0
    var cantidad_pesos = 0
    #echo pesos_inputs.toStringPesosMtx
    #echo "Deltas"
    #echo pesos_deltas.toStringPesosMtx
    for fila in config:
        padres[j]=newSeq[int]()
        let id_fila=fila[0]-dummies
        cantidad_pesos += 1
        for i in countup(1,fila.len-1,1):
            #echo "pessos inputs"
            #echo id_fila
            #La ultima columna es el bias y siempre es valido
            pesos_inputs[id_fila][dummies].valido=true
            #echo "pessos inputs 2"
            if(fila[i]<dummies):
                pesos_inputs[id_fila][fila[i]].valido=true
                cantidad_pesos += 1
            else:
                let id_neurona_inp=fila[i]-dummies
                
                pesos_deltas[id_neurona_inp][id_fila].valido=true
                
                cantidad_pesos += 1
        j += 1

    for i in countdown(config.len-1,0,1):
        let linea=config[i]
        for son in linea:
            if son>=dummies and not any(padres[son-dummies],proc(x:int):bool=x==linea[0]):
                setParent(padres,son,linea[0],config,dummies)
    
    RedNBN2(config:config,output_neurons:output_neurons,dummies:dummies,pesos_inputs:pesos_inputs,pesos_deltas:pesos_deltas,cantidad_pesos:cantidad_pesos,padres:padres)



proc sigmoide(x:float):float=
    1/(1+exp(-x))
proc der_sigmoide(x:float):float=
    sigmoide(x)*(1-sigmoide(x))
proc relu(x:float):float=
    if x>=0:
        x
    else:
        0
proc der_relu(x:float):float=
    if x>=0:
        1
    else:
        0

proc distributiva(j:var seq[float],n:float)=
    for i in countup(0,j.len-1,1):
        j[i] *= n
proc predict*(red: RedNBN2,input:seq[float]):seq[float]=
    var salida=newSeq[float](red.pesos_inputs.len)
    for fila_i in countup(0,red.pesos_inputs.len-1,1):
        var suma = red.pesos_inputs[fila_i][red.dummies].valor
        for inp in countup(0,input.len-1,1):
            if(red.pesos_inputs[fila_i][inp].valido):
                suma += red.pesos_inputs[fila_i][inp].valor*input[inp]
        if fila_i!=0:
            for fila_pesos_delta in countup(0,fila_i-1,1):
                if(red.pesos_deltas[fila_pesos_delta][fila_i].valido):
                    suma += salida[fila_pesos_delta]*red.pesos_deltas[fila_pesos_delta][fila_i].valor
        if any(red.output_neurons,proc(x:int):bool = fila_i + red.dummies == x):
            #echo "Es salida: " & $(fila_i + red.dummies)
            salida[fila_i]=sigmoide(suma)
        else:
            salida[fila_i]=relu(suma)
    var output:seq[float]= @[]
    
    for o in red.output_neurons:
        output.add(salida[o-red.dummies])
    output


proc sfmax(vect:seq[float]):seq[float]=
    var suma = 0.0
    var nuevo_seq:seq[float] = @[]
    for valor in vect:
        let expi = exp(valor)
        suma += expi
        nuevo_seq.add(expi)
    nuevo_seq.distributiva(1/suma)
    nuevo_seq
proc argmax(vect:seq[float]):seq[float]=
    var nuevo_vec = newSeq[float](vect.len)
    let idx = vect.maxIndex
    nuevo_vec[idx] = 1.0
    nuevo_vec
proc predict_softmax*(red: RedNBN2,input:seq[float]):seq[float]=
    var salida=newSeq[float](red.pesos_inputs.len)
    for fila_i in countup(0,red.pesos_inputs.len-1,1):
        var suma = red.pesos_inputs[fila_i][red.dummies].valor
        for inp in countup(0,input.len-1,1):
            if(red.pesos_inputs[fila_i][inp].valido):
                suma += red.pesos_inputs[fila_i][inp].valor*input[inp]
        if fila_i!=0:
            for fila_pesos_delta in countup(0,fila_i-1,1):
                if(red.pesos_deltas[fila_pesos_delta][fila_i].valido):
                    suma += salida[fila_pesos_delta]*red.pesos_deltas[fila_pesos_delta][fila_i].valor
        if any(red.output_neurons,proc(x:int):bool = fila_i + red.dummies == x):
            #echo "Es salida: " & $(fila_i + red.dummies)
            salida[fila_i]=sigmoide(suma)
        else:
            salida[fila_i]=relu(suma)
    var output:seq[float]= @[]
    
    for o in red.output_neurons:
        output.add(salida[o-red.dummies])
    sfmax(output)
proc predict_argmax*(red: RedNBN2,input:seq[float]):seq[float]=
    var salida=newSeq[float](red.pesos_inputs.len)
    for fila_i in countup(0,red.pesos_inputs.len-1,1):
        var suma = red.pesos_inputs[fila_i][red.dummies].valor
        for inp in countup(0,input.len-1,1):
            if(red.pesos_inputs[fila_i][inp].valido):
                suma += red.pesos_inputs[fila_i][inp].valor*input[inp]
        if fila_i!=0:
            for fila_pesos_delta in countup(0,fila_i-1,1):
                if(red.pesos_deltas[fila_pesos_delta][fila_i].valido):
                    suma += salida[fila_pesos_delta]*red.pesos_deltas[fila_pesos_delta][fila_i].valor
        if any(red.output_neurons,proc(x:int):bool = fila_i + red.dummies == x):
            #echo "Es salida: " & $(fila_i + red.dummies)
            salida[fila_i]=sigmoide(suma)
        else:
            salida[fila_i]=relu(suma)
    var output:seq[float]= @[]
    
    for o in red.output_neurons:
        output.add(salida[o-red.dummies])
    argmax(output)
proc actualizar_gr(red: var RedNBN2,j:seq[float],o_n:int,alfa:float)=
    var pesos_i = 0
    for nn_i in countup(0,red.config.len-1,1):
        if isParent(red.padres,nn_i + red.dummies,o_n,red.dummies):
            for c_inp in countup(0,red.dummies,1):
                if red.pesos_inputs[nn_i][c_inp].valido:
                    red.pesos_inputs[nn_i][c_inp].valor -= j[pesos_i]*alfa
                    pesos_i += 1
            for ny_i in countup(0,nn_i-1,1):
                if red.pesos_deltas[ny_i][nn_i].valido:
                    red.pesos_deltas[ny_i][nn_i].valor -= j[pesos_i]*alfa
                    pesos_i += 1

proc learn_gr2*(red: var RedNBN2, iteraciones:int,alfa:float,max_error:float,inputs:seq[seq[float]],outputs:seq[seq[float]],verbose=false):float=
    var error=0.0
    var prev_error=0.0
    for iter in countup(1, iteraciones,1):
        if verbose:
            echo "Iter: ",iter

        var salida=newSeq[float](red.config.len)
        var der_salida=newSeq[float](red.config.len)
        prev_error=error
        error=0
        
        for p_i in countup(0,inputs.len-1,1):
            
            let inp_exp=inputs[p_i]
            if verbose:
                echo "patter"
                echo inp_exp
            let out_exp=outputs[p_i]
            salida=newSeq[float](red.config.len)
            der_salida=newSeq[float](red.config.len)
            #k
            for nn_i in countup(0,red.config.len-1,1):
                #salida de las neuronas
                var suma= red.pesos_inputs[nn_i][red.dummies].valor
                for inp_i in countup(0,red.dummies-1,1):
                    if red.pesos_inputs[nn_i][inp_i].valido:
                        suma += red.pesos_inputs[nn_i][inp_i].valor * inp_exp[inp_i]
                for nx_i in countup(0,nn_i-1,1):
                    if red.pesos_deltas[nx_i][nn_i].valido:
                        suma += red.pesos_deltas[nx_i][nn_i].valor * salida[nx_i]
                let o_n = red.output_neurons
                let dm=red.dummies
                
                if any(o_n,proc(x:int):bool = x == nn_i + dm):
                    salida[nn_i] = sigmoide suma
                    der_salida[nn_i] = der_sigmoide suma
                else:
                    salida[nn_i] = relu suma
                    der_salida[nn_i] = der_relu suma
                #calcular los deltas
                for ny_i in countdown(nn_i,0,1):
                    if ny_i == nn_i:
                        red.pesos_deltas[nn_i][nn_i].valido=true
                        red.pesos_deltas[nn_i][nn_i].valor=der_salida[nn_i]
                    else:
                        if isParent(red.padres,ny_i + red.dummies, nn_i + red.dummies,red.dummies):
                            var xkj=0.0
                            for i in countup(ny_i,nn_i-1,1):
                                if red.pesos_deltas[i][nn_i].valido and red.pesos_deltas[i][ny_i].valido:
                                    xkj += red.pesos_deltas[i][nn_i].valor * red.pesos_deltas[i][ny_i].valor
                            var dkj= xkj * red.pesos_deltas[nn_i][nn_i].valor
                            red.pesos_deltas[nn_i][ny_i].valido=true
                            red.pesos_deltas[nn_i][ny_i].valor=dkj
                #o aca calculo el jacobiano?
            #Aca viene calcular le jacobiano
            for o_i in countup(0, out_exp.len-1,1):
                let o_neurona = red.output_neurons[o_i]
                var j =newSeq[float]()
                
                for nn_i in countup(0,red.config.len-1,1):
                    let derivadas_neurona_out=red.pesos_deltas[o_neurona-red.dummies][nn_i].valor
                    if isParent(red.padres,nn_i + red.dummies,o_neurona,red.dummies):
                        for c_inp in countup(0,red.dummies,1):
                            if red.pesos_inputs[nn_i][c_inp].valido:
                                if c_inp==red.dummies:
                                    j.add(derivadas_neurona_out)
                                else:
                                    j.add(derivadas_neurona_out * inp_exp[c_inp])
                        for nx_i in countup(0,nn_i-1,1):
                            if red.pesos_deltas[nx_i][nn_i].valido:
                                j.add(derivadas_neurona_out * salida[nx_i])
                let diff=salida[o_neurona-red.dummies]-out_exp[o_i]
                if verbose:
                    echo "o_n: ",o_neurona
                    echo "Diff: ",diff
                j.distributiva(diff)
                error += abs(diff)
                if verbose:
                    echo "j"
                    echo j
                if verbose:
                    echo "Pesos deltas antes"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs antes"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
                actualizar_gr(red,j,o_neurona,alfa)
                if verbose:
                    echo "Pesos deltas despues"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs despues"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
        if verbose:
            echo "Error: ",error
        if error < max_error or abs(prev_error - error) <= max_error:
            if verbose:
                echo "Iter ",iter
            return error
    error

proc learn_ce*(red: var RedNBN2, iteraciones:int,alfa:float,max_error:float,inputs:seq[seq[float]],outputs:seq[seq[float]],verbose=false):float=
    var error=0.0
    var prev_error=0.0
    var i = 0
    for iter in countup(1, iteraciones,1):
        i += 1
        if verbose:
            echo "Iter: ",iter

        var salida=newSeq[float](red.config.len)
        var der_salida=newSeq[float](red.config.len)
        prev_error=error
        error=0
        
        for p_i in countup(0,inputs.len-1,1):
            
            let inp_exp=inputs[p_i]
            if verbose:
                echo "patter"
                echo inp_exp
            let out_exp=outputs[p_i]
            salida=newSeq[float](red.config.len)
            der_salida=newSeq[float](red.config.len)
            #k
            for nn_i in countup(0,red.config.len-1,1):
                #salida de las neuronas
                var suma= red.pesos_inputs[nn_i][red.dummies].valor
                for inp_i in countup(0,red.dummies-1,1):
                    if red.pesos_inputs[nn_i][inp_i].valido:
                        suma += red.pesos_inputs[nn_i][inp_i].valor * inp_exp[inp_i]
                for nx_i in countup(0,nn_i-1,1):
                    if red.pesos_deltas[nx_i][nn_i].valido:
                        suma += red.pesos_deltas[nx_i][nn_i].valor * salida[nx_i]
                let o_n = red.output_neurons
                let dm=red.dummies
                # aca esta el chiste para el cros entrpy
                if any(o_n,proc(x:int):bool = x == nn_i + dm):
                    salida[nn_i] = sigmoide suma
                    der_salida[nn_i] = der_sigmoide suma
                else:
                    salida[nn_i] = relu suma
                    der_salida[nn_i] = der_relu suma
                #calcular los deltas
                for ny_i in countdown(nn_i,0,1):
                    if ny_i == nn_i:
                        red.pesos_deltas[nn_i][nn_i].valido=true
                        red.pesos_deltas[nn_i][nn_i].valor=der_salida[nn_i]
                    else:
                        if isParent(red.padres,ny_i + red.dummies, nn_i + red.dummies,red.dummies):
                            var xkj=0.0
                            for i in countup(ny_i,nn_i-1,1):
                                if red.pesos_deltas[i][nn_i].valido and red.pesos_deltas[i][ny_i].valido:
                                    xkj += red.pesos_deltas[i][nn_i].valor * red.pesos_deltas[i][ny_i].valor
                            var dkj= xkj * red.pesos_deltas[nn_i][nn_i].valor
                            red.pesos_deltas[nn_i][ny_i].valido=true
                            red.pesos_deltas[nn_i][ny_i].valor=dkj
                #o aca calculo el jacobiano?
            var output:seq[float]= @[]
    
            for o in red.output_neurons:
                output.add(salida[o-red.dummies])
            let prob = sfmax(output)
            let prob_arg = argmax(output)
            #Aca viene calcular le jacobiano
            for o_i in countup(0, out_exp.len-1,1):
                let o_neurona = red.output_neurons[o_i]
                var j =newSeq[float]()
                
                for nn_i in countup(0,red.config.len-1,1):
                    let derivadas_neurona_out=red.pesos_deltas[o_neurona-red.dummies][nn_i].valor
                    if isParent(red.padres,nn_i + red.dummies,o_neurona,red.dummies):
                        for c_inp in countup(0,red.dummies,1):
                            if red.pesos_inputs[nn_i][c_inp].valido:
                                if c_inp==red.dummies:
                                    j.add(derivadas_neurona_out)
                                else:
                                    j.add(derivadas_neurona_out * inp_exp[c_inp])
                        for nx_i in countup(0,nn_i-1,1):
                            if red.pesos_deltas[nx_i][nn_i].valido:
                                j.add(derivadas_neurona_out * salida[nx_i])
                # o aca esta, creo que aca esta
                var corrector=prob[o_i]
                let diff = prob_arg[o_i] - out_exp[o_i]
                if out_exp[o_i] > 0.0:
                    corrector -= 1.toFloat          
                if verbose:
                    echo "o_n: ",o_neurona
                    echo "Diff: ",corrector
                j.distributiva(corrector)
                error += abs(diff)
                if verbose:
                    echo "j"
                    echo j
                if verbose:
                    echo "Pesos deltas antes"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs antes"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
                actualizar_gr(red,j,o_neurona,alfa)
                if verbose:
                    echo "Pesos deltas despues"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs despues"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
        if verbose:
            echo "Error: ",error
        if error < max_error:# or abs(prev_error - error) <= max_error:
            if verbose:
                echo "Iter ",iter
            #echo i
            return error
    #echo i
    error
proc learn_adam*(red: var RedNBN2, iteraciones:int,alfa,beta1,beta2:float,max_error:float,inputs:seq[seq[float]],outputs:seq[seq[float]],verbose=false):float=
    var error=0.0
    var prev_error=0.0
    var cantidad_pesos_salida:seq[int] = @[]
    var emes:seq[Matrix[float]] = @[]
    var ves:seq[float] = @[]

    for o_i in countup(0,red.output_neurons.len-1):
        var suma = 0
        for nn_i in countup(0,red.config.len-1):
            if isParent(red.padres,nn_i + red.dummies, red.output_neurons[o_i],red.dummies):
                for c_inp in countup(0,red.dummies,1):
                    if red.pesos_inputs[nn_i][c_inp].valido:
                        if c_inp==red.dummies:
                            suma += 1
                        else:
                            suma += 1
                for nx_i in countup(0,nn_i-1,1):
                    if red.pesos_deltas[nx_i][nn_i].valido:
                        suma += 1
        cantidad_pesos_salida.add(suma)
        emes.add(matrix(suma,1,0.0))
        ves.add(0.0)
    for iter in countup(1, iteraciones,1):
        #echo "Iter: ",iter
        if verbose:
            echo "Iter: ",iter

        var salida=newSeq[float](red.config.len)
        var der_salida=newSeq[float](red.config.len)
        prev_error=error
        error=0
        
        for p_i in countup(0,inputs.len-1,1):
            
            let inp_exp=inputs[p_i]
            if verbose:
                echo "patter"
                echo inp_exp
            let out_exp=outputs[p_i]
            salida=newSeq[float](red.config.len)
            der_salida=newSeq[float](red.config.len)
            #k
            for nn_i in countup(0,red.config.len-1,1):
                #salida de las neuronas
                var suma= red.pesos_inputs[nn_i][red.dummies].valor
                for inp_i in countup(0,red.dummies-1,1):
                    if red.pesos_inputs[nn_i][inp_i].valido:
                        suma += red.pesos_inputs[nn_i][inp_i].valor * inp_exp[inp_i]
                for nx_i in countup(0,nn_i-1,1):
                    if red.pesos_deltas[nx_i][nn_i].valido:
                        suma += red.pesos_deltas[nx_i][nn_i].valor * salida[nx_i]
                let o_n = red.output_neurons
                let dm=red.dummies
                if any(o_n,proc(x:int):bool = x == nn_i + dm):
                    salida[nn_i] = sigmoide suma
                    der_salida[nn_i] = der_sigmoide suma
                else:
                    salida[nn_i] = relu suma
                    der_salida[nn_i] = der_relu suma
                #calcular los deltas
                for ny_i in countdown(nn_i,0,1):
                    if ny_i == nn_i:
                        red.pesos_deltas[nn_i][nn_i].valido=true
                        red.pesos_deltas[nn_i][nn_i].valor=der_salida[nn_i]
                    else:
                        if isParent(red.padres,ny_i + red.dummies, nn_i + red.dummies,red.dummies):
                            var xkj=0.0
                            for i in countup(ny_i,nn_i-1,1):
                                if red.pesos_deltas[i][nn_i].valido and red.pesos_deltas[i][ny_i].valido:
                                    xkj += red.pesos_deltas[i][nn_i].valor * red.pesos_deltas[i][ny_i].valor
                            var dkj= xkj * red.pesos_deltas[nn_i][nn_i].valor
                            red.pesos_deltas[nn_i][ny_i].valido=true
                            red.pesos_deltas[nn_i][ny_i].valor=dkj
                #o aca calculo el jacobiano?
            
            #Aca viene calcular le jacobiano
            for o_i in countup(0, out_exp.len-1,1):
                let o_neurona = red.output_neurons[o_i]
                var j =newSeq[float]()
                
                for nn_i in countup(0,red.config.len-1,1):
                    let derivadas_neurona_out=red.pesos_deltas[o_neurona-red.dummies][nn_i].valor
                    if isParent(red.padres,nn_i + red.dummies,o_neurona,red.dummies):
                        for c_inp in countup(0,red.dummies,1):
                            if red.pesos_inputs[nn_i][c_inp].valido:
                                if c_inp==red.dummies:
                                    j.add(derivadas_neurona_out)
                                else:
                                    j.add(derivadas_neurona_out * inp_exp[c_inp])
                        for nx_i in countup(0,nn_i-1,1):
                            if red.pesos_deltas[nx_i][nn_i].valido:
                                j.add(derivadas_neurona_out * salida[nx_i])
                let diff=salida[o_neurona-red.dummies]-out_exp[o_i]
                if verbose:
                    echo "o_n: ",o_neurona
                    echo "Diff: ",diff
                j.distributiva(diff)
                #echo "j"
                #echo j
                # aca hago lo de los ms ves  y arreglo los pesos
                let vector_ge=matrix(j,j.len)
                #echo emes[o_i]
                #echo vector_ge
                #echo m
                emes[o_i] = beta1 * emes[o_i] + (1-beta1) * vector_ge
                ves[o_i] = beta2 * ves[o_i] + (1-beta2) * vector_ge.norm2
                let m_hat = emes[o_i] / (1-pow(beta1,iter.toFloat))
                let v_hat = ves[o_i] / (1-pow(beta2,iter.toFloat))
                let error_peso = alfa * m_hat / (sqrt(v_hat)+0.0000001)
                if verbose:
                    echo "emes"
                    echo emes
                    echo "ves"
                    echo ves
                    echo "error_peso"
                    echo error_peso
                    
                error += abs(diff)
                if verbose:
                    echo "j"
                    echo j
                    echo "j norm"
                    echo matrix(j,j.len).norm2
                if verbose:
                    echo "Pesos deltas antes"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs antes"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
                # j seria una version modificada 
                #echo error_peso.transpose.getArray()[0]
                actualizar_gr(red,error_peso.transpose.getArray()[0],o_neurona,alfa)
                
                if verbose:
                    echo "Pesos deltas despues"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs despues"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
        if verbose:
            echo "Error: ",error
        if error < max_error or abs(prev_error - error) <= max_error:
            if verbose:
                echo "Iter ",iter
            return error
    error
proc learn_adam_cross*(red: var RedNBN2, iteraciones:int,alfa,beta1,beta2:float,max_error:float,inputs:seq[seq[float]],outputs:seq[seq[float]],verbose=false):float=
    var error=0.0
    var prev_error=0.0
    var cantidad_pesos_salida:seq[int] = @[]
    var emes:seq[Matrix[float]] = @[]
    var ves:seq[float] = @[]

    for o_i in countup(0,red.output_neurons.len-1):
        var suma = 0
        for nn_i in countup(0,red.config.len-1):
            if isParent(red.padres,nn_i + red.dummies, red.output_neurons[o_i],red.dummies):
                for c_inp in countup(0,red.dummies,1):
                    if red.pesos_inputs[nn_i][c_inp].valido:
                        if c_inp==red.dummies:
                            suma += 1
                        else:
                            suma += 1
                for nx_i in countup(0,nn_i-1,1):
                    if red.pesos_deltas[nx_i][nn_i].valido:
                        suma += 1
        cantidad_pesos_salida.add(suma)
        emes.add(matrix(suma,1,0.0))
        ves.add(0.0)
    var i=0
    for iter in countup(1, iteraciones,1):
        i += 1
        #echo "Iter: ",iter
        if verbose:
            echo "Iter: ",iter

        var salida=newSeq[float](red.config.len)
        var der_salida=newSeq[float](red.config.len)
        prev_error=error
        error=0
        
        for p_i in countup(0,inputs.len-1,1):
            
            let inp_exp=inputs[p_i]
            if verbose:
                echo "patter"
                echo inp_exp
            let out_exp=outputs[p_i]
            salida=newSeq[float](red.config.len)
            der_salida=newSeq[float](red.config.len)
            #k
            for nn_i in countup(0,red.config.len-1,1):
                #salida de las neuronas
                var suma= red.pesos_inputs[nn_i][red.dummies].valor
                for inp_i in countup(0,red.dummies-1,1):
                    if red.pesos_inputs[nn_i][inp_i].valido:
                        suma += red.pesos_inputs[nn_i][inp_i].valor * inp_exp[inp_i]
                for nx_i in countup(0,nn_i-1,1):
                    if red.pesos_deltas[nx_i][nn_i].valido:
                        suma += red.pesos_deltas[nx_i][nn_i].valor * salida[nx_i]
                let o_n = red.output_neurons
                let dm=red.dummies
                if any(o_n,proc(x:int):bool = x == nn_i + dm):
                    salida[nn_i] = sigmoide suma
                    der_salida[nn_i] = der_sigmoide suma
                else:
                    salida[nn_i] = relu suma
                    der_salida[nn_i] = der_relu suma
                #calcular los deltas
                for ny_i in countdown(nn_i,0,1):
                    if ny_i == nn_i:
                        red.pesos_deltas[nn_i][nn_i].valido=true
                        red.pesos_deltas[nn_i][nn_i].valor=der_salida[nn_i]
                    else:
                        if isParent(red.padres,ny_i + red.dummies, nn_i + red.dummies,red.dummies):
                            var xkj=0.0
                            for i in countup(ny_i,nn_i-1,1):
                                if red.pesos_deltas[i][nn_i].valido and red.pesos_deltas[i][ny_i].valido:
                                    xkj += red.pesos_deltas[i][nn_i].valor * red.pesos_deltas[i][ny_i].valor
                            var dkj= xkj * red.pesos_deltas[nn_i][nn_i].valor
                            red.pesos_deltas[nn_i][ny_i].valido=true
                            red.pesos_deltas[nn_i][ny_i].valor=dkj
                #o aca calculo el jacobiano?
            var output:seq[float]= @[]
    
            for o in red.output_neurons:
                output.add(salida[o-red.dummies])
            let prob = sfmax(output)
            let prob_arg = argmax(output)
            #Aca viene calcular le jacobiano
            for o_i in countup(0, out_exp.len-1,1):
                let o_neurona = red.output_neurons[o_i]
                var j =newSeq[float]()
                
                for nn_i in countup(0,red.config.len-1,1):
                    let derivadas_neurona_out=red.pesos_deltas[o_neurona-red.dummies][nn_i].valor
                    if isParent(red.padres,nn_i + red.dummies,o_neurona,red.dummies):
                        for c_inp in countup(0,red.dummies,1):
                            if red.pesos_inputs[nn_i][c_inp].valido:
                                if c_inp==red.dummies:
                                    j.add(derivadas_neurona_out)
                                else:
                                    j.add(derivadas_neurona_out * inp_exp[c_inp])
                        for nx_i in countup(0,nn_i-1,1):
                            if red.pesos_deltas[nx_i][nn_i].valido:
                                j.add(derivadas_neurona_out * salida[nx_i])
                var corrector=prob[o_i]
                let diff = prob_arg[o_i] - out_exp[o_i]
                if out_exp[o_i] > 0.0:
                    corrector -= 1.toFloat          
                if verbose:
                    echo "o_n: ",o_neurona
                    echo "Diff: ",corrector
                j.distributiva(corrector)
                error += abs(diff)
                #echo "j"
                #echo j
                # aca hago lo de los ms ves  y arreglo los pesos
                let vector_ge=matrix(j,j.len)
                #echo emes[o_i]
                #echo vector_ge
                #echo m
                emes[o_i] = beta1 * emes[o_i] + (1-beta1) * vector_ge
                ves[o_i] = beta2 * ves[o_i] + (1-beta2) * vector_ge.norm2
                let m_hat = emes[o_i] / (1-pow(beta1,iter.toFloat))
                let v_hat = ves[o_i] / (1-pow(beta2,iter.toFloat))
                let error_peso = alfa * m_hat / (sqrt(v_hat)+0.0000001)
                if verbose:
                    echo "emes"
                    echo emes
                    echo "ves"
                    echo ves
                    echo "error_peso"
                    echo error_peso
                    
                error += abs(diff)
                if verbose:
                    echo "j"
                    echo j
                    echo "j norm"
                    echo matrix(j,j.len).norm2
                if verbose:
                    echo "Pesos deltas antes"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs antes"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
                # j seria una version modificada 
                #echo error_peso.transpose.getArray()[0]
                actualizar_gr(red,error_peso.transpose.getArray()[0],o_neurona,alfa)
                
                if verbose:
                    echo "Pesos deltas despues"
                    echo toStringPesosMtx(red.pesos_deltas)
                    echo ""
                    echo "pesos inputs despues"
                    echo toStringPesosMtx(red.pesos_inputs)
                    echo ""
        if verbose:
            echo "Error: ",error
        if error < max_error:# or abs(prev_error - error) <= max_error:
            if verbose:
                echo "Iter ",iter
            echo "iter: " & $i
            return error
    echo "iter: " & $i
    echo error
    error

