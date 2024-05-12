#include 'totvs.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F190BROW
Tratamento complementar
O ponto de entrada F190BROW é executado antes da Mbrowse, pre validando os dados a serem exibidos.

@author Totvs GO
@since 28/08/2020
@version 1.0
@return Retorna URET(nulo)

@type function
/*/
User Function F190BROW()

    ///////////////////////////////////////////////////////////////////////////////////////////
    //             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
    /////////////////////////////////////////////////////////////////////////////////////////
    If ExistBlock("TRETP033")
        lRet := ExecBlock("TRETP033",.F.,.F.)
    EndIf

Return
