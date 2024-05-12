#include 'protheus.ch'

/*/{Protheus.doc} StValPro
Função para validar se um determinado item poderá ser registrado no PDV
@author Maiki Perin
@since 18/09/2018
@version P12
@param PARAMIXB
@return lRet
/*/
User Function StValPro()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)
	Local aArea		:= GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP006")
		xRet := ExecBlock("TPDVP006",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return xRet