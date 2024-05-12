#INCLUDE "TOTVS.CH"
#INCLUDE "autodef.ch"
#INCLUDE "poscss.ch"

Static nQtdCht := 0
Static lSelCMC7 := SuperGetMv("TP_CHTCMC7",,.F.) //Define se obriga a seleção do cheque troco por CMC7

/*/{Protheus.doc} TPDVE007
Tela de seleção de Cheque Troco no PDV

@author Pablo Cavalcante
@since 16/05/2019
@version 1.0

@return ${return}, ${return_description}

@type function
/*/
User Function TPDVE007(nTroco, aChAvul, lImpChq)

	Local aArea         := GetArea()
	Local aAreaSL1      := SL1->(GetArea())

	Local cCorBg := SuperGetMv( "MV_LJCOLOR",,"07334C")// Cor da tela
	Local nWidth, nHeight
	Local nTamBut := 40
	Local nVlrChtSel := 0

	Private oButPesq
	Private oBtnOK
	Private oBtnCanc
	Private oGetCmc7
	Private cGetCmc7 := Space(34) //CMC7

	Private oPanelChq
	Private oTotCh
	Private nTotCh := 0
	Private cTotCh := Alltrim(Transform(nTotCh,"@E 999,999,999.99"))
	Private oTotDi
	Private nTotDi := 0
	Private cTotDi := Alltrim(Transform(nTotDi,"@E 999,999,999.99"))
	Private oTotTr
	Private nTotTr := 0
	Private cTotTr := Alltrim(Transform(nTotTr,"@E 999,999,999.99"))
	Private oGetChTr
	Private aChTrocos := {}
	Private nTrocoX := 0
	Private o7MsgInfo
	Private c7MsgInfo := ""

	Private oDlgChTrc

	Default nTroco := iif(SL1->(FieldPos("L1_XTROCCH"))>0 .and. SL1->L1_XTROCCH>0 .and. SL1->L1_TROCO1>0, SL1->L1_XTROCCH, 0) //STBGetTroco()
	Default aChAvul := {SL1->L1_DOC,SL1->L1_SERIE,"",SL1->L1_CLIENTE,SL1->L1_LOJA,,SL1->L1_PDV}
	Default lImpChq := .T. //realiza impressão do cheque

	nTotDi  := nTroco
	nTrocoX := nTroco

	If (nTrocoX <= 0) .or. (nTroco <= 0)
		Return {0,{}}
	EndIf

	CarChTroco() //carrega os cheques trocos que estao no controle do caixa logado

	If nTrocoX > 0 .and. len(aChTrocos)>0

		//limpa as tecla atalho
		U_UKeyCtr() 

	  	DEFINE MSDIALOG oDlgChTrc TITLE "" FROM 000,000 TO 400,600 PIXEL STYLE nOr(WS_VISIBLE, WS_POPUP)

	  	nWidth := (oDlgChTrc:nWidth/2)
	  	nHeight := (oDlgChTrc:nHeight/2)

	  	@ 000, 000 MSPANEL oPanelChq SIZE nWidth, nHeight OF oDlgChTrc
	  	oPanelChq:SetCSS( "TPanel{border: 2px solid #999999; background-color: #f4f4f4;}" )

	  	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, 017 OF oPanelChq
	  	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))
		if lSelCMC7
			@ 004, 005 SAY oSay1 PROMPT " Uso de Cheques Troco " SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
		else
			@ 004, 005 SAY oSay1 PROMPT " Lista de Cheques Troco " SIZE 100, 015 OF oPnlTop COLORS 0, 16777215 PIXEL
		endif
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))
		oClose := TBtnBmp2():New( 002,oDlgChTrc:nWidth-25,20,30,'FWSKIN_DELETE_ICO',,,,{|| iif(MsgYesNo("O valor do troco sera todo em dinheiro. Deseja realmente cancelar?","Cheque Troco"),oDlgChTrc:End(),)},oPnlTop,,,.T. )
		oClose:SetCss("TBtnBmp2{border: none;background-color: none;}")

		if lSelCMC7
			@ 025, 010 SAY oSay2 PROMPT "Lançamento Cheque por CMC7 (utilize leitor de código de cheques)" SIZE 300, 008 OF oPanelChq COLORS 0, 16777215 PIXEL
		else
			@ 025, 010 SAY oSay2 PROMPT "CMC7 (utilize leitor de código de cheques) / Núm. Cheque" SIZE 200, 008 OF oPanelChq COLORS 0, 16777215 PIXEL
		endif
		oSay2:SetCSS( POSCSS (GetClassName(oSay2), CSS_LABEL_FOCAL ))
		oGetCmc7 := TGet():New( 035, 010,{|u| iif(PCount()>0,cGetCmc7:=u,cGetCmc7)}, oPanelChq, nWidth-018, 013,,{|| ValidCMC7()},,,,,,.T.,,,{|| .T. },,,,,.F.,,"oGetCmc7",,,,.T.,.F.)
		oGetCmc7:SetCSS( POSCSS (GetClassName(oGetCmc7), CSS_GET_NORMAL ))

		//GRID
		@ 055, 010 MSPANEL oPnlGrid SIZE nWidth-018, 135 OF oPanelChq
		//oPnlGrid:SetCss("TPanel{border: none;background-color: none;}")
		oPnlGrid:SetCss("TPanel{border: none;}")

		@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,005 OF oPnlGrid ADJUST PIXEL
		oTop:Align := CONTROL_ALIGN_TOP
		//oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
		oTop:SetCSS("TBitmap{ margin: 0px 9px 0px 5px; border: 1px solid #"+cCorBg+"; background-color: #"+cCorBg+"; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
		oTop:ReadClientCoors(.T.,.T.)

		@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,040 OF oPnlGrid ADJUST PIXEL
		oBottom:Align := CONTROL_ALIGN_BOTTOM
		oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ) )
		oBottom:ReadClientCoors(.T.,.T.)

		@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlGrid ADJUST PIXEL
		oContent:Align := CONTROL_ALIGN_ALLCLIENT
		oContent:ReadClientCoors(.T.,.T.)
		oPnlAux := POSBrwContainer(oContent)

	    oGetChTr := fMSNewGe1(oPnlAux)
	    oGetChTr:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	    oGetChTr:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	    bSvblDb  := oGetChTr:oBrowse:bLDblClick
	    nPosPree := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="PREENCHIDO"})
	    nPosVal  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
		oGetChTr:oBrowse:bLDblClick := {|| iif(oGetChTr:oBrowse:nColPos==@nPosVal .and. oGetChTr:aCols[oGetChTr:oBrowse:NAT][@nPosPree]=="LBNO", U_UGdRstDb(@oGetChTr, @bSvblDb), Clique())}
		oGetChTr:oBrowse:bChange := {|| Refresh()}

		/* Label: Saldo Cheque Troco */
		nTop := 005	// Posição superior
		nLeft := 020 // Posição esquerda
		oLblSalTroc := TSay():New(nTop, nLeft, {|| "Saldo Cheque Troco"}, oBottom,,,,,,.T.,,,150,10)
		oLblSalTroc:SetCSS( POSCSS (GetClassName(oLblSalTroc), CSS_LABEL_NORMAL ))

		/* Label: 0.00 */
		oTotDi := TSay():New(nTop+10, nLeft, {|| cTotDi}, oBottom,,,,,,.T.,,,100,10)
		oTotDi:SetCSS( POSCSS (GetClassName(oTotDi), CSS_LABEL_FOCAL ))

		/* Label: Total Cheque Troco */
		oLblTrocCh := TSay():New(nTop, nLeft+130, {|| "Total Cheque Troco"}, oBottom,,,,,,.T.,,,150,10)
		oLblTrocCh:SetCSS( POSCSS (GetClassName(oLblTrocCh), CSS_LABEL_NORMAL ))

		/* Label: 0.00 */
		oTotCh := TSay():New(nTop+10, nLeft+130, {|| cTotCh}, oBottom,,,,,,.T.,,,100,10)
		oTotCh:SetCSS( POSCSS (GetClassName(oTotCh), CSS_LABEL_FOCAL ))

		// BOTAO CONFIRMAR
		oBtn1 := TButton():New( nHeight-25,;
								nWidth-nTamBut-10,;
								"&Confirmar",;
								oPanelChq	,;
								{|| nVlrChtSel := GeraChAvul(aChAvul,lImpChq), oDlgChTrc:End()},; //fazer gravação nos componentes do totvs pdv, ou preparar retorno para PE
								nTamBut,;
								013,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oBtn2 := TButton():New( nHeight-25,;
								nWidth-(2*nTamBut)-15,;
								"C&ancelar",;
								oPanelChq	,;
								{|| iif(MsgYesNo("O valor do troco sera todo em dinheiro. Deseja realmente cancelar?","Cheque Troco"),(oDlgChTrc:End()),)},;
								nTamBut,;
								013,;
								,,,.T.,;
								,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_ATIVO ))

		o7MsgInfo := TSay():New(nHeight-25, 010, {|| c7MsgInfo }, oPanelChq,,,,,,.T.,,,200,25)
		cCssTst := POSCSS (GetClassName(oLblSalTroc), CSS_LABEL_FOCAL )
		o7MsgInfo:SetCSS( StrTran(cCssTst,"color: #606060;","color: #B30003;") )

		ACTIVATE MSDIALOG oDlgChTrc CENTERED

		//restaura as teclas atalho
		U_UKeyCtr(.T.)

	EndIf

	If SL1->(FieldPos("L1_XTROCCH"))>0 .and. SL1->(!Eof()) .and. IsInCallStack("U_TPDVP005")
		RecLock("SL1",.F.)
			SL1->L1_XTROCCH := nVlrChtSel
		SL1->(MsUnlock())
	EndIf
	
	RestArea(aAreaSL1)
	RestArea(aArea)

