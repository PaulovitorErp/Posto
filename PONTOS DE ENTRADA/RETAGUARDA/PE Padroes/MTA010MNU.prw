#Include "Protheus.ch"

/*/{Protheus.doc} MTA010MNU
PE para adicionar rotinas no cadastro de Produtos.

@author TBC
@since 29/11/2018
@version 1.0
@return Nulo
@type function
/*/
User Function MTA010MNU()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP009")
		ExecBlock("TRETP009",.F.,.F.)
	EndIf

Return
