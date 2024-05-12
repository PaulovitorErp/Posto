#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} M103XFIN
O ponto de entrada M103XFIN é responsável pela validação dos títulos financeiros, na exclusão do Documento de Entrada.
No término da função, permite alterar a validação e configurar se seus avisos serão exibidos.

@author Pablo Cavalcante
@since 19/11/2017
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETP026()

	Local aArea := GetArea()
	Local aAreaSA6	:= SA6->(GetArea())
	Local aAreaSD1	:= SD1->(GetArea())
	Local aAreaSL1	:= SL1->(GetArea())
	Local aAreaSLW 	:= SLW->(GetArea())
	Local aAreaSE1	:= SE1->(GetArea())
	Local lValida := .T.
	Local lAviso := .F.
	Local lAvisoISS := .F.
	Local cParcela := PadR(SuperGetMV("MV_1DUP"), TamSX3("E1_PARCELA")[1])
	Local cMV_XBCOCDV := AllTrim(SuperGetMV("MV_XBCOCDV",,""))	// Banco de Devoluções: banco + agencia + conta (A6_COD+A6_AGENCIA+A6_NUMCON)

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

//nota de devolução e exclusao
	If SF1->F1_TIPO == 'D'

		//posiciona no banco de devolução
		SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
		SA6->(DbSeek(xFilial("SA6")+cMV_XBCOCDV))

		//posiciona na nos itens da nota de devolução
		SD1->(DbSetOrder(1)) //D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
		If SD1->(DbSeek(xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)))

			//posiciona na NF de Origem
			SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			If SL1->(DbSeek(xFilial("SL1")+SD1->(D1_SERIORI+D1_NFORI)))

				//posiciona na SLW (caixa da nota de origem)
				SLW->(DbSetOrder(1)) //LW_FILIAL+LW_PDV+LW_OPERADO+DTOS(LW_DTABERT)+LW_NUMMOV
				SLW->(DbSeek(xFilial("SLW")+PadR(AllTrim(SL1->L1_PDV),TamSX3("LW_PDV")[1])+SL1->L1_OPERADO+DtoS(SL1->L1_EMISNF)+SL1->L1_NUMMOV))
				lOk := .F.
				While SLW->(!Eof()) .AND. !lOk
					If SL1->L1_FILIAL = SLW->LW_FILIAL ;
							.AND. (DtoS(SL1->L1_EMISNF)+SL1->L1_HORA) >= (DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT) ;
							.AND. (DtoS(SL1->L1_EMISNF)+SL1->L1_HORA) <= (DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA) ;
							.AND. SL1->L1_OPERADO = SLW->LW_OPERADO ;
							.AND. SL1->L1_NUMMOV = SLW->LW_NUMMOV ;
							.AND. AllTrim(SL1->L1_PDV) = AllTrim(SLW->LW_PDV) ;
							.AND. SL1->L1_ESTACAO = SLW->LW_ESTACAO

						lOk := .T.
						Exit //sai do While

					EndIf
					SLW->(DbSkip())
				EndDo

				If lOk
					//posiciona na NCC gerada
					SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
					If SE1->(DbSeek(xFilial("SE1")+SF1->F1_SERIE+SF1->F1_DOC+cParcela+"NCC"))
						//baixar a ncc
						If SE1->E1_SALDO <> SE1->E1_VALOR
							If ExBxNcc(SE1->(RecNo()))
								AJUSSNG(SA6->A6_COD, SF1->F1_VALBRUT)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaSLW)
	RestArea(aAreaSL1)
	RestArea(aAreaSD1)
	RestArea(aAreaSA6)
	RestArea(aArea)

Return {lValida,lAviso,lAvisoISS}

//
// Exclui baixa da NCC da devolução
//
Static Function ExBxNcc(nRec)

	Local aArea 	:= GetArea()
	Local aAreaSE1	:= SE1->(GetArea())
	Local lRet 		:= .T.
	Local _aBaixa 	:= {}

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	SE1->(DbGoto(nRec))

	_aBaixa := {;
		{"E1_PREFIXO"   ,SE1->E1_PREFIXO 	,Nil},;
		{"E1_NUM"       ,SE1->E1_NUM		,Nil},;
		{"E1_PARCELA"   ,SE1->E1_PARCELA	,Nil},;
		{"E1_TIPO"      ,SE1->E1_TIPO		,Nil},;
		{"E1_CLIENTE" 	,SE1->E1_CLIENTE 	,Nil},;
		{"E1_LOJA" 		,SE1->E1_LOJA 		,Nil}}

	MSExecAuto({|x,y| Fina070(x,y)}, _aBaixa, 6) // 3 - Baixa de Título, 5 - Cancelamento de baixa, 6 - Exclusão de Baixa.

	If lMsErroAuto
		MostraErro()
		lRet := .F.
	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)

