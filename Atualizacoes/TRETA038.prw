#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"

#DEFINE CRLF CHR(10)+CHR(13)


/*/{Protheus.doc} TRETA038
Rotina de Transferencia de Cheque Troco entre caixas

@author Totvs TBC
@since 08/04/2014
@version 1.0

@type function
/*/
User Function TRETA038()
	Local oFont14   := TFont():New ("Arial",, 14,, .F.)
	Local cTitulo 	:= "Transferencia de Cheques entre Caixas"
	Local oButton1
	Local oButton2
	Local oButton3
	Local oGroup1
	Local oGroup2
	Local oGroup3
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	Private oPdv
	Private cPdv	 := Space(TamSx3("LG_PDV")[1])
	Private cBanco	 := Space(TamSx3("UF1_COD")[1])
	Private cAgencia := Space(TamSx3("UF1_AGENCI")[1])
	Private cConta 	 := Space(TamSx3("UF1_NUMCON")[1])
	Private cChequeD := Space(TamSx3("UF2_NUM")[1])
	Private cChequeA := Padl("",TamSx3("UF2_NUM")[1],"9")
	Private nQtde := 0
	Private oQtde
	Private nTotal := 0
	Private oTotal
	Private cOpeOri := Space(TamSx3("UF2_CODCX")[1])
	Private cNomeOr := Space(TamSx3("A6_NOME")[1])
	Private cOpeDes := Space(TamSx3("UF2_CODCX")[1])
	Private cNomeDe := Space(TamSx3("A6_NOME")[1])
	Private lLib 	:= .T.

	Static oDlg

	//cadastra rotina para controle de acesso
	U_TRETA37B("CHQTRC","TRANSFERENCIA DE CHEQUE TROCO")

	//verifica se o usuário tem permissão para acesso a rotina
	cUsrCmp := U_VLACESS1("CHQTRC", RetCodUsr(),/*lMsg*/.F.)
	If cUsrCmp == Nil .OR. empty(cUsrCmp)
		MsgAlert('Usuário sem permissão de acesso a rotina de "CHQTRC - TRANSFERENCIA DE CHEQUE TROCO"!',"Atenção")
		Return
	EndIf

	DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000, 000  TO 500, 500 COLORS 0, 16777215 PIXEL

	//cabeçalho
	@ 005, 007 GROUP oGroup1 TO 092, 243 OF oDlg COLOR 0, 16777215 PIXEL

	//caixa
	@ 010, 016 SAY "Cx Origem" SIZE 038, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
	@ 020, 016 MSGET oCodOr VAR cOpeOri SIZE 021, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 CpoRetF3("UF2_CODCX")/*SX523*/ FONT oFont14 Valid (Empty(cOpeOri) .or. (ExistCpo("SX5","23"+cOpeOri) .and. DescCaixa() /*.and. VerCaixa(1,cOpeOri)*/ .and. CARREGAR()))

	@ 010, 048 SAY "Nome do Caixa" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
	@ 020, 048 MSGET oNomecx VAR cNomeOr SIZE 060, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When .F.

	@ 008, 111 GROUP oGroup3 TO 034, 113 OF oDlg COLOR 0, 16777215 PIXEL

	@ 010, 117 SAY "Cx Destino" SIZE 038, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
	@ 020, 117 MSGET oCodDe VAR cOpeDes SIZE 021, 007 OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL F3 CpoRetF3("UF2_CODCX") FONT oFont14 Valid (Empty(cOpeDes) .or. ((cOpeDes != cOpeOri) .and. ExistCpo("SX5","23"+cOpeDes) .and. DescCaixa() /*.and. VerCaixa(2,cOpeDes)*/))

	@ 010, 150 SAY "Nome do Caixa" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
	@ 020, 150 MSGET oNomeDe VAR cNomeDe SIZE 060, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14 When .F.

	If !lChTrOp
		@ 010, 214 SAY "Pdv" SIZE 040, 007 OF oDlg COLORS CLR_BLACK PIXEL FONT oFont14
		@ 020, 214 MSGET oPdv VAR cPdv SIZE 026, 007 F3 "PDV"  OF oDlg COLORS CLR_BLACK HASBUTTON PIXEL FONT oFont14 When lLib Valid (Empty(cPdv) .or. vLG_PDV(cPdv))
	EndIf

	//dados do banco e cheque (filtros)
	@ 036, 010 GROUP oGroup3 TO 038, 240 OF oDlg COLOR 0, 16777215 PIXEL

	@ 042, 016 SAY "Banco" SIZE 021, 007 OF oDlg PIXEL FONT oFont14
	@ 052, 016 MSGET oBanco VAR cBanco SIZE 021, 008 OF oDlg HASBUTTON PIXEL F3 "SA6" Picture "@!" WHEN .T. FONT oFont14 Valid CARREGAR()

	@ 042, 052 SAY "Agência" SIZE 028, 007 OF oDlg PIXEL FONT oFont14
	@ 052, 052 MSGET cAgencia SIZE 028, 008 OF oDlg PIXEL Picture "@!" WHEN .T. FONT oFont14

	@ 042, 087 SAY "Conta" SIZE 028, 007 OF oDlg PIXEL FONT oFont14
	@ 052, 087 MSGET cConta SIZE 039, 008 OF oDlg PIXEL Picture "@!" WHEN .T. FONT oFont14

	@ 067, 016 SAY "Cheque De ?" SIZE 046, 010 OF oDlg PIXEL FONT oFont14
	@ 077, 016 MSGET oChequeD VAR cChequeD SIZE 049, 008 OF oDlg PIXEL Picture "999999" FONT oFont14 Valid AjustNum(@cChequeD,@oChequeD) .AND. CARREGAR()

	@ 067, 087 SAY "Cheque Ate ?" SIZE 046, 010 OF oDlg PIXEL FONT oFont14
	@ 077, 087 MSGET oChequeA VAR cChequeA SIZE 049, 008 OF oDlg PIXEL Picture "999999" FONT oFont14 Valid AjustNum(@cChequeA,@oChequeA) .AND. CARREGAR()

	@ 052, 202 BUTTON oButton8 PROMPT "Imp Transf." SIZE 037, 012 OF oDlg PIXEL ACTION U_TRETR013(2)
	@ 077, 202 BUTTON oButton3 PROMPT "Carregar" SIZE 037, 012 OF oDlg PIXEL ACTION MsAguarde( {|| CARREGAR()}, "Aguarde", "Selecionando registros...", .F. )

	//@ C(029),C(005) MsGet oDebito Var _cDebito When Inclui .or. Altera Size C(035),C(007) COLOR CLR_BLACK PIXEL OF _oDlg FONT oFont14 Picture "@!" F3 "CT1" Valid ValCT1(_cDebito,@cDDebito)

	@ 095, 007 GROUP oGroup2 TO 225, 243 OF oDlg COLOR 0, 16777215 PIXEL
	oBtn1 := tButton():New(101, 016, "Marca Todos    ", oDlg, {|| fMarTudo(1)}, 050, 012,,,, .T.)
	oBtn2 := tButton():New(101, 076, "Desmarca Todos ", oDlg, {|| fMarTudo(2)}, 050, 012,,,, .T.)
	oBtn3 := tButton():New(101, 136, "Inverte Seleção", oDlg, {|| fMarTudo(3)}, 050, 012,,,, .T.)

	oGet5 := fMSNewGe1()
	bSvblDb5 := oGet5:oBrowse:bLDblClick
	oGet5:oBrowse:bLDblClick := {|| if(oGet5:oBrowse:nColPos!=0, CLIQUE5(), GdRstDblClick(@oGet5, @bSvblDb5))}
	oGet5:oBrowse:bChange := {|| Refresh5()}

	@ 227, 010 TO 246, 080 LABEL " Qtd Cheques " OF oDlg PIXEL
	@ 236, 048 SAY oQtde VAR nQtde Size 070,010 OF oDlg Font oFont COLOR CLR_BLACK Picture "@E 999,999,999.99" PIXEL

	@ 227, 085 TO 246, 155 LABEL " Total " OF oDlg PIXEL
	@ 236, 123 SAY oTotal VAR nTotal Size 070,010 OF oDlg Font oFont COLOR CLR_BLACK Picture "@E 999,999,999.99" PIXEL

	@ 233, 160 BUTTON oButton1 PROMPT "Transferir" SIZE 037, 012 OF oDlg PIXEL ACTION (TRANSFERIR(cOpeDes,cPdv))
	@ 233, 205 BUTTON oButton2 PROMPT "Fechar"     SIZE 037, 012 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

