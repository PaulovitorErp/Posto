#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7082
Este Ponto de entrada permite a execu��o de um processo customizado, para que se possa determinar se a venda ser� processada pelo LjGrvBatch.
Se a venda n�o for processada e n�o sofrer nenhuma altera��o, ela tentar� ser processada na pr�xima execu��o do LjGrvBatch.

@author Pablo Nunes
@since 03/01/2020
@version 1.0
@return 	
Retorno L�gico .T. = a venda ser� processada .F. = a venda n�o ser� processada

@type function
/*/
User Function LJ7082()

	Local aParam := aClone(ParamIxb)
	Local xRet := .T.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP029")
		xRet := ExecBlock("TRETP029",.F.,.F.,aParam)
	Endif

Return xRet