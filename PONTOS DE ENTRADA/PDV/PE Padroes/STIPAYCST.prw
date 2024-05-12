#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STIPAYCST
Ponto de Entrada para Incluir a forma de pagamento Especifica.

@author pablo
@since 20/11/2018
@version 1.0
@return xRet
@type function
/*/
User Function STIPAYCST()

	Local aArea		:= GetArea()
	Local xRet		:= .T. //abre o painel de pagamento padrao

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP004")
		xRet := ExecBlock("TPDVP004",.F.,.F.,ParamIxb)
	EndIf

	RestArea(aArea)

Return xRet
