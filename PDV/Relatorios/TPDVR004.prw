#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TPDVR004
Imprimir leitura de encerrantes

@author Totvs TBC
@since 08/08/2019
@version 1.0

@return ${return}, ${return_description}

@param dDataMov, date, data do movimento

@type function
/*/

User Function TPDVR004(dDataMov)

    Local aBicos	   		:= {}
    Local aProdutos	  		:= {}
    Local nLarg         	:= 48 //considera o cupom de 48 posições
    Local cTxtEncerrante	:= ""
    Local cTxtProdutos		:= ""      
    Local nVias             := 1 //numero de vias (2 - uma para o cliente outra para a estabelecimento)
    Local nX
    Local aArea   	   		:= GetArea()

    Default dDataMov        := dDataBase

    // Faz conexao na central para buscar valores dos bicos
    CursorArrow()
    STFCleanInterfaceMessage()

    STFMessage(ProcName(),"STOP","Realizando consulta dos encerrantes dos bicos. Aguarde...")
    STFShowMessage(ProcName())

    CursorWait()

    aParam := {dDataMov}
    aParam := {"U_TPDVR4AA",aParam}
    aRet   := Nil
    If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN", aParam,,, @aRet)

        // Tratamento do erro de conexao
        STFMessage(ProcName(), "ALERT", "Consulta de dados: falha de comunicação com a Central PDV..." )
        STFShowMessage(ProcName())

        CursorArrow()
        Return .F.

    ElseIf ValType(aRet)=="A" .and. Len(aRet)>0

        aBicos := aClone(aRet)

    Else

        // Tratamento para retorno vazio
        STFMessage(ProcName(), "ALERT", "Não foram localizados dados de encerrantes dos bicos!" )
        STFShowMessage(ProcName())

        CursorArrow()
        Return .F.

    EndIf

    CursorArrow()

    // precorre o array de bicos para impressão
    If Len(aBicos) > 0
        
        ASORT(aBicos,,,{|x, y| x[01] < y[01]}) //ordenação crescente pelo código do bico
        
        // percorro o array de bicos para fazer a somatória
        // crio um array de produtos, totalizando as quantidades dos bicos do mesmo produto
        For nX := 1 To Len(aBicos)
            
            nPosProd := aScan(aProdutos,{|x| AllTrim(x[1]) = AllTrim(aBicos[nX,3])})
            
            // se o produto já existir no array
            If nPosProd > 0
                aProdutos[nPosProd,2] += aBicos[nX,6]
            Else
                aadd(aProdutos,{aBicos[nX,3],aBicos[nX,6]})
            EndIf
            
        Next nX
        
        cTxtEncerrante := Replicate("-",nLarg) + CRLF
        cTxtEncerrante += "-" + PADC("CONTROLE DE ENCERRANTES",nLarg - 2) + "-" + CRLF
        
        // monto a string dos bicos
        For nX := 1 To Len(aBicos)     
        
            // Bico + Encerrante inicial + encerrante final + volume
            // B1 EI100 EF200,000 V100,000
            cTxtEncerrante += Replicate("-",nLarg) + CRLF
            cTxtEncerrante += "B" + AllTrim(aBicos[nX,1])
            cTxtEncerrante += " EI" + AllTrim(Transform(aBicos[nX,4],"@E 999,999,999.999"))
            cTxtEncerrante += " EF" + AllTrim(Transform(aBicos[nX,5],"@E 999,999,999.999"))
            cTxtEncerrante += " V"  + AllTrim(Transform(aBicos[nX,6],"@E 999,999,999.999"))
            cTxtEncerrante += CRLF
            cTxtEncerrante += Replicate("-",nLarg) + CRLF
            
        Next nX
        
        If Len(aProdutos) > 0
            
            cTxtProdutos := Replicate("-",nLarg) + CRLF
            cTxtProdutos += "-" + PADC("ACUMULADOR DE ABASTECIMENTOS",nLarg - 2) + "-" + CRLF
            
            For nX := 1 To Len(aProdutos)
                
                // COMBUSTIVEL: GASOLINA COMUM
                // VOLUME VENDIDO: 100,000
                cTxtProdutos += Replicate("-",nLarg) + CRLF
                cTxtProdutos += "COMBUSTIVEL: " + AllTrim(Posicione("SB1",1,xFilial("SB1") + aProdutos[nX,1],"B1_DESC")) + CRLF
                cTxtProdutos += "VOLUME VENDIDO: " + AllTrim(Transform(aProdutos[nX,2],"@E 999,999,999.999")) + CRLF
                cTxtProdutos += Replicate("-",nLarg) + CRLF
                
            Next nX 
            
        EndIf
        
    EndIf    

    //função para impressão
    For nX:=1 to nVias

        // imprime o relatório gerencial de encerrantes
        If !Empty(cTxtEncerrante)
            //parametro nVias=1 para fazer o corte
            STWManagReportPrint( cTxtEncerrante , 1/*nVias*/ )
        EndIf		

        // imprime o relatório gerencial de volumes
        If !Empty(cTxtProdutos) 
            //parametro nVias=1 para fazer o corte
            STWManagReportPrint( cTxtProdutos , 1/*nVias*/ )
        EndIf   
        
    Next nX

    STFMessage(ProcName(), "ALERT", "Relatorio de encerrantes impresso com sucesso!" )
    STFShowMessage(ProcName())

    RestArea(aArea)

