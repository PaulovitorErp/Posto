#Include "Protheus.ch"

/*/{Protheus.doc} OM010MNU
Ponto de entrada para inclusao de rotina no menu da tabela de preco

@author TBC
@since 29/11/2018
@version 1.0
@return Nulo
@type function
/*/
User Function OM010MNU()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP010")
		ExecBlock("TRETP010",.F.,.F.)
	EndIf

Return
