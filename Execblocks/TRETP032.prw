#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP032
Tratamento complementar
O ponto de entrada F190SE5 sera utilizado no tratamento complementar da gravacao do movimento no SE5 na liberacao de cheques.

@author Totvs GO
@since 28/08/2020
@version 1.0
@return Retorna URET(nulo)

@type function
/*/
User Function TRETP032()
    
    Local nRegSEF

    Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
    //Caso o Posto Inteligente não esteja habilitado não faz nada...
    If !lMvPosto
        Return
    EndIf
    
	//atualiza o complemento dos dados na SE5
    nRegSEF := SEF->(Recno())
    U_TRETE29B(nRegSEF)

Return
