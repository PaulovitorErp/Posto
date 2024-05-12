/*/{Protheus.doc} TPDVP027 (StCallPay)
Ponto de entrada validar chamada tela de pagamento

@author thebr
@since 03/09/2019
@version 1.0
@return Nil

@type function
/*/
User Function TPDVP027()

    Local oProdutos     := PARAMIXB[3]  //Produtos registrados na venda
    Local nDesc 
    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).

    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return .T.
    EndIf

    //solucao contorno errorlog: argument #0 error, expected A->N,  function aeval on STDSETNCCS(STDNCCMODEL.PRW)
    aNccs := STDGetNCCs("1") 
    if empty(aNccs)
        STDSetNCCs("1",{}) //limpo pois estava dando errorlog
    endif

    If SuperGetMv("TP_PROFLEX",,.F.) 
        
        If STDGPBasket("SL1","L1_XUSAPRO") <> 'S' .or. Empty(STDGPBasket("SL1","L1_XCODPRO"))
            U_TPDVE016(1) //pergunta se integra promoflex
        ENDIF
        
        if STDGPBasket("SL1","L1_XUSAPRO") == "S" .AND. !Empty(STDGPBasket("SL1","L1_XCODPRO"))
            FWMsgRun(, {|oSay| nDesc := U_TPDVE016(2, oSay, oProdutos) }, "Conectando com PromoFlex", "Calculando o desconto para o codigo: " + STDGPBasket("SL1","L1_XCODPRO") )
        endif

        //chumbado para simular promoflex
        //STDSPBasket("SL1","L1_XUSAPRO","S")
        //STDSPBasket("SL1","L1_XINTPRO","N")
        //STDSPBasket("SL1","L1_XCODPRO","02792732156")
        //STDSPBasket("SL1","L1_XCHVPRO", "351afs3513513as51f3as5")
        //STDSPBasket("SL1","L1_XDESPRO", 10)

        /*If nDesc > 0

            //Função STWTotDisc responsável em aplicar o desconto no Totvs Pdv
            //Parâmetros:
            //1º - Indico o valor do desconto
            //2º - Indico que o desconto sera em valor 'V', ou poderia passar 'P' para percentual
            //3º - Indica a origem que esta sendo chamada a função, não é um parâmetro obrigatório, pode-se passar em branco
            //4º - Indica se o desconto sera cumulativo, ou seja, caso já tenha aplicado um desconto antes de executar esse ponto de entrada,
            //o sistema considera o desconto aplicado anteriormente mais o desconto de 10 reais que esta sendo aplicado no ponto de entrada.
            STWTotDisc( nDesc , 'V' , '' , .T. )

        EndIf*/

    EndIf

Return .T.
