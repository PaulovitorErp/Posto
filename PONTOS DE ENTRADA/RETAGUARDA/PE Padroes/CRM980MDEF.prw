#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CRM980MDef
Ponto de entrada para adicionar rotinas no Cadastro de Clientes (CRMA980)

@author TBC
@since 29/11/2018
@version 1.0
@return Array
@type function
/*/
User Function CRM980MDef()

    Local aRotAdic := {}

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP038")
		aRotAdic := ExecBlock("TRETP038", .F., .F.)
	EndIf
    
Return( aRotAdic )