Return

//------------------------------------------------
Static Function AjustNum(cCheque, oCheque)

	if !empty(cCheque)
		cCheque := StrZero(Val(cCheque),6,0)
		oCheque:Refresh()
	endif

Return .T.

//------------------------------------------------
Static Function fMSNewGe1()
	Local nX
	Local aHeaderEx    := {}
	Local aColsEx      := {}
	//Local aFieldFill   := {}
	Local aFields      := {"MARK","UF2_NUM", "UF2_VALOR","UF2_BENEF","UF2_HIST","RECNO"}
	Local aAlterFields := {"MARK"}
	Local nLinMax 	   := 999  // Quantidade delinha na getdados

	// Define field properties
	Aadd(aHeaderEx,{'','MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX], "X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Next nX
	Aadd(aHeaderEx,{"RECNO","RECNO","@E 99999999999999999",17,0,"","","N","","","",""})

	if Len(aColsEx) == 0
		Aadd(aColsEx, {"LBNO", space(tamsx3("UF2_NUM")[1]), 0 /*"UF2_VALOR"*/, space(tamsx3("UF2_BENEF")[1]), space(tamsx3("UF2_HIST")[1]), 0, .F.})
	endif

Return MsNewGetDados():New( 120/*101*/, 010, 223, 239, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "AllwaysTrue",;
		aAlterFields, , nLinMax, "AllwaysTrue", "AllwaysTrue", "U_DelVariant()", oDlg, aHeaderEx, aColsEx)

//------------------------------------------------
Static Function clique5()

	If len(oGet5:aCols) == 0
		Return()
	Endif

	If oGet5:aCols[oGet5:NAT][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})] == "LBOK"
		oGet5:aCols[oGet5:NAT][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})] := "LBNO"
	Else
		oGet5:aCols[oGet5:NAT][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})] := "LBOK"
	Endif

	oGet5:oBrowse:REFRESH()
	Refresh5()

