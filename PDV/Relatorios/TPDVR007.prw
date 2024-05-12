#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} TPDVR007
Rotina de Impressao do Relatorio Gerencial (Aferição de Bico)

@author Pablo Cavalcante
@since 18/02/2022
@type function
/*/

/* LAYOUT DESENVOLVIDO -> 48 POSIÇÕES
         1         2         3         4
123456789012345678901234567890123456789012345678

------------------------------------------------
          MARAJO APARECIDA DE GOIANIA
------------------------------------------------

             ** AFERIÇÃO DE BICO **

DATA.....: XX/XX/XXXX          HORA...: HH:MM:SS
OPERADOR.: CAMILA

BOMBA....: XXX                         BICO: XXX
PRODUTO..: XXXXXXXXXX - GASOLINA COMUM
LITROS...: 22,449 L
EI: XXX.XXX.XXX,XX
EF: XXX.XXX.XXX,XX
DT ABAST.: XX/XX/XXXX            HR ABAST: HH:MM

------------------------------------------------
APLICATIVO: MICROSIGA PROTHEUS - TOTVS PDV
------------------------------------------------
*/

User Function TPDVR007(cOperador,cProduto,nLitros,cBomba,cBico,nEncIn,nEncFi,dDtAb,cHrAb)

	Local aArea    := GetArea()
	Local aAreaSM0 := SM0->( GetArea() )

	Local nLarg         := 48 //considera o cupom de 48 posições
	Local _aMsg			:= {} //mensagens do cupom
	Local _cMsg         := ""
	Local _cRodape      := ""
	Local nVias         := SuperGetMv("MV_XVIASAF",,2) //numero de vias (2 - uma para o cliente outra para a marajo)
	Local aTitVias		:= StrToKArr(SuperGetMV('MV_XTVIAAF',,"cliente;operador"),";") //define o tiulo da via
    Local cPulaLin      := Space(nLarg)
	Local nX := 0
	Local cTxtTmp

	//forço o posicionamento na SM0
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
		SM0->(DbSkip())
	EndDo

	If !IsInCallStack("STIPosMain")
		U_SetMsgRod("Falha na comunicação com a impressora!" )
		Return
	EndIf

	_aMsg := {} //mensagens do cupom

	AAdd( _aMsg, cPulaLin )
	AAdd( _aMsg, Replicate("-",nLarg) )

	cTxtTmp := Alltrim(SM0->M0_NOMECOM)
	AAdd( _aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp) //SM0->M0_NOMECOM
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, cPulaLin )

	cTxtTmp := "** AFERIÇÃO DE BICO **"
	AAdd( _aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)
	AAdd( _aMsg, "@VIA@" )

	AAdd( _aMsg, cPulaLin )
    cPref := "DATA.....: "+DtoC(date())
	cSufi := "HORA...: "+time()
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )
	
	AAdd( _aMsg, PadR("OPERADOR.: "+AllTrim(cOperador),nLarg) )
    AAdd( _aMsg, cPulaLin )

    cPref := "BOMBA....: "+cBomba
	cSufi := "BICO: "+cBico
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

	AAdd( _aMsg, PadR("PRODUTO..: "+AllTrim(cProduto),nLarg) )

    cPref := "LITROS...: "
	cSufi := Alltrim(Transform(nLitros,"@E 99,999,999,999.999")) + " (L)"
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

    cPref := "EI: "
	cSufi := Alltrim(Transform(nEncIn,"@E 99,999,999,999.999"))
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

    cPref := "EF: "
	cSufi := Alltrim(Transform(nEncFi,"@E 99,999,999,999.999"))
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

    cPref := "DT ABAST.: "+DtoC(dDtAb)
	cSufi := "HR ABAST: "+cHrAb
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )
    AAdd( _aMsg, cPulaLin )

	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, PadR("APLICATIVO: MICROSIGA PROTHEUS - TOTVS",nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )

	For nX:=1 to Len( _aMsg )
		_cRodape += _aMsg[nX] + chr(10)
	Next nX

	_cMsg := _cMsg + chr(10) + _cRodape

	//imprime
	CursorWait()
	For nX:=1 To nVias //duas vias -> comprovante de quitação

		If nX <= len(aTitVias)
			cTxtTmp := "via "+aTitVias[nX]
			cTxtTmp := Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp
			cTxtTmp := StrTran(_cMsg, "@VIA@",cTxtTmp)
		else
			cTxtTmp := _cMsg
		EndIf

		U_SetMsgRod("Aguarde, imprimindo comprovante Aferição de Bico - " + StrZero(nVias,2) )

		STWManagReportPrint(cTxtTmp,1/*nVias*/)

	Next nX

	CursorArrow()
	U_SetMsgRod("" )

	RestArea( aAreaSM0 )
	RestArea( aArea )

Return


