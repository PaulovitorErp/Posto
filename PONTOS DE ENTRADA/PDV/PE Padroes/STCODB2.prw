#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STCodB2
Este Ponto de Entrada é destinado para a Alteração do cupom virtual, 
onde permite modificar as posições de exibição das colunas dos itens da venda.

@author danilo
@since 09/03/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function STCodB2()

	Local xRet
    Local aParam 	:= aClone(ParamIxb)
	Local aArea		:= GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP022")
		xRet := ExecBlock("TPDVP022",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return xRet
