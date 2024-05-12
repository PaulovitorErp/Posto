#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STConfSale
Validação das formas de pagamentos utilizadas na finalização da venda/recebimento de título no TOTVS PDV.

@author pablo
@since 14/05/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function STConfSale()
	Local xRet
	Local aParam 	:= aClone(ParamIxb)
	Local aArea		:= GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP017")
		xRet := ExecBlock("TPDVP017",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return xRet
