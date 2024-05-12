#include "protheus.ch"

/*/{Protheus.doc} FISTRFNFE
Ponto de entrada que tem por finalidade incluir novos botões na rotina SPEDNFE
@author Maiki Perin
@since 12/02/2016
@version P11
@param Nao recebe parametros
@return nulo
/*/

/************************/
User Function FISTRFNFE()
/************************/

///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////

If ExistBlock("TRETP037")
	ExecBlock("TRETP037",.F.,.F.)
EndIf       

Return
