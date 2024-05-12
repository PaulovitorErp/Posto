#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StValCGC
Ponto de entrada de validação da tela de digitação do CPF

@author Danilo Brito
@since 01/10/2018
@version 1.0
@return lRet
@type function
/*/
User function StValCGC()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP008")
		 xRet := ExecBlock("TPDVP008",.F.,.F.,aParam)
	EndIf

Return xRet