Return {nTotDi,aChTrocos}

//--------------------------------------------------------------
Static Function fMSNewGe1(oPnlAux)

	Local nX
	Local aHeaderEx    := {}
	Local aColsEx      := {}
	Local aFieldFill   := {}
	Local aFields      := {"MARK","UF2_NUM","UF2_VALOR","UF2_BANCO","UF2_AGENCI","UF2_CONTA","PREENCHIDO","RECNO"}
	Local aAlterFields := {"UF2_VALOR"}
	Local nLinMax 	   := 999  // Quantidade delinha na getdados

	nWidth  := (oPnlAux:nWidth/2)
	nHeight := (oPnlAux:nHeight/2)

	// Define field properties
	Aadd(aHeaderEx,{'','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	For nX := 1 to Len(aFields)
		If AllTrim(aFields[nX]) == "PREENCHIDO"
			Aadd(aHeaderEx,{'Preenchido','PREENCHIDO','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
		ElseIf !empty(GetSx3Cache( aFields[nX] ,"X3_CAMPO"))
			if aFields[nX] == "UF2_VALOR"
				aadd(aHeaderEx, U_UAHEADER("UF2_VALOR") )
				aHeaderEx[len(aHeaderEx)][6] := "U_TPDVE07A()"
			else
				aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
			endif
		Endif
	Next nX
	Aadd(aHeaderEx,{"RECNO","RECNO","@E 99999999999999999",17,0,"","","N","","","",""})

	if !lSelCMC7
		aColsEx := aClone(aChTrocos)
	endif

	If Len(aColsEx) == 0
		Aadd(aColsEx, {"LBNO", space(tamsx3("UF2_NUM")[1]), 0 /*"UF2_VALOR"*/, space(tamsx3("UF2_BANCO")[1]), space(tamsx3("UF2_AGENCI")[1]), space(tamsx3("UF2_CONTA")[1]), "LBNO", 0, .F.})
	EndIf

Return MsNewGetDados():New( 055, 010, 130, nWidth-010, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "AllwaysTrue",;
aAlterFields, , nLinMax, "AllwaysTrue", "AllwaysTrue", "AllwaysTrue", oPnlAux, aHeaderEx, aColsEx)

//--------------------------------------------------------------
Static Function Clique()

	Local nPosMark  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosVal   := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})

	If len(oGetChTr:aCols) == 0
		Return()
	Endif

	If oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosMark] == "LBOK"
		oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosMark] := "LBNO"
	ElseIf oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosMark] == "LBNO"
		If oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal]>0 .and. (oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal] + nTotCh) <= nTotTr
			oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosMark] := "LBOK"
		ElseIf oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal]>0 .and. (oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal] + nTotCh) > nTotTr
			//MsgInfo('Valor de cheque inválido! O total dos valores de cheque troco utilizados não pode ser maior do que o total de troco.','Atenção')
			//STFMessage( ProcName(), "STOP", "O valor do cheque troco não pode ser maior que o saldo de troco:"+" "+AllTrim(Str(nTotDi,10,2))+" "+"" )
			//STFShowMessage(ProcName())
			c7MsgInfo := "O valor do cheque troco não pode ser maior que o saldo de troco:"+" "+AllTrim(Str(nTotDi,10,2))+" "+""
			o7MsgInfo:Refresh()
		EndIf
	EndIf

	oGetChTr:oBrowse:Refresh()
	Refresh()