Return .T.

/*
    Retorna os bicos e seus valores de encerrantes
*/
User Function TPDVR4AA(dDataMov)

    Local cCodBico	   		:= ""
    Local cNumBico			:= ""
    Local cProduto	   		:= ""
    Local nQtdAferic   		:= 0
    Local nQtdVenda	   		:= 0
    Local nQtdAberto   		:= 0
    Local nEncAnt	   		:= 0
    Local nEncAtu	   		:= 0
    Local aBicos	   		:= {}

    Local aArea   	   		:= GetArea()
    Local aAreaMID 	   		:= (cTabMID)->(GetArea())
    Local aAreaMIC 	   		:= MIC->(GetArea())

    MID->(DbOrderNickname("MID_004")) //MID_FILIAL+DTOS(MID_DATACO)+MID_XPROD+MID_CODBIC+MID_CODTAN
    MIC->(DbSetOrder(3)) //MIC_FILIAL+MIC_CODBIC+MIC_CODTAN

    MIC->(DbGoTop())
    MIC->(DbSeek(xFilial("MIC")))

    // zero as variáveis do bico
    cCodBico := MIC->MIC_CODBIC
    cNumBico := MIC->MIC_NLOGIC + "/" + MIC->MIC_LADO
    If MIC->(!Eof())
        cProduto := Posicione("MHZ",1,xFIlial("MHZ")+MIC->MIC_CODTAN,"MHZ_CODPRO")
    Else
        cProduto := ""
    EndIf

    While MIC->(!Eof()) .and. MIC->MIC_FILIAL = xFilial("MIC")

        //If MIC->MIC_STATUS = "1" // se o bico estiver ativado
        If ((MIC->MIC_STATUS = '1' .AND. MIC->MIC_XDTATI <= dDataMov) .OR. (MIC->MIC_STATUS = '2' .AND. MIC->MIC_XDTDES >= dDataMov))
            
            If MID->(DbSeek(xFilial("MID")+DtoS(dDataMov)+cProduto+MIC->MIC_CODBIC+MIC->MIC_CODTAN))
                While MID->(!Eof()) .AND. MID->MID_FILIAL = xFilial("MID") .AND. DtoS(MID->MID_DATACO) = DtoS(dDataMov) .AND. MID->MID_CODBIC = MIC->MIC_CODBIC .AND. MID->MID_XPROD== cProduto
            
                    If MID->MID_AFERIR == "S" // aferição
                        nQtdAferic += MID->MID_LITABA
                    Elseif MID->MID_NUMORC = Padr("P",TAMSX3("MID_NUMORC")[1]) .or. MID->MID_NUMORC = Padr("O",TAMSX3("MID_NUMORC")[1]) // abastecimento pendente ou em orçamento
                        nQtdAberto += MID->MID_LITABA
                    ElseIf !Empty(MID->MID_NUMORC) .and. Len(AllTrim(MID->MID_NUMORC)) = TAMSX3("MID_NUMORC")[1] // abastecimento finalizado
                        nQtdVenda += MID->MID_LITABA
                    EndIf
                    
                    MID->(DbSkip())
                    
                    // se o bico for alterado, zero os totalizadores e pego os encerrantes deste bico
                    If MIC->MIC_CODBIC <> MID->MID_CODBIC
                        
                        // encerrante do último abastecimento do dia anterior
                        nEncAnt := LastMIDDay(cCodBico,dDataMov - 1)
                        
                        // encerrante do último abastecimento do dia atual
                        nEncAtu := LastMIDDay(cCodBico,dDataMov)
                        
                        // adiciono os dados no array de bicos
                        aadd(aBicos,{cCodBico,cNumBico,cProduto,nEncAnt,nEncAtu,nQtdAferic + nQtdVenda + nQtdAberto})
                        
                        // zero as variáveis totalizadoras
                        nQtdAferic 	:= 0
                        nQtdVenda 	:= 0
                        nQtdAberto 	:= 0
                        
                    EndIf
                    
                EndDo
            Else
            
                // encerrante do último abastecimento do dia anterior
                nEncAnt := LastMIDDay(cCodBico,dDataMov - 1)
                
                // encerrante do último abastecimento do dia atual
                nEncAtu := LastMIDDay(cCodBico,dDataMov)
                
                // adiciono os dados no array de bicos
                aadd(aBicos,{cCodBico,cNumBico,cProduto,nEncAnt,nEncAtu,nQtdAferic + nQtdVenda + nQtdAberto})
                
                // zero as variáveis totalizadoras
                nQtdAferic 	:= 0
                nQtdVenda 	:= 0
                nQtdAberto 	:= 0
                
            EndIf
        EndIf
        
        MIC->(DbSkip())
        
        // zero as variáveis do bico
        cCodBico := MIC->MIC_CODBIC
        cNumBico := MIC->MIC_NLOGIC + "/" + MIC->MIC_LADO
        If MIC->(!Eof())
            cProduto := Posicione("MHZ",1,xFIlial("MHZ")+MIC->MIC_CODTAN,"MHZ_CODPRO")
        Else
            cProduto := ""
        EndIf
        
    EndDo

    RestArea(aAreaMID)
    RestArea(aAreaMIC)
    RestArea(aArea)

Return(aBicos)

/*
    Função que verifica o último (maior) encerrante do bico em uma data
*/
Static Function LastMIDDay(cCodBic,dDataAbast)

    Local nRet			:= 0
    Local cQry

    Local aArea 		:= GetArea()
    Local aAreaMID 		:= MID->(GetArea())

    cQry := "SELECT MAX(MID_ENCFIN) nULTIMO "
    cQry += " FROM " + RetSqlName("MID")
    cQry += " WHERE MID_FILIAL = '" + xFilial("MID") + "' "
    cQry += "   AND MID_CODBIC = '" + cCodBic + "' "
    cQry += "   AND MID_DATACO <= '" + DTOS(dDataAbast) + "' "
    cQry := ChangeQuery(cQry)

    If Select("QAUX") > 0
        QAUX->(dbCloseArea())
    EndIf

    TcQuery cQry NEW Alias "QAUX"

    If QAUX->(!Eof())
        nRet := QAUX->nULTIMO
    EndIf

    QAUX->(dbCloseArea())

    // restauro as áreas
    RestArea(aAreaMID)
    RestArea(aArea)

Return(nRet)
