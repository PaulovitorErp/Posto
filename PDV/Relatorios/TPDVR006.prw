#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} TPDVR006
Rotina de Impressao do Relatorio Gerencial (Vale Haver)

@author Pablo Cavalcante
@since 05/06/2014
@version 1.0
@return Nil
@param nVale, numeric, Valor do Vale Haver
@param lCmp, logical, Define se está imprimindo de compensação ou nao
@param cPfxVlh, characters, Prefixo Vale Haver
@type function
/*/

/* LAYOUT FORNECIDO PELA MARAJO -> 40 POSIÇÕES
         1         2         3         4
1234567890123456789012345678901234567890

----------------------------------------
       MARAJO APARECIDA DE GOIANIA
----------------------------------------

              ** HAVER **

DATA.....: XX/XX/XXXX  HORA...: HH:MM:SS
N. CUPOM.: XXXXXX      PLACA..: AAA-9X99
OPERADOR.: CAMILA
CLIENTE..: MANUAL HENRIQUE DA SILVA

VALOR DO COMBUSTIVEL (LITRO).: R$ 2,449
FORMA DE PAGAMENTO UTILIZADAS NO CUPOM:
CHEQUE A VISTA PROMO - R$ 2000,00

N. HAVER.: 999999999-99
VALOR HAVER: R$ 319,59
**(TREZENTOS E DEZENOVE REAIS E CINQUEN
TA E NOVE CENTAVOS)**
----------------------------------------
NAO PODE SER TROCADO POR DINHEIRO

---------NÃO É DOCUMENTO FISCAL---------
APLICATIVO: MICROSIGA PROTHEUS - TOTVS

*/

User Function TPDVR006(nVale, lCmp, cPfxVlh)

Local aArea    := GetArea()
Local aAreaSL1 := SL1->( GetArea() )
Local aAreaSL2 := SL2->( GetArea() )
Local aAreaSL4 := SL4->( GetArea() )
Local aAreaSA1 := SA1->( GetArea() )
Local aAreaSA6 := SA6->( GetArea() )
Local aAreaUC0 := UC0->( GetArea() )
Local aAreaUC1 := UC1->( GetArea() )
Local aAreaSM0 := SM0->( GetArea() )
Local nLarg         := 48 //considera o cupom de 40 posições
Local _aMsg			:= {} //mensagens do cupom
Local _cMsg         := ""
Local _cRodape      := ""
Local _aPgtos       := {}
Local nVias         := SuperGetMv("MV_XVIAVLH",,2) //numero de vias (2 - uma para o cliente outra para a marajo)
Local aTitVias		:= StrToKArr(SuperGetMV('MV_XTVIAVH',,"cliente;operador"),";") //define o tiulo da via
Local aSL4          := {} //{{L4_FORMA, SUM(L4_VALOR-L4_TROCO)}}
Local nX := 0, nI := 0
Local cTxtTmp

Default lCmp := .F.
Default cPfxVlh 	:= ""

If nVale > 0 .And. ExistBlock("TPR006IM")
	
	//Ponto de Entrada TPR006IM - que permite a impressão customizada pelo usuário do Vale Haver
	ExecBlock("TPR006IM",.F.,.F., {nVale, lCmp, cPfxVlh})