Return

//------------------------------------------------
Static Function Refresh5()
	Local nPosMark := aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nPosVal  := aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="UF2_VALOR"})
	Local nX

	nQtde  := 0
	nTotal := 0

	If len(oGet5:aCols) == 0
		Return()
	Endif

	For nX:=1 to len(oGet5:aCols)
		If oGet5:aCols[nX][nPosMark] == "LBOK"
			nQtde++
			nTotal += oGet5:aCols[nX][nPosVal]
		EndIf
	Next nX

	oQtde:Refresh()
	oTotal:Refresh()

Return()

//-------------------------------------------------------------------
Static Function CARREGAR()
	Local aArea  := GetArea()
	Local cCondicao	:= ""
	Local bCondicao
	Local cQry := ""

	oGet5:acols := {}

	#IFDEF TOP

		cQry := "SELECT UF2.R_E_C_N_O_ RECUF2, UF2_NUM, UF2_VALOR, UF2_BENEF, UF2_HIST "
		cQry += " FROM " + RetSqlName("UF2") + " UF2"
		cQry += " WHERE UF2.D_E_L_E_T_ = ' ' "
		cQry += " AND UF2_FILIAL = '" + xFilial("UF2") + "' "
		If !Empty(cBanco)
			cQry += " AND UF2_BANCO = '" + cBanco + "' "
		EndIf
		If !Empty(cAgencia)
			cQry += " AND UF2_AGENCI = '" + cAgencia + "' "
		EndIf
		If !Empty(cConta)
			cQry += " AND UF2_CONTA = '" + cConta + "' "
		EndIf
		cQry += " AND UF2_NUM >= '" + cChequeD + "' "
		cQry += " AND UF2_NUM <= '" + cChequeA + "' "
		cQry += " AND UF2_CODCX = '" + cOpeOri + "' "
		cQry += " AND UF2_DOC = '"+Space(TamSx3("UF2_DOC")[1])+"' "
		cQry += " AND UF2_SERIE = '"+Space(TamSx3("UF2_SERIE")[1])+"' "
		cQry += " AND UF2_STATUS <> '2' AND UF2_STATUS <> '3' " //remove as folhas de cheque usadas e inutilizadas
		cQry += " ORDER BY UF2_FILIAL, UF2_BANCO, UF2_AGENCI, UF2_CONTA, UF2_NUM"

		If Select("QAUX") > 0
			QAUX->(dbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QAUX"

		If QAUX->(!Eof())
			While QAUX->(!Eof())
				aadd(oGet5:acols, {"LBNO", QAUX->UF2_NUM, QAUX->UF2_VALOR, QAUX->UF2_BENEF, QAUX->UF2_HIST, QAUX->RECUF2, .F.})
				QAUX->( dbskip() )
			EndDo
		EndIf

		QAUX->(dbCloseArea())

	#ELSE

		cCondicao := " UF2_FILIAL = '" + xFilial("UF2") + "'"
		if !empty(cBanco)
			cCondicao += " .AND. UF2_BANCO = '" + cBanco + "'"
		endif
		if !empty(cAgencia)
			cCondicao += " .AND. UF2_AGENCI = '" + cAgencia + "'"
		endif
		if !empty(cConta)
			cCondicao += " .AND. UF2_CONTA = '" + cConta + "'"
		endif
		cCondicao += " .AND. UF2_CODCX = '" + cOpeOri + "'"
		cCondicao += " .AND. UF2_NUM >= '" + cChequeD + "'"
		cCondicao += " .AND. UF2_NUM <= '" + cChequeA + "'"
		cCondicao += " .AND. UF2_DOC = '"+space(tamsx3("UF2_DOC")[1])+"'"
		cCondicao += " .AND. UF2_SERIE = '"+space(tamsx3("UF2_SERIE")[1])+"'"
		cCondicao += " .AND. UF2_STATUS <> '2' .AND. UF2_STATUS <> '3'" //remove as folhas de cheque usadas e inutilizadas

		// limpo os filtros da UF2
		UF2->(DbClearFilter())

		// executo o filtro na UF2
		bCondicao 	:= "{|| " + cCondicao + " }"
		UF2->(DbSetFilter(&bCondicao,cCondicao))

		// vou para a primeira linha
		UF2->(DbGoTop())

		While UF2->(!Eof())
			aadd(oGet5:acols, {"LBNO", UF2->UF2_NUM, UF2->UF2_VALOR, UF2->UF2_BENEF, UF2->UF2_HIST, UF2->(RecNo()), .F.})
			UF2->(DbSkip())
		EndDo

		// limpo os filtros da UF2
		UF2->(DbClearFilter())

	#ENDIF

	If Len(oGet5:acols) == 0
		Aadd(oGet5:acols, {"LBNO", space(tamsx3("UF2_NUM")[1]), 0 /*"UF2_VALOR"*/, space(tamsx3("UF2_BENEF")[1]), space(tamsx3("UF2_HIST")[1]), 0, .F.})
	EndIf

	nQtde  := 0
	nTotal := 0
	oGet5:oBrowse:REFRESH()
	Refresh5()

	RestArea( aArea )

Return .T.

//-------------------------------------------------------------------
Static Function TRANSFERIR(cOpeOri,cPdv)
	Local aArea := GetArea()
	Local lRet := .T.
	Local lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV
	Local nX

//if lLib .AND. Empty(cPdv)
//	MsgAlert("Numero de PDV para o caixa selecionado é obrigatório!","Atenção")
//	Return .F.
//Endif

	If lRet

		For nX:=1 to len(oGet5:aCols)
			cMarcacao := oGet5:aCols[nX][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})]
			If !Empty(oGet5:aCols[nX,2]) .AND. !oGet5:aCols[nX,Len(oGet5:aCols[nX])] .AND. cMarcacao == "LBOK"

				nRecno := oGet5:aCols[nX][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="RECNO"})]

				DbSelectArea("UF2")
				UF2->(DbGoTo(nRecno))

				RecLock("UF2",.F.)
				UF2->UF2_CODCX 	:= cOpeOri //caixa novo portador do cheque
				UF2->UF2_PDV	:= cPdv
				if UF2->(FieldPos("UF2_DTREM"))
					UF2->UF2_DTREM 	:= dDataBase
				endif
				UF2->(MsUnLock())

				If !lSrvPDV //se for na retaguarda replica o cadastro...
					U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")
				EndIf

			Endif
		Next nX

		MsgInfo("Transferência(s) realizada(s) com sucesso!","Atenção!")

		U_TRETR013(2) //impressao dos cheques transfereridos
		CARREGAR() //atualiza o cheques do caixa origem

		oDlg:End()

	EndIf

	RestArea(aArea)

