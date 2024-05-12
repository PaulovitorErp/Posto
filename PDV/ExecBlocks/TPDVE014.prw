#include 'protheus.ch'
#include 'parmtype.ch'

Static aAreaSA6 := {}

/*/{Protheus.doc} TPDVE014
Função para filtrar bancos que irão aparecer no combobox da sangria e suprimento.
É chamado no PE TPVDP002 (STMenEdt)

@author danilo
@since 02/09/2020
@version 1.0
@type function
/*/
User Function TPDVE014(nOpc)

	Local nX
	Local cCondicao, bCondicao
	Local aStation
	Local cComboCx 
	Local aComboCx 
	Local aFilBancos := {} 
	Local cCodBanco := ""
	Local cCodAgen  := ""
	Local cNumCon   := ""
    Local lMvXGERENT := SuperGetMv("MV_XGERENT",,.F.)

    //somente se tem o campo A6_XGERENT que vai entrar na customização
	If lMvXGERENT
		If nOpc == 1

			LjGrvLog( "TPDVE014", "Antes de Filtrar SA6: ", SA6->A6_COD+"|"+SA6->A6_AGENCIA + "|" + SA6->A6_NUMCON )
			aAreaSA6 := SA6->(GetArea())

			aStation := STBInfoEst( 1, .T. ) // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS
			LjGrvLog( "TPDVE014", "aStation", aStation) 

			cComboCx   := AllTrim(SuperGetMv("MV_CXLOJA",.F.,"")) // Caixa Geral  
			If !Empty(cComboCx)
				aComboCx   := StrTokArr( cComboCx, '/' ) 
				cCodBanco  := PadR(aComboCx[1],TamSX3("A6_COD")[1],)
				cCodAgen   := PadR(aComboCx[2],TamSX3("A6_AGENCIA")[1],)
				cNumCon    := PadR(aComboCx[3],TamSX3("A6_NUMCON")[1],)
				aadd(aFilBancos, '(A6_COD == "'+cCodBanco+'" .AND. A6_AGENCIA == "'+cCodAgen+'" .AND. A6_NUMCON == "'+cNumCon+'")' )

				//se é multilo de 3 e tem mais que um conjunto
				If (len(aComboCx) % 3) == 0 .AND. (len(aComboCx) / 3) > 1
					For nX := 4 To len(aComboCx)
						cCodBanco  := PadR(aComboCx[nX],TamSX3("A6_COD")[1],)
						cCodAgen   := PadR(aComboCx[++nX],TamSX3("A6_AGENCIA")[1],)
						cNumCon    := PadR(aComboCx[++nX],TamSX3("A6_NUMCON")[1],)
						aadd(aFilBancos, '(A6_COD == "'+cCodBanco+'" .AND. A6_AGENCIA == "'+cCodAgen+'" .AND. A6_NUMCON == "'+cNumCon+'")' )
					Next nX
				EndIf
			EndIf

			cCondicao := 'A6_FILIAL == xFilial("SA6") .AND. A6_BLOCKED <> "1" .AND. ' //retiro os bloqueados
			cCondicao += '( A6_COD=="'+aStation[1]+'"' //deixo o caixa atual
			If SA6->(FieldPos("A6_XGERENT")) > 0
				cCondicao += ' .OR. A6_XGERENT == "1" ' //caixas gernciais pelo campo
			EndIf
			If !Empty(aFilBancos) //caixas do parametro
				For nX := 1 To len(aFilBancos)
					cCondicao += ' .OR. '+aFilBancos[nX]
				Next nX
			EndIf
			cCondicao += ')'

			// limpo os filtros
			SA6->(DbClearFilter())
			// executo o filtro
			bCondicao 	:= "{|| " + cCondicao + " }"
			SA6->(DbSetFilter(&bCondicao,cCondicao))
			SA6->(DbGoTop()) 
			If SA6->(Eof()) //se nao tiver nenhum... cancelo o filtro
				SA6->(DbClearFilter())
			EndIf

			RestArea(aAreaSA6)

			LjGrvLog( "TPDVE014", "Depois de Filtrar SA6: ", SA6->A6_COD+"|"+SA6->A6_AGENCIA + "|" + SA6->A6_NUMCON )

		Else
			
			LjGrvLog( "TPDVE014", "Antes de limpar filtro SA6: ", SA6->A6_COD+"|"+SA6->A6_AGENCIA + "|" + SA6->A6_NUMCON )

			SA6->(DbClearFilter())

			if !empty(aAreaSA6)
				RestArea(aAreaSA6)
				aAreaSA6 := {}
			endif

			LjGrvLog( "TPDVE014", "Depois de limpar filtro SA6: ", SA6->A6_COD+"|"+SA6->A6_AGENCIA + "|" + SA6->A6_NUMCON )
			LjGrvLog( "TPDVE014", "aStation", STBInfoEst( 1, .T. ) ) 

		EndIf
	EndIf

Return
