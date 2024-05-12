#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720FLT
Esse ponto de entrada é chamado para permitir customizar o filtro de seleção dos dados de itens da venda.
PE da Rotina de Troca e Devolução de Mercadorias (loja)

@author danlo.brito
@since 02/03/2018
@version undefined
@type function
/*/
User function LJ720FLT()

	Local xRet
	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP016")
		xRet := ExecBlock("TRETP016",.F.,.F.,aParam)
	EndIf

Return xRet