Return(lRet)

//-------------------------------------------------------------------
Static Function fMarTudo(nOpc)
	Local nPosMark := aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"})
	Local nX

	If len(oGet5:aCols) == 0
		Return()
	Endif

	For nX:=1 to len(oGet5:aCols)

		If nOpc == 1 //marca todos
			oGet5:aCols[nX][nPosMark] := "LBOK"
		ElseIf nOpc == 2 // desmarca todos
			oGet5:aCols[nX][nPosMark] := "LBNO"
		Else //inverte selecao
			If oGet5:aCols[nX][nPosMark] == "LBOK"
				oGet5:aCols[nX][nPosMark] := "LBNO"
			Else
				oGet5:aCols[nX][nPosMark] := "LBOK"
			EndIf
		EndIf

	Next nX

	oGet5:oBrowse:REFRESH()
	Refresh5()

Return

//-------------------------------------------------------------------
Static Function DescCaixa()
	cNomeOr := POSICIONE("SA6",1,XFILIAL("SA6")+cOpeOri,"A6_NOME")
	cNomeDe := POSICIONE("SA6",1,XFILIAL("SA6")+cOpeDes,"A6_NOME")
Return .T.

//----------------------------------------------------------------------------------------
// Validação de Caixa [TODO: função em DESUSO]
//----------------------------------------------------------------------------------------
Static Function VerCaixa(nOpc,cCodCaixa)

	Local cCaixa  := xNumCaixa()
	Local lRet	  := .T.

	SLF->(DbSetOrder(1)) //LF_FILIAL+LF_COD
	SLF->(DbGoTop())

