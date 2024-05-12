#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TPDVP015 (StClsVCash)
Validacao antes fechar o caixa.

@author pablo
@since 15/04/2019
@return lRet, Logico, Retorno .T. continua fechamento ou .F. não pode fechar caixa
/*/
User Function TPDVP015()

	Local lRet := .T.
	Local aParam, xResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.
	Local lValAbast := SuperGetMV("TP_FCHABAS",,.F.) //No fechamento de caixa, valida se possui abastecimentos pendêntes (default .F.)
    Local aDtConf := {}

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

//Caso o parâmetro TP_FCHABAS estiver ativo, não deixa fechar o caixa, caso existam abastecimentos pendêntes
	If lValAbast

		CursorWait()

        aDtConf := STDDtAbCx()
		aParam := {aDtConf[1]} //aDtConf[1] - Data de Abertura;
		aParam := {"U_TPDVP15A",aParam}
		If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@xResult,/*cType*/,/*cKeyOri*/, @nCodRet )
			// Se retornar esses codigos siginifica que a central esta off
			lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
			// Verifica erro de execucao por parte do host
			//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
			lHostError := (nCodRet == -103 .OR. nCodRet == -106)

			If lHostError
				STFMessage("TPDVP15A","STOP", "Erro de conexão central PDV: " + cValtoChar(nCodRet) )
				STFShowMessage("TPDVP15A")
				Conout("TPDVP15A - Erro de conexão central PDV: " + cValtoChar(nCodRet))
				
			EndIf

		ElseIf nCodRet == -101 .OR. nCodRet == -108
			STFMessage("TPDVP15A","STOP", "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet) )
			STFShowMessage("TPDVP15A")
			Conout( "TPDVP15A - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
			
		Else
			STFMessage("TPDVP15A","STOP", "Erro de conexão central PDV: " + cValtoChar(nCodRet) )
			STFShowMessage("TPDVP15A")
			Conout("TPDVP15A - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			
		EndIf

		lRet := lRet .AND. lHasConnect .AND. ValType(xResult)=="N" .AND. !(xResult>0)

		If !lRet 
			Aviso( "Atenção!", "Existem "+cValToChar(xResult)+" abastecimentos pendêntes, com data menor ou igual a 'Dt. Abertura' ("+DtoC(aDtConf[1])+"). Para continuar com o fechamento de caixa, favor baixar todos abastecimentos pendêntes."+CRLF+CRLF+"Essa validação foi ativada pelo parâmetro: [TP_FCHABAS].", {"Ok"} )
		EndIf

		CursorArrow()
	EndIf

Return lRet

/*/{Protheus.doc} TPDVP15A
Retorna se possui abastecimentos pendêntes.

@author pablo
@since 17/06/2022
@return nQtdPend, Numérico, Retorna a quantidade de abastecimentos pendêntes.
/*/
User Function TPDVP15A(dDtAbert)

	Local nQtdPend := 0 //quantidade de abastecimentos pendêntes
	Local cQry

	Local aArea 		:= GetArea()
	Local aAreaMID 		:= MID->(GetArea())

	LjGrvLog("TPDVP15A","Retorna se possui abastecimentos pendêntes.",)

	cQry := "SELECT 1 "+CRLF
    cQry += " FROM " + RetSQLName("MID") + " MID "+CRLF
    cQry += " WHERE MID_FILIAL = '" + xFilial("MID") + "'"+CRLF
    cQry += " AND D_E_L_E_T_ = ' ' "+CRLF
    cQry += " AND MID_DATACO <= '" + DtoS(dDtAbert) + "' "+CRLF
    //-- Vamos carregas 2 situações:
    //-- 	P => Abastecimentos pendentes que vieram da bomba
    //-- 	O => Abastecimentos selecionados para finalizacao da venda
    cQry += " AND (MID_NUMORC = 'P' OR MID_NUMORC = 'O')"+CRLF

	LjGrvLog("TPDVP15A","Query de abastecimentos pendentes:",cQry)
	
	cQry := ChangeQuery(cQry)

	If Select("QAUX") > 0
		QAUX->(dbCloseArea())
	EndIf

	TcQuery cQry NEW Alias "QAUX"

	QAUX->(DbGoTop())
	If QAUX->(!Eof())
		QAUX->(dbEval({|| nQtdPend++})) //existe abastecimento pendênte
	EndIf

	QAUX->(dbCloseArea())

	// restauro as áreas
	RestArea(aAreaMID)
	RestArea(aArea)

	LjGrvLog("TPDVP15A","Retorno da busca de abastecimentos pendêntes.",nQtdPend)

Return nQtdPend