Return

//
// Abre modo de edição do campo "Vlr Nominal", quando seu valor for igual a zero
//
Static Function CHQEditCell()

	Local nPosMark  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosVal   := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})

	If Len(oGetChTr:aCols) == 0
		Return()
	Endif

	If oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosMark] == "LBNO" ;
		.and. (oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal] == 0) .and. ((oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal] + nTotCh) < nTotTr)

			nColPosBk := oGetChTr:oBrowse:nColPos
			oGetChTr:oBrowse:nColPos := nPosVal
			oGetChTr:EditCell()

	EndIf

Return

//--------------------------------------------------------------
// refresh na tela
//--------------------------------------------------------------
Static Function Refresh()

	Local nPosMark := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosVal  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
	Local nX

	nTotCh := 0
	nTotDi := 0
	nTotTr := nTrocoX

	If len(oGetChTr:aCols) == 0
		Return()
	Endif

	For nX:=1 to len(oGetChTr:aCols)
		If oGetChTr:aCols[nX][nPosMark] == "LBOK"
			nTotCh += oGetChTr:aCols[nX][nPosVal]
		EndIf
	Next nX

	nTotDi := nTrocoX - nTotCh

	cTotCh := Alltrim(Transform(nTotCh,"@E 999,999,999.99"))
	cTotDi := Alltrim(Transform(nTotDi,"@E 999,999,999.99"))
	//cTotTr := Alltrim(Transform(nTotTr,"@E 999,999,999.99"))

	oTotCh:Refresh()
	oTotDi:Refresh()
	//oTotTr:Refresh()

Return()

//
// rotina que carrega os cheques trocos para o array "aChTrocos"
//
Static Function CarChTroco()


	Local cPdv := ""

	//lRet := ChecaUserCX() //verifica se o usuario eh caixa (posiciona na SA6)
	aChTrocos := {}

	//If lRet

		cCdCx := SA6->A6_COD
		cPdv  := LjGetStation("LG_PDV")
		LjMsgRun("Aguarde... Carregando cheques troco...",,{ || aChTrocos := RetChTrocos(cCdCx,cPdv)})
		
		nQtdCht := Len(aChTrocos)
	//EndIf

Return

//--------------------------------------------------------------------------
// Rotina | RetChTrocos      | Autor | Pablo Cavalcante  | Data | 05.09.2014
//--------------------------------------------------------------------------
// Descr. | Rotina faz retorno dos cheques trocos de determinado caixa.
//        |
//--------------------------------------------------------------------------
// Uso    | Totvs GO
//--------------------------------------------------------------------------
Static Function RetChTrocos(cCdCx, cPdv)

	Local aArea := GetArea()
	Local cCondicao := ""
	Local bCondicao
	Local aChTc := {}
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)
	Default cPdv := ""

	cCondicao := " UF2_FILIAL = '"+xFilial("UF2")+"'"
	If lChTrOp
		cCondicao += " .AND. UF2_CODCX = '"+cCdCx+"'"
	Else
		cCondicao += " .AND. UF2_PDV = '"+PadR(cPdv,TamSx3("LG_PDV")[1])+"'"
	EndIf
	cCondicao += " .AND. UF2_DOC = '"+Space(TamSx3("UF2_DOC")[1])+"'"
	cCondicao += " .AND. UF2_SERIE = '"+Space(TamSx3("UF2_SERIE")[1])+"'"
	cCondicao += " .AND. UF2_STATUS <> '2' .AND. UF2_STATUS <> '3'" //2 -> cheque gerado na SEF e liberado (SE5); 3->Inutilizado

	// limpo os filtros da UF2
	UF2->(DbClearFilter())

	// executo o filtro na UF2
	bCondicao 	:= "{|| " + cCondicao + " }"
	UF2->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	UF2->(DbGoTop())

	While UF2->(!EOF()) //se nao encontrou resultados, o retorno sera zerado
		aadd(aChTc,{"LBNO", UF2->UF2_NUM,UF2->UF2_VALOR, UF2->UF2_BANCO, ;
			UF2->UF2_AGENCI, UF2->UF2_CONTA, iif(UF2->UF2_VALOR>0, "LBOK", "LBNO"), UF2->(RecNo()), .F.})
		UF2->(DbSkip())
	EndDo

	// limpo os filtros da UF2
	UF2->(DbClearFilter())

	RestArea( aArea )

Return(aChTc)

//--------------------------------------------------------------
// Verifica se o usuario eh caixa (posiciona na SA6)
//--------------------------------------------------------------
Static Function ChecaUserCX()

	Local lRet   	:= .T.
	Local lAchouSx5 := .F.
	Local lAchouSa6 := .T.

	Local nX := 0, cX5_CHAVE := ""
	Local aContent := {} //campos de uma tabela no SX5 (Vetor com os dados do SX5 - com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO)

	//??????????????????????????????????????????????????ø
	//? Verifica se usuario esta cadastrado como caixa. ?
	//¿??????????????????????????????????????????????????
	aContent := FWGetSX5( "23" )
	If Len(aContent) > 0
		For nX := 1 to Len(aContent)
			If Upper(Trim(aContent[nX][4])) == AllTrim(Upper(cUserName))
				cX5_CHAVE := aContent[nX][3]
				lAchouSx5 := .T.
				Exit
			EndIf
		Next nX
	EndIf

	If lAchouSx5 .AND. lRet
		DbSelectArea( "SA6" )
		If !(SA6->(DbSeek( xFilial("SA6") + SubStr( cX5_CHAVE, 1, 3 ))))
			lAchouSa6 := .F.
		EndIf
	EndIf

	If !lAchouSx5 .AND. lRet
		Help( " ", 1, "NOCAIXASX5" )
		lRet := .F.
	EndIf

	If !lAchouSA6 .AND. lRet
		Help( " ", 1, "NOCAIXASA6" )
		lRet := .F.
	EndIf

Return lRet