/* LAYOUT DESENVOLVIDO -> 48 POSIÇÕES
         1         2         3         4
123456789012345678901234567890123456789012345678

------------------------------------------------
          MARAJO APARECIDA DE GOIANIA
------------------------------------------------

             ** AFERIÇÃO DE BICO **

DATA.....: XX/XX/XXXX          HORA...: HH:MM:SS
OPERADOR.: CAMILA

BOMBA....: XXX                         BICO: XXX
PRODUTO..: XXXXXXXXXX - GASOLINA COMUM
LITROS...: 22,449 L
EI: XXX.XXX.XXX,XX
EF: XXX.XXX.XXX,XX
DT ABAST.: XX/XX/XXXX            HR ABAST: HH:MM

------------------------------------------------
APLICATIVO: MICROSIGA PROTHEUS - TOTVS PDV
------------------------------------------------
*/
User Function TPDVR07A(aImpAgrup)

	Local aArea    := GetArea()
	Local aAreaSM0 := SM0->( GetArea() )

	Local nLarg         := 48 //considera o cupom de 48 posições
	Local _aMsg			:= {} //mensagens do cupom
	Local _cMsg         := ""
	Local nVias         := SuperGetMv("MV_XVIASAF",,2) //numero de vias (2 - uma para o cliente outra para a marajo)
	Local aTitVias		:= StrToKArr(SuperGetMV('MV_XTVIAAF',,"cliente;operador"),";") //define o tiulo da via
    Local cPulaLin      := Space(nLarg)
	Local nX := 0
	Local cTxtTmp

	//forço o posicionamento na SM0
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
		SM0->(DbSkip())
	EndDo

	If !IsInCallStack("STIPosMain")
		U_SetMsgRod("Falha na comunicação com a impressora!" )
		Return
	EndIf

	_aMsg := {} //mensagens do cupom

	AAdd( _aMsg, cPulaLin )
	AAdd( _aMsg, Replicate("-",nLarg) )

	cTxtTmp := Alltrim(SM0->M0_NOMECOM)
	AAdd( _aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp) //SM0->M0_NOMECOM
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, cPulaLin )

	cTxtTmp := "** AFERIÇÃO DE BICO **"
	AAdd( _aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)
	AAdd( _aMsg, "@VIA@" )

	AAdd( _aMsg, cPulaLin )
    cPref := "DATA.....: "+DtoC(date())
	cSufi := "HORA...: "+time()
	AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

	AAdd( _aMsg, PadR("OPERADOR.: "+AllTrim(aImpAgrup[1][1]),nLarg) )
    AAdd( _aMsg, cPulaLin )

	//aadd(aImpAgrup, {cOperador,cProduto,nLitros,cBomba,cBico,nEncIn,nEncFi,dDtAb,cHrAb})
	For nX := 1 to len(aImpAgrup)

		cPref := "BOMBA....: "+ aImpAgrup[nX][4]//cBomba
		cSufi := "BICO: "+aImpAgrup[nX][5]//cBico
		AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

		AAdd( _aMsg, PadR("PRODUTO..: "+AllTrim(aImpAgrup[nX][2]),nLarg) )//cProduto

		cPref := "LITROS...: "
		cSufi := Alltrim(Transform(aImpAgrup[nX][3],"@E 99,999,999,999.999")) + " (L)" //nLitros
		AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

		cPref := "EI: "
		cSufi := Alltrim(Transform(aImpAgrup[nX][6],"@E 99,999,999,999.999")) //nEncIn
		AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

		cPref := "EF: "
		cSufi := Alltrim(Transform(aImpAgrup[nX][7],"@E 99,999,999,999.999")) //nEncFi
		AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )

		cPref := "DT ABAST.: "+DtoC(aImpAgrup[nX][8]) //dDtAb
		cSufi := "HR ABAST: "+aImpAgrup[nX][9] //cHrAb
		AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )
		AAdd( _aMsg, cPulaLin )

	next nX

	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, PadR("APLICATIVO: MICROSIGA PROTHEUS - TOTVS",nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )

	For nX:=1 to Len( _aMsg )
		_cMsg += _aMsg[nX] + chr(10)
	Next nX

	//imprime
	CursorWait()
	For nX:=1 To nVias //duas vias -> comprovante de quitação

		If nX <= len(aTitVias)
			cTxtTmp := "via "+aTitVias[nX]
			cTxtTmp := Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp
			cTxtTmp := StrTran(_cMsg, "@VIA@",cTxtTmp)
		else
			cTxtTmp := _cMsg
		EndIf

		U_SetMsgRod("Aguarde, imprimindo comprovante Aferição de Bico - " + StrZero(nVias,2) )

		STWManagReportPrint(cTxtTmp,1/*nVias*/)

	Next nX

	CursorArrow()
	U_SetMsgRod("" )

	RestArea( aAreaSM0 )
	RestArea( aArea )

Return
