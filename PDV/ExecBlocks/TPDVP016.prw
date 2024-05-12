#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TRETP016 (StOpenFCash)
PE Após abertura do caixa no PDV
Prepara para consultar cheques trocos que serão transferidos para usuario PDV.

@author Rafael Brito
@since 03/05/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function TPDVP016()

	Local aItensCh	:= {}
	Local lOpenCash := ParamIxb[1]
//Local cStation := ParamIxb[2]
	Local lMvXGERENT := SuperGetMv("MV_XGERENT",,.F.)
	Local nViasAd := SuperGetMv("TP_SSVIASA",,0) //Define numero de vias adicionais para sangria e suprimentos
	Local nX := nVlrOpen := 0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	//LjGrvLog("TPDVP016", "(StOpenFCash) Antes chamada consulta de cheques. lOpenCash=" + iif(lOpenCash,".T.",".F.") )

	If lOpenCash
		aItensCh := U_TPDVP16A()
		If Len(aItensCh)>0
			U_TRETR013(3,aItensCh) //impressao dos cheques transfereridos
		EndIf

		//Tratamento para Bloqueio por Senha Vendedor
		U_TPDVE013()

		//tratamento para limpar filtros caixas combo abertura caixa
		If lMvXGERENT
			U_TPDVE014(2)
		EndIf

		//Tratamentos vias adicionais sangria e suprimento
		If nViasAd > 0
			nVlrOpen := U_T024VOpe() //verifico se digitou algo no campo valor inicial
			If nVlrOpen > 0
				For nX :=1 to nViasAd
					//StaticCall(STBSupplyBleeding, STBImpSupNFCE, 2, nVlrOpen)
					&("StaticCall(STBSupplyBleeding, STBImpSupNFCE, 2, nVlrOpen)")
				Next nX
			EndIf
		EndIf

	EndIf

Return

//------------------------------------------------------------------------------
// Pega lista dos cheques a sem impressos
//------------------------------------------------------------------------------
User Function TPDVP16A()

	Local aDados 	:= {}
	//Local cAlias	:= ""
	//Local cCondicao	:= ""
	Local cPdv		:= LJGetStation("LG_PDV") //codigo do PDV
	Local cCaixa  	:= xNumCaixa()
	Local lChTrOp 	:= SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)
	//Local bCondicao
	Local cQry := ""

	DbSelectArea("UF2")

	#IFDEF TOP

		cQry := "SELECT UF2_BANCO, UF2_AGENCI, UF2_CONTA, UF2_SEQUEN, UF2_NUM, UF2_VALOR "
		cQry += " FROM " + RetSqlName("UF2") + " UF2 "
		cQry += " WHERE UF2.D_E_L_E_T_ = ' ' "
		cQry += " AND UF2_FILIAL = '" + xFilial("UF2") + "' "
		If lChTrOp
			cQry += " AND UF2_CODCX = '" + PadR(cCaixa,TamSx3("UF2_CODCX")[1]) + "' "
		Else
			cQry += " AND UF2_PDV = '" + PadR(cPdv,TamSx3("UF2_PDV")[1]) + "' "
		EndIf
		cQry += " AND UF2_DOC = '"+Space(TamSx3("UF2_DOC")[1])+"' "
		cQry += " AND UF2_SERIE = '"+Space(TamSx3("UF2_SERIE")[1])+"' "
		cQry += " AND UF2_STATUS <> '2' AND UF2_STATUS <> '3' "
		cQry += " ORDER BY UF2_FILIAL, UF2_BANCO, UF2_AGENCI, UF2_CONTA, UF2_NUM"

		If Select("QAUX") > 0
			QAUX->(dbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QAUX"

		If QAUX->(!Eof())
			While QAUX->(!Eof())
				aadd(aDados, {"LBOK",QAUX->UF2_BANCO,QAUX->UF2_AGENCI,QAUX->UF2_CONTA,QAUX->UF2_SEQUEN,QAUX->UF2_NUM,QAUX->UF2_VALOR}) // Array que sera usado na impressao do relatorio
				QAUX->( dbskip() )
			EndDo
		EndIf

		QAUX->(dbCloseArea())

	#ELSE

		cAlias := "UF2"
		// Busco cheques que estao amarrados ao PDV
		cCondicao := " UF2_FILIAL = '" + xFilial("UF2") + "'"
		If lChTrOp
			cCondicao += " .AND. UF2_PDV = '" + PadR(cPdv,TamSx3("UF2_PDV")[1]) + "'"
		Else
			cCondicao += " .AND. UF2_CODCX = '" + PadR(cCaixa,TamSx3("UF2_CODCX")[1]) + "'"
		EndIf
		cCondicao += " .AND. UF2_STATUS <> '2' .AND. UF2_STATUS <> '3'"

		//LjGrvLog("TPDVP16A", "Filtrando cheques. cCondicao = " + cCondicao)

		// limpo os filtros da UF2
		//(cAlias)->(DbClearFilter())

		// executo o filtro na UF2
		//bCondicao 	:= "{|| " + cCondicao + " }"
		//(cAlias)->(DbSetFilter(&bCondicao,cCondicao))

		DbSelectArea("UF2")
		//(CALIAS)->(DbSetOrder(1)) //UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM
		(CALIAS)->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV

		// vou para a primeira linha
		(CALIAS)->(DbGoTop())

		(CALIAS)->(DbSeek(xFilial("UF2")+SPACE(TamSx3("UF2_DOC")[1])+SPACE(TamSx3("UF2_SERIE")[1])+cPdv))

		While (cAlias)->(!EOF())
			If &(AllTrim(cCondicao))
				aadd(aDados, {"LBOK",(cAlias)->UF2_BANCO,(cAlias)->UF2_AGENCI,(cAlias)->UF2_CONTA,(cAlias)->UF2_SEQUEN,(cAlias)->UF2_NUM,(cAlias)->UF2_VALOR}) // Array que sera usado na impressao do relatorio
			EndIf
			(cAlias)->(DbSkip())
		EndDo

		// limpo os filtros da UF2
		//(CALIAS)->(DbClearFilter())

	#ENDIF

Return aDados
