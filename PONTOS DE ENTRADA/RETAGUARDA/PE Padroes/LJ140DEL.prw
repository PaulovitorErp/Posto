#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ140DEL
Esse ponto de entrada é chamado antes da exclusão da nota fiscal; 
logo, pode-se ter acesso ao número da nota por meio do campo L1_DOC.

@author Totvs GO
@since 09/02/2015
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function LJ140DEL()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP017")
		ExecBlock("TRETP017",.F.,.F.)
	EndIf

Return
