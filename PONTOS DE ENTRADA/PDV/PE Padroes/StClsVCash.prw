#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StClsVCash
Validacao antes fechar o caixa.

@author pablo
@since 15/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function StClsVCash()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP015")
		xRet := ExecBlock("TPDVP015",.F.,.F.,aParam)
	EndIf
	
Return xRet