Return(lRet)

//
// Ajusta sangria do caixa
//	>> função foi copiada do fonte ULOJA076 (a chamada via staticcall não estava funcionando)
//
Static Function AJUSSNG(cBanco,nValAnt)

	Local aArea		:= GetArea()
	Local aAreaSE5	:= SE5->(GetArea())
	Local _lxAlter1 := .F.
	Local cCondicao := ""
	Local bCondicao

	//Altera o troco final Operador
	cCondicao := " E5_FILIAL = '" + xFilial("SE5") + "'"
	cCondicao += " .AND. E5_BANCO == '"+SLW->LW_OPERADO+"' .AND. E5_NUMMOV == '"+SLW->LW_NUMMOV+"' .AND. Alltrim(E5_XPDV) == '"+Alltrim(SLW->LW_PDV)+"' .AND. E5_XESTAC == '"+SLW->LW_ESTACAO+"' "
	cCondicao += " .AND. (DTOS(E5_DATA) == '"+DTOS(SLW->LW_DTABERT)+"' .OR. DTOS(E5_DATA) == '"+DTOS(SLW->LW_DTFECHA)+"') "
	cCondicao += " .AND. AllTrim(E5_MOEDA)=='R$'.AND. AllTrim(E5_TIPODOC)=='TR' "
	cCondicao += " .AND. E5_VALOR == "+Str(nValAnt)

	bCondicao 	:= "{|| " + cCondicao + " }"

	SE5->(DbClearFilter())
	SE5->(DbSetFilter(&bCondicao,cCondicao))
	SE5->(dbOrderNickName("PDV01"))
	SE5->(DbGoTop())

	While SE5->(!EOF()) .AND. SE5->E5_FILIAL == xFilial("SE5")

		//verifico se o movimento está dentro da data e hora apontados na abertura e fechamento
		if DTOS(SE5->E5_DATA)+SE5->E5_XHORA 	>= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT ;
				.AND. DTOS(SE5->E5_DATA)+SE5->E5_XHORA 	<= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA  .AND. !empty(SE5->E5_XHORA)

			Reclock("SE5",.f.)
			SE5->(DbDelete())
			SE5->(MsUnlock())
			_lxAlter1:=.T.
			EXIT
		endif

		SE5->(dbSkip())
	EndDo

	If _lxAlter1==.T. //Se alterou o troco final do operador altera o troco final do caixa gerencial

		cCondicao := " E5_FILIAL = '" + xFilial("SE5") + "'"
		cCondicao += " .AND. E5_BANCO == '"+cBanco+"' .AND. E5_NUMMOV == '"+SLW->LW_NUMMOV+"' .AND. Alltrim(E5_XPDV) == '"+Alltrim(SLW->LW_PDV)+"' .AND. E5_XESTAC == '"+SLW->LW_ESTACAO+"' "
		cCondicao += " .AND. (DTOS(E5_DATA) == '"+DTOS(SLW->LW_DTABERT)+"' .OR. DTOS(E5_DATA) == '"+DTOS(SLW->LW_DTFECHA)+"') "
		cCondicao += " .AND. AllTrim(E5_MOEDA)=='R$'.AND. AllTrim(E5_TIPODOC)=='TR' "
		cCondicao += " .AND. E5_VALOR == "+Str(nValAnt)

		bCondicao 	:= "{|| " + cCondicao + " }"

		SE5->(DbClearFilter())
		SE5->(DbSetFilter(&bCondicao,cCondicao))
		SE5->(dbOrderNickName("PDV01"))
		SE5->(DbGoTop())

		While SE5->(!EOF()) .AND. SE5->E5_FILIAL == xFilial("SE5")

			//verifico se o movimento está dentro da data e hora apontados na abertura e fechamento
			if DTOS(SE5->E5_DATA)+SE5->E5_XHORA 	>= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT ;
					.AND. DTOS(SE5->E5_DATA)+SE5->E5_XHORA 	<= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA  .AND. !empty(SE5->E5_XHORA)

				Reclock("SE5",.f.)
				SE5->(DbDelete())
				SE5->(MsUnlock())
				EXIT
			endif

			SE5->(dbSkip())
		EndDo
	EndIf

	SE5->(DbClearFilter())

	RestArea(aAreaSE5)
	RestArea(aArea)

Return(Nil)
