#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StwCncSale
Ponto de entrada executado no início do cancelamento
@author thebr
@since 20/12/2018
@version 1.0
@return lRet
@type function
/*/
User function StwCncSale()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP013")
		xRet := ExecBlock("TPDVP013",.F.,.F.,aParam)
	EndIf

Return xRet