//--------------------------------------------------------------
/*/{TPDVE007.PRW} ValidCMC7
Description
Função que faz validação do codigo CMC7.
Também faz consulta nos itens do objeto oGetChTr

@param xParam Parameter Description
@return xRet Return Description
@author Pablo Cavalcante
@since 22/08/2014
/*/
//--------------------------------------------------------------
Static Function ValidCMC7()

	Local lRet      := .T.
	Local cCmc7     := cGetCmc7
	Local c1 := c2 := c3 := ""
	Local cBanco := cAgenc := cCompl := cNumer := cConta := ""
	Local nTamBanco := TamSx3("EF_BANCO")[1]
	Local nTamAgenc := TamSx3("EF_AGENCIA")[1]
	Local nTamConta := TamSx3("EF_CONTA")[1]
	Local nTamCheq  := TamSx3("EF_NUM")[1]
	Local nTamComp  := TamSx3("L4_COMP")[1]
	Local nPosBc    := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_BANCO"})
	Local nPosAg    := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_AGENCI"})
	Local nPosCt    := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_CONTA"})
	Local nPosNm    := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_NUM"})
	Local nPosPree  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="PREENCHIDO"})
	Local nGetAtual := oGetChTr:oBrowse:NAT
	Local nGetNew   := 0

	c7MsgInfo := ""
	o7MsgInfo:Refresh()

    If nTamConta > 10
    	nTamConta := 10
    EndIf

	If !Empty(cCmc7)//se nao preenchido passa

		If !lSelCMC7 .AND. Len(AllTrim(cCmc7)) <= TamSx3("UF2_NUM")[1]

			cNumer  := AllTrim(cCmc7)
			nGetNew := aScan(oGetChTr:aCols,{|x| val(x[nPosNm])==val(cNumer) })

		Else

			If ((SubStr(cCmc7,1,1) != "<") .AND. len(Alltrim(cCmc7)) < 30) .OR. ((SubStr(cCmc7,1,1) == "<") .AND. len(Alltrim(cCmc7)) < 34) //tamanho
				//MsgInfo('Campo CMC7 inválido. Faltam digitos para processamento.',"Atenção")
				//STFMessage( ProcName(), "STOP",  )
				//STFShowMessage(ProcName())
				c7MsgInfo := "Campo CMC7 inválido. Faltam digitos para processamento."
				o7MsgInfo:Refresh()
				lRet := .F.
				Return lRet
			EndIf

		    If !SubStr(cCmc7,1,1) = "<"
				c1 := SubStr(cCmc7,1,8)
				c2 := SubStr(cCmc7,9,10)
				c3 := SubStr(cCmc7,19,12)
				cCmc7 := "<"+c1+"<"+c2+">"+c3+":"
			EndIf

		    //<23732184<0480001815>336203201458: //<23733874<0480001015>336202455458:

			cBanco := PadR(SubStr(cCmc7, 2, 3),nTamBanco) //Banco
			cAgenc := PadR(SubStr(cCmc7, 5, 4),nTamAgenc) //Agencia
			cCompl := PadR(SubStr(cCmc7, 11, 3),nTamComp) //Comp.
			cNumer := PadR(SubStr(cCmc7, 14, 6),nTamCheq) //Nro Cheque

			//buscando a conta para cada banco
			If Alltrim(cBanco)  $  "314/001" //itau, brasil
			 	cConta := SubStr(cCmc7, 27, 6)  //Conta
			ElseIf Alltrim(cBanco) = "756" //sicoob
			 	cConta := SubStr(cCmc7, 23, 9)  //Conta
			ElseIf Alltrim(cBanco) = "237" //bradesco
			 	cConta := SubStr(cCmc7, 26, 6)  //Conta
			ElseIf Alltrim(cBanco) = "104" //caixa
			 	cConta := SubStr(cCmc7, 24, 9)  //Conta
			ElseIf Alltrim(cBanco) = "356" //real
			 	cConta := SubStr(cCmc7, 26, 7)  //Conta
			ElseIf Alltrim(cBanco) = "399" //hsbc
			 	cConta := SubStr(cCmc7, 23, 9)  //Conta
			ElseIf Alltrim(cBanco) = "745" //citibank
				cConta := SubStr(cCmc7, 25, 8)  //Conta
			Else
				cConta := SubStr(cCmc7, 25, 8)  //Conta
				//cConta := SubStr(cCmc7, 23+(10-nTamConta), nTamConta) //Conta
			EndIf

			nGetNew := aScan(oGetChTr:aCols,{|x| val(x[nPosBc])==val(cBanco) .AND. val(x[nPosAg])==val(cAgenc) .AND. val(x[nPosCt])==val(cConta) .AND. val(x[nPosNm])==val(cNumer) })

			//se ainda não foi adicionado no aCols, busco o array aChTrocos
			if lSelCMC7 .AND. nGetNew == 0
				nGetNew := aScan(aChTrocos,{|x| val(x[nPosBc])==val(cBanco) .AND. val(x[nPosAg])==val(cAgenc) .AND. val(x[nPosCt])==val(cConta) .AND. val(x[nPosNm])==val(cNumer) })
				if nGetNew > 0
					if empty(oGetChTr:aCols[1][nPosNm])
						aSize(oGetChTr:aCols, 0)
					endif
					aadd(oGetChTr:aCols, Nil)
					aIns(oGetChTr:aCols, 1)
					oGetChTr:aCols[1] := aClone(aChTrocos[nGetNew])
					nGetNew := 1//len(oGetChTr:aCols)
				else
					//STFMessage( ProcName(), "STOP",  )
					//STFShowMessage(ProcName())
					c7MsgInfo := "O cheque referente ao CMC7 informado não está disponível para uso."
					o7MsgInfo:Refresh()
					lRet := .F.
					Return lRet
				endif
			endif

		EndIf

		If nGetNew > 0

			oGetChTr:GoTo(nGetNew)
			oGetChTr:Refresh()
			oGetChTr:oBrowse:Refresh()
			oGetChTr:oBrowse:SetFocus()

			nPosVlr := GdFieldPos("UF2_VALOR",oGetChTr:aHeader)

			//se cheque é pre preenchido, tento marcar
			If oGetChTr:aCols[oGetChTr:nAt][nPosPree]=="LBOK" 
				Clique()
			//senao abro campo pra digitação
			Elseif (oGetChTr:nAt == nGetNew) .and. (nPosVlr > 0) 
				oGetChTr:oBrowse:nColPos := nPosVlr
				oGetChTr:EditCell()
			EndIf

			cGetCmc7 := Space(34)
			oGetCmc7:Refresh()

		EndIf

	EndIf

Return lRet

