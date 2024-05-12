#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StClsFCash
Ponto de entrada no final do fechamento de caixa

@author thebr
@since 27/12/2018
@version 1.0
@return Nil

@type function
/*/
user function StClsFCash()

	Local xRet := .T.
	Local aParam 	:= aClone(ParamIxb)
	Private _cTitCX := " - Fechamento de Caixa"

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP014")
		xRet := ExecBlock("TPDVP014",.F.,.F.,aParam)
	EndIf

Return xRet