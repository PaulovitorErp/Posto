#include 'protheus.ch'

/*/{Protheus.doc} TPDVP012 (STCpCuston)
Gravação de campos customizados na SE5 de sangria e suprimento
@author thebr
@since 27/12/2018
@version 1.0
@return aRet

@type function
/*/
User function TPDVP012()

	Local aRet := {}
	Local aCampos := {}
	//Local nTipo := PARAMIXB[1] //Tipo de operacao 1=Sangria | 2= Suprimento/Troco
	//Local cRecPag := PARAMIXB[2] //Recebimento "R" ou Pagamento "P"
	Local aStation := STBInfoEst( 1, .T. ) //Informacoes da estacao  // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV [5]-LG_SERNFIS

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return {.F.,{}}
	EndIf

	//campos para que seja possível usar movimento na conferencia de caixa
	if SE5->(FieldPos("E5_XPDV")) > 0
		aadd(aCampos, {"E5_XPDV", aStation[4] } )
		aadd(aCampos, {"E5_XESTAC", aStation[2] } )
		//if Date() > dDataBase
		//	aadd(aCampos, {"E5_XHORA", Left("23:59:00",TamSX3("E5_XHORA")[1]) } )
		//else
			aadd(aCampos, {"E5_XHORA", Left(Time(),TamSX3("E5_XHORA")[1]) } )
		//endif
    endif

	//vendedor que fez a sangria/suprimento
	if SE5->(FieldPos("E5_OPERAD")) > 0
		aadd(aCampos, {"E5_OPERAD", U_TPGetVend() } )
	endif

	aadd(aRet, .T.) //se continua ou nao
	aadd(aRet, aCampos) //campos customizados

	//CONOUT(Time()+ "  - Passou pelo P.E. STCpCuston na gravação da SE5 Sangria/suprimento ")
	//LjGrvLog( "Passou pelo P.E. STCpCuston na gravação da SE5 Sangria/suprimento " )

Return aRet