//--------------------------------------------------------------
// Valida o total de cheque troco
//--------------------------------------------------------------
User Function TPDVE07A()

	Local nPosVal   := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
	Local nPosMark  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local lRet      := .F.
	Local nTotOt    := 0 //total de valor dos demais cheques
	Local nX

	For nX:=1 to len(oGetChTr:aCols)
		If nX <> oGetChTr:oBrowse:NAT .and. oGetChTr:aCols[nX][nPosMark] == "LBOK"
			nTotOt += oGetChTr:aCols[nX][nPosVal]
		EndIf
	Next nX

	If (M->UF2_VALOR + nTotOt) <= nTotTr
		oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal] := M->UF2_VALOR
		lRet := .T.
		If oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosMark] == "LBOK" .AND. oGetChTr:aCols[oGetChTr:oBrowse:NAT][nPosVal] > 0
			Refresh()
		Else
			Clique()
		EndIf
	Else
		//STFMessage( ProcName(), "STOP",  )
		//STFShowMessage(ProcName())
		c7MsgInfo := "O valor do cheque troco não pode ser maior que o saldo de troco:"+" "+AllTrim(Str(nTotDi,10,2))+" "+""
		o7MsgInfo:Refresh()
	EndIf

Return(lRet)

//
// preenche a lista de cheques troco utilizados, array "aChTrocos"
//
Static Function GeraChAvul(aChAvul,lImpChq)

	Local nPosMark  := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosRec := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="RECNO"})
	Local nPosVal   := aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
	Local cPorta := AllTrim(GetPvProfString("CHECKPRINTER", "PORT", "", GetClientDir() + "SMARTCLIENT.INI"))
	Local nTotChtUsado := 0
	Local nX

	//aChTrocos -> array com os cheques trocos utilizados (selecionados)
	aSize(aChTrocos, 0)

	for nX:=1 to len(oGetChTr:aCols)
		if oGetChTr:aCols[nX][nPosMark] == "LBOK" .AND. oGetChTr:aCols[nX][nPosVal] > 0
			Aadd(aChTrocos,aClone(oGetChTr:aCols[nX]))
			//se usar, subtraio dos cheques disponiveis
			nQtdCht--
		endif
	next nX

	lRetCh  := .T.
    For nX:=1 to Len(aChTrocos)
    	If !lRetCh
    		Exit //sai do For
    	ElseIf aChTrocos[nX][nPosMark] == "LBOK" .and. aChTrocos[nX][nPosVal] > 0
    		//-- Ajusta os dados do cheque troco OFF-LINE
			lRetCh := U_TRETE29A(aChTrocos[nX][nPosRec],aChTrocos[nX][nPosVal],aChAvul[01],aChAvul[02],aChAvul[03],aChAvul[04],aChAvul[05],aChAvul[06])
			if lRetCh
				nTotChtUsado += aChTrocos[nX][nPosVal]
			endif
    	EndIf
	Next nX

	//U_XHELP("GeraChAvul","lImpChq: "+U_XtoStrin(lImpChq)+CRLF+;
	//					"lRetCh: "+U_XtoStrin(lRetCh)+CRLF+;
	//					"aChTrocos: "+U_XtoStrin(aChTrocos)+CRLF+;
	//					"cPorta: "+U_XtoStrin(cPorta)+CRLF,)

	If lImpChq .and. lRetCh .and. Len(aChTrocos)>0 .and. ((!Empty(LjGetStation("IMPCHQ")) .AND. !Empty(LjGetStation("PORTCHQ"))) .or. !Empty(cPorta))
		If MsgYesNo("Deseja realizar a impressão dos cheques troco?")
			//realiza a impressao dos cheques troco
			U_TPDVE07B(aChTrocos, SL1->L1_CLIENTE, SL1->L1_LOJA)
		EndIf
	EndIf

Return nTotChtUsado

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVE07B
Realiza a impressao do cheque troco

