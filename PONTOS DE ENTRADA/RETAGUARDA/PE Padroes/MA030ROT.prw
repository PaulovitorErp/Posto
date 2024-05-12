#Include "Protheus.ch"
#Include "RWMAKE.CH"


/*/{Protheus.doc} MA030ROT
Ponto de entrada para adicionar rotinas no Cadastro de Clientes (MATA030)

@author TBC
@since 29/11/2018
@version 1.0
@return Array
@type function
/*/
User Function MA030ROT()

	Local aRotAdic := {}

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP008")
		aRotAdic := ExecBlock("TRETP008", .F., .F.)
	EndIf

Return aRotAdic