ElseIf nVale > 0 

	//forço o posicionamento na SM0
	SM0->(DbGoTop())
	While SM0->(!Eof())
		If (AllTrim(SM0->M0_CODFIL) == AllTrim(cFilAnt)) .and. (AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt))
			Exit
		EndIf
		SM0->(DbSkip())
	EndDo

	If !IsInCallStack("STIPosMain")
		if lCmp
			U_SetMsgRod("Falha na comunicação com a impressora!" )
		else
			STFMessage("TPDVR006", "STOP", "Falha na comunicação com a impressora!" )
			STFShowMessage("TPDVR006")
		endif
		Return
	EndIf

	if lCmp

		UC1->(DbSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
		UC1->(DbSeek(UC0->UC0_FILIAL+UC0->UC0_NUM))
		While UC1->(!Eof()) .AND. UC1->UC1_FILIAL+UC1->UC1_NUM == UC0->UC0_FILIAL+UC0->UC0_NUM

			nPos := aScan(aSL4, {|x| AllTrim(x[1])==AllTrim(UC1->UC1_FORMA) })

			if nPos <= 0
				AAdd(aSL4,{UC1->UC1_FORMA, UC1->UC1_VALOR }) //adiciona forma
			else
				aSL4[nPos][2] += UC1->UC1_VALOR
			endif

			UC1->(DbSkip())
		enddo
		
		SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
		SA1->(DbSeek(xFilial("SA1") + UC0->UC0_CLIENT + UC0->UC0_LOJA ))

		Posicione("SA6",1,xFilial("SA6")+UC0->UC0_OPERAD,"A6_NOME")

	else

		//posiciona nos arquivos utilizados
		SL4->(DbSetOrder(1)) //L4_FILIAL+L4_NUM+L4_ORIGEM
		SL4->(DbSeek(xFilial("SL4") + SL1->L1_NUM))

		While SL4->(!EOF()) .and. SL4->L4_FILIAL == xFilial("SL4") .and. SL4->L4_NUM == SL1->L1_NUM

			nPos := aScan(aSL4, {|x| AllTrim(x[1])==AllTrim(SL4->L4_FORMA)})

			if nPos <= 0
				AAdd(aSL4,{SL4->L4_FORMA,(SL4->L4_VALOR-SL4->L4_TROCO)}) //adiciona forma
			else
				aSL4[nPos][2] += (SL4->L4_VALOR-SL4->L4_TROCO)
			endif

			SL4->(dbskip())
		EndDo

		SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
		SA1->(DbSeek(xFilial("SA1") + SL1->L1_CLIENTE + SL1->L1_LOJA))

		Posicione("SA6",1,xFilial("SA6")+SL1->L1_OPERADO,"A6_NOME")

	endif

	//verifica se possui a forma de pagamento para impressao do cupom nao fiscal
	For nX:=1 to len(aSL4)
		AAdd(_aPgtos, {AllTrim(RetField("SX5",1,xFilial("SX5")+"24"+aSL4[nX][1],"X5_DESCRI")), Alltrim(Transform(aSL4[nX][2],"@E 999,999,999.99"))})
	Next nX

	_aMsg := {} //mensagens do cupom

	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )

	cTxtTmp := Alltrim(SM0->M0_NOMECOM)
	AAdd( _aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)//SM0->M0_NOMECOM
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, Space(nLarg) )

	cTxtTmp := "***** HAVER *****"
	AAdd( _aMsg, Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp)
	AAdd( _aMsg, "@VIA@" )
	
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, PadR("DATA.....: "+DtoC(date())+"  HORA...: "+time(),nLarg) )
	if lCmp
		AAdd( _aMsg, PadR("N. COMPEN.: "+alltrim(UC0->UC0_NUM)+"      PLACA..: "+SubStr(UC0->UC0_PLACA,1,3)+"-"+SubStr(UC0->UC0_PLACA,4,4),nLarg) )
	else
		AAdd( _aMsg, PadR("N. CUPOM.: "+alltrim(SL1->L1_DOC)+"      PLACA..: "+SubStr(SL1->L1_PLACA,1,3)+"-"+SubStr(SL1->L1_PLACA,4,4),nLarg) )
	endif
	AAdd( _aMsg, PadR("OPERADOR.: "+AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME),nLarg) )
	AAdd( _aMsg, PadR("CLIENTE..: "+AllTrim(SA1->A1_COD)+"/"+AllTrim(SA1->A1_LOJA)+" - "+AllTrim(SA1->A1_NOME),nLarg) )
	AAdd( _aMsg, Space(nLarg) )

	if lCmp
		AAdd( _aMsg, PadR("FORMAS DE ENTRADA UTILIZADAS:",nLarg) )
	else
		AAdd( _aMsg, PadR("PRODUTOS NO CUPOM:",nLarg) )

		dbselectarea("SL2")
		SL2->(dbSetOrder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO
		SL2->(dbSeek(xFilial("SL2") + SL1->L1_NUM))

		While SL2->(!EOF()) .and. SL2->L2_NUM == SL1->L1_NUM .and. SL2->L2_FILIAL == SL1->L1_FILIAL
			AAdd( _aMsg, PadR(""+AllTrim(SL2->L2_ITEM)+" - "+AllTrim(SL2->L2_DESCRI)+": QTD - "+Alltrim(Transform(SL2->L2_QUANT,"@E 999,999,999.999")),nLarg) )
			SL2->(dbskip())
		EndDo

		AAdd( _aMsg, Space(nLarg) )
		AAdd( _aMsg, PadR("FORMAS DE PAGAMENTO UTILIZADAS NO CUPOM:",nLarg) )
	endif

	For nI:=1 to Len(_aPgtos)
    	AAdd( _aMsg, PadR(_aPgtos[nI][1]+Space(nLarg-(len(_aPgtos[nI][1]+_aPgtos[nI][2])))+_aPgtos[nI][2], nLarg) )
    Next nI

    if !lCmp
	    /* array aNccItens (Creditos do Venda Assistida)
			AAdd(_aNccItens, { .F.	, SE1->E1_SALDO 		, SE1->E1_NUM		, SE1->E1_EMISSAO	,;
				  					  SE1->(Recno())		, SE1->E1_XSALDOS 	, SuperGetMV("MV_MOEDA1")	, SE1->E1_MOEDA	  	,;
				  					  SE1->E1_PREFIXO		, SE1->E1_PARCELA	, SE1->E1_TIPO })
		*/
	    If Type("_aNCCItens") <> "U" .and. len(_aNCCItens) > 0
	    	For nX:=1 to len(_aNCCItens)
	    		If _aNCCItens[nX][1]
	    			cPref := "CREDITO: "+_aNCCItens[nX][9]+"/"+_aNCCItens[nX][3]+" - "+_aNCCItens[nX][10]
	    			cSufi := Alltrim(Transform(_aNCCItens[nX][2],"@E 999,999,999.99"))
	    			AAdd( _aMsg, PadR(cPref+Space(nLarg-(len(cPref+cSufi)))+cSufi, nLarg) )
	    		EndIf
	    	Next nX
	    EndIf
	endif

	AAdd( _aMsg, Space(nLarg) )

	if lCmp
		AAdd( _aMsg, PadR("PREFIXO..: "+cPfxVlh,nLarg) )
		AAdd( _aMsg, PadR("N. HAVER.: "+alltrim(UC0->UC0_NUM),nLarg) )
	else
		AAdd( _aMsg, PadR("PREFIXO..: "+cPfxVlh,nLarg) )
		AAdd( _aMsg, PadR("N. HAVER.: "+alltrim(SL1->L1_DOC),nLarg) )
	endif

	AAdd( _aMsg, PadR("PARCELA..: "+SubStr("VLH",1,TamSx3("E1_PARCELA")[1]),nLarg) )

	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, PadR("VALOR HAVER: R$ "+AllTrim(Transform(nVale,"@E 999,999,999.99")),nLarg) )

	cExtenso := "**("+AllTrim(Extenso(nVale))+")**"
	While !empty(cExtenso)
		 AAdd( _aMsg, substr(cExtenso,1,nLarg) )
		 if len(cExtenso) > nLarg
		 	cExtenso := substr(cExtenso,nLarg+1,len(cExtenso)-(nLarg+1))
		 else
		 	cExtenso := ""
		 endif
	EndDo

	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, Space(nLarg) )

	For nX:=1 to Len( _aMsg )
		_cMsg += _aMsg[nX] + chr(10)
	Next nX

	_aMsg := {} //mensagens do cupom
	AAdd( _aMsg, Space(nLarg) )
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, PadR("NAO PODE SER TROCADO POR DINHEIRO",nLarg) )
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
		
		if nX <= len(aTitVias)
			cTxtTmp := "via "+aTitVias[nX]
			cTxtTmp := Space((nLarg-Len(cTxtTmp))/2) + cTxtTmp
			cTxtTmp := StrTran(_cMsg, "@VIA@",cTxtTmp)
		else
			cTxtTmp := _cMsg
		endif

		if lCmp
			U_SetMsgRod("Aguarde, imprimindo comprovante Vale Haver - " + StrZero(nVias,2) )
		else
			STFMessage("TPDVR006","STOP", "Aguarde, imprimindo comprovante Vale Haver - " + StrZero(nVias,2))
			STFShowMessage("TPDVR006")
		endif

		STWManagReportPrint(cTxtTmp,1/*nVias*/)
		
	Next nX
	CursorArrow()

	if lCmp
		U_SetMsgRod("" )
	else
		STFMessage("TPDVR006","STOP", "")
		STFShowMessage("TPDVR006")
	endif

EndIf

RestArea( aAreaSM0 )
RestArea( aAreaSL1 )
RestArea( aAreaSL2 )
RestArea( aAreaSL4 )
RestArea( aAreaSA1 )
RestArea( aAreaSA6 )
RestArea( aAreaUC0 )
RestArea( aAreaUC1 )
RestArea( aArea )

Return
