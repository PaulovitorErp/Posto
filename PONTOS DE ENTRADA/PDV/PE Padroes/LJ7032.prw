/*/{Protheus.doc} User Function LJ7032
PE para ajustar array aTotais, ao gravar orçamento na centralPDV
@type  Function
@author danilo
@since 05/06/2023
@version 1
/*/
User Function LJ7032()

    if SuperGetMv("TP_ACTORC",,.F.) .AND. type("aTotais") == "A" .AND. len(aTotais) == 7
        aadd(aTotais,Nil)
        aTotais[8] := aTotais[7]
    endif

Return .T.
