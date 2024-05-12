#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TRETP016 (LJ720FLT)
Esse ponto de entrada é chamado para permitir customizar o filtro de seleção dos dados de itens da venda.
PE da Rotina de Troca e Devolução de Mercadorias (loja)

@author thebr
@since 14/01/2019
@version 1.0
@return Nil
@type function
/*/
user function TRETP016()

	Local cCond := ""
	Local dDataDe := ParamIxb[1]
	Local dDataAte := ParamIxb[2]
	Local cCodCli := ParamIxb[3]
	Local cLojaCli := ParamIxb[4]
	Local nFiltroPor := ParamIxb[5] //1=Data e Cliente/Loja; 2=Doc/Serie
	Local cNumNF := ParamIxb[6]
	Local cSerieNF := ParamIxb[7]
	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea())

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return cCond
	EndIf

	//tratamentos para L1_SITUA = 'X3' //cancelamento nao autorizado.
	if !IsInCallStack("U_TRETA028") //se for da conferencia de caixa
		if !empty(cNumNF) .AND. !empty(cSerieNF)
			SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			if SL1->(DbSeek(xFilial("SL1")+cSerieNF+cNumNF+SLW->LW_PDV ))
				if SL1->L1_SITUA == "X3"
					//volto status para OK, para permitir fazer a devolução.
					Reclock("SL1",.F.)
						SL1->L1_SITUA := "OK"
					SL1->(MsUnlock())
					MsgInfo("Status da venda mudado para OK, para permitir devolução!","SigaPosto")
				Elseif DTOS(dDATABASE)+Time() > calcPrazo() .and. (SL1->L1_SITUA == "X0" .OR. SL1->L1_SITUA == "X1")
					//volto status para OK, para permitir fazer a devolução.
					Reclock("SL1",.F.)
						SL1->L1_SITUA := "OK"
					SL1->(MsUnlock())
					MsgInfo("Status da venda mudado para OK, para permitir devolução!","SigaPosto")
				endif
			endif
		endif
	EndIf

	//trecho copiado do fonte padrão para manter as funcionalidades.
	If nFiltroPor == 1
		If !Empty(cCodCli)
		  	cCond += " .AND. D2_CLIENTE == '" + cCodCli + "' "
		Endif
		If !Empty(cLojaCli)
		  	cCond += " .AND. D2_LOJA    == '" + cLojaCli    + "' "
		Endif
		If !Empty(dDataDe)
		  	cCond += " .AND. DtoS(D2_EMISSAO) >= '" + DtoS(dDataDe)  + "'"
		Endif
		If !Empty(dDataAte)
			cCond += " .AND. DtoS(D2_EMISSAO) <= '" + DtoS(dDataAte) + "' "
		Endif
	Else
		If !Empty(cNumNF)
		  	cCond += " .AND. D2_DOC == '" + cNumNF + "' "
		Endif
		If !Empty(cSerieNF)
		  	cCond += " .AND. D2_SERIE == '" + cSerieNF + "' "
		Endif
	EndIf

	RestArea(aAreaSL1)
	RestArea(aArea)

return cCond

//--------------------------------------------------
// Retorna data de prazo cancelamento
//--------------------------------------------------
Static function calcPrazo()

	Local cRet := ""

	_nDias := int(GetMv("MV_NFCEEXC")/24)
	_nHora := GetMv("MV_NFCEEXC")-(_nDias*24)
	_cHora := StrZero(Iif((Val(Substr(SL1->L1_HORA,1,2))+_nHora) > 23,(Val(Substr(SL1->L1_HORA,1,2))+_nHora)-24,Val(Substr(SL1->L1_HORA,1,2))+_nHora),2)
	_dData := Iif((Val(Substr(SL1->L1_HORA,1,2))+_nHora) > 23, SL1->L1_EMISNF + _nDias +1 , SL1->L1_EMISNF +_nDias )

	cRet := DTOS(_dData)+_cHora+SubStr(SL1->L1_HORA,3,6)

Return cRet
