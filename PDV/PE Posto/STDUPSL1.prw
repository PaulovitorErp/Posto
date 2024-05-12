/*/{Protheus.doc} User Function STDUPSL1 (fonte STDUpData)
Ponto de entrada para validar se a SL1 encontrada poder� ou n�o subir ao BackOffice

@type  Function
@author danilobrito
@since 21/02/2024
@version 1
/*/
User Function STDUPSL1(param_name)
    
    Local lRet := .T.
    Local lCentPDV := ParamIxb[1]

    if !lCentPDV //se for PDV
        //se tem o flag L1_FORCADA preenchido, aborto a subida da venda (esse campo padr�o n�o usa no TotvsPDV)
        if SL1->L1_SITUA == "00" .AND. SL1->L1_FORCADA == "S" 
            LjGrvLog( "L1_NUM: "+SL1->L1_NUM, "Venda n�o ser� integrada ainda pois est� em processo de finaliza��o (SL1->L1_FORCADA = S)" )
            lRet := .F.
        endif
    endif

Return lRet
