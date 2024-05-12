#include 'protheus.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ TPDVE012 ºAutor  ³ Totvs GO           º Data ³  07/03/15   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³  Ajuste de saida de troco no caixa (Tabela SE5)            º±±
±±º          ³  -> ajusta o campo E5_TIPODOC = 'VL' -> 'TR'               º±±
±±º          ³  condição: troco não eh de origem de pagamento de R$, ou seº±±
±±º          ³  ja, TROCO -> E5_MOEDA = 'TC' .AND. !EMPTY(E5_PARCELA)     º±±
±±º          ³                                                            º±±
±±º          ³ Ajuste necessario para a contabilização do troco           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajo                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function TPDVE012(cDoc,cSerie)

Local aArea		:= GetArea()
Local aAreaSE5  := SE5->(GetArea())
Local aAreaSA6	:= SA6->(GetArea())
Local aAreaSL1  := SL1->(GetArea())
Local cTmp		:= GetNextAlias()
Local cPrefixo 	:= ""
Local cNum 		:= ""
Local cNumPdv	:= ""
Local cBanco    := "" //banco do operador
Local cAgencia  := ""
Local cNumCon   := ""
Local cData     := ""
Local cCliente  := ""
Local cLoja     := ""
Local lRet		:= .T.

//Conout("Entrou no fonte TPDVE012 - "+Time())

DbSelectArea("SL1")
SL1->(DbSetOrder(2)) //L1_FILIAL + L1_SERIE + L1_DOC + L1_PDV
If SL1->(DbSeek(xFilial("SL1")+cSerie+cDoc))

	cPrefixo	:= IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)
	cNum 		:= IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC)
	cNumPdv		:= SL1->L1_PDV
	cData		:= DtoS(SL1->L1_EMISNF)
	cCliente	:= SL1->L1_CLIENTE
	cLoja		:= SL1->L1_LOJA

	SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
	If (SA6->(DbSeek( xFilial("SA6") + SL1->L1_OPERADO))) //posiciona no banco do caixa (operador) que finalizou a venda

		cBanco    := SA6->A6_COD
		cAgencia  := SA6->A6_AGENCIA
		cNumCon   := SA6->A6_NUMCON

		// Ajusto a SE5
		// E5_MOEDA = 'TC' e E5_TIPODOC $ 'VL/TR'
		// indice 2 -> E5_FILIAL+E5_TIPODOC+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DtoS(E5_DATA)+E5_CLIFOR+E5_LOJA+E5_SEQ

		//MV_LJTRDIN -> Define se grava o valor liqüido do troco em dinheiro. (0-Nao Utiliza ; 1-Gera Valor Liquido)
		If SuperGetMV("MV_LJTRDIN",,0) <> 0 //se parametro ativo não combiliza o troco da forma de pagamento dinheiro R$

			BeginSql Alias cTmp

				SELECT *
				FROM %table:SE5% SE5
					WHERE SE5.E5_FILIAL = %xFilial:SE5%
					AND SE5.E5_TIPODOC  = %Exp:'VL'%
					AND SE5.E5_PREFIXO 	= %Exp:cPrefixo%
					AND SE5.E5_NUMERO	= %Exp:cNum%
					AND SE5.E5_PARCELA  <> %Exp:''%
					//AND SE5.E5_TIPO 	= %Exp:''%
					AND SE5.E5_BANCO 	= %Exp:cBanco%
					AND SE5.E5_AGENCIA 	= %Exp:cAgencia%
					AND SE5.E5_CONTA 	= %Exp:cNumCon%
					AND SE5.E5_DATA 	= %Exp:cData%
					AND SE5.E5_CLIFOR 	= %Exp:cCliente%
					AND SE5.E5_LOJA 	= %Exp:cLoja%
					AND SE5.E5_MOEDA 	= %Exp:'TC'%
					//AND SE5.E5_VALOR 	> 0
					//AND SE5.%NotDel%

			EndSql

		Else

			BeginSql Alias cTmp

				SELECT *
				FROM %table:SE5% SE5
					WHERE SE5.E5_FILIAL = %xFilial:SE5%
					AND SE5.E5_TIPODOC  = %Exp:'VL'%
					AND SE5.E5_PREFIXO 	= %Exp:cPrefixo%
					AND SE5.E5_NUMERO	= %Exp:cNum%
					AND SE5.E5_BANCO 	= %Exp:cBanco%
					AND SE5.E5_AGENCIA 	= %Exp:cAgencia%
					AND SE5.E5_CONTA 	= %Exp:cNumCon%
					AND SE5.E5_DATA 	= %Exp:cData%
					AND SE5.E5_CLIFOR 	= %Exp:cCliente%
					AND SE5.E5_LOJA 	= %Exp:cLoja%
					AND SE5.E5_MOEDA 	= %Exp:'TC'%

			EndSql

		EndIf

		SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_

		While !(cTmp)->(EOF())

			//posiciono na SE5
			DbSelectArea("SE5")
			SE5->(DbGoTo( (cTmp)->R_E_C_N_O_ ))

			//Ajusta o Tipo de Documento para Troco
			RecLock("SE5")
				SE5->E5_TIPODOC := 'TR' //'VL' -> 'TR'
			SE5->(MsUnlock())

		(cTmp)->(DbSkip())
		EndDo

		SET DELETED ON //Habilita filtro do campo D_E_L_E_T_

		(cTmp)->( dbCloseArea() )

	EndIf
EndIf

//Conout("Saida do fonte TPDVE012 - "+Time())

RestArea(aAreaSL1)
RestArea(aAreaSE5)
RestArea(aAreaSA6)
RestArea(aArea)

Return