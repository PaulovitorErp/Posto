
/*/{Protheus.doc} SE5FI460
O ponto de entrada SE5FI460 será utilizado na gravação complementar no SE5, 
pela gravação da baixa do título liquidado.

@type function
@version 12.1.25
@author Pablo
@since 25/05/2021

/*/
User Function SE5FI460()

	///////////////////////////////////////////////////////////////////////////////////////////
    //             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
    /////////////////////////////////////////////////////////////////////////////////////////
    If ExistBlock("TRETP034")
        ExecBlock("TRETP034",.F.,.F.)
    EndIf

Return