@author Pablo Cavalcante
@since 26/08/2014
@version P11
/*/
//-------------------------------------------------------------------

User Function TPDVE07B(_aChTrocos,cCliente,cLoja)

	Local aArea	:= GetArea()
	Local aAreaSA1 := SA1->(GetArea())
	Local aImpCheque := {} //controla se os cheques da venda foram impressos
	Local nI		 := 0  //controle de loop
	Local lTemCH	 := .F.
	Local cObs		 := ""
	Local cVerso	 := ""
	Local nX

	//{"MARK","UF2_NUM","UF2_VALOR","UF2_BANCO","UF2_AGENCI","UF2_CONTA","PREENCHIDO","RECNO"}
	Local nPosMark  := 1 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosRecno := 8 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="RECNO"})
	Local nPosVal   := 3 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
	Local nPosBco   := 4 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_BANCO"})
	Local nPosAge   := 5 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_AGENCI"})
	Local nPosCon   := 6 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_CONTA"})
	Local nPosNum   := 2 //aScan(oGetChTr:aHeader,{|x| AllTrim(x[2])=="UF2_NUM"})
	Local cFavorec
	Local cCidade
	Local cBanco
	Local nValor
	Local dEmissao
	Local cAgencia
	Local cConta
	Local cCheque

	Default cCliente  := AllTrim(GetMv("MV_CLIPAD"))  //SL1->L1_CLIENTE
	Default cLoja     := AllTrim(GetMv("MV_LOJAPAD")) //SL1->L1_LOJA

	SA1->(DbSetOrder(1)) //A1_FILIAL + A1_COD + A1_LOJA
	If SA1->(DbSeek(xFilial("SA1")+cCliente+cLoja))
		cFavorec := "" //SA1->A1_NOME //nome do favorecido -> o cliente solicitou para o cheque não sair nominal
		cCidade  := Left(SM0->M0_CIDCOB,15)
		cCidade  := If(Empty(cCidade), "Goiania", cCidade)

		For nX:=1 to Len(_aChTrocos)
			If _aChTrocos[nX][nPosMark] == "LBOK" .and. _aChTrocos[nX][nPosVal]>0

				cBanco   := _aChTrocos[nX][nPosBco]
				nValor   := _aChTrocos[nX][nPosVal]
				dEmissao := dDataBase //SuperGetMV("MV_DATCHE") == "E"
				cAgencia := _aChTrocos[nX][nPosAge]
				cConta   := _aChTrocos[nX][nPosCon]
				cCheque  := _aChTrocos[nX][nPosNum]

				//rotina padrao de impressao de cheque (LOJXFUNB.prx)
				//LjImpCheque( cBanco      ,cAgencia  ,cConta   ,cCheque   ,;
				//             @nValor     ,@cFavorec ,@cCidade ,@dEmissao ,;
				//             @cObs       ,@cVerso   ,   .F.   ,     nX   ,;
				//             @aImpCheque )

				U_TPDVE07D(  cBanco      ,cAgencia  ,cConta   ,cCheque   ,;
				             @nValor     ,@cFavorec ,@cCidade ,@dEmissao ,;
				             @cObs       ,@cVerso   ,   .F.   ,     nX   ,;
				             @aImpCheque )

			EndIf
		Next nX
	EndIf

	RestArea(aAreaSA1)
	RestArea(aArea)

Return(NIL)

//
// Teste de impressao de cheque no PDV
// ( Venda Assistida -> Ações Relacionadas -> Teste de Impressão de Cheque )
//
User Function TPDVE07C()

	//Desc.     ?Exibe interface grafica para coletar os dados para impressao?
	//          ?dos cheques e executa funcao GENERICA LJIMPCHEQUE (SIGALOJA)?
	//Private NVLRTOT := 100
	Local _aChTrocos := {{"LBOK",'000001',100,'001',"000001",'000001','',0}} //{"MARK","UF2_NUM","UF2_VALOR","UF2_BANCO","UF2_AGENCI","UF2_CONTA","PREENCHIDO","RECNO"}
	Local cGetCodCli := AllTrim(GetMv("MV_CLIPAD"))
	Local cGetLoja 	 := AllTrim(GetMv("MV_LOJAPAD"))
	Local cPorta := AllTrim(GetPvProfString("CHECKPRINTER", "PORT", "", GetClientDir() + "SMARTCLIENT.INI"))

	If (!Empty(LjGetStation("IMPCHQ")) .AND. !Empty(LjGetStation("PORTCHQ"))) .or. !Empty(cPorta)

		If MsgYesNo("Deseja realizar a impressão do cheque TESTE?")
		//realiza a impressao dos cheques troco
			U_TPDVE07B(_aChTrocos,cGetCodCli,cGetLoja)
		EndIf
	EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³LJIMPCHEQUºAutor  ³ Vendas Clientes    º Data ³  11/08/00   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Faz a impressao do cheque utilizando a dll fiscal           º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºSintaxe   ³ExpA1 := LjImpCheque(ExpC1,ExpC2,ExpC3,ExpC4,ExpN5,ExpC6,   º±±
±±º			 ³                     ExpC7,ExpD8,ExpC9,ExpC10,ExpL11,ExpN12,º±±
±±º			 ³                     ExpA13)                                º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametro ³ExpC1 - Codigo do banco                                     º±±
±±º			 ³ExpC2 - Codigo da agencia                                   º±±
±±º			 ³ExpC3 - Numero da conta corrente                            º±±
±±º			 ³ExpC4 - Numero do cheque                                    º±±
±±º			 ³ExpN5 - Valor do cheque                                     º±±
±±º			 ³ExpC6 - Nome do favorecido                                  º±±
±±º			 ³ExpC7 - Nome da cidade                                      º±±
±±º			 ³ExpD8 - Data de emissao                                     º±±
±±º			 ³ExpC9 - Observacao do cheque                                º±±
±±º			 ³ExpC10 - Dados impressos no verso do cheque                 º±±
±±º			 ³ExpL11 - Define se deve atualizar EF_IMPRESS                º±±
±±º			 ³ExpN12 - Parcela da venda(aPgtos)                           º±±
±±º			 ³ExpA13 - Controla que cheque foi impresso para gravar no    º±±
±±º			 ³		   EF_IMPRESS										  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ExpA1[1] - Determina se eh para executar a funcao IfCheque  º±±
±±º			 ³ExpA1[2] - Determina se o cheque foi impresso no PE		  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function U_TPDVE07D(  cBanco     ,cAgencia  ,cConta   ,cCheque   ,;
                      nValor     ,cFavorec  ,cCidade  ,dEmissao  ,;
                      cObs       ,cVerso    ,lAtuSEF  ,nParc     ,;
                      aImpCheque )

Local aRet := {.T.,.F.}
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Estrutura da aRet                                                   ³
//³[1] - logico, se e ou nao para executar a funcao IFCheque           ³
//³[2] - logico, se o cheque foi ou nao impresso no ponto de entrada   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lImprimiu 	:= .F. 		// Variavel que verifica se imprimiu
Local nRet 			:= 0		// Variavel de retorno
Local nOpc 			:= 0		// Variavel de opção do DEFINE SBUTTON
Local lImpCheque    := .F.    // Controla se o cheque foi impresso
Local nPosImpCheque := 0      // Posicao do cheque no array aImpCheque para determinar se foi impresso
Local lFtvdVer12	:= FindFunction("LjFTvd") .AND. LjFTVD() //Verifica se é Release 11.7 e o FunName é FATA701 - Compatibilização Venda Direta x Venda Assisitida
//Local cNomeProg		:= Iif(lFtvdVer12,"FATA701","LOJA701") //Nome da Rotina
Local lUsaDisplay 	:= !Empty(STFGetStation("DISPLAY")) // Verifica se a estacao possui Display
Local aDados		:= {}
Local cExtenso		:= Extenso(nValor,.F.,,,,.T.,,)
Local cModImpChq    := Alltrim(SLG->LG_IMPCHQ) // Felipe Sousa - Rede Maracanã - 09/08/2023

Local cPorta := AllTrim(GetPvProfString("CHECKPRINTER", "PORT", "", GetClientDir() + "SMARTCLIENT.INI"))

Private nHdlCH := -1
Private oAutocom := Autocom():New()

Default lAtuSEF     	:= .T.		// Variavel que recebe atualização do SEF
Default nParc       	:= 1      	// Parcela do aPgtos
Default aImpCheque  	:= {}     	// Controla impressao do cheque
Default cBanco     		:= ""
Default cAgencia		:= ""
Default cConta			:= ""
Default cCheque			:= ""
Default nValor			:= 0
Default cFavorec 		:= ""
Default cCidade  		:= ""
Default dEmissao		:= dDataBase
Default cObs			:= ""
Default cVerso			:= ""

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se existe o ponto de entrada para impressao de cheque                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock('LJCHEQUE') .AND. !lFtvdVer12
	aRet := ExecBlock('LJCHEQUE',.F.,.F.,{cBanco,nValor,cFavorec,dEmissao,cObs,cVerso,cCheque,cConta,nParc,cCidade})
EndIf

If ExistBlock('FTVDCHEQUE') .AND. lFtvdVer12
	aRet := ExecBlock('FTVDCHEQUE',.F.,.F.,{cBanco,nValor,cFavorec,dEmissao,cObs,cVerso,cCheque,cConta,nParc,cCidade})
EndIf

If aRet[1]
	While !lImprimiu
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Executa Dialog de confirmação da Impressão do Cheque                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lUsaDisplay
			//DisplayEnv(StatDisplay(), "1C"+ Upper("Insira o cheque número: " + cCheque) )	//"Insira o cheque número: "
			//DisplayEnv(StatDisplay(), "2C"+ Upper("E pressione <ENTER>") )					//"E pressione <ENTER>"

			STFFireEvent(ProcName(0), "STDisplay", { StatDisplay(), "1C"+ Upper("Insira o cheque número: " + cCheque) } )
			STFFireEvent(ProcName(0), "STDisplay", { StatDisplay(), "2C"+ Upper("E pressione <ENTER>") } )

		End
		DEFINE MSDIALOG oDlgCheque TITLE ("Impressao de cheques") FROM 96,42 TO 230,285 PIXEL		// "Impressao de cheques"
			@ 03,03 TO 048,117 PIXEL
			@ 13,06 SAY ("Insira o cheque número: " + cCheque) OF oDlgCheque PIXEL SIZE 105,10								// "Insira o cheque número: "
			@ 23,06 SAY ("Banco: " + cBanco + " - Agência: " + cAgencia) OF oDlgCheque PIXEL SIZE 105,10					// "Banco: " / " - Agência: "
			@ 33,06 SAY ("Conta: " + cConta + " - Valor  : " + Alltrim(Str(nValor,14,2))) OF oDlgCheque PIXEL SIZE 105,10	// "Conta: " / " - Valor  : "
			DEFINE SBUTTON FROM 53,55 TYPE 1 ENABLE OF oDlgCheque ACTION (nOpc:=1,oDlgCheque:End())
			DEFINE SBUTTON FROM 53,90 TYPE 2 ENABLE OF oDlgCheque ACTION (nOpc:=0,oDlgCheque:End())
		ACTIVATE DIALOG oDlgCheque CENTERED

		If nOpc == 1
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//| "Aguarde a impressão do cheque..."   |
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lUsaDisplay
				//DisplayEnv(StatDisplay(), "1C"+ Upper("Aguarde a impressão do cheque...") )
				//DisplayEnv(StatDisplay(), "2C"+ " " )

				STFFireEvent(ProcName(0), "STDisplay", { StatDisplay(), "1C"+ Upper("Aguarde a impressão do cheque...") } )
				STFFireEvent(ProcName(0), "STDisplay", { StatDisplay(), "2C"+ " " } )

			End
			If !Empty(cPorta)

				//LJMsgRun("Aguarde a impressão do cheque...",, {|| nRet := U_TPDVCHEC( cBanco, Alltrim(Transform(nValor,"@E 999,999,999.99")), cFavorec, cCidade, DTOC(dEmissao) )})
				nRet := U_TPDVCHEC( cBanco, Alltrim(Transform(nValor,"@E 999,999,999.99")), cFavorec, cCidade, DTOC(dEmissao) )

			ElseIf !Empty(STFGetStat("IMPCHQ")) .AND. !Empty(STFGetStat("PORTCHQ"))//!Empty(LjGetStation("IMPCHQ")) .AND. !Empty(LjGetStation("PORTCHQ"))

				// Abertura da Impressora de Cheque
				/*If nHdlCH == -1
					nHdlCH := CHAbrir( LJGetStation("IMPCHQ"), LJGetStation("PORTCHQ") )
				    If nHdlCH < 0
				    	MsgStop("Falha na comunição com a Impressora de Cheque.")
				    EndIf
				EndIf

				//LJMsgRun("Aguarde a impressão do cheque...",, {|| nRet := CHImprime( nHdlCH, cBanco, StrZero(nValor,12,2), cFavorec, cCidade, DTOS(dEmissao), cObs, cVerso )}) //LOJXECF.prx
				//nRet := MyCHImprime( nHdlCH, cBanco, StrZero(nValor,12,2), cFavorec, cCidade, DTOS(dEmissao), cObs, cVerso )
				//Danilo: Chamo a padrão que tem no fonte LOJXECF
				nRet := CHImprime( nHdlCH, cBanco, StrZero(nValor,12,2), cFavorec, cCidade, DTOS(dEmissao), cObs, cVerso )
				
				// Fechamento da Impressora de Cheque
				CHFechar( nHdlCH, LJGetStation("PORTCHQ") )
				*/

				//Felipe Sousa - Rede Maracanã - 09/08/2023
				//Ajustado para validar se for impressora Chronos, enviar com separador de decimal
				If cModImpChq $ "CHRONOS 31100"
					aDados := {cBanco, AllTrim(Str(nValor,10,2)), PadR(cFavorec,60), Left(cCidade,15), DToS(dEmissao), cObs, cVerso, "","" }
				Else
					aDados := {cBanco, AllTrim(Str(nValor)), PadR(cFavorec,60), Left(cCidade,15), DToS(dEmissao), cObs, cVerso, "","" }
				EndIf

				if STFUsePrtCh()
					STFFireEvent(ProcName(0), "STCHPRINTS", aDados)
				endif

			Else
				nRet := 0
			EndIf
			lImprimiu := (nRet==0)
		Else
			lImprimiu := .T.
			Exit
		EndIf
		If !lImprimiu
			If lUsaDisplay
				//DisplayEnv(StatDisplay(), "1C"+ Upper("Falha na impressão do cheque") )
				//DisplayEnv(StatDisplay(), "2C"+ " " )

				STFFireEvent(ProcName(0), "STDisplay", { StatDisplay(), "1C"+ Upper("Falha na impressão do cheque") } )
				STFFireEvent(ProcName(0), "STDisplay", { StatDisplay(), "2C"+ " " } )

			End
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//| "Falha na impressão do cheque", "Não foi possível realizar a impressão do cheque. Será realizada a reimpressão."|
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			//Aviso("Falha na impressão do cheque", "Não foi possível realizar a impressão do cheque. Será realizada a reimpressão.", {"Ok"})
			if !MSGYESNO( "Não foi possível realizar a impressão do cheque. Deseja tentar imprimir novamente?", "Falha na Impressão do Cheque" )
				EXIT
			endif
		EndIf
	End

