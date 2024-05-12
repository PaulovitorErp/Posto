#Include "Protheus.ch"
#Include "RwMake.ch"


/*/{Protheus.doc} FA330QRY
O ponto de entrada FA330QRY está na função Fa330Tit() que possibilita criar e manipular a query.

@obs
Ponto de entra para editar a query que ira montar o MarkBrowser da tela de selecao dos titulos na compensacao

@author Totvs TBC
@since 04/11/2016
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETP036()

Local cQuery := PARAMIXB[1]
Local cQTemp := ""
Local cNota  := ""
Local lQryCompen := SuperGetMV("TP_HFA330Q",,.T.) //Habilita a manipulação de query na FINA330 - compensação de valores (PE FA330QRY) ? (default .T.)

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return cQuery
EndIf

    If !lQryCompen
        Return cQuery
    EndIf

	If Alltrim(FUNNAME()) == "TRETA028" .or. IsInCallStack("U_TRETA028") //se chamado da conferencia
		cQuery := StrTran(cQuery, "WHERE ", "WHERE SE1.E1_FILIAL = '" + cFilAnt + "' AND ")
	EndIf

	If IsInCallStack("LOJA720") //Chamada pela rotina de Troca/Devolução
		cQTemp := "WHERE ("
		SD1->(DbSetOrder(1)) //D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
		SD1->(DbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
		If SD1->(!Eof()) 
			cNota := ""
			While SD1->(!Eof()) .and. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) = (xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)
				If !Empty(SD1->D1_NFORI) .and. !Empty(SD1->D1_SERIORI) .and. cNota <> (SD1->D1_SERIORI + SD1->D1_NFORI)
					cQTemp += "(SE1.E1_PREFIXO = '" + SD1->D1_SERIORI + "' AND SE1.E1_NUM = '" + SD1->D1_NFORI + "') OR " //NF Origem
					cNota := (SD1->D1_SERIORI + SD1->D1_NFORI)
				EndIf
				SD1->(DbSkip())
			EndDo
		EndIf
		cQTemp += "(SE1.E1_PREFIXO = '" + SF1->F1_SERIE + "' AND SE1.E1_NUM = '" + SF1->F1_DOC + "') OR " //NF Devolução
		cQTemp += "(SE1.E1_PREFIXO = '" + SF2->F2_SERIE + "' AND SE1.E1_NUM = '" + SF2->F2_DOC + "') " //NF Avulsa
		cQTemp += ") AND "

		cQuery := StrTran(cQuery, "WHERE ", cQTemp)
	EndIf

Return cQuery
