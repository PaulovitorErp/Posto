#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StOpenFCash
Ponto de entrada após abertura de caixa

@author thebr
@since 14/02/2019
@version 1.0
@return Nil

@type function
/*/
user function StOpenFCash()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)
	Private _cTitCX := " - Abertura de Caixa"

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP016")
		xRet := ExecBlock("TPDVP016",.F.,.F.,aParam)
	EndIf

return