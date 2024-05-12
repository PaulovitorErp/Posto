#include 'totvs.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StwFsQuery
Manipular a seleção do abastecimento de acordo com uma regra especifica do cliente

@author Totvs GO
@since 05/09/2019
@version 1.0
@return xRet - nova query
@type function
/*/
User Function StwFsQuery()

	Local xRet
	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP021")
		xRet := ExecBlock("TPDVP021",.F.,.F.,aParam)
	EndIf

Return xRet
