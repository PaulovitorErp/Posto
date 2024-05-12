#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STCANSALE
Este Ponto de Entrada é acionado após a confirmação do cancelamento da venda.

@author pablo
@since 30/05/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVP019()
Local nX

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return
EndIf

//conout("PE STCANSALE - Data/hora INICIO de execucao: "+DtoS(DDataBase)+"-"+cValToChar(Time())+"")
//conout("PE STCANSALE - Orçamento: " + SL1->L1_NUM + " - Doc/Serie: " + SL1->L1_DOC + "/" + SL1->L1_SERIE + "")

//-- busca cheques troco da venda para liberá-lo no ambiente PDV
If !Empty(SL1->L1_DOC) .and. !Empty(SL1->L1_SERIE)
		
	UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
	UF2->(DbSeek(xFilial("UF2")+SL1->L1_DOC+SL1->L1_SERIE))
	aRecUF2 := {}
	While !UF2->(Eof()) .and. UF2->(UF2_FILIAL+UF2_DOC+UF2_SERIE) == (xFilial("UF2")+SL1->L1_DOC+SL1->L1_SERIE)
		//conout("PE STCANSALE - Estorna do troco utilizado na venda...")
		//--- limpa campos de situa pra nem subir, caso ainda esteja pendente.
		If UF2->UF2_SITUA == '00'
			If RecLock("UF2")
				UF2->UF2_XSITUA := ""
				UF2->UF2_XINDEX := 0
				UF2->UF2_SITUA  := "TX"
			UF2->(MsUnlock())
			EndIf
		EndIf
		
		aadd(aRecUF2, UF2->(Recno()))
		
		UF2->(DbSkip())
	EndDo
	
	For nX:= 1 to Len(aRecUF2)
		nRecUF2	:= aRecUF2[nX]
		U_TRETE29E(nRecUF2) //limpo campos de usado do cheque
	Next nX
EndIf

///////////////////////////////////////////////////////////////////////////////////////////
//             Funcao de integracao promoflex                                             //
/////////////////////////////////////////////////////////////////////////////////////////
If SuperGetMv("TP_PROFLEX",,.F.)
	If SL1->L1_XUSAPRO == 'S'
		FWMsgRun(, {|oSay| U_TPDVE016(4) }, "Conectando com PromoFlex", "Cancelando venda com codigo: " + SL1->L1_XCHVPRO )
	ENDIF
EndIf

//conout("PE STCANSALE - Data/hora FIM de execucao: "+DtoS(DDataBase)+"-"+cValToChar(Time())+"")		
	
Return
