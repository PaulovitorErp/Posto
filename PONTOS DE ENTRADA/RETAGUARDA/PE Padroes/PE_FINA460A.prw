#include 'protheus.ch'

/*/{Protheus.doc} FINA460A
Pontos de Entrada para rotina FINA460 (Liquidação) 
@author Maiki Perin
@since 05/04/2019
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User function FINA460A()
/***********************/

Local xRet := .T.
Local aParam := aClone(ParamIxb)

///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////
If ExistBlock("TRETP018")
	xRet := ExecBlock("TRETP018",.F.,.F.,aParam)
Endif

return xRet
