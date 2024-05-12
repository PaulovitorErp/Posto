#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TPDVE008
Ajusta a saida de caixa da SE5 e gera NCC do vale haver

@author Pablo Cavalcante
@since 08/07/2014
@version 1.0
@return ${return}, ${return_description}
@param nVale, numeric, valor do vale haver

@type function
/*/
User Function TPDVE008(nVale)

Local aArea		:= GetArea()
Local aAreaSE5  := SE5->(GetArea())
Local aAreaSA6	:= SA6->(GetArea())
Local cTmp		:= GetNextAlias()
Local cPrefixo 	:= IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)
Local cNum 		:= IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC)
Local cNumPdv	:= SL1->L1_PDV
Local cBanco    := "" //banco do operador
Local cAgencia  := ""
Local cNumCon   := ""
Local cData     := dtos(SL1->L1_EMISNF)
Local cCliente  := SL1->L1_CLIENTE
Local cLoja     := SL1->L1_LOJA
Local aDados 	:= {}
Local cIdFKAux  := ""
Local lOk := .T.
Local dBkpDBase := dDataBase

Local nE1_VALOR := 0
Default nVale   := 0

SA6->(DbSetOrder(1))
If (SA6->(DbSeek( xFilial("SA6") + SL1->L1_OPERADO))) //posiciona no banco do caixa (operador) que finalizou a venda

	// inicio o controle de transação
	BeginTran()

	cBanco    := SA6->A6_COD
	cAgencia  := SA6->A6_AGENCIA
	cNumCon   := SA6->A6_NUMCON
	// Ajusto a SE5
	// E5_MOEDA = 'TC' e E5_TIPODOC $ 'VL/TR'
	// indice 2 -E5_FILIAL+E5_TIPODOC+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DtoS(E5_DATA)+E5_CLIFOR+E5_LOJA+E5_SEQ
	BeginSql Alias cTmp
	
		SELECT *
		FROM %table:SE5% SE5
			WHERE SE5.E5_FILIAL = %xFilial:SE5%
			AND (SE5.E5_TIPODOC = %Exp:'VL'% OR SE5.E5_TIPODOC = %Exp:'TR'%)
			AND SE5.E5_PREFIXO = %Exp:cPrefixo%
			AND SE5.E5_NUMERO = %Exp:cNum%
			AND SE5.E5_BANCO = %Exp:cBanco%
			AND SE5.E5_AGENCIA = %Exp:cAgencia%
			AND SE5.E5_CONTA = %Exp:cNumCon%
			AND SE5.E5_DATA = %Exp:cData%
			AND SE5.E5_MOEDA = %Exp:'TC'%
			AND SE5.E5_VALOR > 0
			AND SE5.%NotDel%
			//AND SE5.E5_CLIFOR = %Exp:cCliente%
			//AND SE5.E5_LOJA = %Exp:cLoja%
	
	EndSql
	
	While !(cTmp)->(EOF()) .and. nVale > 0
		dbselectarea("SE5")
		SE5->(dbgoto( (cTmp)->R_E_C_N_O_ ))
		
		If SE5->E5_VALOR <= nVale
			nE1_VALOR += SE5->E5_VALOR
			nVale -= SE5->E5_VALOR
			
			cIdFKAux := SE5->E5_IDORIG
			lOk := .T.
			If ExistFunc("LjNewGrvTC") .And. LjNewGrvTC() //Verifica se o sistema est?atualizado para executar o novo procedimento para grava?o dos movimentos de troco.
				aDados := {}
				//cDescErro:=""
				lMsErroAuto := .F.
				aAdd( aDados, {"E5_DATA"    , SE5->E5_DATA     	, NIL} )
				aAdd( aDados, {"E5_MOEDA" 	, SE5->E5_MOEDA    	, NIL} )
				aAdd( aDados, {"E5_VALOR"   , SE5->E5_VALOR    	, NIL} )
				aAdd( aDados, {"E5_NATUREZ" , SE5->E5_NATUREZ  	, NIL} )
				aAdd( aDados, {"E5_BANCO" 	, SE5->E5_BANCO  	, NIL} )
				aAdd( aDados, {"E5_AGENCIA" , SE5->E5_AGENCIA  	, NIL} )
				aAdd( aDados, {"E5_CONTA" 	, SE5->E5_CONTA  	, NIL} )
				aAdd( aDados, {"E5_HISTOR" 	, SE5->E5_HISTOR  	, NIL} )
				aAdd( aDados, {"E5_TIPOLAN" , SE5->E5_TIPOLAN  	, NIL} )

				MsExecAuto( {|w,x, y| FINA100(w, x, y)}, 0, aDados, 5 ) //5=Exclusão de Movimento

				If lMsErroAuto
					//cDescErro:= MostraErro("\")
					//cDescErro := "Erro de Exclusão do troco na Rotina Automatica FINA100:" + Chr(13) + cDescErro 
					nE1_VALOR := 0 //zero para abortar
					lOk := .F.
					EXIT
				EndIf
			else
				RecLock("SE5", .F.)
				SE5->(DbDelete())
				SE5->(MsUnlock())
			endif

			//Excluindo as FK5 que fica la (são duas, do mov e estorno)
			if lOk .AND. !empty(cIdFKAux)
				FKA->(DbSetOrder(3)) //FKA_FILIAL+FKA_TABORI+FKA_IDORIG
				FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
				if FKA->(DbSeek(xFilial("FKA") +"FK5"+ cIdFKAux ))
					cIdFKAux := FKA->FKA_IDPROC
					FKA->(DbSetOrder(2)) //FKA_FILIAL+FKA_IDPROC+FKA_IDORIG+FKA_TABORI
					if FKA->(DbSeek(xFilial("FKA") + cIdFKAux ))
						While FKA->(!Eof()) .AND. FKA->FKA_FILIAL+FKA->FKA_IDPROC == xFilial("FKA") + cIdFKAux
							if FKA->FKA_TABORI == "FK5" .AND. FK5->(DbSeek(xFilial("FK5") + FKA->FKA_IDORIG ))
								RecLock("FK5", .F.)
								FK5->(DbDelete())
								FK5->(MsUnlock())
							endif
							FKA->(DbSkip())
						enddo
					endif
				endif
			endif

		Else
			RecLock("SE5")
			SE5->E5_VALOR -= nVale
			SE5->(MsUnlock())
			
			FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
			if !empty(SE5->E5_IDORIG) .AND. FK5->(DbSeek(xFilial("FK5") + SE5->E5_IDORIG ))
				RecLock("FK5", .F.)
				FK5->FK5_VALOR -= nVale
				FK5->(MsUnlock())
			endif

			nE1_VALOR += nVale
			nVale -= nVale
		EndIf
		
	(cTmp)->(dbskip())
	EndDo
	
	(cTmp)->( dbCloseArea() )
	
	//Conout("TPDVE008: INICIO INC VALE HAVER")
	// Felipe sousa - 26/04/2024
	// Ajustado para a data do cupom em caso de venda demorar explodir e virar de uma data para outra.
	dDataBase := SL1->L1_EMISNF
	// gera NCC do vale
	If nE1_VALOR > 0
		If U_IncVlHav(nE1_VALOR, cNum, cCliente, cLoja, dDataBase, cPrefixo, cNumPdv)
	   		DbCommitAll()
		Else
			nE1_VALOR := 0
			// cancelo a transação de inclusão
			DisarmTransaction()
		EndIf
	Else
		nE1_VALOR := 0
		// cancelo a transação de inclusão
		DisarmTransaction()
	EndIf
	// finalizo o controle de transação
	EndTran()
	
	dDataBase := dBkpDBase
	//Conout("TPDVE008: FIM INC VALE HAVER")
	
EndIf

RestArea(aAreaSA6)
RestArea(aAreaSE5)
RestArea(aArea)

Return(nE1_VALOR)

//----------------------------------------------------------------
// Inclui o titulo NCC do vale haver
//----------------------------------------------------------------
User Function IncVlHav(nValTit, cNum, cCliente, cLoja, dEmissao, cSerie, cNumPdv, cNatNcc)

	Local lRet 			:= .T.
	Private lMsErroAuto := .F. // variavel interna da rotina automatica
	Private lMsHelpAuto := .F.
	Default cNatNcc		:= SuperGetMV("MV_XNATNCC", /*lHelp*/, "OUTROS" /*cPadrao*/)
	
	//Conout("IncVlHav: INICIO EXECAUTO INC VALE HAVER")
	
	aFIN040 := {}
		
	AADD(aFIN040, {"E1_FILIAL"	,xFilial("SE1")		,Nil } )
	AADD(aFIN040, {"E1_PREFIXO"	,cSerie          	,Nil } ) //Modificado por Rafael
	AADD(aFIN040, {"E1_NUM"		,cNum    			,Nil } )
	AADD(aFIN040, {"E1_PARCELA"	,SubStr("VLH",1,TamSX3("E1_PARCELA")[1]),Nil } )//Modificado por Rafael //-> O NCC gerado com Vale Haver poderá ter um prefixo pré-definido de identificação. Ex.: "VLH".
	AADD(aFIN040, {"E1_TIPO"	,"NCC"      		,Nil } )
	AADD(aFIN040, {"E1_NATUREZ"	,cNatNcc			,Nil } )
	AADD(aFIN040, {"E1_CLIENTE"	,cCliente			,Nil } )
	AADD(aFIN040, {"E1_LOJA"	,cLoja				,Nil } )
	IF SE1->(FieldPos("E1_DTLANC")) > 0
		AADD(aFIN040, {"E1_DTLANC"	,dEmissao			,Nil } )
	EndIf
	AADD(aFIN040, {"E1_EMISSAO"	,dEmissao			,Nil } )
	AADD(aFIN040, {"E1_VENCTO"	,dEmissao			,Nil } )
	AADD(aFIN040, {"E1_VENCREA"	,DataValida(dEmissao),Nil } )
	AADD(aFIN040, {"E1_VALOR"	,nValTit			,Nil } )
	AADD(aFIN040, {"E1_NUMNOTA"	,cNum				,Nil } ) //chave do cupom E1_NUMNOTA
	AADD(aFIN040, {"E1_SERIE"	,cSerie				,Nil } ) //chave do cupom E1_SERIE
	AADD(aFIN040, {"E1_XPDV"	,cNumPdv			,Nil } )
	AADD(aFIN040, {"E1_ORIGEM" 	,"TPDVE008" 		,Nil } )
	
	// Chama a funcao de gravacao automatica do FINA040
	MSExecAuto({|x,y| FINA040(x,y)},aFIN040,3)
	
	//Conout("IncVlHav: FIM EXECAUTO INC VALE HAVER")
	
	If lMsErroAuto
		cErroExec := MostraErro("\temp")
 		//Conout(" ============ ERRO =============")
		//Conout(cErroExec)
		cErroExec := ""
		lRet := .F.
	EndIf

Return lRet
