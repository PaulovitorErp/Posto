#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StiVlCGC
Ponto de entrada de valida��o da tela de digita��o do CPF

@author Totvs GO
@since 02/03/2021
@version 1.0
@return lRet
@type function
/*/
User function StiVlCGC()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP008")
		 xRet := ExecBlock("TPDVP008",.F.,.F.,aParam)
	EndIf

Return xRet