EndIf
lImpCheque  := lImprimiu .OR. aRet[2]
nPosImpCheque := Ascan(aImpCheque,{|x| x[1] == nParc })
If nPosImpCheque == 0
	AADD(aImpCheque,{nParc,lImpCheque})
Else
	aImpCheque[nPosImpCheque][2] := lImpCheque
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o cheque foi impresso para ser gravado no SEF                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If (lImprimiu .OR. aRet[2]) .AND. lAtuSEF
	DbSelectArea('SEF')
	DbSetOrder(1)

	cBanco   := PadR(cBanco, TamSx3("EF_BANCO")[1], " ")
	cAgencia := PadR(cAgencia, TamSx3("EF_AGENCIA")[1], " ")
	cConta   := PadR(cConta, TamSx3("EF_CONTA")[1], " ")
	cCheque  := PadR(cCheque, TamSx3("EF_NUM")[1], " ")

	If DbSeek( xFilial('SEF')+cBanco+cAgencia+cConta+cCheque )
		RecLock('SEF',.F.)
		SEF->EF_IMPRESS := 'S'
		MsUnLock()
	EndIf

EndIf

oAutocom := Nil

Return (aRet)

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±ºFuncao    ³CHImprime ºAutor  ³Microsiga           º Data ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Realiza a impressao do cheque                              º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ EXPn1 - Handle de uso da DLL                               º±±
±±º          ³ EXPc1 - Indica qual eh o banco do cheque                   º±±
±±º          ³ EXPc2 - Valor do cheque                                    º±±
±±º          ³ EXPc3 - Favorecido do cheque                               º±±
±±º          ³ EXPc4 - Municipio do cheque                                º±±
±±º          ³ EXPc5 - Data do cheque                                     º±±
±±º          ³ EXPc6 - Mensagem a ser impressa no cheque                  º±±
±±º          ³ EXPc7 - Mensagem a ser impressa no verso do cheque         º±±
±±º          ³ EXPc8 - Valor por extenso do cheque                        º±±
±±º          ³ EXPc9 - Texto da chancela do cheque                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ EXPn1 - Indica sucesso da execucao - 0 = OK / 1 = Nao OK   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGALOJA / FRONTLOJA                                       º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºAnalista  ³ Data/Bops/Ver ³Manutencao Efetuada                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºConrado Q ³05/04/07³10    ³BOPS 122711: Alterada a utilização da cham. º±±
±±º          ³        ³      ³SubStr(cUsuario,7,15) por cUserName         º±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function MyCHImprime( nImpHnd, cBanco, cValor, cFavorec, cCidade, cData, cMensagem, cVerso, cExtenso, cChancela )
Local nRet		:= -1										// Retorno da funcao da dll
Local cRet		:= Space(1)									// Retorno do status da impressora
Local cParam	:= ""										// Concatena o comando antes de ser enviado
Local aDadosUsu	:= {}										// Armazena os dados do usuario
Local cUsu		:= cUserName								// Recebe dados do usuario
Local nAno		:= 4										// Recebe a qtde de digitos de anos do usuario
Local cMoedaS	:= SuperGetMV( "MV_MOEDA1", ,"REAL" )
Local cMoedaP	:= SuperGetMV( "MV_MOEDAP1", ,"REAIS" )
Local cDataOrig	:= cData

