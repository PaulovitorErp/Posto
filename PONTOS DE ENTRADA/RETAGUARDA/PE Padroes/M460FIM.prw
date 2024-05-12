#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} M460FIM
Este P.E. e' chamado apos a Gravacao da NF de Saida, e fora da transação
@author Totvs TBC
@since 02/10/2013
@version 1.0
@return Nulo

@type function
/*/

User Function M460FIM()   

///////////////////////////////////////////////////////////////////////////////////////////
//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
/////////////////////////////////////////////////////////////////////////////////////////
If ExistBlock("TRETP027")
    ExecBlock("TRETP027",.F.,.F.)
EndIf

Return
