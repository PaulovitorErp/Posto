#include 'protheus.ch'
#include 'parmtype.ch'
#Include "TOPCONN.CH"

/*/{Protheus.doc} TRETA003
Rotina para fazer a transferencia de veículos entre cliente/Grupo

@author thebr
@since 01/10/2018
@version 1.0
@return Nil
@type function
/*/
user function TRETA003()

	Local oFontGrid := TFont():New('Arial',,18,.T.,.T.)
	Local nCorGrid	:= 7888896
	Local aHeaderEx := {}, aColsEx :={}
	Local bGatCliDe := {|| cNomeDe:=Posicione("SA1",1,xFilial("SA1")+cCliDe+cLojaDe,"A1_NOME"), oNomeDe:Refresh() }
	Local bGatCliPara := {|| cNomePara:=Posicione("SA1",1,xFilial("SA1")+cCliPara+cLojaPara,"A1_NOME"), oNomePara:Refresh() }
	Local bGatGrpDe := {|| cDsGrpDe:=Posicione("ACY",1,xFilial("ACY")+cGrpDe, "ACY_DESCRI"), oDsGrpDe:Refresh() }
	Local bGatGrpPara := {|| cDGrpPara:=Posicione("ACY",1,xFilial("ACY")+cGrpPara, "ACY_DESCRI"), oDGrpPara:Refresh() }
	Local bGatPlaca := {|| cModeloDe:=Posicione("DA3",1,xFilial("DA3")+cPlacaDe, "DA3_DESC"), cCliPla:=DA3->DA3_XCODCL, cLojaPla:=DA3->DA3_XLOJCL, cNomePla:=Posicione("SA1",1,xFilial("SA1")+cCliPla+cLojaPla,"A1_NOME"), cGrpPla:=DA3->DA3_XGRPCL, cNomeGrPla:=Posicione("ACY",1,xFilial("ACY")+cGrpPla, "ACY_DESCRI"), oModeloDe:Refresh(), oCliPla:Refresh(), oLojaPla:Refresh(), oNomePla:Refresh(), oGrpPla:Refresh(), oNomeGrPla:Refresh() }
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }

	Local oFolderDe, oFolderPa
	Local oBTransf, oBLimpar, oBCancel, oBBusPla
	Local oSCliDe, oSGrpDe, oSPlaca, oSModelo, oSCliPla, oSGrpPla, oSCliPara, oSGrpPara

	Private oCliDe, oLojaDe, oNomeDe, oGrpDe, oDsGrpDe, oPlacaDe, oModeloDe, oCliPla, oLojaPla, oNomePla, oGrpPla, oNomeGrPla
	Private oCliPara, oLojaPara, oNomePara, oGrpPara, oDGrpPara
	Private oGdCli, oGdGrp

	Private cCliDe := Space(TamSX3("DA3_XCODCL")[1])
	Private cLojaDe := Space(TamSX3("DA3_XLOJCL")[1])
	Private cNomeDe := ""
	Private cGrpDe := Space(TamSX3("DA3_XGRPCL")[1])
	Private cDsGrpDe := ""
	Private cPlacaDe := Space(TamSX3("DA3_PLACA")[1])
	Private cModeloDe := ""
	Private cCliPla := ""
	Private cLojaPla := ""
	Private cNomePla := ""
	Private cGrpPla := ""
	Private cNomeGrPla := ""
	Private cCliPara := Space(TamSX3("DA3_XCODCL")[1])
	Private cLojaPara := Space(TamSX3("DA3_XLOJCL")[1])
	Private cNomePara := ""
	Private cGrpPara := Space(TamSX3("DA3_XGRPCL")[1])
	Private cDGrpPara := ""

	Private oDlg
	Private aCpoGdCli := {"MARK","DA3_COD","DA3_DESC","DA3_XCODCL","DA3_XLOJCL","A1_NOME"}
	Private aCpoGdGrp := {"MARK","DA3_COD","DA3_DESC","DA3_XGRPCL","ACY_DESCRI"}
	Private lMARKALL := .F.

	if !U_VLACESS2("UFT010", __cUserid)
		MsgAlert("Usuário sem permissão para acessar esta rotina.")
		Return NIL
	endif

	DEFINE MSDIALOG oDlg TITLE "Transferência de Veículos" FROM 000, 000  TO 530, 700 COLORS 0, 16777215 PIXEL

	TSay():New( 005, 007,{|| "Buscar veiculo(s) a serem transferidos"}, oDlg,,oFontGrid,,,,.T.,nCorGrid,,200,15 )
	TSay():New( 007, 005,{|| Replicate("_",340) }, oDlg,,oFontGrid,,,,.T.,nCorGrid,, 340,15 )
	@ 015, 005 FOLDER oFolderDe SIZE 340, 155 OF oDlg ITEMS "Cliente","Grupo","Veículo" COLORS 0, 16777215 PIXEL
	oFolderDe:bSetOption := {|x| Limpar() }

	TSay():New( 175, 007,{|| "Transferir veículo(s) para"}, oDlg,,oFontGrid,,,,.T.,nCorGrid,,200,15 )
	TSay():New( 177, 005,{|| Replicate("_",340) }, oDlg,,oFontGrid,,,,.T.,nCorGrid,, 340,15 )
	@ 185, 005 FOLDER oFolderPa SIZE 340, 050 OF oDlg ITEMS "Cliente","Grupo" COLORS 0, 16777215 PIXEL
	oFolderPa:bSetOption := {|x| Limpar(.T.) }

	@ 242, 300 BUTTON oBTransf PROMPT "&Transferir"  SIZE 045, 016 OF oDlg PIXEL Action Transfere()
	@ 242, 255 BUTTON oBCancel PROMPT "&Cancelar"	SIZE 040, 016 OF oDlg PIXEL Action (oDlg:End())
	@ 242, 210 BUTTON oBLimpar PROMPT "Limpar" 		SIZE 040, 016 OF oDlg PIXEL Action Limpar()
	oBTransf:SetCss( U_TbcCss(1) ) //Botão Azul

	//Pasta Cliente De
	@ 009, 003 SAY 	 oSCliDe PROMPT "Cliente:" SIZE 025, 007 OF oFolderDe:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 005, 025 MSGET oCliDe  VAR cCliDe  SIZE 055, 013 OF oFolderDe:aDialogs[1] COLORS 0, 16777215 F3 "SA1" PICTURE "@!" PIXEL Valid (empty(cCliDe).OR.ExistCpo("SA1",cCliDe)) .AND. Eval(bGatCliDe) HASBUTTON
	@ 005, 080 MSGET oLojaDe VAR cLojaDe SIZE 020, 013 OF oFolderDe:aDialogs[1] COLORS 0, 16777215 PICTURE "@!" PIXEL Valid (empty(cLojaDe).OR.ExistCpo("SA1",cCliDe+cLojaDe)) .AND. Eval(bGatCliDe) HASBUTTON
	@ 005, 105 MSGET oNomeDe VAR cNomeDe SIZE 170, 013 OF oFolderDe:aDialogs[1] COLORS 0, 16777215 WHEN .F. PIXEL HASBUTTON

	@ 005, 280 BUTTON oBBusPla PROMPT "Buscar Veículos" SIZE 050, 015 OF oFolderDe:aDialogs[1] PIXEL Action BuscaPlaca(1,@oGdCli)

	aHeaderEx := U_MontaHeader(aCpoGdCli)
	aColsEx := {}
	aadd(aColsEx, U_MontaDados("DA3",aCpoGdCli, .T.) ) //linha limpa
	oGdCli := MsNewGetDados():New( 025, 001, 135, 338, ,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oFolderDe:aDialogs[1], aHeaderEx, aColsEx)
	oGdCli:oBrowse:bLDblClick := {|| oGdCli:aCols[oGdCli:nAt][1] := iif(oGdCli:aCols[oGdCli:nAt][1]=="LBNO", iif(!empty(oGdCli:aCols[oGdCli:nAt][2]),"LBOK","LBNO"), "LBNO") , oGdCli:oBrowse:Refresh() }
	oGdCli:oBrowse:bHeaderClick := {|oBrw,nCol| iif(lMARKALL .AND. !empty(oGdCli:aCols[1][2]), (aEval(oGdCli:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) }

	//Pasta Grupo De
	@ 009, 003 SAY 	 oSGrpDe  PROMPT "Grupo:" SIZE 025, 007 OF oFolderDe:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ 005, 025 MSGET oGrpDe  VAR cGrpDe  SIZE 055, 013 OF oFolderDe:aDialogs[2] COLORS 0, 16777215 PICTURE "@!" F3 "ACY" PIXEL Valid (empty(cGrpDe).OR.ExistCpo("ACY",cGrpDe)) .AND. Eval(bGatGrpDe) HASBUTTON
	@ 005, 080 MSGET oDsGrpDe VAR cDsGrpDe SIZE 195, 013 OF oFolderDe:aDialogs[2] COLORS 0, 16777215 WHEN .F. PIXEL HASBUTTON

	@ 005, 280 BUTTON oBBusPla PROMPT "Buscar Veículos" SIZE 050, 015 OF oFolderDe:aDialogs[2] PIXEL Action BuscaPlaca(2,@oGdGrp)

	aHeaderEx := U_MontaHeader(aCpoGdGrp)
	aColsEx := {}
	aadd(aColsEx, U_MontaDados("DA3",aCpoGdGrp, .T.) ) //linha limpa
	oGdGrp := MsNewGetDados():New( 025, 001, 135, 338, ,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oFolderDe:aDialogs[2], aHeaderEx, aColsEx)
	oGdGrp:oBrowse:bLDblClick := {|| oGdGrp:aCols[oGdGrp:nAt][1] := iif(oGdGrp:aCols[oGdGrp:nAt][1]=="LBNO", iif(!empty(oGdGrp:aCols[oGdGrp:nAt][2]),"LBOK","LBNO"), "LBNO") , oGdGrp:oBrowse:Refresh() }
	oGdGrp:oBrowse:bHeaderClick := {|oBrw,nCol| iif(lMARKALL .AND. !empty(oGdGrp:aCols[1][2]), (aEval(oGdGrp:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) }

	// Pasta Placa De
	@ 009, 005 SAY oSPlaca 	 PROMPT "Veículo:" SIZE 025, 007 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 PIXEL
	@ 005, 045 MSGET oPlacaDe VAR cPlacaDe SIZE 060, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 PICTURE PesqPict("DA3","DA3_COD") F3 "DA3" PIXEL Valid (empty(cPlacaDe).OR.ExistCpo("DA3",cPlacaDe)) .AND. Eval(bGatPlaca) HASBUTTON

	@ 029, 005 SAY oSModelo PROMPT "Modelo:" SIZE 045, 007 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 PIXEL
	@ 025, 045 MSGET oModeloDe VAR cModeloDe SIZE 175, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 WHEN .F. PIXEL

	@ 049, 005 SAY oSCliPla	 PROMPT "Cliente:" SIZE 025, 007 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 PIXEL
	@ 045, 045 MSGET oCliPla VAR cCliPla  SIZE 050, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 WHEN .F. PIXEL
	@ 045, 100 MSGET oLojaPla VAR cLojaPla SIZE 020, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 WHEN .F. PIXEL
	@ 045, 125 MSGET oNomePla VAR cNomePla SIZE 150, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 WHEN .F. PIXEL

	@ 069, 005 SAY oSGrpPla	 PROMPT "Grupo:" SIZE 025, 007 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 PIXEL
	@ 065, 045 MSGET oGrpPla VAR cGrpPla SIZE 050, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 WHEN .F. PIXEL
	@ 065, 100 MSGET oNomeGrPla VAR cNomeGrPla SIZE 175, 013 OF oFolderDe:aDialogs[3] COLORS 0, 16777215 WHEN .F. PIXEL

	// Pasta Cliente Para
	@ 009, 003 SAY oSCliPara PROMPT "Cliente:" SIZE 025, 007 OF oFolderPa:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ 005, 025 MSGET oCliPara VAR cCliPara  SIZE 055, 013 OF oFolderPa:aDialogs[1] COLORS 0, 16777215 F3 "SA1" PIXEL Valid (empty(cCliPara).OR.ExistCpo("SA1",cCliPara)) .AND. Eval(bGatCliPara) HASBUTTON
	@ 005, 080 MSGET oLojaPara VAR cLojaPara SIZE 020, 013 OF oFolderPa:aDialogs[1] COLORS 0, 16777215 PIXEL Valid (empty(cLojaPara).OR.ExistCpo("SA1",cCliPara+cLojaPara)) .AND. Eval(bGatCliPara) HASBUTTON
	@ 005, 105 MSGET oNomePara VAR cNomePara SIZE 170, 013 OF oFolderPa:aDialogs[1] COLORS 0, 16777215 PIXEL WHEN .F.

	// Pasta Grupo Para
	@ 009, 003 SAY oSGrpPara PROMPT "Grupo:" SIZE 025, 007 OF oFolderPa:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ 005, 025 MSGET oGrpPara  VAR cGrpPara  SIZE 055, 013 OF oFolderPa:aDialogs[2] COLORS 0, 16777215 F3 "ACY" PIXEL Valid (empty(cGrpPara).OR.ExistCpo("ACY",cGrpPara)) .AND. Eval(bGatGrpPara) HASBUTTON
	@ 005, 080 MSGET oDGrpPara VAR cDGrpPara SIZE 195, 013 OF oFolderPa:aDialogs[2] COLORS 0, 16777215 WHEN .F. PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

return

//---------------------------------------------------------------
// busca das placas amarradas ao cliente ou grupo
//---------------------------------------------------------------
Static Function BuscaPlaca(nOpc,oMsMark)

	Local aTemp

	cQry:= " SELECT DA3.R_E_C_N_O_ RECDA3, ACY.R_E_C_N_O_ RECACY, SA1.R_E_C_N_O_ RECSA1 "
	cQry+= "FROM "+RetSqlName("DA3")+" DA3 "
	cQry+= "LEFT JOIN "+RetSqlName("ACY")+" ACY "
	cQry+= "	ON ACY_GRPVEN = DA3_XGRPCL AND "
	cQry+= "	   ACY_FILIAL = '"+xFilial("ACY")+"' AND "
	cQry+= "	   ACY.D_E_L_E_T_ <> '*' "
	cQry+= "LEFT JOIN "+RetSqlName("SA1")+" SA1 "
	cQry+= "	ON A1_COD = DA3_XCODCL AND "
	cQry+= "	   A1_LOJA = DA3_XLOJCL AND "
	cQry+= "	   A1_FILIAL = '"+xFilial("SA1")+"' AND "
	cQry+= "	   SA1.D_E_L_E_T_ <> '*' "
	cQry+= "WHERE DA3.D_E_L_E_T_ <> '*' "
	cQry+= "  AND DA3_FILIAL = '"+xFilial("DA3")+"' "
	if nOpc == 1
		cQry+= "AND DA3_XGRPCL = '' "
		cQry+= "AND DA3_XCODCL = '"+cCliDe+"' "
		cQry+= "AND DA3_XLOJCL = '"+cLojaDe+"' "
	Elseif nOpc == 2
		cQry+= "AND DA3_XGRPCL = '"+cGrpDe+"' "
		cQry+= "AND DA3_XCODCL = '' "
		cQry+= "AND DA3_XLOJCL = '' "
	EndIf

	if Select("QRYPLACA") > 0
		QRYPLACA->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "QRYPLACA" // Cria uma nova area com o resultado do query

	oMsMark:acols := {}

	QRYPLACA->(DbGoTop())
	While QRYPLACA->(!Eof())

		DA3->(DbGoTo(QRYPLACA->RECDA3))
		ACY->(DbGoTo(QRYPLACA->RECACY))
		SA1->(DbGoTo(QRYPLACA->RECSA1))

		aTemp := U_MontaDados("DA3", iif(nOpc==1,aCpoGdCli,aCpoGdGrp))

		AADD(oMsMark:acols,aTemp)

		QRYPLACA->(DbSkip())
	EndDo


	if empty(oMsMark:acols)
		MsgInfo("Não foram encontrados veículos vinculados!")
		aadd(oMsMark:acols, U_MontaDados("DA3",iif(nOpc==1,aCpoGdCli,aCpoGdGrp), .T.) )
	endif

	oMsMark:oBrowse:Refresh()

Return

//-------------------------------------------------------------------
// limpa campos da tela
//-------------------------------------------------------------------
Static Function Limpar(lPara)

	Default lPara := .F.

	if !lPara
		cCliDe := Space(TamSX3("DA3_XCODCL")[1])
		cLojaDe := Space(TamSX3("DA3_XLOJCL")[1])
		cNomeDe := ""
		cGrpDe := Space(TamSX3("DA3_XGRPCL")[1])
		cDsGrpDe := ""
		cPlacaDe := Space(TamSX3("DA3_PLACA")[1])
		cModeloDe := ""
		cCliPla := ""
		cLojaPla := ""
		cNomePla := ""
		cGrpPla := ""
		cNomeGrPla := ""
		oGdCli:acols := {}
		aadd(oGdCli:acols, U_MontaDados("DA3",aCpoGdCli, .T.) )
		oGdCli:oBrowse:Refresh()
		oGdGrp:acols := {}
		aadd(oGdGrp:acols, U_MontaDados("DA3",aCpoGdGrp, .T.) )
		oGdGrp:oBrowse:Refresh()
	endif

	cCliPara := Space(TamSX3("DA3_XCODCL")[1])
	cLojaPara := Space(TamSX3("DA3_XLOJCL")[1])
	cNomePara := ""
	cGrpPara := Space(TamSX3("DA3_XGRPCL")[1])
	cDGrpPara := ""

	oDlg:Refresh()

Return

//-------------------------------------------------------------------
// validaçao e chamada da gravaçao
//-------------------------------------------------------------------
Static Function Transfere()

	Local lTemGdCli := aScan(oGdCli:aCols,{|x| x[1]=="LBOK"}) > 0
	Local lTemGdGrp := aScan(oGdGrp:aCols,{|x| x[1]=="LBOK"}) > 0
	Local bGrava := {|x| iif(x[1]=="LBOK", Grava(x[2]),) }

	if empty(cPlacaDe) .AND. !lTemGdCli .AND. !lTemGdGrp
		MsgInfo("Selecione pelo menos uma placa para ser transferida!","Atenção")
		Return
	endif

	if empty(cCliPara+cGrpPara)
		MsgInfo("Informe um cliente ou grupo destino!","Atenção")
		Return
	endif

	BeginTran()

	if !empty(cPlacaDe)
		Grava(cPlacaDe)
	endif

	if lTemGdCli
		aEval(oGdCli:aCols, bGrava )
	endif

	if lTemGdGrp
		aEval(oGdGrp:aCols, bGrava )
	endif

	EndTran()

	MsgInfo("Placa(s) transferida(s) com sucesso!","Sucesso!")
	Limpar()

Return

//-------------------------------------------------------------------
// Gravação
//-------------------------------------------------------------------
Static Function Grava(cPlaca)

	DA3->(DbSetOrder(1))
	if DA3->(DbSeek(xFilial("DA3")+cPlaca ))
		RecLock("DA3", .F.)
			DA3->DA3_XCODCL := cCliPara
			DA3->DA3_XLOJCL := cLojaPara
			DA3->DA3_XGRPCL := cGrpPara
		DA3->(MsUnlock())
	endif

Return
