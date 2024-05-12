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
User Function STCANSALE()
	Local aArea		:= GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP019")
		ExecBlock("TPDVP019",.F.,.F.)
	EndIf

	RestArea(aArea)
Return