#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} TRETE027
JOB para limpar Preços Negociados da Base POSTO

@author Totvs GO
@since 14/01/2015
@version 1.0
@return Nulo

@type function
/*/
User Function TRETE027 //U_TRETE027()

//TODO: VERIFICAR ONDE CHAMAR ESSA FUNÇÃO, POIS EXISTE UMA ROTINA DE TROCA DE TURNO ONDE 
//PODERÁ TER ACESSO EXCLUSIVO A TABELA DE PREÇOS NEGOCIADOS.

	Local dDtExclus := dDataBase - 2
	Local cCondicao		:= ""
	Local bCondicao
	Local cAliasSX2 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela

	If !isBlind()
		If !MsgYesNo("Serão excluidos os preços negociados NÃO VIGENTES da base PDV. Deseja Prosseguir?","Atenção")
			Return
		EndIf
		#IFDEF TOP
			MsgAlert("Esta rotina nao pode ser executada em ambiente TOPCON.","Atenção")
			Return
   		#ENDIF
	EndIf

    DbSelectArea("U25")
	
	cCondicao := " U25_FILIAL == '"+xFilial("U25")+"' "	
   	cCondicao += "	.AND. !empty(U25_DTFIM) " 
   	cCondicao += "	.AND. DTOS(U25_DTFIM) <= '"+DTOS(dDtExclus)+"' " 
   	//cCondicao += "	.AND. U25_FLAGREPLICA " 
	
	// limpo os filtros da U25
	U25->(DbClearFilter())
	
	// executo o filtro na U25
	bCondicao 	:= "{|| " + cCondicao + " }"
	U25->(DbSetFilter(&bCondicao,cCondicao))
	U25->(DbGoTop())
	
	while U25->(!Eof())
		cChvRep := U25->U25_FILIAL+U25->U25_REPLIC
		RecLock("U25", .F.)   
			U25->(DbDelete())
		U25->(MsUnlock())
		U_UREPLICA("U25", 1, cChvRep, "E")
		U25->(DbSkip())
	enddo

	U25->(DbClearFilter())	
	U25->(DbCloseArea())

	// abre o dicionário SX2
	OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX2, "SX2", NIL, .F.)
	lOpen := Select(cAliasSX2) > 0

	// caso aberto, posiciona no topo
	If !(lOpen)
		Return .F.
	EndIf
	DbSelectArea(cAliasSX2)
	(cAliasSX2)->( DbSetOrder( 1 ) ) //X2_CHAVE
	(cAliasSX2)->( DbGoTop() )

	If (cAliasSX2)->( DbSeek("U25") )
		USE (Alltrim((cAliasSX2)->&("X2_PATH"))+Alltrim((cAliasSX2)->&("X2_ARQUIVO"))) ALIAS ("TMP") EXCLUSIVE NEW VIA "DBF"
		If NetErr()
	 		//conout("TRETE027 PACK: Nao foi possivel abrir U25 em modo EXCLUSIVO.")	 
		Else
		 	PACK //realiza pack (limpa os registros da tabela) 
			USE
			//conout("TRETE027 PACK: Registros da tabela U25 eliminados com sucesso.")
		EndIf
	EndIf
	
Return
