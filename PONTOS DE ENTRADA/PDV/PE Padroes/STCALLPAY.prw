/*/{Protheus.doc} StCallPay
Ponto de entrada validar chamada tela de pagamento

@author thebr
@since 03/09/2019
@version 1.0
@return Nil

@type function
/*/
User Function StCallPay()

	Local aArea		:= GetArea()
    Local aParam 	:= aClone(ParamIxb)
    Local lRet      := .T.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP027")
		lRet := ExecBlock("TPDVP027",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return lRet