// Verifica se Usuario é Supervisor
/*
If SLF->(DbSeek(xFilial("SLF")+cCaixa))
		If SLF->LF_XFUNCAO == "S" .AND. !Empty(cCodCaixa)
			//Valido se caixa selecionado é tesouraria
			If !SLF->(DbSeek(xFilial("SLF")+cCodCaixa))
				lRet := .F.
			Else  
				lRet := .T.
			Endif	                                                        
		Else 
			If Empty(cCodCaixa)
				lRet := .T.
			Else
				Alert("Usuário sem premissao para utilizar esta rotina !")
				Return .F.
			Endif	
		Endif
	
Else // Caixa Geral/Tesouraria
	lRet := .T.	   
Endif
*/

	If !lRet
		Alert("Transferência não permitida !" + CRLF;
			+ "Será permitido transferênncia somente para PDV ou Gerente.","Atenção")
		Return .F.
	EndIf

	If nOpc == 2
		// Valida se codigo selecionado é caixa
		If SLF->(DbSeek(xFilial("SLF")+cCodCaixa))
			If SubStr(SLF->LF_ACESSO,3,1) == 'S' // verifica se o usuario é fiscal
				lLib := .T.
				cPdv := Space(TamSx3("LG_PDV")[1])
			Else
				lLib := .T. //.F. -> não existe necessidade de bloqueio do campo de PDV
				cPdv := Space(TamSx3("LG_PDV")[1])
			EndIf
			oPdv:Refresh()
		EndIf
	EndIf

Return .T.


//
// Valida o codigo do PDV digitado.
//
Static Function vLG_PDV(cPdv)
	Local aArea  	:= GetArea()
	Local aAreaSLG 	:= SLG->(GetArea())
	Local cCondicao	:= ""
	Local bCondicao
	Local lRet   	:= .T.

	cCondicao := " LG_FILIAL = '" + xFilial("SLG") + "'"
	cCondicao += " .AND. LG_PDV = '" + cPdv + "'"

// limpo os filtros da SLG
	SLG->(DbClearFilter())

// executo o filtro na SLG
	bCondicao 	:= "{|| " + cCondicao + " }"
	SLG->(DbSetFilter(&bCondicao,cCondicao))

// vou para a primeira linha  
	SLG->(DbGoTop())

	If !Empty(cPdv) .and. SLG->(Eof())
		lRet := .F.
		MsgAlert("O código de PDV informando é inválido.","Atenção")
	EndIf

// limpo os filtros da SLG
	SLG->(DbClearFilter())

	RestArea(aAreaSLG)
	RestArea(aArea)
Return lRet