DEFAULT cExtenso := Space(10)			// Recebe valor por extenso do cheque
DEFAULT cChancela := 'N'				// Verifica se imprimirá chancela

nRet := ChStatus( nImpHnd, '01', @cRet )

 If (CPaisLoc <> 'BRA') .OR. (nRet == 0)
 	  cExtenso:=Extenso(Val(cValor),.F.,,,,.T.,,)
 EndIf

// Busca dados do usuário para saber qtos digitos usa no ANO.
 PswOrder(2)
 If PswSeek( cUsu, .T. )
   aDadosUsu := PswRet() // Retorna vetor com informações do usuário
   nAno:= aDadosUsu[1][18]
 EndIf

 If nAno == 2
 	cData := SubStr(cData,3,6)
 EndIf

cParam := Str(nImpHnd)+"|"+cBanco+"|"+cValor+"|"+cFavorec+"|"+cCidade+"|"+cData+"|"+cMensagem+"|"+cVerso+"|"+cExtenso+"|"+cChancela+"|"+cPaisLoc

If Type("oImpFisc") <> "U" //oImpFisc <> Nil

	If Type("oImpFisc:oEcf:lImpCheque") <> "U" .AND. oImpFisc:oEcf:lImpCheque
		oRet := oImpFisc:ImpCheque(	cBanco	, Val(cValor)	, cDataOrig	, cFavorec	,;
									cCidade	, cMensagem		, cExtenso	, cMoedaS	,;
				 					cMoedaP	, cPaisLoc)


		If oRet:lRetorno
			nRet := 0
		EndIf

		Return nRet
	EndIf

EndIf

If ChkAutocom() == DLL_SIGALOJA						// Verifica o parametro MV_AUTOCOM
	CheckDLLLj()									// Verifica se a SIGALOJA.DLL esta aberta
	nRet := ExeDLLRun2(nHnd, 77, cParam)
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Pesquisa se o modelo do equipamento existe na AUTOCOM                          ³
	//³ Caso houver equipamento homologado nas duas DLLs, a prioridade sera a AUTOCOM. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If IsAutocom(EQUIP_IMPCHEQUE) == EQUIP_DLL_AUTOCOM
		nRet := oAutocom:CHImprime(cBanco, cValor, cFavorec, cCidade, cData, cMensagem, cVerso, cExtenso, cChancela )
	Else
		If IsAutocom(EQUIP_IMPCHEQUE) == EQUIP_DLL_SIGALOJA
			CheckDLLLj()								// Verifica se a SIGALOJA.DLL esta aberta
			nRet := ExeDLLRun2(nHnd, 77, cParam)
		EndIf
	EndIf
EndIf

Return nRet

//-----------------------------------------------------
// Retorna quantidade de cheques trocos disponiveis
//-----------------------------------------------------
User Function CHTEmpty()
	Local aCHTList
	Local cCdCx, cPdv
	if nQtdCht == 0
		cCdCx := SA6->A6_COD
		cPdv  := LjGetStation("LG_PDV")
		LjMsgRun("Aguarde... Carregando cheques troco...",,{|| aCHTList := RetChTrocos(cCdCx,cPdv)})
		nQtdCht := Len(aCHTList)
	endif
Return nQtdCht
