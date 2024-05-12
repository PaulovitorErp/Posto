#INCLUDE 'Protheus.ch'
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'FWMVCDEF.CH'

#Define CRLF chr(13)+chr(10)
#Define CSS_BTNAZUL " QPushButton { color: #FFFFFF; font-weight:bold; "+;
				"    background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #3AAECB, stop: 1 #0F9CBF); "+;
				"    border:1px solid #369CB5; "+;
				"    border-radius: 3px; } "+;
				" QPushButton:pressed { "+;
				"    background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #148AA8, stop: 1 #39ACC9); "+;
				"    border:1px solid #369CB5; }";

Static lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV
Static lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.)
Static SIMBDIN := Alltrim(SuperGetMV("MV_SIMB1",,"R$"))
Static cLIBCHEQ := SuperGetMV( "MV_LIBCHEQ" , .T./*lHelp*/, "S" )
Static cSGBD	:= AllTrim(Upper(TcGetDb()))	// -- Banco de dados atulizado (Para embientes TOP) 			 	

Static lImpOnly := .F.

/*/{Protheus.doc} TRETA028
Conferencia de Caixa - Retaguarda do Totvs PDV
@author thebr
@since 28/12/2018
@version 1.0
@return Nil

@type function
/*/
User function TRETA028()

	Local aCores, nX
	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea())
	Local aAreaSL2 := SL2->(GetArea())
	Local aAreaSL4 := SL4->(GetArea())
	Local aAreaSLW := SLW->(GetArea())
	Local aAreaSLT := SLT->(GetArea())

	Private aRotina
	Private cCadastro := "Conferencia de Caixa"
	Private oBrowse

	// variavel para ordenação de grids
	Private __XVEZ 		:= "0"
	Private __ASC       := .T.

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( "SLW" )
	oBrowse:SetDescription( cCadastro )

	aCores := U_TRA028LG(1)

	//legendas
	For nX := 1 to len(aCores)
		oBrowse:AddLegend( aCores[nX][1], aCores[nX][2] , aCores[nX][3] )
	next nX

	if lSrvPDV
		if MsgYesNo("Deseja filtrar registros do caixa?",cCadastro)
			U_TRA028FL(.T.)
		EndIf
	endif

	if lImpOnly
		U_TRA028FL(.T., .T.)
	endif

	oBrowse:Activate()

	FreeObj(oBrowse)
	oBrowse := Nil

	RestArea(aAreaSL1)
	RestArea(aAreaSL2)
	RestArea(aAreaSL4)
	RestArea(aAreaSLW)
	RestArea(aAreaSLT)
	RestArea(aArea)

Return

//Browse criado para atender
User Function TR028REL
	
	lImpOnly := .T.
	SetFunName("TRETA028")
	U_TRETA028()

Return

//--------------------------------------------------------------------------------------
// Monta o menu da rotina de acordo com o tipo de base
//--------------------------------------------------------------------------------------
Static Function MenuDef()

	aRotina := {}

	if lSrvPDV .OR. lImpOnly
		ADD OPTION aRotina TITLE 'Visualizar'  ACTION "U_TRA028CF(2)" OPERATION 2 ACCESS 0
		ADD OPTION aRotina TITLE 'Filtrar'       ACTION "U_TRA028FL()" OPERATION 3 ACCESS 0
		ADD OPTION aRotina TITLE 'Relatório'      ACTION "U_TRA028RL()" OPERATION 4 ACCESS 0
		ADD OPTION aRotina TITLE 'Rel.Caixa x Vendedor'  ACTION "U_TRA028RI()" OPERATION 6 ACCESS 0
		ADD OPTION aRotina TITLE 'Legenda'  	  ACTION "U_TRA028LG(2)" OPERATION 6 ACCESS 0
	else
		ADD OPTION aRotina TITLE 'Visualizar'  ACTION "U_TRA028CF(2)" OPERATION 2 ACCESS 0
		ADD OPTION aRotina TITLE 'Conferir'    ACTION "U_TRA028CF(4)" OPERATION 4 ACCESS 0
		ADD OPTION aRotina TITLE 'Estornar'    ACTION "U_TRA028ES(.T.)" OPERATION 4 ACCESS 0
		ADD OPTION aRotina TITLE 'Legenda'  	  ACTION "U_TRA028LG(2)" OPERATION 6 ACCESS 0
		ADD OPTION aRotina TITLE 'Atualiza Status'  ACTION "U_TRA028AS()" OPERATION 6 ACCESS 0
		ADD OPTION aRotina TITLE 'Relatório'      ACTION "U_TRA028RL()" OPERATION 7 ACCESS 0
		ADD OPTION aRotina TITLE 'Rel.Caixa x Vendedor'  ACTION "U_TRA028RI()" OPERATION 2 ACCESS 0
		ADD OPTION aRotina TITLE 'Vale'       ACTION "U_TRA028VL()" OPERATION 8 ACCESS 0
		ADD OPTION aRotina TITLE 'Exporta p/ Excel'      ACTION "U_TRA028EX()" OPERATION 8 ACCESS 0
		ADD OPTION aRotina TITLE 'Imp.Log.Caixa'      ACTION "U_TRA028IH()" OPERATION 8 ACCESS 0
		if FindFunction('U_TRETR022')
		ADD OPTION aRotina TITLE 'Rel. Geral Caixa'      ACTION "U_TRETR022()" OPERATION 8 ACCESS 0
		endif
	endif

	If ExistBlock("TR028MNU")
		aRotina := ExecBlock("TR028MNU",.F.,.F.,aRotina)
	EndIf

Return aRotina

//--------------------------------------------------------------------------------------
// Função para filtar registro (base DBF)
//--------------------------------------------------------------------------------------
User Function TRA028FL(lSugere, lKingPosto)

	Local cFiltro := ""
	Local aParamEnc := {}
	Local aPergs := {}
	Local lUsePDV := SuperGetMv("KP_USEPDV",,.T.) //determina se usa campo PDV como chave na integração
	Local cUserNameSA3
	Default lSugere := .F.
	Default lKingPosto := .F.

	//sugere os dados do pdv, operador e data hoje
	if lSugere
		if lKingPosto
			if lUsePDV
				aadd(aParamEnc, PadR(LjGetStation("LG_PDV"),TamSX3("LW_PDV")[1]))
			else
				aadd(aParamEnc, PadR("KINGPOSTO",TamSX3("LW_PDV")[1]))
			endif
			cUserNameSA3 := ALLTRIM(USRRETNAME(RetCodUsr()))
			SA6->(DbSetOrder(2)) //A6_FILIAL+A6_NOME
			If SA6->(DbSeek( xFilial("SA6") + Upper(cUserNameSA3) )) 
				aadd(aParamEnc, SA6->A6_COD)
			else
				aadd(aParamEnc, Space(TamSX3("LW_OPERADO")[1]))
			endif
			aadd(aParamEnc, dDataBase )
		else
			aadd(aParamEnc, PadR(LjGetStation("LG_PDV"),TamSX3("LW_PDV")[1]))
			aadd(aParamEnc, PadR(xNumCaixa(),TamSX3("LW_OPERADO")[1]))
			aadd(aParamEnc, dDataBase )
		endif
	else
		aadd(aParamEnc, Space(TamSX3("LW_PDV")[1]))
		aadd(aParamEnc, Space(TamSX3("LW_OPERADO")[1]))
		aadd(aParamEnc, STOD("") )
	endif

	aAdd( aPergs ,{1,"Num. PDV",aParamEnc[1],"@!",'.T.',"",'.T.',50,.F.})
	aAdd( aPergs ,{1,"Operador Caixa",aParamEnc[2],"@!",'.T.',"",'.T.',50,.F.})
	aAdd( aPergs ,{1,"Data Abertura De:",aParamEnc[3],"",'.T.',"",'.T.',60,.F.})

	if ParamBox(aPergs ,"Filtre o caixa/turno",@aParamEnc,,,,,,,.F.,.F.)
		if !empty(aParamEnc[1])
			cFiltro += "LW_PDV == '" +aParamEnc[1]+"'"
		endif
		if !empty(aParamEnc[2])
			if !empty(cFiltro)
				cFiltro += " .AND. "
			endif
			cFiltro += "LW_OPERADO == '" +aParamEnc[2]+"'
		endif
		if !empty(aParamEnc[3])
			if !empty(cFiltro)
				cFiltro += " .AND. "
			endif
			cFiltro += "LW_DTABERT = STOD('"+DTOS(aParamEnc[3])+"')"
		endif
	endif

	oBrowse:SetFilterDefault( cFiltro )

Return

//--------------------------------------------------------------------------------------
// Função para mostrar tela de legendas
// nTipo: 1=Filtros; 2=Legenda
//--------------------------------------------------------------------------------------
User Function TRA028LG(nTipo)

	Local aLegenda := {}

	if nTipo == 1 //Filtros mBrowse

		aadd(aLegenda, {"LW_CONFERE == '2' .AND. !empty(LW_DTFECHA)" ,'BR_VERDE', "Conferencia Pendente"}) //Pendente
		aadd(aLegenda, {"LW_CONFERE == '1' .AND. !empty(LW_DTFECHA)"	,'BR_VERMELHO', "Caixa Conferido"}) //Conferido
		aadd(aLegenda, {"LW_CONFERE == '3' .OR. empty(LW_DTFECHA)"	,'BR_AMARELO', "Pendente ou Aberto no PDV"}) //Pendente PDV

	else //Tela Legenda

		aadd(aLegenda,{"BR_VERDE"	, "Conferencia Pendente"})
		aadd(aLegenda,{"BR_VERMELHO", "Caixa Conferido"})
		aadd(aLegenda,{"BR_AMARELO"	, "Pendente ou Aberto no PDV"})

		BrwLegenda(cCadastro,"Legenda",aLegenda)

	endif

Return aLegenda

//--------------------------------------------------------------------------------------
// Função para atualizar status quando há falha da integração da SLW
//--------------------------------------------------------------------------------------
User Function TRA028AS()

	Local nX, nY
	Local aCampos := {}
	Local cFiltro := ""
	Local aRegSLW := {}
	Local cChavSLW

	Private oRpcSrv
	
	if empty(SLW->LW_DTFECHA)

		aadd(aCampos, "LW_FILIAL" )
		aadd(aCampos, "LW_PDV" )
		aadd(aCampos, "LW_OPERADO" )
		aadd(aCampos, "LW_DTABERT" )
		aadd(aCampos, "LW_NUMMOV" )
		aadd(aCampos, "LW_DTFECHA" )
		aadd(aCampos, "LW_SERIE" )
		aadd(aCampos, "LW_NUMINI" )
		aadd(aCampos, "LW_NUMFIM" )
		aadd(aCampos, "LW_CONFERE" )
		aadd(aCampos, "LW_OPCEXIB" )
		aadd(aCampos, "LW_ESTACAO" )
		aadd(aCampos, "LW_HRABERT" )
		aadd(aCampos, "LW_HRFECHA" )
		aadd(aCampos, "LW_SITUA" )
		aadd(aCampos, "LW_TIPFECH" )
		aadd(aCampos, "LW_ORIGEM" )

		cFiltro := "D_E_L_E_T_ = ' ' AND LW_FILIAL='"+SLW->LW_FILIAL+"' AND LW_PDV = '"+SLW->LW_PDV+"' AND LW_OPERADO = '"+SLW->LW_OPERADO+"' AND LW_DTABERT = '"+DTOS(SLW->LW_DTABERT)+"' AND LW_NUMMOV = '"+SLW->LW_NUMMOV+"'"
		aRegSLW := DoRPC_Pdv("STDQueryDB", aCampos, {"SLW"}, cFiltro)

		SLW->(DbSetOrder(1)) //LW_FILIAL+LW_PDV+LW_OPERADO+DTOS(LW_DTABERT)+LW_NUMMOV
		For nX := 1 to len(aRegSLW)
			
			cChavSLW := aRegSLW[nX][aScan(aCampos,"LW_FILIAL")]
			cChavSLW += aRegSLW[nX][aScan(aCampos,"LW_PDV")]
			cChavSLW += aRegSLW[nX][aScan(aCampos,"LW_OPERADO")]
			cChavSLW += DTOS(aRegSLW[nX][aScan(aCampos,"LW_DTABERT")])
			cChavSLW += aRegSLW[nX][aScan(aCampos,"LW_NUMMOV")]

			if SLW->(DbSeek(cChavSLW))
				If RecLock('SLW',.F.)
					for nY := 1 to len(aCampos)
						SLW->&(aCampos[nY]) := aRegSLW[nX][nY]
					next nY
					SLW->(MsUnlock())
				EndIf
			endif
		next nX	

		DoRpcClose()

	endif

Return

//--------------------------------------------------------------------------------------
// Função para chamar o cadastro, de acordo com opção acessada
// nOpcX: 2=Visualizar;4=Conferir
//--------------------------------------------------------------------------------------
User Function TRA028CF(nOpcx)

	Local dBkpDBase := dDataBase
	Local lVldAcess := SuperGetMv("MV_XCONFAC",.F.,.F.) .OR. SuperGetMv("MV_XMARAJO",.F.,.F.)

	If (SLW->LW_CONFERE == '3' .Or. SLW->LW_CONFERE == '1')  .And. nOpcx == 4
		If SLW->LW_CONFERE == '1'
			MsgAlert("Conferência não permitida. O caixa já foi conferido.","Atenção")
		Else
			MsgAlert("Conferência não permitida. O caixa está aberto e em operaçao.","Atenção")
		endIf
		Return
	Endif

	//verifica se o usuário tem permissão para acesso a rotina
	If lVldAcess .And. nOpcx == 4
		U_TRETA37B("CONFCX", "PERMITE CONFERIR O CAIXA")
		if !U_VLACESS2("CONFCX", RetCodUsr()) 
			MsgAlert("Usuário sem permissão para conferir caixa.","Atenção")
			Return
		endif
	endif

	//Ponto de entrada para validar acesso a tela de conferencia de caixa
	if ExistBlock("TRA028AC")
		if !ExecBlock("TRA028AC",.F.,.F., nOpcx)
			Return
		endif
	endif

	If nOpcx == 4
		dDataBase := SLW->LW_DTABERT
	EndIf

	//Abre tela de conferência
	TelaConf(nOpcx)

	dDataBase := dBkpDBase

Return

//--------------------------------------------------------------------------------------
// Montagem da tela conferencia
// nOpcX: 2=Visualizar; 4=Conferir
//--------------------------------------------------------------------------------------
Static Function TelaConf(nOpcx)

	//dimensionamento de tela e componentes
	Local aSize 	:= MsAdvSize() // Retorna a área útil das janelas Protheus
	Local aInfo 	:= {aSize[1], aSize[2], aSize[3], aSize[4], 2, 2}
	Local aObjects 	:= {{100,35,.T.,.T.},{100,55,.T.,.T.},{100,10,.T.,.T.}}
	Local aPObj 	:= MsObjSize( aInfo, aObjects, .T. )

	//enchoicebar
	Local bOk := {|| iif(nOpcx==4, DoGravaConf(nOpcx), oDlgFCaixa:End()) }
	Local bCancel := {|| oDlgFCaixa:End() }
	Local aButtons := {}

	//objetos da tela
	Local oScrCab
	Local oScrRod
	Local oFontGrid := TFont():New('Arial',,18,.T.,.T.)
	Local nCorGrid	:= 7888896

	//variaveis cabeçalho
	Private oGetCxa
	Private cGetCxa	:= SLW->LW_OPERADO
	Private oGetNom
	Private cGetNom	:= Posicione("SA6",1,xFilial("SA6")+SLW->LW_OPERADO,"A6_NOME")
	Private oGetEst
	Private cGetEst	:= SLW->LW_ESTACAO
	Private oGetSer
	Private cGetSer	:= SLW->LW_SERIE
	Private oGetPDV
	Private cGetPDV	:= SLW->LW_PDV
	Private oGetFil
	Private cGetFil	:= SLW->LW_FILIAL
	Private oGetMov
	Private cGetMov	:= SLW->LW_NUMMOV
	Private oGetDtA
	Private dGetDtA	:= SLW->LW_DTABERT
	Private oGetHrA
	Private cGetHrA	:= SLW->LW_HRABERT
	Private oGetDtF
	Private dGetDtF	:= SLW->LW_DTFECHA
	Private oGetHrF
	Private cGetHrF	:= SLW->LW_HRFECHA
	Private oGetObs
	Private cGetObs := iif(SLW->(FieldPos("LW_XOBS"))>0, SLW->LW_XOBS, "")

	//variaveis rodapé
	Private oGetVDg
	Private nGetVDg	:= 0
	Private oGetVAp
	Private nGetVAp	:= 0
	Private oGetSld
	Private nGetSld	:= 0

	Private oDlgFCaixa
	Private oGridForma
	Private cCadastro	:= "Conferência de Caixa - " + iif(nOpcx==4,"CONFERIR","VISUALIZAR")
	Private aFormasHab	:= FormasHab()
	Private oRpcSrv

	Private aDadosPdv := {} //variavel para tela conferencia documentos

	DEFINE MSDIALOG oDlgFCaixa TITLE cCadastro FROM aSize[7],aSize[1] TO aSize[6],aSize[5] PIXEL OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)
	aPObj[1,3] -= 27 //retiro tamanho da enchoice p12
	aPObj[3,3] += 10 //adiciono tamanho da enchoice p11

	//CAMPOS CABEÇALHO
	oScrCab := TScrollBox():New(oDlgFCaixa,aPObj[1,1],aPObj[1,2],aPObj[1,3],aPObj[1,4],.F.,.T.,.T.)

	@ 005, 012 SAY "Caixa:" SIZE 025, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 003, 075 MSGET oGetCxa  VAR cGetCxa SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 020, 012 SAY "Nome:" SIZE 025, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 018, 075 MSGET oGetNom  VAR cGetNom SIZE 204, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 035, 012 SAY "Estação:" SIZE 025, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 033, 075 MSGET oGetEst  VAR cGetEst SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 050, 012 SAY "Serie:" SIZE 025, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 048, 075 MSGET oGetSer  VAR cGetSer SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 065, 012 SAY "PDV:" SIZE 025, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 063, 075 MSGET oGetPDV  VAR cGetPDV SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 080, 012 SAY "Emp./Fil:" SIZE 025, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 078, 075 MSGET oGetFil  VAR cGetFil SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 005, 156 SAY "Num. Movimento:" SIZE 043, 006 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 003, 219 MSGET oGetMov  VAR cGetMov SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 035, 156 SAY "Dt. Abertura:" SIZE 042, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 033, 219 MSGET oGetDtA  VAR dGetDtA SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 050, 156 SAY "Hr. Abertura:" SIZE 038, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 048, 219 MSGET oGetHrA  VAR cGetHrA SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 065, 156 SAY "Dt. Fechamento:" SIZE 052, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 063, 219 MSGET oGetDtF  VAR dGetDtF SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 080, 156 SAY "Hr. Fechamento:" SIZE 044, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 078, 219 MSGET oGetHrF VAR cGetHrF SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL READONLY

	@ 005, 300 SAY "Observações:" SIZE 050, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	if nOpcx == 4
		@ 018, 300 GET oGetObs VAR cGetObs OF oScrCab MULTILINE SIZE aPObj[1,4]-315, aPObj[1,3]-25 COLORS 0, 16777215 PIXEL
	else
		@ 018, 300 GET oGetObs VAR cGetObs OF oScrCab MULTILINE SIZE aPObj[1,4]-315, aPObj[1,3]-25 COLORS 0, 16777215 PIXEL READONLY
	endif

	//GRID FORMAS
	TSay():New( aPObj[2,1]+5,aPObj[2,2]+5,{|| "Valores " }, oDlgFCaixa,,oFontGrid,,,,.T.,nCorGrid,,200,15 )
	TSay():New( aPObj[2,1]+5,aPObj[2,2],{|| Replicate("_",aPObj[2,4]) }, oDlgFCaixa,,oFontGrid,,,,.T.,nCorGrid,,aPObj[2,4],15 )

	oGridForma := DoGridForma(oDlgFCaixa, aPObj[2,1]+15, aPObj[2,2], aPObj[2,3], aPObj[2,4] )

	//CAMPOS RODAPÉ
	oScrRod := TScrollBox():New(oDlgFCaixa,aPObj[3,1],aPObj[3,2],aPObj[3,3]-aPObj[3,1],aPObj[3,4],.F.,.T.,.T.)

	@ 008, 012 SAY "Dif. Operador:" SIZE 040, 007 OF oScrRod COLORS 0, 16777215 PIXEL
	@ 006, 057 MSGET oGetVDg VAR nGetVDg When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oScrRod HASBUTTON COLORS 0, 16777215 PIXEL

	@ 008, 170 SAY "Dif. Apurado:" SIZE 040, 007 OF oScrRod COLORS 0, 16777215 PIXEL
	@ 006, 219 MSGET oGetVAp VAR nGetVAp When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oScrRod HASBUTTON COLORS 0, 16777215 PIXEL

	@ 008, 335 SAY "Saldo "+SIMBDIN+" Sistema:" SIZE 080, 007 OF oScrRod COLORS 0, 16777215 PIXEL
	@ 006, 381 MSGET oGetSld VAR nGetSld When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oScrRod HASBUTTON COLORS 0, 16777215 PIXEL

	//definição de açoes sobre grid
	oGridForma:oBrowse:BlDblClick := {|| DoDetForma(nOpcx) }

	//Adiciono botões em ações relacionadas
	if !lSrvPDV
		aadd(aButtons, {"Conf. Documentos", {|| ConfDocs(nOpcx==4) }, "Conf. Documentos"} )
		if nOpcx == 4
			aadd(aButtons ,{"Devolução de Venda", {|| DevVenda()}, "Devolução de Venda"})
		endif
		if lMvPosto
			aadd(aButtons ,{"Abast. Duplicado", {|| ListDev() }, "Abast. Duplicado"})
		endif
		If ChkFile("U0H") //verifica existência de arquivo: U0H - Hist. Movim. Processos Venda
			aadd(aButtons ,{"Log Conferencia Caixa", {|| ListHist()}, "Log Conferencia Caixa"})
		EndIf
	endif

	//encerra montagem DLG
	oDlgFCaixa:bInit := {|| EnchoiceBar(oDlgFCaixa, bOk, bCancel,.F.,@aButtons, SLW->(Recno()),"SLW", .F., .F., .F., .T., .F.), AtuVlrGrid("", nOpcX, .T.), oGridForma:oBrowse:SetFocus() }
	oDlgFCaixa:lCentered := .T.
	oDlgFCaixa:Activate()

	DoRpcClose() //fecha RPC caso ainda em aberto

	//independente se confirmou ou não a tela, vou gravar a observação
	if nOpcx == 4
		if RecLock("SLW", .F.)
			if SLW->(FieldPos("LW_XOBS")) > 0
				SLW->LW_XOBS := cGetObs
			endif
			SLW->(MsUnlock())
		endif
	endif

	DbCommitAll()
	DbUnlockAll()

Return

//--------------------------------------------------------------------------------------
// Função para montagem do grid de valores por forma
//--------------------------------------------------------------------------------------
Static Function DoGridForma(oDlgX, nTop, nLeft, nBottom, nRight)

	Local aHeaderEx    := {}
	Local aColsEx      := {}
	Local aFieldFill   := {}
	Local aCampos      := {}
	Local aAlterFields := {}
	Local nLinMax 	   := 999  // Quantidade de linha na getdados
	Local nX := 0

	aCampos := {"DET","LT_FORMPG","X5_DESCRI","LT_VLRDIG","LT_VLRAPU","DIF","DEBCRE"}

	// Define field properties
	For nX := 1 to Len(aCampos)
		If AllTrim(aCampos[nX])== "DET"
			Aadd(aHeaderEx,{ ' ','DET','@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
		ElseIf AllTrim(aCampos[nX])== "APURADO"
			Aadd(aHeaderEx,{ '','APURADO','@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
		ElseIf AllTrim(aCampos[nX])== "DIF"
			Aadd(aHeaderEx,{ 'Diferença ','DIF','@E 9,999,999.99',12,2,'','€€€€€€€€€€€€€€','N','','','',''})
		ElseIf AllTrim(aCampos[nX])== "DEBCRE"
			Aadd(aHeaderEx,{ ' ','DEBCRE','@!',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
		ElseIf !empty(GetSx3Cache( aCampos[nX] ,"X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aCampos[nX]) )
			If AllTrim(aCampos[nX])== "LT_VLRDIG"
				aHeaderEx[len(aHeaderEx)][1] := "Valor Operador"
			ElseIf AllTrim(aCampos[nX])== "X5_DESCRI"
				aHeaderEx[len(aHeaderEx)][4] := 60
			ElseIf AllTrim(aCampos[nX])== "LT_FORMPG"
				aHeaderEx[len(aHeaderEx)][4] := 3
			EndIf
		Endif
	Next nX

	//montado dados de acordo com formas habilitadas
	For nX := 1 to len(aFormasHab)

		aFieldFill := {}

		if !empty(aFormasHab[nX][4]) //se tem função de total mostra
			Aadd(aFieldFill,"PESQUISA")
			Aadd(aFieldFill,aFormasHab[nX][1]) //ID FORMA
			Aadd(aFieldFill,aFormasHab[nX][2]) //DESC FORMA
			Aadd(aFieldFill,0) //VALOR OPERADOR
			Aadd(aFieldFill,0) //VALOR APURADO
			Aadd(aFieldFill,0) //DIF
			Aadd(aFieldFill, "("+aFormasHab[nX][3]+")") //DEBCRE
			Aadd(aFieldFill,.F.) //deletado
			Aadd(aColsEx, aFieldFill)
		endif

	Next nX

Return MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "AllwaysTrue",aAlterFields, , nLinMax, "AllwaysTrue", "AllwaysTrue", "AllwaysTrue", oDlgX, aHeaderEx, aColsEx)

//--------------------------------------------------------------------------------------
// Função responsável por retornar as formas habilitadas na rotina
//--------------------------------------------------------------------------------------
User Function TR028FHA()
	Local aRet := FormasHab()
Return aRet
Static Function FormasHab()

	Local aRet := {}

	/* Posições do array de retorno
	---------------------------------------
	1: Codigo da Forma
	2: Descrição da Forma
	3: Sinal da Forma ("+"=Soma;"-"=Subtrai;""=Neutro)
	4: Função para apurar forma (somar total da forma)
	5: Função para tela detalhar itens
	6: Função para relatório detalhar itens
	7: Digita Conferencia PDV (logico): .T.=Digita;.F.=Apura Automatico
	8: Habilita forma para trocar por outra na venda
	--------------------------------------- */

	//atualizo, pois se o parametro estiver criado por filial, poderá montar a tela errada.
	lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.)

	aadd(aRet, {"NFC", "CUPONS / NOTAS FISCAIS ", "", "", "", "T028RSL1", .F., .F.} )

	aadd(aRet, {"SU", "SUPRIMENTO DE CAIXA", "+", "T028TSU", "T028DSU", "T028RSS", .F., .F.} )
	if lMvPosto
		aadd(aRet, {"VC", "VENDA COMBUSTIVEL", "+", "T028TVC", "T028DVC", "T028RVC", .F., .F.} )
	endif
	aadd(aRet, {"VP", "VENDA PRODUTOS", "+", "T028TVP", "T028DVP", "T028RVP", .F., .F.} )
	if lMvPosto
		if SuperGetMV("TP_ACTVLS",,.F.)
			aadd(aRet, {"VLS", "VALE SERVIÇO (PRÉ/PÓS EMITIDO)", "+", "T028TVLS", "T028DVLS", "T028RVLS", .F., .F.} )
		endif
		if SuperGetMV("TP_ACTCHT",,.F.)
			aadd(aRet, {"CHT", "CHEQUE TROCO", "+", "T028TCHT", "T028DCHT", "T028RCHT", .F., .F.} )
		endif
		if SuperGetMV("TP_ACTVLH",,.F.)
			aadd(aRet, {"VLH", "VALE HAVER EMITIDO", "+", "T028TVLH", "T028DVLH", "T028RVLH", .F., .F.} )
		endif
		if SuperGetMV("TP_ACTDP",,.F.)
			aadd(aRet, {"DP", "DEPÓSITO NO PDV", "+", "T028TDP", "T028DDP", "T028RSQ", .F., .F.} )
		endif
	endif

	//------------------------------- DIVISÃO POSITIVO/NEGATIVO ----------------------------------------

	aadd(aRet, {"DIN", "RECEBIDO EM DINHEIRO", "", "T028TDIN", "T028DDIN", "T028RDIN", .F., .F.} )
	aadd(aRet, {"CC", "CARTAO DE CREDITO", "-", "T028TCC", "T028DCC", "T028RGEN", .T., .T.} )
	aadd(aRet, {"CD", "CARTAO DE DEBITO", "-", "T028TCD", "T028DCD", "T028RGEN", .T., .T.} )
	aadd(aRet, {"CH", "CHEQUE A VISTA", "-", "T028TCH", "T028DCH", "T028RCHR", .T., .T.} )
	aadd(aRet, {"CHP", "CHEQUE A PRAZO", "-", "T028TCHP", "T028DCHP", "T028RCHR", .T., .T.} )
	aadd(aRet, {"CR", "CREDITOS USADOS VENDA (RA/NCC)", "-", "T028TCR", "T028DCR", "T028RCR", .T., .T.} )
	If !Empty(Posicione("SX5",1,xFilial("SX5")+"24"+"PX","X5_DESCRI"))
		aadd(aRet, {"PX", "PIX", "-", "T028TPX", "T028DPX", "T028RGEN", .T., .T.} )
	EndIf
	if lMvPosto
		if SuperGetMV("TP_ACTNP",,.F.)
			aadd(aRet, {"NP" , "NOTA A PRAZO", "-", "T028TNP", "T028DNP", "T028RGEN", .T., .T.} )
		endif
		if SuperGetMV("TP_ACTCT",,.F.)
			aadd(aRet, {"CT" , "CTF - CONTROLE TOTAL DE FROTAS", "-", "T028TCT", "T028DCT", "T028RGEN", .T., .T.} )
		endif
		if SuperGetMV("TP_ACTCF",,.F.)
			aadd(aRet, {"CF" , "CARTA FRETE", "-", "T028TCF", "T028DCF", "T028RCF", .T., .T.} )
		endif
		if SuperGetMV("TP_ACTSQ",,.F.)
			aadd(aRet, {"SQ" , "REQ. PRE-PAGA SAQUE ( DEPOSITO EM CONTA SAQUE )", "-", "T028TSQ", "T028DSQ", "T028RSQ", .F., .F.} )
			aadd(aRet, {"VLM", "REQ. POS-PAGA SAQUE ( VALE MOTORISTA )", "-", "T028TVLM", "T028DVLM", "T028RSQ", .F., .F.} )
		endif
		if SuperGetMV("TP_ACTVLS",,.F.)
			aadd(aRet, {"VSF", "VALE SERVIÇO (FINANCEIRO PÓS-PAGO)", "-", "T028TVSF", "T028DVSF", "", .F., .F.} )
		endif
	endif
	aadd(aRet, {"SG", "SANGRIA DE CAIXA", "-", "T028TSG", "T028DSG", "T028RSS", .F., .F.} )

	if SuperGetMV("TP_DETTVEN",,.T.) //Detalhamento de troco em dinheiro das vendas (default .T.)
		aadd(aRet, {"TR", "TROCO EM DINHEIRO (VENDAS)", "", "T028TTV", "T028DTV", "T028RTV", .F., .F.} )
	endif

	if lMvPosto
		if SuperGetMV("TP_ACTCMP",,.F.)
			aadd(aRet, {"CMP", "COMPENSAÇÃO DE VALORES", "", "", "", "T028RCMP", .F., .F.} )
		endif
	endif

	//Ponto de entrada para adicionar novas formas
	if ExistBlock("TRA028FP")
		aRetPE := ExecBlock("TRA028FP",.F.,.F., aRet)
		if valtype(aRetPE) == "A"
			aRet := aClone(aRetPE)
		endif
	endif

Return aRet

//--------------------------------------------------------------------------------------
// Chama rotina de detalhamento, de acordo com a forma
//--------------------------------------------------------------------------------------
Static Function DoDetForma(nOpcX)

	Local nPosForma := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_FORMPG"})
	Local cForma := oGridForma:aCols[oGridForma:nAt][nPosForma]
	Local nPosFunc := aScan(aFormasHab, {|x| x[1] == cForma })
	Local cFuncton := ""
	Local aRetBlock
	Local lAtuGrid := .F.
	Local lAtuTudo := .F.
	Private __cFORMAATU := cForma

	if nPosFunc > 0
		cFuncton := aFormasHab[nPosFunc][5]
		if !empty(cFuncton)
			if ExistBlock(cFuncton)
				MsAguarde({|| aRetBlock := ExecBlock(cFuncton,.F.,.F., {nOpcX}) },"Aguarde...","Abrindo detalhamento...",.T.)

				if valtype(aRetBlock) == "A"
					lAtuGrid := aRetBlock[1]
					lAtuTudo := aRetBlock[2]
				else
					lAtuGrid := .F.
					lAtuTudo := .F.
				endif

				//atualização da tela
				if lAtuGrid
					if lAtuTudo
						AtuVlrGrid("", nOpcX, .T.)
					else
						AtuVlrGrid(cForma, nOpcX, .T.)
					endif
				endif
			else
				MsgInfo("Função de usuário " + cFuncton + " não está compilada.","Atenção")
			endif
		else
			MsgInfo("Esta forma não tem detalhamento!","Atenção")
		endif
	else
		MsgInfo("Não é possível detalhar esta forma.","Atenção")
	endif

Return

//--------------------------------------------------------------------------------------
// Atualiza valor no grid da forma de pagamento
// Obs: Se cForma for vazio, atualza tudo
//--------------------------------------------------------------------------------------
User Function TR028AVG(cForma, nOpcX, lRefresh)
Return AtuVlrGrid(cForma, nOpcX, lRefresh)
Static Function AtuVlrGrid(cForma, nOpcX, lRefresh)

	Local cMsgAguarde := "Consulta do fluxo de caixa do operador (Movimento Processos de Venda)..."
	LjMsgRun(cMsgAguarde,"Conferencia de Caixa",{|| AtuVlrProc(cForma, nOpcX, lRefresh) })

Return

//--------------------------------------------------------------------------------------
// Processamento da funçao AtuVlrGrid
//--------------------------------------------------------------------------------------
Static Function AtuVlrProc(cForma, nOpcX, lRefresh)

	Local nPosVlrDig := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRDIG"})
	Local nPosVlrApu := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRAPU"})
	Local nPosForma  := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_FORMPG"})
	Local nPosDifer  := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "DIF"})
	Local nPosAtu := 0
	Local nX := 0

	Local cForAtu := ""

	//Carregando SLT no Valor Digitado
	if empty(cForma)
		SLT->(DbSetorder(5))
		If SLT->(DbSeek(xFilial("SLT")+DTOS(SLW->LW_DTFECHA)+SLW->LW_NUMMOV+SLW->LW_OPERADO+SLW->LW_ESTACAO+SLW->LW_PDV))
			While SLT->(!Eof()) .AND. SLT->LT_FILIAL+DTOS(SLT->LT_DTFECHA)+SLT->LT_NUMMOV+SLT->LT_OPERADO+SLT->LT_ESTACAO+SLT->LT_PDV == ;
			xFilial("SLT")+DTOS(SLW->LW_DTFECHA)+SLW->LW_NUMMOV+SLW->LW_OPERADO+SLW->LW_ESTACAO+SLW->LW_PDV

				nX := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == Alltrim(SLT->LT_FORMPG) })

				if nX > 0
					oGridForma:aCols[nX][nPosVlrDig] := SLT->LT_VLRDIG
				endif

				SLT->(DbSkip())
			EndDo
		EndIf
	endif

	//Carregando valores apurados pelas funções
	For nX := 1 to len(oGridForma:aCols)

		cForAtu := ""
		if empty(cForma)
			cForAtu := oGridForma:aCols[nX][nPosForma]
		else
			if oGridForma:aCols[nX][nPosForma] == cForma
				cForAtu := cForma
			endif
		endif

		if !empty(cForAtu)

			//atualiza a partir da função definida no aFormasHab
			nPosAtu := nPosVlrApu
			oGridForma:aCols[nX][nPosAtu] := DoTotForma(cForAtu, nOpcX)

			oGridForma:aCols[nX][nPosDifer] := oGridForma:aCols[nX][nPosVlrApu] - oGridForma:aCols[nX][nPosVlrDig]

		endif

	next nX

	if lRefresh
		oGridForma:oBrowse:Refresh()
		AtuTotais(lRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Chama rotina de detalhamento, de acordo com a forma
//--------------------------------------------------------------------------------------
User Function TR028DTF(cForma, nOpcX)
	Local nRet := DoTotForma(cForma, nOpcX)
Return nRet
Static Function DoTotForma(cForma, nOpcX)

	Local nPosFunc := aScan(aFormasHab, {|x| x[1] == cForma })
	Local cFuncton := ""
	Local nRet := 0
	Private __cFORMAATU := cForma

	if nPosFunc > 0
		cFuncton := aFormasHab[nPosFunc][4]

		if !empty(cFuncton)
			if ExistBlock(cFuncton)
				nRet := ExecBlock(cFuncton,.F.,.F., {nOpcX})
			endif
		endif
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Atualiza totalizadores de acordo com o grid
//--------------------------------------------------------------------------------------
Static Function AtuTotais(lRefresh)

	Local nX := 0
	Local nPosSinal := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "DEBCRE"})
	Local nPosVlrDig := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRDIG"})
	Local nPosVlrApu := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRAPU"})

	nGetVDg := 0
	nGetVAp := 0
	nGetSld := 0

	for nX := 1 to len(oGridForma:aCols)
		if "+" $ oGridForma:aCols[nX][nPosSinal]
			nGetVDg += oGridForma:aCols[nX][nPosVlrDig]
			nGetVAp += oGridForma:aCols[nX][nPosVlrApu]
		elseif "-" $ oGridForma:aCols[nX][nPosSinal]
			nGetVDg -= oGridForma:aCols[nX][nPosVlrDig]
			nGetVAp -= oGridForma:aCols[nX][nPosVlrApu]
		endif
	next nX

	//inverto sinal
	nGetVDg *= (-1)
	nGetVAp *= (-1)

	nGetSld := CalcSaldoFinal()

	oGetSld:Refresh()
	oGetVDg:Refresh()
	oGetVAp:Refresh()

Return

//--------------------------------------------------------------------------------------
// Gravação na confirmação da tela de conferência.
//--------------------------------------------------------------------------------------
Static Function DoGravaConf(nOpcx)

	Local nX
	Local nPosVlrApu := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRAPU"})
	Local nPosForma  := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_FORMPG"})
	Local cForAtu := ""
	Local dBkpDBase := dDataBase
	Local lOk := .T.
	Local aRatFCX := {}
	Local lAlcada	:= SuperGetMv("ES_ALCADA",,.F.)
	Local lAlcDifCx	:= SuperGetMv("ES_ALCDCX",.F.,.F.)
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lConfPend := SuperGetMv("ES_CONFPEN",,.F.) // Permite confirmar caixa com pendência financeira (default .F.)
	Private aLogAlcada := {}

	LjGrvLog ("TRETA028", "Inicio Confirmar Caixa",)
	LjGrvLog ("TRETA028", "AMBIENTE", GetEnvServer() )
	LjGrvLog ("TRETA028", "LW_FILIAL", SLW->LW_FILIAL)
	LjGrvLog ("TRETA028", "LW_OPERADO", SLW->LW_OPERADO)
	LjGrvLog ("TRETA028", "LW_NUMMOV", SLW->LW_NUMMOV)
	LjGrvLog ("TRETA028", "LW_ESTACAO", SLW->LW_ESTACAO)
	LjGrvLog ("TRETA028", "LW_PDV", SLW->LW_PDV)
	LjGrvLog ("TRETA028", "LW_DTABERT", SLW->LW_DTABERT)
	LjGrvLog ("TRETA028", "LW_HRABERT", SLW->LW_HRABERT)

	MsAguarde({|| lOk := VldCancSL1() },"Aguarde...","Verificando Cupons Cancelados...",.T.)
	If !lOk //verifico cupons cancelados quanto a devoluçoes e prazo de cancelamento.
		LjGrvLog ("TRETA028", "Retorno: !VldCancSL1()",)
		Return
	EndIf

	If !ConfDocs(.F.,.T.)
		If lConfPend 
			If !MsgYesNo("O caixa será confirmado com pendências financeiras, deseja Continuar?"+CRLF+CRLF+"Verifique as pendências na opção 'Conf. Documentos'.","Atenção")
				LjGrvLog ("TRETA028", "O caixa não será confirmado porque existem pendências financeiras. Verifique as pendências na opção 'Conf. Documentos'.",)
				Return
			EndIf
		Else 
			MsgAlert("O caixa não será confirmado porque existem pendências financeiras. Verifique as pendências na opção 'Conf. Documentos'.","Atenção")
			LjGrvLog ("TRETA028", "O caixa não será confirmado porque existem pendências financeiras. Verifique as pendências na opção 'Conf. Documentos'.",)
			Return
		EndIf
	EndIf

	If nGetSld <> Round((nGetVAp*(-1)),2)
		MsgAlert("O caixa possui documentos não conferidos ou não lançados. Por favor faça a conferência.","Atenção")
		LjGrvLog ("TRETA028", "O caixa possui documentos não conferidos ou não lançados. Por favor faça a conferência.",)
		Return
	EndIf

	//VALIDA BAIXA DUPLICADA DE ABASTECIMENTO
	if lMvPosto 
		MsAguarde({|| lOk := AtuGrid(3) },"Aguarde...","Verificando abast. duplicado...",.T.)
		if lOk .and. !lConfPend
			MsgAlert("O caixa não será confirmado porque tem vendas de abastecimento baixado em duplicidade! Verifique as vendas na opção 'Abast. Duplicado'.","Atenção")
			LjGrvLog ("TRETA028", "O caixa não será confirmado porque tem vendas de abastecimento baixado em duplicidade! Verifique as vendas na opção 'Abast. Duplicado'.",)
			Return
		endif
	endif

	MsAguarde({|| lOk := U_TRA028ES(.F.) },"Aguarde...","Verificando movimento diferença...",.T.)
	If !lOk //verifica se já possuí movimento de difernça de caixa e estorna
		LjGrvLog ("TRETA028", "Retorno: !U_TRA028ES(.F.)",)
		Return //não foi possível estornar
	EndIf

	//Ponto de entrada para validar confirmação da conferencia do caixa
	if ExistBlock("TRA028OK")
		if !ExecBlock("TRA028OK",.F.,.F.)
			Return
		endif
	endif

	If !MsgYesNo("O Caixa será confirmado. Não será possível fazer novas alterações, deseja Continuar?","Atenção")
		LjGrvLog ("TRETA028", "Retorno: Cancelado pelo usuario",)
		Return
	EndIf

	BeginTran()
	LjGrvLog ("TRETA028", "BeginTran()",)

	//Faz gravações na SLT
	LjGrvLog ("TRETA028", "Antes da Gravacao da SLT",)
	SLT->(DbSetorder(4)) //LT_FILIAL+LT_OPERADO+DTOS(LT_DTFECHA)+LT_FORMPG+LT_PDV+LT_NUMMOV+LT_ADMIFIN+DTOS(LT_DTMOV)
	For nX:=1 to Len(oGridForma:aCols)

		cForAtu := PADR(oGridForma:aCols[nX][nPosForma],TamSX3("LT_FORMPG")[1])

		If SLT->(DbSeek(xFilial("SLT")+SLW->LW_OPERADO+DTOS(SLW->LW_DTFECHA)+cForAtu+SLW->LW_PDV+SLW->LW_NUMMOV))
			RecLock("SLT",.F.)
			SLT->LT_VLRAPU := oGridForma:aCols[nX][nPosVlrApu]
			SLT->(MsUnLock())
		Else
			RecLock("SLT",.T.)
			SLT->LT_FILIAL 	:= xFilial("SLT")
			SLT->LT_OPERADO := SLW->LW_OPERADO
			SLT->LT_DTFECHA := SLW->LW_DTFECHA
			SLT->LT_FORMPG 	:= cForAtu
			SLT->LT_VLRAPU 	:= oGridForma:aCols[nX][nPosVlrApu]
			SLT->LT_NUMMOV	:= SLW->LW_NUMMOV
			SLT->LT_MOEDA 	:= 1
			SLT->LT_DTMOV 	:= dDataBase
			SLT->LT_SITUA	:= "RX"
			SLT->LT_PDV	 	:= SLW->LW_PDV
			SLT->LT_CONFERE := "1"
			SLT->LT_ESTACAO := SLW->LW_ESTACAO
			SLT->(MsUnLock())
		EndIf

	Next
	LjGrvLog ("TRETA028", "Depois da Gravacao da SLT",)

	//posiciono no banco para caso de fazer movimento bancario da diferença caixa
	SA6->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6")+SLW->LW_OPERADO))
	dDataBase := SLW->LW_DTABERT

	If nGetVap < 0  // se tiver falta de caixa

		// se for menor que a difernça maxima fica para o posto
		if nGetVap*(-1) <= SuperGetMv("MV_XDIFMAX",.T.,0)
			
			LjGrvLog ("TRETA028", "Falta Caixa menor que a difernça maxima MV_XDIFMAX: Lança diferenca para Empresa",)

			MsAguarde({|| lOk := GravaDifCaixa( nGetVap*(-1) , 3) },"Aguarde...","Gravando movimento caixa...",.T.)
			if lOk //movimento saida
				RecLock("SLW",.F.)
				SLW->LW_CONFERE := "1"
				if SLW->(FieldPos("LW_XOBS")) > 0
					SLW->LW_XOBS := cGetObs
				endif
				if SLW->(FieldPos("LW_XFLTCX")) > 0
					SLW->LW_XFLTCX := nGetVap*(-1) //HISTORICO DE DIFERENCA DE CAIXA PARA POSSIBILITAR ESTORNO
				endif
				SLW->(MsUnlock())
				MsgInfo("Movimento bancario da falta de caixa incluido com sucesso!","Atenção")
				LjGrvLog ("TRETA028", "Movimento bancario da falta de caixa incluido com sucesso!",)
			else
				MsgAlert("Falha ao incluir movimento bancario de falta de caixa! Gravação abortada.","Atenção")
				LjGrvLog ("TRETA028", "Falha ao incluir movimento bancario de falta de caixa! Gravação abortada. #1",)
				lOk := .F.
				DisarmTransaction()
			endif

		Else

			//verifica se diferença vai na folha ou vai solicitar empresa assumir (passando por alçada)
			nRet := Aviso("Falta de Caixa", ;
						"A diferença de caixa de "+SIMBDIN+" " + AllTrim(Str(nGetVap*(-1))) + ;
						" é maior que o maximo permitido de "+SIMBDIN+" " + AllTrim(Str(SuperGetMv("MV_XDIFMAX",.T.,0))) + "." + ;
						CRLF + CRLF + "Lançar o valor da falta de caixa para?" ,;
						{"Operador", "Empresa"}, 2)

			if nRet == 1 //se lança para operador
				LjGrvLog ("TRETA028", "Lança diferenca para Operador",)

				If SA6->(FieldPos("A6_XRATFCX")) > 0 .AND. SA6->A6_XRATFCX == "S"
					if !RatFaltaCX(@aRatFCX)
						lOk := .F.
						DisarmTransaction()
					endif
				EndIf
				if lOk
					MsAguarde({|| lOk := GravaDifCaixa( nGetVap*(-1) , 3, GetMv("MV_XNATFUN"),aRatFCX) },"Aguarde...","Gravando movimento caixa...",.T.)
					if lOk //movimento saida
						RecLock("SLW",.F.)
						SLW->LW_CONFERE := "1"
						if SLW->(FieldPos("LW_XOBS")) > 0
							SLW->LW_XOBS := cGetObs
						endif
						if SLW->(FieldPos("LW_XFALTCX")) > 0
							SLW->LW_XFALTCX:= nGetVap*(-1)//INTEGRACAO COM A FOLHA (DESCONTANDO DO FUNCIONARIO)
						endif
						if SLW->(FieldPos("LW_XFLTCX")) > 0
							SLW->LW_XFLTCX:= nGetVap*(-1)//HISTORICO DE DIFERENCA DE CAIXA PARA POSSIBILITAR ESTORNO
						endif
						SLW->(MsUnlock())
						MsgInfo("Falta de caixa lançada para operador de caixa! " + CRLF + "Movimento bancario da falta de caixa incluido com sucesso!","Atenção")
						LjGrvLog ("TRETA028", "Falta de caixa lançada para operador! Movimento bancario da falta de caixa incluido com sucesso!",)
					else
						MsgAlert("Falha ao incluir movimento bancario de falta de caixa! Gravação abortada.","Atenção")
						LjGrvLog ("TRETA028", "Falha ao incluir movimento bancario de falta de caixa! Gravação abortada. #2",)
						lOk := .F.
						DisarmTransaction()
					endif
				endif

			elseIf nRet == 2 //se diferença para empresa
				
				LjGrvLog ("TRETA028", "Lança diferenca para Empresa",)

				if lAlcada .AND. lAlcDifCx
					LjGrvLog ("TRETA028", "Verifica alçada para diferenca Empresa",)
					lOk := LibAlcadaDif(,(nGetVap*(-1))) //verifico alçada do prorio usuario
					if !lOk
						lOk := TelaLibAlcada((nGetVap*(-1)))
					endif
				endif
				if lOk
					MsAguarde({|| lOk := GravaDifCaixa( nGetVap*(-1) , 3) },"Aguarde...","Gravando movimento caixa...",.T.)
					if lOk //movimento saida
						RecLock("SLW",.F.)
						SLW->LW_CONFERE := "1"
						if SLW->(FieldPos("LW_XOBS")) > 0
							SLW->LW_XOBS := cGetObs
						endif
						if SLW->(FieldPos("LW_XFLTCX")) > 0
							SLW->LW_XFLTCX:= nGetVap*(-1)//HISTORICO DE DIFERENCA DE CAIXA PARA POSSIBILITAR ESTORNO
						endif
						SLW->(MsUnlock())
						
						if lAlcada .AND. lAlcDifCx .AND. !empty(aLogAlcada) 
							for nX := 1 to len(aLogAlcada)
								U_TR037LCE(aLogAlcada[nX][1], aLogAlcada[nX][2], SLW->LW_FILIAL+SLW->LW_PDV+SLW->LW_OPERADO+DTOS(SLW->LW_DTABERT)+SLW->LW_ESTACAO+SLW->LW_NUMMOV , aLogAlcada[nX][3])
							next nX
						endif
						
						MsgInfo("Falta de caixa lançada para empresa!" + CRLF + "Movimento bancario da falta de caixa incluido com sucesso!","Atenção")
						LjGrvLog ("TRETA028", "Falta de caixa lançada para empresa! Movimento bancario da falta de caixa incluido com sucesso!" ,)
					else
						MsgAlert("Falha ao incluir movimento bancario de falta de caixa! Gravação abortada.","Atenção")
						LjGrvLog ("TRETA028", "Falha ao incluir movimento bancario de falta de caixa! Gravação abortada. #3",)
						lOk := .F.
						DisarmTransaction()
					endif
				else
					LjGrvLog ("TRETA028", "Não tem alçada ou abortou gravaçao!",)
					DisarmTransaction()
				endif

			endif

		endif

	elseif nGetVap > 0 // Grava a sobra de caixa para empresa
		
		//verifica se diferença vai na folha ou vai solicitar empresa assumir (passando por alçada)
		nRet := Aviso("Sobra de Caixa", ;
					"Sobra de caixa de "+SIMBDIN+" " + AllTrim(Str(nGetVap)) + "." +;
					CRLF + CRLF + "Lançar o valor da sobra de caixa para?" ,;
					{"Operador", "Empresa"}, 2)

		if nRet == 1 //se lança para operador
			LjGrvLog ("TRETA028", "Lança diferenca para Operador",)

			If SA6->(FieldPos("A6_XRATFCX")) > 0 .AND. SA6->A6_XRATFCX == "S"
				if !RatFaltaCX(@aRatFCX,.T.)
					lOk := .F.
					DisarmTransaction()
				endif
			EndIf
			if lOk
				MsAguarde({|| lOk := GravaDifCaixa( nGetVap , 4, GetMv("MV_XNATFUN"),aRatFCX) },"Aguarde...","Gravando movimento caixa...",.T.)
				if lOk //movimento entrada
					RecLock("SLW",.F.)
					SLW->LW_CONFERE := "1"
					if SLW->(FieldPos("LW_XOBS")) > 0
						SLW->LW_XOBS := cGetObs
					endif
					if SLW->(FieldPos("LW_XFLTCX")) > 0
						SLW->LW_XFLTCX := nGetVap //HISTORICO DE DIFERENCA DE CAIXA PARA POSSIBILITAR ESTORNO
					endif
					SLW->(MsUnlock())
					MsgInfo("Movimento bancario da sobra de caixa incluido com sucesso!","Atenção")
					LjGrvLog ("TRETA028", "Movimento bancario da sobra de caixa incluido com sucesso!",)
				else
					MsgAlert("Falha ao incluir movimento bancario de sobra de caixa! Gravação abortada.","Atenção")
					LjGrvLog ("TRETA028", "Falha ao incluir movimento bancario de sobra de caixa! Gravação abortada.",)
					lOk := .F.
					DisarmTransaction()
				endif
			endif

		elseIf nRet == 2 //se diferença para empresa
			
			LjGrvLog ("TRETA028", "Grava a sobra de caixa para empresa",)

			MsAguarde({|| lOk := GravaDifCaixa(nGetVap, 4) },"Aguarde...","Gravando movimento caixa...",.T.)
			if lOk //movimento entrada
				RecLock("SLW",.F.)
				SLW->LW_CONFERE := "1"
				if SLW->(FieldPos("LW_XOBS")) > 0
					SLW->LW_XOBS := cGetObs
				endif
				if SLW->(FieldPos("LW_XFLTCX")) > 0
					SLW->LW_XFLTCX := nGetVap //HISTORICO DE DIFERENCA DE CAIXA PARA POSSIBILITAR ESTORNO
				endif
				SLW->(MsUnlock())
				MsgInfo("Movimento bancario da sobra de caixa incluido com sucesso!","Atenção")
				LjGrvLog ("TRETA028", "Movimento bancario da sobra de caixa incluido com sucesso!",)
			else
				MsgAlert("Falha ao incluir movimento bancario de sobra de caixa! Gravação abortada.","Atenção")
				LjGrvLog ("TRETA028", "Falha ao incluir movimento bancario de sobra de caixa! Gravação abortada.",)
				lOk := .F.
				DisarmTransaction()
			endif

		endif

	else //sem diferença de caixa (valor zerado), apenas muda status
		
		LjGrvLog ("TRETA028", "Sem diferença de caixa (valor zerado), apenas muda status.",)

		RecLock("SLW",.F.)
		SLW->LW_CONFERE := "1"
		if SLW->(FieldPos("LW_XOBS")) > 0
			SLW->LW_XOBS := cGetObs
		endif
		if SLW->(FieldPos("LW_XFLTCX")) > 0
			SLW->LW_XFLTCX:= nGetVap //HISTORICO DE DIFERENCA DE CAIXA PARA POSSIBILITAR ESTORNO
		endif
		SLW->(MsUnlock())

	endif

	EndTran()
	LjGrvLog ("TRETA028", "EndTran()",)
	
	if !lOk
		LjGrvLog ("TRETA028", "Retorno: !lOk",)
		Return
	endif

	dDataBase := dBkpDBase
	oDlgFCaixa:End()

	LjGrvLog ("TRETA028", "Fechou tela: oDlgFCaixa:End() ",)

	//Ponto de entrada para realizar alguma ação após fechamento do caixa
	if ExistBlock("CONCXFIM")
		LjGrvLog ("TRETA028", "Antes do PE CONCXFIM",)
		ExecBlock("CONCXFIM",.F.,.F.,{nGetVap})
		LjGrvLog ("TRETA028", "Após do PE CONCXFIM",)
	endif

	If lOk .AND. lLogCaixa .and. SLW->LW_CONFERE == "1"
		LjGrvLog ("TRETA028", "Antes de gravar historico do caixa.",)
		MsAguarde({|| GrvLogConf("1","F") },"Aguarde...","Gravando historico do caixa...",.T.)
		LjGrvLog ("TRETA028", "Após gravar historico do caixa.",)
	EndIf

	LjGrvLog ("TRETA028", "Fim do Confirmar Caixa",)

Return

//Tela de liberação do caixa alçada
Static Function LibAlcadaDif(cCodUsr, nVlrDif)

	Local nZ
	Local lRet := .F.
	Local nVlrDifAlc := 0
	Local cMsgLog 
	Default cCodUsr := RetCodUsr()

	cMsgLog := "Alçada Diferença de Caixa." + CRLF
	cMsgLog += "Valor falta de caixa: " + cValToChar(nVlrDif) + CRLF

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		nVlrDifAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_FALTCX")
		if nVlrDifAlc >= nVlrDif
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				nVlrDifAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_FALTCX")
				if nVlrDifAlc >= nVlrDif
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		cMsgLog += "Valor Alçada Dif. Caixa: " + cValToChar(nVlrDifAlc) + CRLF
		aadd(aLogAlcada, {"ALCDCX", USRRETNAME(cCodUsr), cMsgLog})
	endif

Return lRet

Static Function TelaLibAlcada(nVlrDif)
	
	Local lRet := .F.
	Local lEscape := .T.
	Local cMsgErr := "Diferença de caixa a lançar para a Empresa maior que permitido. Solicite liberação por alçada de um supervisor."
	Local aLogin

	While lEscape
		aLogin := U_TelaLogin(cMsgErr,"Limite Diferença Caixa", .T.)
		if empty(aLogin) //cancelou tela
			lEscape := .F.
		else
			lRet := LibAlcadaDif(aLogin[1], nVlrDif)
			if !lRet
				cMsgErr := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para liberar a diferença de caixa!"
			endif
			lEscape := !lRet
		endif
	enddo

Return lRet

//----------------------------------------------------------------------
//Validaçao de NFCe canceladas/pendentes cancelamento
//----------------------------------------------------------------------
Static Function VldCancSL1()

	Local lRet := .T.
	Local lTemDev := .F.
	Local nSpedExc := GetMv("MV_SPEDEXC") //tempo cancelamento
	Local cCondicao, cQry

	cCondicao := GetFilSL1("TOP",, .F.)
	cCondicao += " AND L1_SITUA IN ('X0','X1','X3') "

	cQry := "SELECT R_E_C_N_O_ RECSL1 FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 WHERE SL1.D_E_L_E_T_= ' ' AND "+cCondicao
	if Select("TSL1") > 0
		TSL1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "TSL1" // Cria uma nova area com o resultado do query

	SL1->(DbSetOrder(1))
	SL1->(DbGoTop())
	While TSL1->(!Eof())

		SL1->(DbGoto(TSL1->RECSL1))

		// Verifica quando foi realizada a emiss? da NFC-e e bloqueia caso for maior que o conte?o do par?etro MV_SPEDEXC
		nHoras := SubtHoras(SL1->L1_EMISNF,SubStr(SL1->L1_HORA,1,5), Date(), substr(Time(),1,2)+":"+substr(Time(),4,2) )
		If nHoras < nSpedExc //se está em prazo de cancelamento

			MsgInfo("Existe venda pendente de cancelamento, dentro do prazo de " + Alltrim(STR(nSpedExc)) +"h da SEFAZ! Aguarde o cancelamento ser autorizado para realizar o fechamento do caixa."+CRLF+CRLF+"Doc: "+SL1->L1_DOC+CRLF+"Serie: "+SL1->L1_SERIE,"Atenção")
			lRet := .F.
			EXIT

		else //se passou do prazo de cancelamento, deve ter devolução

			lTemDev := .T.
			SD1->(DbSetOrder(19)) //D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA
			If SD1->(DbSeek(xFilial("SD1") + SL1->L1_DOC + SL1->L1_SERIE ))
				If SD1->D1_TIPO <> 'D'
					lTemDev := .F.
				endif
			else
				lTemDev := .F.
			endif

			if !lTemDev
				MsgInfo("Venda com problema de cancelamento dentro do prazo de " + Alltrim(STR(nSpedExc)) +"h da SEFAZ! Deve ser feita devolução do NFCe para realizar o fechamento do caixa."+CRLF+CRLF+"Doc: "+SL1->L1_DOC+CRLF+"Serie: "+SL1->L1_SERIE,"Atenção")
				lRet := .F.
				EXIT
			endif

		EndIf

		TSL1->(DbSkip())
	endDo

Return lRet

//--------------------------------------------------------------------------------------
// Tela de Rateio Falta de Caixa
//--------------------------------------------------------------------------------------
Static Function RatFaltaCX(aRatFCX, lSobra)

	Local oPnlDet
	Local aCampos := {"LEG","A3_COD","A3_NOME","E5_VALOR"}
	Local aHeaderEx := {}
	Local aAlterFields := {"E5_VALOR"}
	Local aColsEx := {}
	Local lRet := .F.

	Default lSobra := .F.

	Private oTotFalta := 0
	Private nTotFalta := 0
	Private oGridDet
	Private oDlgDet
	Private aRet := {}
	Private bSvblDblClick

	DEFINE MSDIALOG oDlgDet TITLE "Rateio da "+iif(lSobra,"Sobra","Falta")+" de Caixa" STYLE DS_MODALFRAME FROM 000, 000  TO 300, 600 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,122,290,.F.,.T.,.T.)

	@ 005, 005 SAY "Vendedores no Caixa" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",284) SIZE 284, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos,.f.)
	aHeaderEx[4][6] := "U_TR028ATF(M->E5_VALOR, "+iif(lSobra,".T.",".F.")+")" //validaçao campo
	MsAguarde({|| AtGrdFCX(@aColsEx, lSobra) },"Aguarde...","Calculando rateios por vendedor...",.T.)
	oGridDet := MsNewGetDados():New( 015, 002, 100, 286, GD_UPDATE,"AllwaysTrue","AllwaysTrue","+Field1+Field2",aAlterFields,,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}
	bSvblDblClick := oGridDet:oBrowse:bLDblClick
	oGridDet:oBrowse:bLDblClick := {|| IIF(oGridDet:oBrowse:nColPos <> 1,GdRstDblClick(@oGridDet,@bSvblDblClick),  (oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="BR_AZUL", "BR_VERDE", "BR_AZUL") , U_TR028ATF(,lSobra), oGridDet:oBrowse:Refresh())   )}

	if lSobra
		@ 108, 010 SAY ("Sobra de Caixa:   R$ "+Alltrim(Transform(nGetVap,"@E 999,999,999.99"))) SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	else
		@ 108, 010 SAY ("Falta de Caixa:   R$ "+Alltrim(Transform(nGetVap*-(1),"@E 999,999,999.99"))) SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	endif

	@ 108, 180 SAY "Valor Rateado:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 105, 225 MSGET oTotFalta VAR nTotFalta When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	//Legendas
	@ 132, 010 BITMAP oLeg ResName "BR_AZUL" OF oDlgDet Size 10, 10 NoBorder When .F. PIXEL
	@ 132, 020 SAY "Mov. de Falta" OF oDlgDet Color CLR_BLACK PIXEL

	@ 132, 060 BITMAP oLeg ResName "BR_VERDE" OF oDlgDet Size 10, 10 NoBorder When .F. PIXEL
	@ 132, 070 SAY "Mov. de Sobra" OF oDlgDet Color CLR_BLACK PIXEL

	@ 132, 214 BUTTON oButton1 PROMPT "Cancelar" SIZE 037, 012 OF oDlgDet PIXEL Action (lRet := VldFaltaCX(2,lSobra), oDlgDet:End() )
	@ 132, 255 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 012 OF oDlgDet PIXEL Action iif(lRet := VldFaltaCX(1,lSobra),oDlgDet:End(),)

	ACTIVATE MSDIALOG oDlgDet CENTERED

	aRatFCX := aClone(aRet)

Return lRet

//--------------------------------------------------------------------------------------
// Validaçao tela de falta de caixa
//--------------------------------------------------------------------------------------
Static Function VldFaltaCX(nOpc, lSobra)

	Local lOk := .T.
	Local nTotal := 0
	Local lMvRatPosto := SuperGetMv("MV_XRATFCP",,.F.) //define se no rateio da diferença, poderá colocar parte para o posto.
	Local nQtdVend := Len(oGridDet:aCols)-1
	Local nDifMax := SuperGetMv("MV_XDIFMAX",.T.,0)
	Local nX

	If nOpc == 2
		aRet := {}
		Return .F.
	EndIf

	For nX := 1 to Len(oGridDet:aCols)
		if (lSobra .AND. oGridDet:aCols[nX][1] == "BR_VERDE") .OR. (!lSobra .AND. oGridDet:aCols[nX][1] == "BR_AZUL")
			nTotal += oGridDet:aCols[nX][4]
		else
			nTotal -= oGridDet:aCols[nX][4]
		endif

		if lMvRatPosto .AND. nQtdVend > 0
			if oGridDet:aCols[nX][2] == "POSTO"
				if oGridDet:aCols[nX][4] > (nDifMax * nQtdVend)
					MsgAlert("Diferença para o posto nao pode ultrapassar o maximo de R$ "+cValToChar(nDifMax)+" pra cada operador.","Atenção")
					lOk := .F.
					EXIT
				endif
			endif
		endif
	Next

	if lOk
		If Round(nTotal,2) == Round(nGetVap*iif(lSobra,1,-(1)),2)
			aRet := aClone(oGridDet:aCols)
		Else
			MsgInfo("O total do rateio deve ser igual ao total da falta de caixa (R$ "+Alltrim(Transform(nGetVap*iif(lSobra,1,-(1)),"@E 999,999,999.99"))+").","Atenção")
			lOk := .F.
		EndIf
	endif

Return lOk

//--------------------------------------------------------------------------------------
// Atualiza Grid Falta de Caixa
//--------------------------------------------------------------------------------------
Static Function AtGrdFCX(aDados, lSobra)

	Local nTotRat := 0
	Local nAjuste := 0
	Local aFieldFill := {}
	Local lMvRatPosto := SuperGetMv("MV_XRATFCP",,.F.) //define se no rateio da diferença, poderá colocar parte para o posto.
	Local nY, _aVend
	Default aDados := {}

	if SuperGetMv("MV_XRATAUT",,.F.) //rateia automatico
		_aVend := GetVendCaixa() //somente vendedores com movimentos
		if lSobra
			nTotFalta := nGetVap
		else
			nTotFalta := nGetVap*-(1)
		endif
		nTotRat := Round(nTotFalta/len(_aVend),2)
	Else
		//listo todos os vendedores
		_aVend := {}
		aAreaSA3 := SA3->(GetArea())
		SA3->(DbSetOrder(1))
		SA3->(DbSeek(xFilial("SA3")))
		While SA3->(!Eof()) .AND. SA3->A3_FILIAL == xFilial("SA3")
			aadd(_aVend, SA3->A3_COD )
			SA3->(DbSkip())
		Enddo
		RestArea(aAreaSA3)
	EndIf

	For nY := 1 to len(_aVend)
		aFieldFill := {}
		if !Empty(_aVend[nY])
			Aadd(aFieldFill, iif(lSobra,"BR_VERDE","BR_AZUL") ) //verde=sobra;azul=falta
			Aadd(aFieldFill, _aVend[nY] )
			Aadd(aFieldFill, Posicione("SA3",1,xFilial("SA3")+_aVend[nY],"A3_NOME") )
			Aadd(aFieldFill, nTotRat )
			Aadd(aFieldFill, .F.) //deleted

			aadd(aDados, aFieldFill)
		endif
	Next

	if lMvRatPosto
		aFieldFill := {}

		Aadd(aFieldFill, iif(lSobra,"BR_VERDE","BR_AZUL") ) //verde=sobra;azul=falta
		Aadd(aFieldFill, "POSTO" )
		Aadd(aFieldFill, "DIFERENCA PARA POSTO" )
		Aadd(aFieldFill, 0 )
		Aadd(aFieldFill, .F.) //deleted

		aadd(aDados, aFieldFill)
	endif

	If SuperGetMv("MV_XRATAUT",,.F.) //rateia automatico
		nAjuste := nTotFalta-(nTotRat*Len(_aVend))
		aDados[1][4]+=nAjuste
	EndIf

Return

//--------------------------------------------------------------------------------------
// Tela de manutençao da falta de caixa para vendedor
//--------------------------------------------------------------------------------------
//Static Function AtuTotFalta(nValor)
User Function TR028ATF(nValor,lSobra)

	Local nX

	nTotFalta := 0
	For nX:=1 to Len(oGridDet:aCols)
		if nX == oGridDet:nAT .AND. nValor<>Nil
			if (lSobra .AND. oGridDet:aCols[nX][1] == "BR_VERDE" ) .OR. (!lSobra .AND. oGridDet:aCols[nX][1] == "BR_AZUL")
		 		nTotFalta += nValor
			else
				nTotFalta -= nValor
			endif
		else
			if (lSobra .AND. oGridDet:aCols[nX][1] == "BR_VERDE" ) .OR. (!lSobra .AND. oGridDet:aCols[nX][1] == "BR_AZUL")
				nTotFalta += oGridDet:aCols[nX][4]
			else
				nTotFalta -= oGridDet:aCols[nX][4]
			endif
		endif
	Next

	oGridDet:oBrowse:Refresh()
	oTotFalta:Refresh()

Return .T.

//--------------------------------------------------------------------------------------
// Grava movimento de diferença de caixa
// nOpcX : 3=Mov. a Pagar ; 4=Mov. a Receber
//--------------------------------------------------------------------------------------
Static Function GravaDifCaixa(nValor, nOpcX, cNaturez,aRatFCX)

	Local aFINA100
	Local lRet := .T.
	Local cHist := ""
	Local nX, cQry
	Local nTotQry := 0
	Local aAreaSLW := SLW->(GetArea())
	Local cNatPosto := SuperGetMv("MV_XNATFAL",,"")
	Local cCenCusto	:= SuperGetMv("MV_XCCPDV",,"")
	Default cNaturez := SuperGetMv("MV_XNATFAL",,"")
	Default aRatFCX := {}
	Private lMsErroAuto := .F.

	If len(aRatFCX) > 0
		BeginTran()

		For nX := 1 to len(aRatFCX)
			RestArea(aAreaSLW) //forço manter posicionado na SLW, pois algum PE no processo pode desposicionar
			
			If aRatFCX[nX][4] > 0
				nOpcX := iif(aRatFCX[nX][1] == "BR_VERDE", 4, 3)
				cHist := "Dif Cx: "+DTOC(SLW->LW_DTABERT)+" - "+ aRatFCX[nX][2]
				aFINA100 := {	{"E5_DATA"		,SLW->LW_DTABERT					,Nil},;
								{"E5_MOEDA"		,"M1"								,Nil},;
								{"E5_VALOR"		,aRatFCX[nX][4]						,Nil},;
								{"E5_BANCO"		,SLW->LW_OPERADO					,Nil},;
								{"E5_AGENCIA"	,SA6->A6_AGENCIA					,Nil},;
								{"E5_CONTA"		,SA6->A6_NUMCON						,Nil},;
								{"E5_HISTOR"	,cHist								,Nil},;
								{"E5_NATUREZ"	,iif(aRatFCX[nX][2]=="POSTO",cNatPosto,cNaturez) ,Nil},;
								{"E5_NUMMOV"	,SLW->LW_NUMMOV						,Nil}}

				if SE5->(FieldPos("E5_XPDV")) > 0
					aadd(aFINA100,{"E5_XPDV"		,SLW->LW_PDV					,Nil} )
					aadd(aFINA100,{"E5_XESTAC"		,SLW->LW_ESTACAO				,Nil} )
					aadd(aFINA100,{"E5_XHORA"		,SLW->LW_HRABERT				,Nil} )
				endif

				if SE5->(FieldPos("E5_XVEND")) > 0
					aadd(aFINA100,{"E5_XVEND"		,aRatFCX[nX][2]				,Nil} )
				endif

				if !empty(cCenCusto)
					aadd(aFINA100, {"E5_CCUSTO"		,cCenCusto						,Nil})
					if nOpcX == 3
						aadd(aFINA100, {"E5_CCD"		,cCenCusto						,Nil})
					else
						aadd(aFINA100, {"E5_CCC"		,cCenCusto						,Nil})
					endif
				Endif

				MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100, nOpcX)

				If lMsErroAuto
					lRet := .F.
					MostraErro()
					DisarmTransaction()
					EndTran()
					Return lRet
				endif
			EndIf
		Next

		EndTran()
	Else
		aFINA100 := {	{"E5_DATA"		,SLW->LW_DTABERT					,Nil},;
						{"E5_MOEDA"		,"M1"								,Nil},;
						{"E5_VALOR"		,nValor								,Nil},;
						{"E5_BANCO"		,SLW->LW_OPERADO					,Nil},;
						{"E5_AGENCIA"	,SA6->A6_AGENCIA					,Nil},;
						{"E5_CONTA"		,SA6->A6_NUMCON						,Nil},;
						{"E5_HISTOR"	,"Dif Cx: "+DTOC(SLW->LW_DTABERT)	,Nil},;
						{"E5_NATUREZ"	,cNaturez						  	,Nil},;
						{"E5_NUMMOV"	,SLW->LW_NUMMOV						,Nil}}

		if SE5->(FieldPos("E5_XPDV")) > 0
			aadd(aFINA100,{"E5_XPDV"		,SLW->LW_PDV					,Nil} )
			aadd(aFINA100,{"E5_XESTAC"		,SLW->LW_ESTACAO				,Nil} )
			aadd(aFINA100,{"E5_XHORA"		,SLW->LW_HRABERT				,Nil} )
		endif

		if nOpcX == 3
			aadd(aFINA100, {"E5_CCD"		,cCenCusto						,Nil})
		else
			aadd(aFINA100, {"E5_CCC"		,cCenCusto						,Nil})
		endif

		MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100, nOpcX)

		If lMsErroAuto
			lRet := .F.
			MostraErro()
		endif
	EndIf

	//Confirmo se realmente incluiu. tem vez que nao inclui mesmo o execauto retornando .t.
	if lRet
		cQry:=" SELECT E5_RECPAG, SUM(E5_VALOR) AS VLRTOTAL FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5"
		cQry+=" WHERE D_E_L_E_T_<> '*' AND E5_DATA = '"+Dtos(SLW->LW_DTABERT)+"'"
		if SE5->(FieldPos("E5_XPDV")) > 0
			cQry+=" AND E5_FILORIG = '"+SLW->LW_FILIAL+"' AND E5_NUMMOV='"+SLW->LW_NUMMOV+"'"
			cQry+=" AND E5_XESTAC = '"+SLW->LW_ESTACAO+"' AND E5_XPDV='"+SLW->LW_PDV+"'"
		Else
			cQry+=" AND E5_FILORIG = '"+SLW->LW_FILIAL+"' AND E5_NUMMOV='"+SLW->LW_NUMMOV+"'"
		EndIf
		cQry+=" AND E5_MOEDA = 'M1'"
		cQry+=" AND E5_NUMERO = ' '" // movimento de diferença de caixa não tem DOC
		cQry+=" AND E5_BANCO = '"+SLW->LW_OPERADO+"'" //campo criado somente para possibilitar o estorno
		cQry+=" AND E5_SITUACA = ' '"
		cQry+=" GROUP BY E5_RECPAG "
		cQry := ChangeQuery(cQry)

		If Select("DataSe5")>0
			DataSe5->(DbCloseArea())
		Endif
		Tcquery cQry New alias "DataSe5"

		While DataSe5->(!Eof()) 
			if DataSe5->E5_RECPAG == "R"
				nTotQry += DataSe5->VLRTOTAL
			elseif DataSe5->E5_RECPAG == "P"
				nTotQry -= DataSe5->VLRTOTAL
			endif
			DataSe5->(DbSkip())
		enddo
		if Abs(nTotQry) <> nValor
			lRet := .F.
		endif
		DataSe5->(DbCloseArea())
	endif
	
	RestArea(aAreaSLW)

Return lRet

//--------------------------------------------------------------------------------------
// Calcula Saldo Final do Caixa (Troco final apurado pelo sistema)
//--------------------------------------------------------------------------------------
Static Function CalcSaldoFinal()

	Local nSaldo := 0
	Local nSldPE := 0
	Local nPosForma  := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_FORMPG"})
	Local nPosVlrApu := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRAPU"})
	Local aDados
	Local nX := 0
	Local nPosAux := 0
	Local cCondicao, bCondicao

	nPosAux := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "SU" })
	nSaldo += oGridForma:aCols[nPosAux][nPosVlrApu] //+ Suprimento

	nPosAux := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "SG" })
	nSaldo -= oGridForma:aCols[nPosAux][nPosVlrApu] //- Sangria

	//+ Apurando vendas dinheiro
	if lSrvPDV
		aDados := BuscaSL4("PDV", 2, {"L4_VALOR"},,"Alltrim(SL4->L4_FORMA) == '"+SIMBDIN+"'")
	else
		aDados := BuscaSE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = '"+SIMBDIN+"'",,,.T.,.F.)
	endif
	For nX:=1 To Len(aDados)
		nSaldo += aDados[nX][1]
	Next

	if lMvPosto
		if SuperGetMV("TP_ACTCMP",,.F.)
			//- Saída Dinheiro Compensação Valores
			if lSrvPDV
				cCondicao := GetFilUC0("PDV", .T.)
				bCondicao 	:= "{|| " + cCondicao + " }"
				UC0->(DbClearFilter())
				UC0->(DbSetFilter(&bCondicao,cCondicao))
				UC0->(DbGoTop())
				While UC0->(!Eof())
					nSaldo -= UC0->UC0_VLDINH
					UC0->(DbSkip())
				enddo
				UC0->(DbClearFilter())
			else
				aDados := BuscaSE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = 'NCC'",,,.F.,.T.)
				For nX:=1 To Len(aDados)
					nSaldo -= aDados[nX][1]
				Next
			endif
		endif

		//+ Depositos no PDV
		if SuperGetMV("TP_ACTDP",,.F.)
			nPosAux := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "DP" })
			nSaldo += oGridForma:aCols[nPosAux][nPosVlrApu]
		endif

		if SuperGetMV("TP_ACTVLS",,.F.)
			//+ Entrada dinheiro Vales Serviços Pré-Pago
			nSaldo += U_T028TVLS(4,,,,.T.)
		endif

		if SuperGetMV("TP_ACTSQ",,.F.)
			//- Saques
			nPosAux := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "SQ" })
			nSaldo -= oGridForma:aCols[nPosAux][nPosVlrApu]

			//- Vale Motorista
			nPosAux := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "VLM" })
			nSaldo -= oGridForma:aCols[nPosAux][nPosVlrApu]

			if SuperGetMV("TP_ACTCHT",,.F.)
				//+ Cheque troco de Saques e VLM (pq estou somando SQ e VLM, devo tirar os que foram em cheque)
				nSaldo += U_T028TCHT(4,,,.F.,.F.,.T.)
			endif
		endif
	endif

	//- Apurando Trocos de Venda
	nSaldo -= U_T028TTV(4)

	//Ponto de entrada para manipular saldo sistema
	if ExistBlock("TRA028SF")
		nSldPE := ExecBlock("TRA028SF",.F.,.F., nSaldo)
		if valtype(nSldPE) == "N"
			nSaldo := nSldPE
		endif
	endif

Return nSaldo

//--------------------------------------------------------------------------------------
// Rotina de Conferencia de Documentos
//--------------------------------------------------------------------------------------
Static Function ConfDocs(lHabBotoes, lAuto)

	//dimensionamento de tela e componentes
	Local lRet		:= .T.
	Local aSize 	:= MsAdvSize() // Retorna a área útil das janelas Protheus
	Local aInfo 	:= {aSize[1], aSize[2], aSize[3], aSize[4], 2, 2}
	Local aObjects 	:= {{100,95,.T.,.T.},{100,5,.T.,.T.}}
	Local aPObj 	:= MsObjSize( aInfo, aObjects, .T. )
	Local aHeaderEx := {}
	Local aColsEx 	:= {}
	Local oFilial, oCaixa, oPDVEst, oDataHora

	Default lHabBotoes := .T.
	Default lAuto := .F.

	Private oDlgCDoc
	Private oTFolder
	Private aTFolder := {}

	Private oBrrSL1Pdv
	Private oBrrSL1Top
	Private oBrrSL1Fin
	Private oGridSL1
	Private cObsSL1 := ""
	Private oObsSL1
	Private nQtdSL1 := 0
	Private oQtdSL1

	Private oGridSE5
	Private cObsSE5 := ""
	Private oObsSE5
	Private nQtdSE5 := 0
	Private oQtdSE5

	//aHeader dos grids
	Private aCpoGdSL1	:= {"LEG1-PDV","LEG2-RET.","LEG3-FIN.","L1_DOC","L1_SERIE","L1_CLIENTE","L1_LOJA","A1_NOME","L1_VLRTOT","L1_VLRLIQ","L1_EMISNF","L1_TROCO1","L1_KEYNFCE","L1_OPERADO","L1_PDV","L1_ESTACAO","L1_NUMMOV","L1_NUM","L1_PLACA","L1_STORC","L1_STATUS","L1_VEND","A3_NOME"}
	Private aCpoGdSE5	:= {"LEG1-PDV","LEG2-RET.","LEG3-FIN.","E5_FILIAL","E5_DATA","E5_VALOR","E5_PREFIXO","E5_NUMERO","E5_SEQ","E5_NATUREZ","E5_HISTOR","E5_OPERAD","A3_NOME"}

	//campos para busca dos dados
	Private aDadosTop := {}
	Private aDadosFin := {}
	Private aPendencia := {}
	Private nPendAtual := 0
	Private aCpoSL1 := {"L1_DOC","L1_SERIE","L1_CLIENTE","L1_LOJA","L1_VLRTOT","L1_VLRLIQ","L1_SITUA","L1_TROCO1","L1_EMISNF","L1_KEYNFCE","L1_OPERADO","L1_PDV","L1_ESTACAO","L1_NUMMOV","L1_NUM","L1_STORC","L1_STATUS","L1_RETSFZ","L1_PLACA","L1_VEND","L1_CREDITO"}
	Private aCpoSL2 := {"L2_PRODUTO","L2_QUANT","L2_VRUNIT","L2_PRCTAB","L2_DESCPRO","L2_VALDESC","L2_VLRITEM","L2_DESPESA"}
	Private aCpoSL4 := {"L4_FORMA","L4_VALOR","L4_DATA"}
	Private aCpoSE5	:= {"E5_FILIAL","E5_DATA","E5_VALOR","E5_PREFIXO","E5_NUMERO","E5_SEQ","E5_NATUREZ","E5_HISTOR","D_E_L_E_T_","E5_OPERAD"}
	Private nPosSL2, nPosSL4

	if lMvPosto
		if SuperGetMV("TP_ACTCHT",,.F.)
			aadd(aCpoSL1,"L1_XTROCCH")
		endif
		if SuperGetMV("TP_ACTVLH",,.F.)
			aadd(aCpoSL1,"L1_XTROCVL")
		endif
		aadd(aCpoSL2,"L2_MIDCOD")

		Private oBrrUC0Pdv
		Private oBrrUC0Top
		Private oBrrUC0Fin
		Private oGridUC0
		Private cObsUC0 := ""
		Private oObsUC0
		Private nQtdUC0 := 0
		Private oQtdUC0
		Private aCpoGdUC0	:= {"LEG1-PDV","LEG2-RET.","LEG3-PEND.","UC0_NUM","UC0_DATA","UC0_CLIENT","UC0_LOJA","A1_NOME","UC0_PLACA","UC0_VLDINH","UC0_VLVALE","UC0_VLCHTR","UC0_VLTOT","UC0_VEND","A3_NOME"}
		Private aCpoUC0	:= {"UC0_NUM","UC0_DATA","UC0_CLIENT","UC0_LOJA","UC0_PLACA","UC0_VLDINH","UC0_VLVALE","UC0_VLCHTR","UC0_VLTOT","UC0_ESTORN","UC0_ESTACA","UC0_VEND"}
		Private aCpoUC1	:= {"UC1_FORMA","UC1_VALOR","UC1_VENCTO"}
		if UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
			aadd(aCpoGdUC0, "UC0_DOC")
			aadd(aCpoGdUC0, "UC0_SERIE")
			aadd(aCpoUC0, "UC0_DOC")
			aadd(aCpoUC0, "UC0_SERIE")
		endif
		Private nPosUC1 := len(aCpoUC0)+1

		Private oBrrVLS
		Private oGridVLS
		Private cObsVLS := ""
		Private oObsVLS
		Private nQtdVLS := 0
		Private oQtdVLS
		Private aCpoGdUIC	:= {"LEG1-PDV","LEG2-RET.","LEG3-PEND.","UIC_AMB","UIC_CODIGO","UIC_TIPO","UIC_PRODUT","UIC_DESCRI","UIC_PRCPRO","UIC_CLIENT","UIC_LOJAC","UIC_NOMEC","UIC_FORNEC","UIC_LOJAF","UIC_NOMEF","UIC_STATUS","UIC_VEND","A3_NOME"}
		Private aCpoUIC	:= {"UIC_AMB","UIC_CODIGO","UIC_TIPO","UIC_PRODUT","UIC_DESCRI","UIC_PRCPRO","UIC_CLIENT","UIC_LOJAC","UIC_NOMEC","UIC_FORNEC","UIC_LOJAF","UIC_NOMEF","UIC_STATUS","UIC_VEND"}

		Private oBrrU57
		Private oGridU57
		Private cObsU57 := ""
		Private oObsU57
		Private nQtdU57 := 0
		Private oQtdU57
		Private aCpoGdU57	:= {"LEG1-PDV","LEG2-RET.","LEG3-PEND.","U57_FILIAL","U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALOR","U57_VALSAQ","U56_CODCLI","U56_LOJA","U56_NOME","U57_MOTORI","U57_PLACA","U56_REQUIS","U57_VEND","A3_NOME"}
		Private aCpoU57 := {"U57_FILIAL","U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALOR","U57_VALSAQ","U56_CODCLI","U56_LOJA","U56_NOME","U57_MOTORI","U57_PLACA","U56_REQUIS","U57_XGERAF","U57_VEND"}

		Private cMvNFRecu := SuperGetMv("MV_XNFRECU",.F.,"XPROTH/XCOPIA/XSEFAZ/XXML") //Tipos de recuperação de NF
	endif

	nPosSL2 := len(aCpoSL1)+1
	nPosSL4 := len(aCpoSL1)+2

	//adiciono as ABAS
	aadd(aTFolder, "Vendas")
	aadd(aTFolder, "Suprimentos e Sangrias")
	if lMvPosto
		aadd(aTFolder, "Compensações")
		aadd(aTFolder, "Vale Serviço")
		aadd(aTFolder, "Saques/Depósitos")
	endif

	if lAuto
		DEFINE MSDIALOG oDlgCDoc TITLE "Conferência de Documentos" FROM -100,-100 TO 100,100 PIXEL
	else
		aPObj[1,1] -= 30
		aPObj[1,3] -= 15
		aPObj[2,1] -= 10
		DEFINE MSDIALOG oDlgCDoc TITLE "Conferência de Documentos" FROM aSize[7],aSize[1] TO aSize[6],aSize[5] PIXEL
	endif
	//dados do caixa
	oScrCab := TScrollBox():New(oDlgCDoc,aPObj[1,1],aPObj[1,2],20,aPObj[1,4],.F.,.T.,.T.)

	@ 005, 005 SAY "Filial:" SIZE 50, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 003, 025 MSGET oFilial  VAR cGetFil SIZE 040, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL When .F.

	@ 005, 080 SAY "Caixa:" SIZE 50, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 003, 100 MSGET oCaixa VAR (SLW->LW_OPERADO + " - " + Posicione("SA6",1,xFilial("SA6")+SLW->LW_OPERADO,"A6_NOME")) SIZE 110, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL  When .F.

	@ 005, 220 SAY "PDV/Estação/Movim.:" SIZE 55, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 003, 275 MSGET oPDVEst VAR (Alltrim(SLW->LW_PDV) + " / " + SLW->LW_ESTACAO + " / " + SLW->LW_NUMMOV ) SIZE 060, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL  When .F.

	@ 005, 345 SAY "Data/Hora:" SIZE 035, 007 OF oScrCab COLORS 0, 16777215 PIXEL
	@ 003, 375 MSGET oDataHora  VAR (DTOC(SLW->LW_DTABERT) + " " + SLW->LW_HRABERT + " - " + DTOC(SLW->LW_DTFECHA) + " " + SLW->LW_HRFECHA) SIZE 110, 010 OF oScrCab HASBUTTON COLORS 0, 16777215 PIXEL  When .F.

	oTFolder := TFolder():New( aPObj[1,1]+20, aPObj[1,2], aTFolder,,oDlgCDoc,,,,.T.,,aPObj[1,4],aPObj[2,1]-20 )

	//-- ABA VENDAS ------------------------------------------------
	aHeaderEx := MontaHeader(aCpoGdSL1, .F.)
	aHeaderEx[aScan(aCpoGdSL1,"L1_TROCO1")][3] := PesqPict("SL1","L1_VLRTOT")
	aColsEx := {}
	aadd(aColsEx, MontaDados("SL1",aCpoGdSL1, .T.,,.F.))
	oGridSL1 := MsNewGetDados():New( aPObj[1,1], aPObj[1,2], aPObj[1,3]-135, aPObj[1,4]-(2*aPObj[1,2]),,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oTFolder:aDialogs[1], aHeaderEx, aColsEx)
	oGridSL1:oBrowse:bchange := {|| CarrDetVend("oGridSL1:oBrowse:bchange") }
	oGridSL1:oBrowse:bLDblClick := {|| DetVenda(lHabBotoes) }
	oGridSL1:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridSL1, @nCol), )}
	if lMvPosto
		bSavClrBack := oGridSL1:oBrowse:aColumns[1]:BCLRBACK
		oGridSL1:oBrowse:SetBlkBackColor({|| iif(Alltrim(oGridSL1:aCols[oGridSL1:nAt][aScan(aCpoGdSL1,"L1_STATUS")]) $ cMvNFRecu,RGB(240,210,130), Eval(bSavClrBack) ) })
	endif

	@ aPObj[1,3]-130, aPObj[1,2] GROUP oGroup4 TO aPObj[1,3]-52, aPObj[1,4]-(2*aPObj[1,2]) PROMPT "Análise pendências da Venda Selecionada" OF oTFolder:aDialogs[1] COLOR 0, 16777215 PIXEL

	@ aPObj[1,3]-110, 10 SAY "Base PDV" SIZE 50, 007 OF oTFolder:aDialogs[1] COLORS 0, 16777215 PIXEL
	oBrrSL1Pdv := BTotaisVenda():New(oTFolder:aDialogs[1], aPObj[1,3]-120, 80, .T.)

	@ aPObj[1,3]-90, 10 SAY "Base Retaguarda" SIZE 50, 007 OF oTFolder:aDialogs[1] COLORS 0, 16777215 PIXEL
	oBrrSL1Top := BTotaisVenda():New(oTFolder:aDialogs[1], aPObj[1,3]-100, 80, .F.)

	@ aPObj[1,3]-70, 10 SAY "Financeiro" SIZE 50, 007 OF oTFolder:aDialogs[1] COLORS 0, 16777215 PIXEL
	oBrrSL1Fin := BTotaisVenda():New(oTFolder:aDialogs[1], aPObj[1,3]-80, 80, .F., .F.)

	@ aPObj[1,3]-120, iif(lMvPosto,500,360) SAY "Detalhe Pendência:" SIZE 80, 007 OF oTFolder:aDialogs[1] COLORS 0, 16777215 PIXEL
	@ aPObj[1,3]-112, iif(lMvPosto,500,360) GET oObsSL1 VAR cObsSL1 OF oTFolder:aDialogs[1] MULTILINE SIZE aPObj[1,4]-iif(lMvPosto,510,370), 52 COLORS 0, 16777215 PIXEL READONLY

	TButton():New(  aPObj[1,3]-47, aPObj[1,2], "Detalhar Venda", oTFolder:aDialogs[1], {|| DetVenda(lHabBotoes) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	if lHabBotoes
		TButton():New(  aPObj[1,3]-47, aPObj[1,2]+65, "Buscar Venda", oTFolder:aDialogs[1], {|| BuscarVenda() }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New(  aPObj[1,3]-47, aPObj[1,2]+120, "Corrigir", oTFolder:aDialogs[1], {|| MsAguarde( {|| CorrigeVenda() }, "Aguarde", "Processando Ajuste...", .F. ) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	endif
	
	if lMvPosto
		@ aPObj[1,3]-46, aPObj[1,4]-150 SAY oSayVendR PROMPT "Venda Recuperada" SIZE 060, 010 OF oTFolder:aDialogs[1] COLORS 0, 16777215 PIXEL CENTERED
		oSayVendR:SETCSS( "TSay{ background-color: #f0d282; border-radius: 3px; border: 1px solid #c6ac66;}" )
	endif

	@ aPObj[1,3]-44, aPObj[1,4]-70 SAY oQtdSL1 PROMPT "Qtd.Vendas:  " + cValtochar(nQtdSL1) SIZE 100, 007 OF oTFolder:aDialogs[1] COLORS 0, 16777215 PIXEL

	//-- ABA Suprimentos e Sangrias ---------------------------------------
	aHeaderEx := MontaHeader(aCpoGdSE5)
	aHeaderEx[aScan(aCpoGdSE5,"E5_FILIAL")][1] := "TIPO DOC."
	aHeaderEx[aScan(aCpoGdSE5,"E5_FILIAL")][4] := 15
	aColsEx := {}
	aadd(aColsEx, MontaDados("SE5",aCpoGdSE5, .T.))
	oGridSE5 := MsNewGetDados():New( aPObj[1,1], aPObj[1,2], aPObj[1,3]-100, aPObj[1,4]-(2*aPObj[1,2]),,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oTFolder:aDialogs[2], aHeaderEx, aColsEx)
	oGridSE5:oBrowse:bchange := {|| CarrDetSE5() }
	oGridSE5:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridSE5, @nCol), )}

	@ aPObj[1,3]-95, aPObj[1,2] GROUP oGroup4 TO aPObj[1,3]-52, aPObj[1,4]-(2*aPObj[1,2]) PROMPT "Análise pendências do Documento selecionado" OF oTFolder:aDialogs[2] COLOR 0, 16777215 PIXEL

	@ aPObj[1,3]-85, 010 SAY "Detalhe Pendência:" SIZE 80, 007 OF oTFolder:aDialogs[2] COLORS 0, 16777215 PIXEL
	@ aPObj[1,3]-85, 65 GET oObsSE5 VAR cObsSE5 OF oTFolder:aDialogs[2] MULTILINE SIZE 300, 27 COLORS 0, 16777215 PIXEL READONLY

	if lHabBotoes
		TButton():New(  aPObj[1,3]-47, aPObj[1,2], "Incluir", oTFolder:aDialogs[2], {|| MntSE5Troco(3) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New(  aPObj[1,3]-47, aPObj[1,2]+50, "Excluir", oTFolder:aDialogs[2], {|| MntSE5Troco(5,oGridSE5:aCols[oGridSE5:nAt][Len(oGridSE5:aHeader)]) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New(  aPObj[1,3]-47, aPObj[1,2]+100, "Manutenção", oTFolder:aDialogs[2], {|| MntSE5Troco(4,oGridSE5:aCols[oGridSE5:nAt][Len(oGridSE5:aHeader)]) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New(  aPObj[1,3]-47, aPObj[1,2]+150, "Corrigir", oTFolder:aDialogs[2], {|| CorrigeSupSang() }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		if SE5->(FieldPos("E5_XPDV")) > 0
			TButton():New(  aPObj[1,3]-47, aPObj[1,2]+200, "Busca Movimento", oTFolder:aDialogs[2], {|| BuscarSupSang() }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		endif
	endif

	@ aPObj[1,3]-44, aPObj[1,4]-80 SAY oQtdSE5 PROMPT "Qtd.Documentos:  " + cValtochar(nQtdSE5) SIZE 100, 007 OF oTFolder:aDialogs[2] COLORS 0, 16777215 PIXEL

	if lMvPosto

		//-- ABA COMPENSAÇÕES ---------------------------------------
		if SuperGetMV("TP_ACTCMP",,.F.)
			aHeaderEx := MontaHeader(aCpoGdUC0, .F.)
			aColsEx := {}
			aadd(aColsEx, MontaDados("UC0",aCpoGdUC0, .T.,,.F.))
			oGridUC0 := MsNewGetDados():New( aPObj[1,1], aPObj[1,2], aPObj[1,3]-135, aPObj[1,4]-(2*aPObj[1,2]),,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oTFolder:aDialogs[3], aHeaderEx, aColsEx)
			oGridUC0:oBrowse:bchange := {|| CarrDetComp() }
			oGridUC0:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridUC0, @nCol), )}

			@ aPObj[1,3]-130, aPObj[1,2] GROUP oGroup4 TO aPObj[1,3]-52, aPObj[1,4]-(2*aPObj[1,2]) PROMPT "Análise pendências da Compensaçao selecionada" OF oTFolder:aDialogs[3] COLOR 0, 16777215 PIXEL

			@ aPObj[1,3]-110, 10 SAY "Base PDV" SIZE 50, 007 OF oTFolder:aDialogs[3] COLORS 0, 16777215 PIXEL
			oBrrUC0Pdv := BTotaisComp():New(oTFolder:aDialogs[3], aPObj[1,3]-120, 80, .T.)

			@ aPObj[1,3]-90, 10 SAY "Base Retaguarda" SIZE 50, 007 OF oTFolder:aDialogs[3] COLORS 0, 16777215 PIXEL
			oBrrUC0Top := BTotaisComp():New(oTFolder:aDialogs[3], aPObj[1,3]-100, 80, .F.)

			@ aPObj[1,3]-70, 10 SAY "Financeiro" SIZE 50, 007 OF oTFolder:aDialogs[3] COLORS 0, 16777215 PIXEL
			oBrrUC0Fin := BTotaisComp():New(oTFolder:aDialogs[3], aPObj[1,3]-80, 80, .F.)

			@ aPObj[1,3]-120, 430 SAY "Detalhe Pendência:" SIZE 80, 007 OF oTFolder:aDialogs[3] COLORS 0, 16777215 PIXEL
			@ aPObj[1,3]-112, 430 GET oObsUC0 VAR cObsUC0 OF oTFolder:aDialogs[3] MULTILINE SIZE aPObj[1,4]-440, 52 COLORS 0, 16777215 PIXEL READONLY

			TButton():New(  aPObj[1,3]-47, aPObj[1,2], "Visualizar", oTFolder:aDialogs[3], {|| MntCompensacao(2) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			if lHabBotoes
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+50, "Buscar Comp.", oTFolder:aDialogs[3], {|| BuscarComp() }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+100, "Incluir", oTFolder:aDialogs[3], {|| MntCompensacao(3) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+150, "Estornar", oTFolder:aDialogs[3], {|| MntCompensacao(5) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+200, "Reprocessar", oTFolder:aDialogs[3], {|| MntCompensacao(6) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+250, "Trocar Cliente", oTFolder:aDialogs[3], {|| MntCompensacao(7) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+300, "Trocar Entrada", oTFolder:aDialogs[3], {|| MntCompensacao(8) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+350, "Troca Saída", oTFolder:aDialogs[3], {|| MntCompensacao(9) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			endif

			@ aPObj[1,3]-44, aPObj[1,4]-80 SAY oQtdUC0 PROMPT "Qtd.Compensações:  " + cValtochar(nQtdUC0) SIZE 100, 007 OF oTFolder:aDialogs[3] COLORS 0, 16777215 PIXEL

		else
			@ aPObj[1,1]+10, aPObj[1,2]+10 SAY "Rotina de Compensações não Habilitada! Parametro TP_ACTCMP." SIZE 200, 007 OF oTFolder:aDialogs[3] COLORS 0, 16777215 PIXEL
		endif

		//-- ABA VALE SERVIÇO ---------------------------------------
		if SuperGetMV("TP_ACTVLS",,.F.)
			aHeaderEx := MontaHeader(aCpoGdUIC, .F.)
			aColsEx := {}
			aadd(aColsEx, MontaDados("UIC",aCpoGdUIC, .T.,,.F.))
			oGridVLS := MsNewGetDados():New( aPObj[1,1], aPObj[1,2], aPObj[1,3]-100, aPObj[1,4]-(2*aPObj[1,2]),,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oTFolder:aDialogs[4], aHeaderEx, aColsEx)
			oGridVLS:oBrowse:bchange := {|| CarrDetVlServ() }
			oGridVLS:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridVLS, @nCol), )}

			@ aPObj[1,3]-95, aPObj[1,2] GROUP oGroup4 TO aPObj[1,3]-52, aPObj[1,4]-(2*aPObj[1,2]) PROMPT "Análise pendências da Vale Serviço selecionado" OF oTFolder:aDialogs[4] COLOR 0, 16777215 PIXEL

			oBrrVLS := BTotaisVLS():New(oTFolder:aDialogs[4], aPObj[1,3]-80, 010)

			@ aPObj[1,3]-90, 360 SAY "Detalhe Pendência:" SIZE 80, 007 OF oTFolder:aDialogs[4] COLORS 0, 16777215 PIXEL
			@ aPObj[1,3]-82, 360 GET oObsVLS VAR cObsVLS OF oTFolder:aDialogs[4] MULTILINE SIZE aPObj[1,4]-370, 27 COLORS 0, 16777215 PIXEL READONLY

			TButton():New(  aPObj[1,3]-47, aPObj[1,2], "Visualizar", oTFolder:aDialogs[4], {|| MntValeSrv(2) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			if lHabBotoes
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+50, "Buscar Vale", oTFolder:aDialogs[4], {|| BuscarVLS() }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+100, "Incluir", oTFolder:aDialogs[4], {|| MntValeSrv(3) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+150, "Estornar", oTFolder:aDialogs[4], {|| MntValeSrv(5) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+200, "Reprocessar", oTFolder:aDialogs[4], {|| MntValeSrv(6) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			endif

			@ aPObj[1,3]-44, aPObj[1,4]-80 SAY oQtdVLS PROMPT "Qtd.Vales Serviço:  " + cValtochar(nQtdVLS) SIZE 100, 007 OF oTFolder:aDialogs[4] COLORS 0, 16777215 PIXEL
		else
			@ aPObj[1,1]+10, aPObj[1,2]+10 SAY "Rotina de Vales Serviço não Habilitada! Parametro TP_ACTVLS." SIZE 200, 007 OF oTFolder:aDialogs[4] COLORS 0, 16777215 PIXEL
		endif

		//-- ABA SAQUES/DEPOSITOS ---------------------------------------
		if SuperGetMV("TP_ACTSQ",,.F.) .OR. SuperGetMV("TP_ACTDP",,.F.)
			aHeaderEx := MontaHeader(aCpoGdU57, .F.)
			aHeaderEx[aScan(aCpoGdU57,"U57_FILIAL")][1] := "Tipo Doc."
			aHeaderEx[aScan(aCpoGdU57,"U57_FILIAL")][4] := 15
			aColsEx := {}
			aadd(aColsEx, MontaDados("U57",aCpoGdU57, .T.,,.F.))
			oGridU57 := MsNewGetDados():New( aPObj[1,1], aPObj[1,2], aPObj[1,3]-100, aPObj[1,4]-(2*aPObj[1,2]),,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oTFolder:aDialogs[5], aHeaderEx, aColsEx)
			oGridU57:oBrowse:bchange := {|| CarrDetU57() }
			oGridU57:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridU57, @nCol), )}

			@ aPObj[1,3]-95, aPObj[1,2] GROUP oGroup4 TO aPObj[1,3]-52, aPObj[1,4]-(2*aPObj[1,2]) PROMPT "Análise pendências do Documento selecionado" OF oTFolder:aDialogs[5] COLOR 0, 16777215 PIXEL

			oBrrU57 := BTotaisU57():New(oTFolder:aDialogs[5], aPObj[1,3]-80, 010)

			@ aPObj[1,3]-90, 430 SAY "Detalhe Pendência:" SIZE 80, 007 OF oTFolder:aDialogs[5] COLORS 0, 16777215 PIXEL
			@ aPObj[1,3]-82, 430 GET oObsU57 VAR cObsU57 OF oTFolder:aDialogs[5] MULTILINE SIZE aPObj[1,4]-440, 27 COLORS 0, 16777215 PIXEL READONLY

			TButton():New(  aPObj[1,3]-47, aPObj[1,2], "Visualizar", oTFolder:aDialogs[5], {|| MntRequis(2) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			if lHabBotoes
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+50, "Busca Doc.", oTFolder:aDialogs[5], {|| BuscarU57() }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+100, "Incluir", oTFolder:aDialogs[5], {|| MntRequis(3) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+150, "Excluir", oTFolder:aDialogs[5], {|| MntRequis(5) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+200, "Altera Saida", oTFolder:aDialogs[5], {|| MntRequis(7) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
				TButton():New(  aPObj[1,3]-47, aPObj[1,2]+250, "Reprocessar", oTFolder:aDialogs[5], {|| MntRequis(6) }, 45, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			endif

			@ aPObj[1,3]-44, aPObj[1,4]-80 SAY oQtdU57 PROMPT "Qtd.Documentos:  " + cValtochar(nQtdU57) SIZE 100, 007 OF oTFolder:aDialogs[5] COLORS 0, 16777215 PIXEL
		else
			@ aPObj[1,1]+10, aPObj[1,2]+10 SAY "Rotina de Saques e Depósitos não Habilitada! Parametros TP_ACTSQ e TP_ACTDP." SIZE 200, 007 OF oTFolder:aDialogs[5] COLORS 0, 16777215 PIXEL
		endif
	endif

	//Legendas
	@ aPObj[2,1]+5, 010 BITMAP oLeg ResName "BR_AZUL" OF oDlgCDoc Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2,1]+5, 020 SAY "Documento Ativo" OF oDlgCDoc Color CLR_BLACK PIXEL

	@ aPObj[2,1]+5, 070 BITMAP oLeg ResName "BR_PRETO" OF oDlgCDoc Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2,1]+5, 080 SAY "Documento Cancelado" OF oDlgCDoc Color CLR_BLACK PIXEL

	@ aPObj[2,1]+5, 145 BITMAP oLeg ResName "BR_AMARELO" OF oDlgCDoc Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2,1]+5, 155 SAY "Doc. não Encontrado" OF oDlgCDoc Color CLR_BLACK PIXEL

	@ aPObj[2,1]+5, 220 BITMAP oLeg ResName "BR_VERDE" OF oDlgCDoc Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2,1]+5, 230 SAY "Movimentação OK" OF oDlgCDoc Color CLR_BLACK PIXEL

	@ aPObj[2,1]+5, 285 BITMAP oLeg ResName "BR_VERMELHO" OF oDlgCDoc Size 10, 10 NoBorder When .F. PIXEL
	@ aPObj[2,1]+5, 295 SAY "Pendência de Movimentos" OF oDlgCDoc Color CLR_BLACK PIXEL

	//botoes da tela
	TButton():New( aPObj[2,1]+5, aPObj[2,4]-175, "Busca Pendencia", oDlgCDoc, {|| BuscaPendencia() }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( aPObj[2,1]+5, aPObj[2,4]-110, "Atualizar", oDlgCDoc, {|| Processa({|| AtuConfDocs() },"Avaliando... este processo pode demorar...","Aguarde...") }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtn1 := TButton():New( aPObj[2,1]+5, aPObj[2,4]-55, "Fechar", oDlgCDoc, {|| oDlgCDoc:End() }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtn1:SetCSS( CSS_BTNAZUL )

	//encerra montagem DLG
	if !lAuto
		oDlgCDoc:bInit := {|| Processa({|| AtuConfDocs(), iif(lHabBotoes,BuscarVenda(.T.),) },"Avaliando... este processo pode demorar...","Aguarde...") }
		oDlgCDoc:lCentered := .T.
		oDlgCDoc:Activate()
	else
		Processa({|| AtuConfDocs(,,,,lAuto), iif(lHabBotoes,BuscarVenda(.T.),) },"Verificando pendências documentos...","Aguarde...")
		lRet := BuscaPendencia(lAuto)
	endif

	if lAuto
		oDlgCDoc:bInit := {|| oDlgCDoc:End() }
		oDlgCDoc:Activate()
		FreeObj(oDlgCDoc)
	endif

	FreeObj(oBrrSL1Pdv)
	FreeObj(oBrrSL1Top)
	FreeObj(oBrrSL1Fin)
	if lMvPosto
		if SuperGetMV("TP_ACTCMP",,.F.)
			FreeObj(oBrrUC0Pdv)
			FreeObj(oBrrUC0Top)
			FreeObj(oBrrUC0Fin)
		endif
		if SuperGetMV("TP_ACTVLS",,.F.)
			FreeObj(oBrrVLS)
		endif
		if SuperGetMV("TP_ACTSQ",,.F.) .OR. SuperGetMV("TP_ACTDP",,.F.)
			FreeObj(oBrrU57)
		endif
	endif

	if !lAuto .AND. lHabBotoes
		AtuVlrGrid("", 4, .T.) //Atualizo a tela principal
	endif

Return lRet

//--------------------------------------------------------------------------------------
// Atualiza dados na tela de conferencia de documentos
//--------------------------------------------------------------------------------------
Static Function AtuConfDocs(lVendas,lTrocos,cDocSL1,cSerie,lAuto,lCompens,lValeSrv,lRequis)

	Local nX, nY, aAux
	Local nPosAux1 := 0, nPosAux2 := 0
	Local aLinAux := {}, aDadosAux := {}, aRetSfz
	Local aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,5),SLW->LW_HRFECHA)}
	Local nPosLeg1 := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="LEG1"})
	Local nPosLeg2 := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local nPosLeg3 := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="LEG3"})
	Local nPosDoc := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_DOC"})
	Local nPosSer := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_SERIE"})
	Local nPosCli := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_CLIENTE"})
	Local nPosLoj := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_LOJA"})
	Local nPosNome := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="A1_NOME"})
	Local nPosE5Fil := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_FILIAL"})
	Local nPosE5Pfx := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_PREFIXO"})
	Local nPosE5Num := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_NUMERO"})
	Local nPosE5Seq := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_SEQ"})
	Local nPosE5Dat := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_DATA"})
	Local cLogTime := ""
	Local nAtSL1 := nAtSE5 := nAtUC0 := nAtVLS := 1
	Local nPosUIC_AMB, nPosUIC_COD, nPosUIC_PRC
	Local nPosU57TDoc, nPosU57_PFX, nPosU57_COD, nPosU57_PAR
	Local lConPDV := SuperGetMv("TP_CFCONPD",,.T.)

	Default lVendas := .T.
	Default lTrocos := .T.
	Default cDocSL1 := ""
	Default cSerie := ""
	Default lAuto := .F.
	Default lCompens := .T.
	Default lValeSrv := .T.
	Default lRequis := .T.

	nAtSL1 := oGridSL1:nAt
	nAtSE5 := oGridSE5:nAt
	if lMvPosto

		if SuperGetMV("TP_ACTCMP",,.F.)
			nAtUC0 := oGridUC0:nAt
		else
			lCompens := .F.
		endif

		if SuperGetMV("TP_ACTVLS",,.F.)
			nAtVLS := oGridVLS:nAt
			nPosUIC_AMB := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_AMB"})
			nPosUIC_COD := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_CODIGO"})
			nPosUIC_PRC := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_PRCPRO"})
		else
			lValeSrv := .F.
		endif

		if SuperGetMV("TP_ACTSQ",,.F.) .OR. SuperGetMV("TP_ACTDP",,.F.)
			nAtU57 := oGridU57:nAt
			nPosU57TDoc := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_FILIAL"})
			nPosU57_PFX := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})
			nPosU57_COD := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})
			nPosU57_PAR := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})
		else
			lRequis := .F.
		endif
	else
		lCompens := .F.
		lValeSrv := .F.
		lRequis := .F.
	endif

	ProcRegua(0)
	IncProc("Aguarde.. Iniciando...")
	aPendencia := {}
	nPendAtual := 0

	//busco registros na base PDV, via RPC
	//aDadosPdv é private na funçao ConfDocs()
	if lConPDV
		cLogTime += "Buscando dados PDV/RPC - " + Time() + CRLF
		IncProc("Buscando documentos na base PDV...")
		if empty(aDadosPdv)
			if lMvPosto
				aDadosPdv := DoRPC_Pdv("U_T028DOCS", aSLW, .T., aCpoSL1, aCpoSL2, aCpoSL4, aCpoSE5,,,aCpoUC0,aCpoUC1,aCpoUIC,aCpoU57)
			else
				aDadosPdv := DoRPC_Pdv("U_T028DOCS", aSLW, .T., aCpoSL1, aCpoSL2, aCpoSL4, aCpoSE5)
			endif
			DoRpcClose() //fecha RPC
		endif
	endif

	if empty(aDadosPdv)
		if !lAuto .AND. lConPDV
			MsgInfo("Não foi possível conferir documentos comparando a base do PDV.", "Atenção")
		endif
		//Return
		aDadosPdv := {{},{},{},{},{}} //{aVendas, aSangSup, aCompen, aValeServ, aSaques}
	endif

	//busco registros na base RETAGUARDA
	//aDadosTop é private na funçao ConfDocs()
	cLogTime += "Buscando dados retaguarda - " + Time() + CRLF
	IncProc("Buscando documentos na base Retaguarda...")
	if empty(aDadosTop)
		aDadosTop := {{},{},{},{},{}} //{aVendas, aSangSup, aCompen, aValeServ, aSaques}
	endif
	aDadosAux := U_T028DOCS(aSLW, .F.,;
							iif(lVendas,aCpoSL1,Nil),;
							iif(lVendas,aCpoSL2,Nil),;
							iif(lVendas,aCpoSL4,Nil),;
							iif(lTrocos,aCpoSE5,Nil),;
							iif(lVendas,cDocSL1,Nil),;
							iif(lVendas,cSerie,Nil),;
							iif(lCompens,aCpoUC0,Nil),;
							iif(lCompens,aCpoUC1,Nil),;
							iif(lValeSrv,aCpoUIC,Nil),;
							iif(lRequis,aCpoU57,Nil) )

    //Trecho montado para atualizção dos dados do aDadosTop quando há alguma alteração
	for nX := 1 to len(aDadosAux)
		if (nX==1 .AND. lVendas) .OR. (nX==2 .AND. lTrocos) .OR. (nX==3 .AND. lCompens) .OR. (nX==4 .AND. lValeSrv) .OR. (nX==5 .AND. lRequis)
			if nX==1 .AND. lVendas .AND. !empty(cDocSL1+cSerie)
				if !empty(aDadosAux[nX]) //somente se encontou a venda
					nPosAux1 := aScan(aDadosTop[nX], {|x| x[aScan(aCpoSL1,"L1_DOC")]+x[aScan(aCpoSL1,"L1_SERIE")] == cDocSL1+cSerie })
					if nPosAux1 > 0 //se encontrou a venda, atualizo ele no aDadosTop
						aDadosTop[nX][nPosAux1] := aClone(aDadosAux[nX][1]) //deve vir só um registro filtrado
					endif
				endif
			else
				aDadosTop[nX] := aClone(aDadosAux[nX])
			endif
		endif
	next nX

	//######## APURANDO VENDAS/CUPONS ##########
	IncProc("Carregando vendas (cupons)...")
	cLogTime += "preenchendo grid de vendas SL1 - " + Time() + CRLF
	if lVendas
		if !empty(aDadosPdv[1]) .AND. !empty(aDadosPdv[1][1][aScan(aCpoSL1,"L1_DOC")]) .AND. empty(cDocSL1+cSerie) //ultima condição para refazer este grid apenas quando atualizo tudo.
			oGridSL1:aCols := {}
			For nX := 1 to len(aDadosPdv[1])
				aLinAux := {}
				For nY := 1 to len(oGridSL1:aHeader)
					//nPosAux1 := aScan(aCpoSL1, Alltrim(oGridSL1:aHeader[nY][2]))
					nPosAux1 := aScan(aCpoSL1, {|X| AllTrim(X) == Alltrim(oGridSL1:aHeader[nY][2])})
					if nPosAux1 > 0
						aadd(aLinAux, aDadosPdv[1][nX][nPosAux1]) //adiciono conteudo
					elseif nY == nPosLeg1 //legenda 1
						if aDadosPdv[1][nX][aScan(aCpoSL1,"L1_SITUA")] == "07" .or. aDadosPdv[1][nX][aScan(aCpoSL1,"L1_STORC")] == "A" //se venda cencelada
							aadd(aLinAux, "BR_PRETO")
						else
							aadd(aLinAux, "BR_AZUL")
						endif
					elseif nY == nPosLeg2 //legenda 2
						aadd(aLinAux, "BR_AMARELO")
					elseif nY == nPosNome
						aadd(aLinAux, Posicione("SA1",1,xFilial("SA1")+aDadosPdv[1][nX][aScan(aCpoSL1,"L1_CLIENTE")]+aDadosPdv[1][nX][aScan(aCpoSL1,"L1_LOJA")],"A1_NOME") )
					elseif Alltrim(oGridSL1:aHeader[nY][2]) == "A3_NOME"
						aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosPdv[1][nX][aScan(aCpoSL1,"L1_VEND")],"A3_NOME"))
					else
						aAux := MontaDados("SL1", {Alltrim(oGridSL1:aHeader[nY][2])}, .T.,"",.F.)
						aadd(aLinAux, aAux[1])
					endif
				next nY
				aadd(aLinAux, .F.) //deletado

				aadd(oGridSL1:aCols, aClone(aLinAux) )
			next nX
		endif

		//atualizo grid de vendas SL1 com base na retaguarda
		cLogTime += "Atualizando grid de vendas SL1 - " + Time() + CRLF
		if !empty(aDadosTop[1]) .AND. !empty(aDadosTop[1][1][aScan(aCpoSL1,"L1_DOC")])
			//se nao pegou dados no pdv, zero acols
			if empty(cDocSL1+cSerie) .AND. empty(aDadosPdv[1])
				oGridSL1:aCols := {}
			endif
			//verifico se venda ja existe no grid, senao adiciono
			For nX := 1 to len(aDadosTop[1])
				if empty(cDocSL1+cSerie) .OR. cDocSL1+cSerie == aDadosTop[1][nX][aScan(aCpoSL1,"L1_DOC")]+aDadosTop[1][nX][aScan(aCpoSL1,"L1_SERIE")]
					nPosAux1 := aScan(oGridSL1:aCols, {|x| x[nPosDoc]+x[nPosSer] == aDadosTop[1][nX][aScan(aCpoSL1,"L1_DOC")]+aDadosTop[1][nX][aScan(aCpoSL1,"L1_SERIE")] })
					if nPosAux1 > 0
						if oGridSL1:aCols[nPosAux1][nPosLeg2] == "BR_AZUL" .AND. empty(cDocSL1+cSerie) //se ja estava azul, é SL1 duplicada
							oGridSL1:aCols[nPosAux1][nPosLeg3] := "DUPLICADO"
						else
							oGridSL1:aCols[nPosAux1][nPosLeg2] := "BR_AZUL"
							for nY := 4 to len(oGridSL1:aHeader)
								//nPosAux2 := aScan(aCpoSL1, Alltrim(oGridSL1:aHeader[nY][2]))
								nPosAux2 := aScan(aCpoSL1, {|X| AllTrim(X) == Alltrim(oGridSL1:aHeader[nY][2])})
								if nPosAux2 > 0
									oGridSL1:aCols[nPosAux1][nY] := aDadosTop[1][nX][nPosAux2]
								elseif nY == nPosNome
									oGridSL1:aCols[nPosAux1][nY] := Posicione("SA1",1,xFilial("SA1")+aDadosTop[1][nX][aScan(aCpoSL1,"L1_CLIENTE")]+aDadosTop[1][nX][aScan(aCpoSL1,"L1_LOJA")],"A1_NOME")
								elseif Alltrim(oGridSL1:aHeader[nY][2]) == "A3_NOME"
									oGridSL1:aCols[nPosAux1][nY] := Posicione("SA3",1,xFilial("SA3")+aDadosTop[1][nX][aScan(aCpoSL1,"L1_VEND")],"A3_NOME")
								endif
							next nY
						endif
					else
						aLinAux := {}
						For nY := 1 to len(oGridSL1:aHeader)
							//nPosAux1 := aScan(aCpoSL1, Alltrim(oGridSL1:aHeader[nY][2]))
							nPosAux1 := aScan(aCpoSL1, {|X| AllTrim(X) == Alltrim(oGridSL1:aHeader[nY][2])})
							if nPosAux1 > 0
								aadd(aLinAux, aDadosTop[1][nX][nPosAux1]) //adiciono conteudo
							elseif nY == nPosLeg1 //legenda 1
								aadd(aLinAux, "BR_AMARELO")
							elseif nY == nPosLeg2 //legenda 2
								aadd(aLinAux, "BR_AZUL")
							elseif nY == nPosNome
								aadd(aLinAux, Posicione("SA1",1,xFilial("SA1")+aDadosTop[1][nX][aScan(aCpoSL1,"L1_CLIENTE")]+aDadosTop[1][nX][aScan(aCpoSL1,"L1_LOJA")],"A1_NOME") )
							elseif Alltrim(oGridSL1:aHeader[nY][2]) == "A3_NOME"
								aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosTop[1][nX][aScan(aCpoSL1,"L1_VEND")],"A3_NOME"))
							else
								aAux := MontaDados("SL1", {Alltrim(oGridSL1:aHeader[nY][2])}, .T.,"",.F.)
								aadd(aLinAux, aAux[1])
							endif
						next nY
						aadd(aLinAux, .F.) //deletado

						aadd(oGridSL1:aCols, aClone(aLinAux) )
					endif
				endif
			next nX
		endif

		//verifico cancelamento cupom/nfce na SF3
		cLogTime += "Verifico cancelamento cupom/nfce na SF3 - " + Time() + CRLF
		IncProc("Apurando cancelamento vendas (cupons)...")
		DbSelectArea("SF3")
		SF3->(DBSetOrder(5))
		For nX := 1 to len(oGridSL1:aCols)
			if !empty(oGridSL1:aCols[nX][nPosDoc]) .AND. (empty(cDocSL1+cSerie) .OR. oGridSL1:aCols[nX][nPosDoc]+oGridSL1:aCols[nX][nPosSer] == cDocSL1+cSerie)
				if SF3->(DbSeek(xFilial("SF3")+oGridSL1:aCols[nX][nPosSer]+oGridSL1:aCols[nX][nPosDoc]+oGridSL1:aCols[nX][nPosCli]+oGridSL1:aCols[nX][nPosLoj] ))
					if !empty(SF3->F3_DTCANC)
						oGridSL1:aCols[nX][nPosLeg2] := "BR_PRETO"
					elseif "DENEGADA" $ SF3->F3_OBSERV //se nota denegada, considera como cancelada tbm
						oGridSL1:aCols[nX][nPosLeg2] := "BR_PRETO"
					//else
					//	oGridSL1:aCols[nX][nPosLeg2] := "BR_AZUL"
					endif

					//tratamento para as vendas que nem sobe cancelamento
				elseif oGridSL1:aCols[nX][nPosLeg1] == "BR_PRETO" .AND. oGridSL1:aCols[nX][nPosLeg2] == "BR_AMARELO"
					oGridSL1:aCols[nX][nPosLeg2] := "BR_PRETO"
				endif

				//Considerar vendas canceladas no PDV e que tem devolução retaguarda, como legenda preta também
				if oGridSL1:aCols[nX][nPosLeg1] == "BR_PRETO" .AND. oGridSL1:aCols[nX][nPosLeg2] <> "BR_PRETO"
					SD1->(DbSetOrder(19)) //D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA
					If SD1->(DbSeek(xFilial("SD1") + oGridSL1:aCols[nX][nPosDoc] + oGridSL1:aCols[nX][nPosSer] ))
						If SD1->D1_TIPO == 'D'
							oGridSL1:aCols[nX][nPosLeg2] := "BR_PRETO"
						endif
					endif
				endif
			endif
		Next nX

		//Busco Dados Financeiros das vendas
		cLogTime += "Busco Dados Financeiros das vendas - " + Time() + CRLF
		if len(aDadosFin) < 1
			aadd(aDadosFin, {}) //posicao 1
		elseif empty(cDocSL1+cSerie) //limpo somente se estou atualizando tudo
			aDadosFin[1] := {} //limpo
		endif
		nQtdSL1 := 0
		For nX := 1 to len(oGridSL1:aCols)
			if !empty(oGridSL1:aCols[nX][nPosDoc])
				nQtdSL1++
				if (empty(cDocSL1+cSerie) .OR. oGridSL1:aCols[nX][nPosDoc]+oGridSL1:aCols[nX][nPosSer] == cDocSL1+cSerie)
					IncProc("Apurando financeiro venda: "+oGridSL1:aCols[nX][nPosDoc]+"")

					//{cL1Doc, cL1Serie, lOk, nTotProd, nTotTit, nTotTroDin, cObs, aIdCorrige, nTotTroCht, nTotTroVlh}
					aLinAux := AvalFinSL1(oGridSL1:aCols[nX][nPosDoc], oGridSL1:aCols[nX][nPosSer],oGridSL1:aCols[nX][nPosLeg2] == "BR_PRETO")

					if aLinAux[3]
						//verifico diferença na legenda 1 e 2 da venda
						if oGridSL1:aCols[nX][nPosLeg1]<>"BR_AMARELO" .AND. oGridSL1:aCols[nX][nPosLeg1] <> oGridSL1:aCols[nX][nPosLeg2]
							if oGridSL1:aCols[nX][nPosLeg1] == "BR_AZUL" .AND. oGridSL1:aCols[nX][nPosLeg2] == "BR_AMARELO"
								aLinAux[3] := .F.
								aLinAux[7] := "Venda ativa encontrada no PDV e não encontrada na Retaguarda! Possível falha na integraçao. " + CRLF
								nPosAux1 := aScan(aDadosPdv[1], {|x| x[1]+x[2] == oGridSL1:aCols[nX][nPosDoc]+oGridSL1:aCols[nX][nPosSer] })
								if nPosAux1 > 0 .AND. !empty(aDadosPdv[1][nPosAux1][aScan(aCpoSL1,"L1_RETSFZ")])
									aRetSfz := StrToKArr(aDadosPdv[1][nPosAux1][aScan(aCpoSL1,"L1_RETSFZ")],"|")
									aLinAux[7] += aRetSfz[len(aRetSfz)]
								endif
								aadd(aLinAux[8], "NOVENDARET")
							elseif oGridSL1:aCols[nX][nPosLeg1] == "BR_PRETO" .AND. oGridSL1:aCols[nX][nPosLeg2] == "BR_AZUL"
								aLinAux[3] := .F.
								aLinAux[7] := "Venda cancelada no PDV e não cancelada na Retaguarda!"
								aadd(aLinAux[8], "VENDANOCANC")
							elseif oGridSL1:aCols[nX][nPosLeg1] == "BR_AZUL" .AND. oGridSL1:aCols[nX][nPosLeg2] == "BR_PRETO"
								aLinAux[3] := .F.
								aLinAux[7] := "Venda ativa no PDV e cancelada (ou denegada) na Retaguarda!"
								aadd(aLinAux[8], "CANCERRADO")
							endif
						endif
					endif

					if aLinAux[3] .AND. oGridSL1:aCols[nX][nPosLeg3] == "DUPLICADO"
						aLinAux[3] := .F.
						aLinAux[7] := "Venda duplicada! Encontrado mais de um registro na SL1 com este doc/serie."
						aadd(aLinAux[8], "DUPLICADO")
					endif

					if empty(cDocSL1+cSerie)
						aadd(aDadosFin[1], aClone(aLinAux))
					else
						nPosAux1 := aScan(aDadosFin[1], {|x| x[1]+x[2] == cDocSL1+cSerie })
						aDadosFin[1][nPosAux1] := aClone(aLinAux)
					endif

					if aLinAux[3]
						oGridSL1:aCols[nX][nPosLeg3] := "BR_VERDE"
					else
						oGridSL1:aCols[nX][nPosLeg3] := "BR_VERMELHO"
					endif
				endif
			endif
		next nX
	endif

	//######## APURANDO Suprimentos e Sangrias ##########
	IncProc("Apurando Suprimentos e Sangrias...")
	cLogTime += "preenchendo grid de suprimentos e sangrias SE5 - " + Time() + CRLF
	if lTrocos
		oGridSE5:aCols := {}
		if !empty(aDadosPdv[2]) .AND. !empty(aDadosPdv[2][1][aScan(aCpoSE5,"E5_DATA")])
			For nX := 1 to len(aDadosPdv[2])
				aLinAux := {}
				For nY := 1 to len(oGridSE5:aHeader)
					nPosAux1 := aScan(aCpoSE5, Alltrim(oGridSE5:aHeader[nY][2]))
					if nPosAux1 > 0
						aadd(aLinAux, aDadosPdv[2][nX][nPosAux1]) //adiciono conteudo
					elseif nY == nPosLeg1 //legenda 1
						aadd(aLinAux, "BR_AZUL")
					elseif nY == nPosLeg2 //legenda 2
						aadd(aLinAux, "BR_AMARELO") //por default é amarelo
					elseif Alltrim(oGridSE5:aHeader[nY][2]) == "RECNO"
						aadd(aLinAux, 0)
					elseif Alltrim(oGridSE5:aHeader[nY][2]) == "A3_NOME"
						aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosPdv[2][nX][aScan(aCpoSE5,"E5_OPERAD")] ,"A3_NOME"))
					else
						aAux := MontaDados("SE5", {Alltrim(oGridSE5:aHeader[nY][2])}, .T.,"",.F.)
						aadd(aLinAux, aAux[1])
					endif
				next nY
				aadd(aLinAux, .F.) //deletado

				aadd(oGridSE5:aCols, aClone(aLinAux) )
			next nX
		endif

		cLogTime += "Atualizando grid de Suprimentos e Sangrias SE5 - " + Time() + CRLF
		if !empty(aDadosTop[2]) .AND. !empty(aDadosTop[2][1][aScan(aCpoSE5,"E5_DATA")])
			//verifico se venda ja existe no grid, senao adiciono
			For nX := 1 to len(aDadosTop[2])
				nPosAux1 := aScan(oGridSE5:aCols, {|x| x[nPosE5Fil]+x[nPosE5Pfx]+x[nPosE5Num]+x[nPosE5Seq] == aDadosTop[2][nX][aScan(aCpoSE5,"E5_FILIAL")]+aDadosTop[2][nX][aScan(aCpoSE5,"E5_PREFIXO")]+aDadosTop[2][nX][aScan(aCpoSE5,"E5_NUMERO")]+aDadosTop[2][nX][aScan(aCpoSE5,"E5_SEQ")] })
				if nPosAux1 > 0 //se encontrou
					if aDadosTop[2][nX][aScan(aCpoSE5,"D_E_L_E_T_")] == "*" //se excluido
						oGridSE5:aCols[nPosAux1][nPosLeg2] := "BR_PRETO"
					else
						oGridSE5:aCols[nPosAux1][nPosLeg2] := "BR_AZUL"
					endif

					for nY := 4 to len(oGridSE5:aHeader)
						nPosAux2 := aScan(aCpoSE5, Alltrim(oGridSE5:aHeader[nY][2]))
						if nPosAux2 > 0
							oGridSE5:aCols[nPosAux1][nY] := aDadosTop[2][nX][nPosAux2]
						elseif Alltrim(oGridSE5:aHeader[nY][2]) == "A3_NOME"
							oGridSE5:aCols[nPosAux1][nY] := Posicione("SA3",1,xFilial("SA3")+aDadosTop[2][nX][aScan(aCpoSE5,"E5_OPERAD")],"A3_NOME")
						endif
					next nY
					oGridSE5:aCols[nPosAux1][len(oGridSE5:aHeader)] := aDadosTop[2][nX][len(aDadosTop[2][nX])] //RECNO

				//se nao tem no pdv, e nao ta deletado na retaguarda, mostra
				elseif aDadosTop[2][nX][aScan(aCpoSE5,"D_E_L_E_T_")] != "*"
					aLinAux := {}
					For nY := 1 to len(oGridSE5:aHeader)
						nPosAux1 := aScan(aCpoSE5, Alltrim(oGridSE5:aHeader[nY][2]))
						if nPosAux1 > 0
							aadd(aLinAux, aDadosTop[2][nX][nPosAux1]) //adiciono conteudo
						elseif nY == nPosLeg1 //legenda 1
							aadd(aLinAux, "BR_AMARELO")
						elseif nY == nPosLeg2 //legenda 2
							aadd(aLinAux, "BR_AZUL")
						elseif Alltrim(oGridSE5:aHeader[nY][2]) == "RECNO"
							aadd(aLinAux, aDadosTop[2][nX][len(aDadosTop[2][nX])] )
						elseif Alltrim(oGridSE5:aHeader[nY][2]) == "A3_NOME"
							aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosTop[2][nX][aScan(aCpoSE5,"E5_OPERAD")] ,"A3_NOME"))
						else
							aAux := MontaDados("SE5", {Alltrim(oGridSE5:aHeader[nY][2])}, .T.,"",.F.)
							aadd(aLinAux, aAux[1])
						endif
					next nY
					aadd(aLinAux, .F.) //deletado

					aadd(oGridSE5:aCols, aClone(aLinAux) )
				endif
			next nX
		endif

		//Busco Dados Financeiros dos Suprimentos e Sangrias
		cLogTime += "Legenda financeira Suprimentos e Sangrias SE5 - " + Time() + CRLF
		nQtdSE5 := 0
		For nX := 1 to len(oGridSE5:aCols)
			if !empty(oGridSE5:aCols[nX][nPosE5Dat])
				nQtdSE5++

				if oGridSE5:aCols[nX][nPosLeg1] == "BR_AZUL" .AND. oGridSE5:aCols[nX][nPosLeg2] == "BR_AMARELO"
					oGridSE5:aCols[nX][nPosLeg3] := "BR_VERMELHO"
				else
					oGridSE5:aCols[nX][nPosLeg3] := "BR_VERDE"
				endif
			endif
		next nX

		if empty(oGridSE5:aCols)
			aadd(oGridSE5:aCols, MontaDados("SE5",aCpoGdSE5, .T.))
		endif
	endif

	if lMvPosto

		//######## APURANDO COMPENSAÇÔES DE VALORES ##########
		IncProc("Apurando Compensações de Valores...")
		cLogTime += "preenchendo grid de compensações UC0 - " + Time() + CRLF
		if lCompens
			nPosDoc := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="UC0_NUM"})
			nPosNome := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="A1_NOME"})
			oGridUC0:aCols := {}

			if !empty(aDadosPdv[3]) .AND. !empty(aDadosPdv[3][1][aScan(aCpoUC0,"UC0_NUM")])
				For nX := 1 to len(aDadosPdv[3])
					aLinAux := {}
					For nY := 1 to len(oGridUC0:aHeader)
						nPosAux1 := aScan(aCpoUC0, Alltrim(oGridUC0:aHeader[nY][2]))
						if nPosAux1 > 0
							aadd(aLinAux, aDadosPdv[3][nX][nPosAux1]) //adiciono conteudo
						elseif nY == nPosLeg1 //legenda 1
							if aDadosPdv[3][nX][aScan(aCpoUC0,"UC0_ESTORN")] $ "SX" //se estornada
								aadd(aLinAux, "BR_PRETO")
							else
								aadd(aLinAux, "BR_AZUL")
							endif
						elseif nY == nPosLeg2 //legenda 2
							aadd(aLinAux, "BR_AMARELO") //por default é amarelo
						elseif nY == nPosNome
							aadd(aLinAux, Posicione("SA1",1,xFilial("SA1")+aDadosPdv[3][nX][aScan(aCpoUC0,"UC0_CLIENT")]+aDadosPdv[3][nX][aScan(aCpoUC0,"UC0_LOJA")],"A1_NOME") )
						elseif Alltrim(oGridUC0:aHeader[nY][2]) == "A3_NOME"
							aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosPdv[3][nX][aScan(aCpoUC0,"UC0_VEND")] ,"A3_NOME"))
						else
							aAux := MontaDados("UC0", {Alltrim(oGridUC0:aHeader[nY][2])}, .T.,"",.F.)
							aadd(aLinAux, aAux[1])
						endif
					next nY
					aadd(aLinAux, .F.) //deletado

					aadd(oGridUC0:aCols, aClone(aLinAux) )
				next nX
			endif

			cLogTime += "Atualizando grid de compensações UC0 - " + Time() + CRLF
			if !empty(aDadosTop[3]) .AND. !empty(aDadosTop[3][1][aScan(aCpoUC0,"UC0_NUM")])
				//verifico se compensaçao ja existe no grid, senao adiciono
				For nX := 1 to len(aDadosTop[3])
					nPosAux1 := aScan(oGridUC0:aCols, {|x| x[nPosDoc] == aDadosTop[3][nX][aScan(aCpoUC0,"UC0_NUM")] })
					if nPosAux1 > 0
						if aDadosTop[3][nX][aScan(aCpoUC0,"UC0_ESTORN")] $ "SX" //se estornada
							oGridUC0:aCols[nPosAux1][nPosLeg2] := "BR_PRETO"
						else
							oGridUC0:aCols[nPosAux1][nPosLeg2] := "BR_AZUL"
						endif
						for nY := 4 to len(oGridUC0:aHeader)
							nPosAux2 := aScan(aCpoUC0, Alltrim(oGridUC0:aHeader[nY][2]))
							if nPosAux2 > 0
								oGridUC0:aCols[nPosAux1][nY] := aDadosTop[3][nX][nPosAux2]
							elseif nY == nPosNome
								oGridUC0:aCols[nPosAux1][nY] := Posicione("SA1",1,xFilial("SA1")+aDadosTop[3][nX][aScan(aCpoUC0,"UC0_CLIENT")]+aDadosTop[3][nX][aScan(aCpoUC0,"UC0_LOJA")],"A1_NOME")
							elseif Alltrim(oGridUC0:aHeader[nY][2]) == "A3_NOME"
								oGridUC0:aCols[nPosAux1][nY] := Posicione("SA3",1,xFilial("SA3")+aDadosTop[3][nX][aScan(aCpoUC0,"UC0_VEND")] ,"A3_NOME")
							endif
						next nY
					else
						aLinAux := {}
						For nY := 1 to len(oGridUC0:aHeader)
							nPosAux1 := aScan(aCpoUC0, Alltrim(oGridUC0:aHeader[nY][2]))
							if nPosAux1 > 0
								aadd(aLinAux, aDadosTop[3][nX][nPosAux1]) //adiciono conteudo
							elseif nY == nPosLeg1 //legenda 1
								aadd(aLinAux, "BR_AMARELO")
							elseif nY == nPosLeg2 //legenda 2
								if aDadosTop[3][nX][aScan(aCpoUC0,"UC0_ESTORN")] $ "SX" //se estornada
									aadd(aLinAux, "BR_PRETO")
								else
									aadd(aLinAux, "BR_AZUL")
								endif
							elseif nY == nPosNome
								aadd(aLinAux, Posicione("SA1",1,xFilial("SA1")+aDadosTop[3][nX][aScan(aCpoUC0,"UC0_CLIENT")]+aDadosTop[3][nX][aScan(aCpoUC0,"UC0_LOJA")],"A1_NOME") )
							elseif Alltrim(oGridUC0:aHeader[nY][2]) == "A3_NOME"
								aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosTop[3][nX][aScan(aCpoUC0,"UC0_VEND")] ,"A3_NOME"))
							else
								aAux := MontaDados("UC0", {Alltrim(oGridUC0:aHeader[nY][2])}, .T.,"",.F.)
								aadd(aLinAux, aAux[1])
							endif
						next nY
						aadd(aLinAux, .F.) //deletado

						aadd(oGridUC0:aCols, aClone(aLinAux) )
					endif
				next nX
			endif

			//Busco Dados Financeiros das compensaçoes
			cLogTime += "Busco Dados Financeiros das compensaçoes - " + Time() + CRLF
			if len(aDadosFin) < 2
				aadd(aDadosFin, {}) //posicao 2
			else
				aDadosFin[2] := {} //limpo
			endif
			nQtdUC0 := 0
			For nX := 1 to len(oGridUC0:aCols)
				if !empty(oGridUC0:aCols[nX][nPosDoc])
					nQtdUC0++

					if oGridUC0:aCols[nX][nPosLeg2] == "BR_AMARELO"
						aLinAux := {oGridUC0:aCols[nX][nPosDoc], .F., 0, 0, 0, 0, "Compensação não encontrada na base Retaguarda!",{}}
					else
						//{cNumComp, lOk, nTotEntrada, nTotTroDin, nTotTroCht, nTotTroVlh, cObs, aIdCorrige}
						aLinAux := AvalFinUC0(oGridUC0:aCols[nX][nPosDoc], oGridUC0:aCols[nX][nPosLeg2] == "BR_PRETO")
					endif
					aadd(aDadosFin[2], aClone(aLinAux))

					if aLinAux[2]
						oGridUC0:aCols[nX][nPosLeg3] := "BR_VERDE"
					else
						oGridUC0:aCols[nX][nPosLeg3] := "BR_VERMELHO"
					endif
				endif
			next nX

			if empty(oGridUC0:aCols)
				aadd(oGridUC0:aCols, MontaDados("UC0",aCpoGdUC0, .T.,,.F.))
			endif
		else
			if len(aDadosFin) < 2
				aadd(aDadosFin, {}) //posicao 2
			else
				aDadosFin[2] := {} //limpo
			endif
		endif

		//######## APURANDO VALE SERVIÇO ##########
		IncProc("Apurando Vales Serviços...")
		cLogTime += "preenchendo grid de vale serviço UIC - " + Time() + CRLF
		if lValeSrv
			oGridVLS:aCols := {}
			if !empty(aDadosPdv[4]) .AND. !empty(aDadosPdv[4][1][aScan(aCpoUIC,"UIC_CODIGO")])
				For nX := 1 to len(aDadosPdv[4])
					cAux := aDadosPdv[4][nX][aScan(aCpoUIC,"UIC_AMB")]+aDadosPdv[4][nX][aScan(aCpoUIC,"UIC_CODIGO")]
					if aScan(oGridVLS:aCols, {|x| x[nPosUIC_AMB]+x[nPosUIC_COD] == cAux }) == 0
						aLinAux := {}
						For nY := 1 to len(oGridVLS:aHeader)
							nPosAux1 := aScan(aCpoUIC, Alltrim(oGridVLS:aHeader[nY][2]))
							if nPosAux1 > 0
								aadd(aLinAux, aDadosPdv[4][nX][nPosAux1]) //adiciono conteudo
							elseif nY == nPosLeg1 //legenda 1
								if aDadosPdv[4][nX][aScan(aCpoUIC,"UIC_STATUS")] == "C" //estornada
									aadd(aLinAux, "BR_PRETO")
								else
									aadd(aLinAux, "BR_AZUL")
								endif
							elseif nY == nPosLeg2 //legenda 2
								aadd(aLinAux, "BR_AMARELO") //por default é amarelo
							elseif Alltrim(oGridVLS:aHeader[nY][2]) == "A3_NOME"
								aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosPdv[4][nX][aScan(aCpoUIC,"UIC_VEND")] ,"A3_NOME"))
							else
								aAux := MontaDados("UIC", {Alltrim(oGridVLS:aHeader[nY][2])}, .T.,"",.F.)
								aadd(aLinAux, aAux[1])
							endif
						next nY
						aadd(aLinAux, .F.) //deletado

						aadd(oGridVLS:aCols, aClone(aLinAux) )
					endif
				next nX
			endif

			cLogTime += "Atualizando grid de vale serviço UIC - " + Time() + CRLF
			if !empty(aDadosTop[4]) .AND. !empty(aDadosTop[4][1][aScan(aCpoUIC,"UIC_CODIGO")])
				//verifico se venda ja existe no grid, senao adiciono
				For nX := 1 to len(aDadosTop[4])
					nPosAux1 := aScan(oGridVLS:aCols, {|x| x[nPosUIC_AMB]+x[nPosUIC_COD] == aDadosTop[4][nX][aScan(aCpoUIC,"UIC_AMB")]+aDadosTop[4][nX][aScan(aCpoUIC,"UIC_CODIGO")] })
					if nPosAux1 > 0
						if aDadosTop[4][nX][aScan(aCpoUIC,"UIC_STATUS")] == "C" //estornada
							oGridVLS:aCols[nPosAux1][nPosLeg2] := "BR_PRETO"
						else
							oGridVLS:aCols[nPosAux1][nPosLeg2] := "BR_AZUL"
						endif
						for nY := 4 to len(oGridVLS:aHeader)
							nPosAux2 := aScan(aCpoUIC, Alltrim(oGridVLS:aHeader[nY][2]))
							if nPosAux2 > 0
								oGridVLS:aCols[nPosAux1][nY] := aDadosTop[4][nX][nPosAux2]
							elseif Alltrim(oGridVLS:aHeader[nY][2]) == "A3_NOME"
								oGridVLS:aCols[nPosAux1][nY] := Posicione("SA3",1,xFilial("SA3")+aDadosTop[4][nX][aScan(aCpoUIC,"UIC_VEND")] ,"A3_NOME")
							endif
						next nY
					else
						aLinAux := {}
						For nY := 1 to len(oGridVLS:aHeader)
							nPosAux1 := aScan(aCpoUIC, Alltrim(oGridVLS:aHeader[nY][2]))
							if nPosAux1 > 0
								aadd(aLinAux, aDadosTop[4][nX][nPosAux1]) //adiciono conteudo
							elseif nY == nPosLeg1 //legenda 1
								aadd(aLinAux, "BR_AMARELO")
							elseif nY == nPosLeg2 //legenda 2
								if aDadosTop[4][nX][aScan(aCpoUIC,"UIC_STATUS")] == "C" //estornada
									aadd(aLinAux, "BR_PRETO")
								else
									aadd(aLinAux, "BR_AZUL")
								endif
							elseif Alltrim(oGridVLS:aHeader[nY][2]) == "A3_NOME"
								aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosTop[4][nX][aScan(aCpoUIC,"UIC_VEND")] ,"A3_NOME"))
							else
								aAux := MontaDados("UIC", {Alltrim(oGridVLS:aHeader[nY][2])}, .T.,"",.F.)
								aadd(aLinAux, aAux[1])
							endif
						next nY
						aadd(aLinAux, .F.) //deletado

						aadd(oGridVLS:aCols, aClone(aLinAux) )
					endif
				next nX
			endif

			//Busco Dados Financeiros dos vales serviços
			cLogTime += "Busco Dados Financeiros dos vales serviços - " + Time() + CRLF
			if len(aDadosFin) < 3
				aadd(aDadosFin, {}) //posicao 3
			else
				aDadosFin[3] := {} //limpo
			endif
			nQtdVLS := 0
			For nX := 1 to len(oGridVLS:aCols)
				if !empty(oGridVLS:aCols[nX][nPosUIC_COD])
					nQtdVLS++

					if oGridVLS:aCols[nX][nPosLeg2] == "BR_AMARELO"
						aLinAux := {oGridVLS:aCols[nX][nPosUIC_AMB]+oGridVLS:aCols[nX][nPosUIC_COD], .F., 0, 0, 0, "Vale Serviço não encontrado na base Retaguarda!"}
					else
						//{cChavVLS, lOk, nVlrServico, nVlrReceb, nVlrPagar, cObs}
						aLinAux := AvalFinVLS(oGridVLS:aCols[nX][nPosUIC_AMB], oGridVLS:aCols[nX][nPosUIC_COD], oGridVLS:aCols[nX][nPosUIC_PRC], oGridVLS:aCols[nX][nPosLeg2]=="BR_PRETO")
					endif

					aadd(aDadosFin[3], aClone(aLinAux))

					if aLinAux[2]
						oGridVLS:aCols[nX][nPosLeg3] := "BR_VERDE"
					else
						oGridVLS:aCols[nX][nPosLeg3] := "BR_VERMELHO"
					endif
				endif
			next nX

			if empty(oGridVLS:aCols)
				aadd(oGridVLS:aCols, MontaDados("UIC",aCpoGdUIC, .T.,,.F.))
			endif
		else
			if len(aDadosFin) < 3
				aadd(aDadosFin, {}) //posicao 3
			else
				aDadosFin[3] := {} //limpo
			endif
		endif

		//######## APURANDO SAQUES E DEPOSITOS ##########
		IncProc("Apurando Saques e Depositos...")
		cLogTime += "preenchendo grid de saques e depositos U57 - " + Time() + CRLF
		if lRequis
			oGridU57:aCols := {}
			if !empty(aDadosPdv[5]) .AND. !empty(aDadosPdv[5][1][aScan(aCpoU57,"U57_CODIGO")])
				For nX := 1 to len(aDadosPdv[5])
					aLinAux := {}
					For nY := 1 to len(oGridU57:aHeader)
						nPosAux1 := aScan(aCpoU57, Alltrim(oGridU57:aHeader[nY][2]))
						if nPosAux1 > 0
							aadd(aLinAux, aDadosPdv[5][nX][nPosAux1]) //adiciono conteudo
						elseif nY == nPosLeg1 //legenda 1
							if aDadosPdv[5][nX][aScan(aCpoU57,"U57_XGERAF")] $ "X,D" //se estornada
								aadd(aLinAux, "BR_PRETO")
							else
								aadd(aLinAux, "BR_AZUL")
							endif
						elseif nY == nPosLeg2 //legenda 2
							aadd(aLinAux, "BR_AMARELO") //por default é amarelo
						elseif Alltrim(oGridU57:aHeader[nY][2]) == "A3_NOME"
							aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosPdv[5][nX][aScan(aCpoU57,"U57_VEND")] ,"A3_NOME"))
						else
							aAux := MontaDados("U57", {Alltrim(oGridU57:aHeader[nY][2])}, .T.,"",.F.)
							aadd(aLinAux, aAux[1])
						endif
					next nY
					aadd(aLinAux, .F.) //deletado

					aadd(oGridU57:aCols, aClone(aLinAux) )

				next nX
			endif

			nPosU57TDoc := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_FILIAL"})
			nPosU57_PFX := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})
			nPosU57_COD := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})
			nPosU57_PAR := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})

			cLogTime += "Atualizando grid de saques e depositos U57 - " + Time() + CRLF
			if !empty(aDadosTop[5]) .AND. !empty(aDadosTop[5][1][aScan(aCpoU57,"U57_CODIGO")])
				//verifico se venda ja existe no grid, senao adiciono
				For nX := 1 to len(aDadosTop[5])
					nPosAux1 := aScan(oGridU57:aCols, {|x| x[nPosU57TDoc]+x[nPosU57_PFX]+x[nPosU57_COD]+x[nPosU57_PAR] == aDadosTop[5][nX][aScan(aCpoU57,"U57_FILIAL")]+aDadosTop[5][nX][aScan(aCpoU57,"U57_PREFIX")]+aDadosTop[5][nX][aScan(aCpoU57,"U57_CODIGO")]+aDadosTop[5][nX][aScan(aCpoU57,"U57_PARCEL")] })
					if nPosAux1 > 0
						if aDadosTop[5][nX][aScan(aCpoU57,"U57_XGERAF")] $ "X,D" //se estornada
							oGridU57:aCols[nPosAux1][nPosLeg2] := "BR_PRETO"
						else
							oGridU57:aCols[nPosAux1][nPosLeg2] := "BR_AZUL"
						endif
						for nY := 4 to len(oGridU57:aHeader)
							nPosAux2 := aScan(aCpoU57, Alltrim(oGridU57:aHeader[nY][2]))
							if nPosAux2 > 0
								oGridU57:aCols[nPosAux1][nY] := aDadosTop[5][nX][nPosAux2]
							elseif Alltrim(oGridU57:aHeader[nY][2]) == "A3_NOME"
								oGridU57:aCols[nPosAux1][nY] := Posicione("SA3",1,xFilial("SA3")+aDadosTop[5][nX][aScan(aCpoU57,"U57_VEND")] ,"A3_NOME")
							endif
						next nY
					else
						aLinAux := {}
						For nY := 1 to len(oGridU57:aHeader)
							nPosAux1 := aScan(aCpoU57, Alltrim(oGridU57:aHeader[nY][2]))
							if nPosAux1 > 0
								aadd(aLinAux, aDadosTop[5][nX][nPosAux1]) //adiciono conteudo
							elseif nY == nPosLeg1 //legenda 1
								aadd(aLinAux, "BR_AMARELO")
							elseif nY == nPosLeg2 //legenda 2
								if aDadosTop[5][nX][aScan(aCpoU57,"U57_XGERAF")] $ "X,D" //se estornada
									aadd(aLinAux, "BR_PRETO")
								else
									aadd(aLinAux, "BR_AZUL")
								endif
							elseif Alltrim(oGridU57:aHeader[nY][2]) == "A3_NOME"
								aadd(aLinAux, Posicione("SA3",1,xFilial("SA3")+aDadosTop[5][nX][aScan(aCpoU57,"U57_VEND")] ,"A3_NOME"))
							else
								aAux := MontaDados("U57", {Alltrim(oGridU57:aHeader[nY][2])}, .T.,"",.F.)
								aadd(aLinAux, aAux[1])
							endif
						next nY
						aadd(aLinAux, .F.) //deletado

						aadd(oGridU57:aCols, aClone(aLinAux) )
					endif
				next nX
			endif

			//Aplico legenda preta para saques pré pago estornados 
			for nX := 1 to len(oGridU57:aCols)
				if Alltrim(oGridU57:aCols[nX][aScan(aCpoGdU57,"U57_FILIAL")])=="SAQUE" .AND. oGridU57:aCols[nX][nPosLeg1] == "BR_PRETO" .AND. oGridU57:aCols[nX][nPosLeg2] == "BR_AMARELO"
					oGridU57:aCols[nX][nPosLeg2] := "BR_PRETO"
				endif
			next nX

			//Busco Dados Financeiros das requisições
			cLogTime += "Busco Dados Financeiros saques e depositos - " + Time() + CRLF
			if len(aDadosFin) < 4
				aadd(aDadosFin, {}) //posicao 4
			else
				aDadosFin[4] := {} //limpo
			endif
			nQtdU57 := 0
			For nX := 1 to len(oGridU57:aCols)
				if !empty(oGridU57:aCols[nX][nPosU57_COD])
					nQtdU57++
					//{cChavU57, lOk, nVlrU57, nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}
					aLinAux := AvalFinU57(oGridU57:aCols[nX][nPosU57TDoc], oGridU57:aCols[nX][nPosU57_PFX], oGridU57:aCols[nX][nPosU57_COD], oGridU57:aCols[nX][nPosU57_PAR])
					aadd(aDadosFin[4], aClone(aLinAux))

					if aLinAux[2]
						oGridU57:aCols[nX][nPosLeg3] := "BR_VERDE"
					else
						oGridU57:aCols[nX][nPosLeg3] := "BR_VERMELHO"
					endif
				endif
			next nX

			if empty(oGridU57:aCols)
				aadd(oGridU57:aCols, MontaDados("U57",aCpoGdU57, .T.,,.F.))
			endif
		else
			if len(aDadosFin) < 4
				aadd(aDadosFin, {}) //posicao 4
			else
				aDadosFin[4] := {} //limpo
			endif
		endif

	endif

	cLogTime += "Fim - " + Time() + CRLF
	IncProc("Finalizando...")

	//Alert(cLogTime)

	if !lAuto
		oGridSL1:oBrowse:Refresh()
		oGridSL1:GoTo(iif(len(oGridSL1:aCols)>=nAtSL1,nAtSL1,1))
		CarrDetVend("AtuConfDocs")
		oQtdSL1:Refresh()

		oGridSE5:oBrowse:Refresh()
		oGridSE5:GoTo(iif(len(oGridSE5:aCols)>=nAtSE5,nAtSE5,1))
		CarrDetSE5()
		oQtdSE5:Refresh()

		if lMvPosto
			if lCompens
				oGridUC0:oBrowse:Refresh()
				oGridUC0:GoTo(iif(len(oGridUC0:aCols)>=nAtUC0,nAtUC0,1))
				CarrDetComp()
				oQtdUC0:Refresh()
			endif

			if lValeSrv
				oGridVLS:oBrowse:Refresh()
				oGridVLS:GoTo(iif(len(oGridVLS:aCols)>=nAtVLS,nAtVLS,1))
				CarrDetVlServ()
				oQtdVLS:Refresh()
			endif

			if lRequis
				oGridU57:oBrowse:Refresh()
				oGridU57:GoTo(iif(len(oGridU57:aCols)>=nAtU57,nAtU57,1))
				CarrDetU57()
				oQtdU57:Refresh()
			endif
		endif
	endif

Return

//--------------------------------------------------------------------------------------
// Analisa financeiro de um Cupom na retaguarda
//--------------------------------------------------------------------------------------
Static Function AvalFinSL1(cL1Doc, cL1Serie, lSoSaldo, _lDevol)

	Local lOk := .T.
	Local aRet := {} //{cL1Doc, cL1Serie, lOk, nTotProd, nTotTit, nTotTroDin, cObs, aIdCorrige, nTotTroCht, nTotTroVlh}
	Local aIdCorrige := {}
	Local aDados := {}
	Local aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_CLIENTE","E1_LOJA","E1_VALOR","E1_VLRREAL","E1_SALDO","E1_VENCTO"}
	Local cTipo := ""
	Local nTotProd := nTotTit := nTotTroDin := nTotTroCht := nTotTroVlh := 0
	Local nPosVenda := 0, nY := 0, nX := 0
	Local cObs := ""
	Local lProbVItem := .F.
	Local cDodSerAbst := ""
	Default lSoSaldo := .F. //define se irá avaliar apenas saldo ou tudo
	Default _lDevol := .F. // se tem devolução/Cancelamento

	//conferindo produtos
	if lSoSaldo
		SL1->(DbSetOrder(2)) //L1_FILIAL + L1_SERIE + L1_DOC + L1_PDV
		if SL1->(DbSeek(xFilial("SL1")+cL1Serie+cL1Doc))
			//produtos
			SL2->(DbSetOrder(1))
			If SL2->(DbSeek( xFilial("SL2") + SL1->L1_NUM ))
				While SL2->(!Eof()) .And. SL2->(L2_FILIAL+L2_NUM) == xFilial("SL2") + SL1->L1_NUM

					nTotProd += SL2->L2_VLRITEM

					SL2->(DbSkip())
				EndDo
			endif
		endif
	else
		nPosVenda := aScan(aDadosTop[1], {|x| x[aScan(aCpoSL1,"L1_DOC")]+x[aScan(aCpoSL1,"L1_SERIE")]==cL1Doc+cL1Serie })
		if nPosVenda > 0
			//somando produtos
			For nY := 1 to len(aDadosTop[1][nPosVenda][nPosSL2])
				nTotProd += aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VLRITEM")]

				if empty(aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_STATUS")]) ; //-- ignora notas recuperadas: não valida a consistência dos itens das notas recuperadas pelo Monitor PDV
					.and. Round(aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_QUANT")]*aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_PRCTAB")],2)-aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_DESCPRO")]-aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VALDESC")]+aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_DESPESA")] <> aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VLRITEM")] ;
					.and. NoRound(aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_QUANT")]*aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_PRCTAB")],2)-aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_DESCPRO")]-aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VALDESC")]+aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_DESPESA")] <> aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VLRITEM")]

					lOk := .F.
					aadd(aIdCorrige, "SL2VALOR")
					cObs +=  "Item "+cValToChar(nY)+" -> Inconsistência no valor do item do cupom." + CRLF
					lProbVItem := .T.
				endif
				if lMvPosto
					if empty(aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_MIDCOD")]) .and. !_lDevol
						//verifico se é um combustivel (vendido em bicos)
						if !empty(MHZ->(IndexKey(3)))
							MHZ->(DbSetOrder(3))//MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
							if MHZ->(DbSeek(xFilial("MHZ")+aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_PRODUTO")]))
								lOk := .F.
								aadd(aIdCorrige, "SL2NOABAST")
								cObs +=  "Item "+cValToChar(nY)+" -> Venda de combustível que falta código de abastecimento." + CRLF
							endif
						endif
					elseIf !empty(aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_MIDCOD")]) //!_lDevol
						if !empty(MID->(IndexKey(1)))
							MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
							if !MID->(DbSeek(xFilial("MID")+aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_MIDCOD")]))
								lOk := .F.
								aadd(aIdCorrige, "SL2NOMID")
								cObs +=  "Abastecimento "+aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_MIDCOD")]+ " não encontrado!" + CRLF
							endif
						endif
						
						cDodSerAbst := ""
						SD1->(DbSetOrder(19)) //D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA
						If !SD1->(DbSeek(xFilial("SD1") + cL1Doc+cL1Serie )) .AND. SD1->D1_TIPO <> 'D' //ignora notas devolvidas
							if !U_PodeUseAbast(aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_MIDCOD")], aDadosTop[1][nPosVenda][aScan(aCpoSL1,{|x| x == "L1_NUM"})],,@cDodSerAbst,.T.)
								lOk := .F.
								aadd(aIdCorrige, "ABASTDUPL")
								cObs +=  "Abastecimento "+aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_MIDCOD")]+ " também utilizado em outra venda. " + cDodSerAbst + ". Verifique necessidade de devolução!" + CRLF
							endif
						endif
					endif
				endif
			next nY
			if empty(aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_STATUS")]) ; //-- ignora notas recuperadas: não valida a consistência do total da venda das notas recuperadas pelo Monitor PDV
				.and. nTotProd <> aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_VLRLIQ")]
				lOk := .F.
				lProbVItem := .T.
				aadd(aIdCorrige, "SL2DIFSL1")
				cObs +=  "Total da Venda não confere com total dos itens do cupom." + CRLF
			endif
		endif
	endif

	//buscando total dos titulos
	aDados := BuscaSE1(aCampos, "E1_PREFIXO='"+cL1Serie+"' AND E1_NUM='"+cL1Doc+"' AND E1_TIPO<>'NCC'",,,.T.,.F.)
	For nX:=1 To Len(aDados)

		if aDados[nX][aScan(aCampos,"E1_VLRREAL")] == 0
			nTotTit += aDados[nX][aScan(aCampos,"E1_VALOR")]
		else
			nTotTit += aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		endif

		cTipo := Alltrim(aDados[nX][aScan(aCampos,"E1_TIPO")])
		if !lSoSaldo .AND. cTipo == "CR" //se credito (não tem SL4, considero o que tem em titulos como SL4)
			nPosVenda := aScan(aDadosTop[1], {|x| x[aScan(aCpoSL1,"L1_DOC")]+x[aScan(aCpoSL1,"L1_SERIE")]==cL1Doc+cL1Serie })
			//{"L4_FORMA","L4_VALOR","L4_DATA"}
			aadd(aDadosTop[1][nPosVenda][nPosSL4], { aDados[nX][aScan(aCampos,"E1_TIPO")], aDados[nX][aScan(aCampos,"E1_VALOR")], aDados[nX][aScan(aCampos,"E1_VENCTO")] } )
		endif

		//verificações para os tipos específicos, que deve estar baixados/compensados
		if !lSoSaldo
			if cTipo $ SIMBDIN+",CR"
				SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ 556502
				if SE5->(DbSeek(xFilial("SE5")+cL1Serie+cL1Doc+aDados[nX][aScan(aCampos,"E1_PARCELA")]+aDados[nX][aScan(aCampos,"E1_TIPO")]+aDados[nX][aScan(aCampos,"E1_CLIENTE")]+aDados[nX][aScan(aCampos,"E1_LOJA")] ))
					if aDados[nX][aScan(aCampos,"E1_SALDO")] > 0 //.OR. TemBxCanc() verifica se SE5 posicionado tem estorno/cancelamento
						lOk := .F.
						aadd(aIdCorrige, "SE1NOBX")
						if cTipo == "CR"
							cObs +=  "Titulo do tipo <CR> não compensado com um crédito." + CRLF
						else
							cObs +=  "Titulo "+iif(cTipo == SIMBDIN,"Dinheiro","Fidelidade")+" não baixado." + CRLF
						endif
					endif
					if cTipo == SIMBDIN .AND. aDados[nX][aScan(aCampos,"E1_VALOR")] <> SE5->E5_VALOR
						lOk := .F.
						aadd(aIdCorrige, "SE1BXDIVER")
						cObs +=  "Titulo Dinheiro com valor da baixa divergente do valor do titulo." + CRLF
					endif
				else
					lOk := .F.
					aadd(aIdCorrige, "SE1NOBX")
					if cTipo == "CR"
						cObs +=  "Titulo do tipo <CR> não compensado com um crédito." + CRLF
					else
						cObs +=  "Titulo "+iif(cTipo == SIMBDIN,"Dinheiro","Fidelidade")+" não baixado." + CRLF
					endif
				endif

				if cTipo <> "CR" .AND. aDados[nX][aScan(aCampos,"E1_VLRREAL")] > 0 .AND. aDados[nX][aScan(aCampos,"E1_VLRREAL")] <> aDados[nX][aScan(aCampos,"E1_VALOR")]
					lOk := .F.
					aadd(aIdCorrige, "SE1VLR")
					cObs +=  "Titulo do tipo <"+cTipo+"> com problemas nos campos de valores." + CRLF
				endif
			endif
		endif

	Next nX

	//Troco em Dinheiro
	aDados := {}
	aCampos := {"E5_PREFIXO","E5_NUMERO","E5_NUMMOV","E5_DATA"}
	if SE5->(FieldPos("E5_XPDV")) > 0
		aadd(aCampos,"E5_XPDV")
		aadd(aCampos,"E5_XESTAC")
		aadd(aCampos,"E5_XHORA")
	endif
	nTotTroDin := U_T028TTV(4,@aDados,aCampos,"E5_PREFIXO = '"+cL1Serie+"' AND E5_NUMERO = '"+cL1Doc+"'", .F., .F.)
	//conferindo a chave do caixa nos movimentos de troco venda SE5
	if nTotTroDin > 0
		For nX := 1 to len(aDados)
			//verifico se o movimento está fora da chave do caixa
			if SE5->(FieldPos("E5_XPDV")) > 0
				if aDados[nX][3] <> SLW->LW_NUMMOV ;
					.OR. Alltrim(aDados[nX][5]) <> Alltrim(SLW->LW_PDV) ;
					.OR. aDados[nX][6] <> SLW->LW_ESTACAO;
					.OR. DTOS(aDados[nX][4])+aDados[nX][7] < DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT ;
					.OR. DTOS(aDados[nX][4])+aDados[nX][7] > DTOS(iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA))+iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,5),SLW->LW_HRFECHA)

					lOk := .F.
					aadd(aIdCorrige, "SE5TROCOCHAVE")
					cObs +=  "Movimento de troco encontrado, mas a chave do caixa não preenchida corretamente no registro." + CRLF
				endif
			else
				if aDados[nX][3] <> SLW->LW_NUMMOV ;
					.OR. DTOS(aDados[nX][4]) < DTOS(SLW->LW_DTABERT) ;
					.OR. DTOS(aDados[nX][4]) > DTOS(iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA))

					lOk := .F.
					aadd(aIdCorrige, "SE5TROCOCHAVE")
					cObs +=  "Movimento de troco encontrado, mas a chave do caixa não preenchida corretamente no registro." + CRLF
				endif
			endif
		next nX
	endif
	
	//Cheque Troco
	if lMvPosto .AND. SuperGetMV("TP_ACTCHT",,.F.)
		nTotTroCht := AvalUF2(cL1Doc, cL1Serie, Alltrim(SLW->LW_PDV), @lOK, @cObs, @aIdCorrige)
	endif
	//Vale Haver Emitido
	if lMvPosto .AND. SuperGetMV("TP_ACTVLH",,.F.)
		nTotTroVlh := U_T028TVLH(4,,, cL1Doc, cL1Serie)
	endif

	//verifico se zerou saldo
	if lOk .AND. (nTotTit - nTotProd - nTotTroDin - nTotTroCht - nTotTroVlh) <> 0
		lOk := .F.
		cObs +=  "Saldo da venda não zerado." + CRLF
		if nTotTit - nTotProd < 0
			aadd(aIdCorrige, "SE1DIFSL1") //TOTAL RECEBIDO MENOR QUE O TOTAL DA VENDA

			SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			if SL1->(DbSeek(xFilial("SL1")+cL1Serie+cL1Doc+AllTrim(SLW->LW_PDV)))
				if SL1->L1_SITUA == "ER"
					cObs += "Não foi processada a geração financeira dessa venda (Gravabatch). Utilize botão Corrigir Venda." + CRLF
					if SL1->(FieldPos("L1_ERGRVBT")) > 0
						cObs += "("+SL1->L1_ERGRVBT+")"
					endif
				endif
			endif
		elseif !lProbVItem
			aadd(aIdCorrige, "SL1TROCO") //INCONSISTENCIA NO VALOR DO TROCO DO CUPOM
		endif
	endif

	if lOk
		cObs +=  "Venda sem pendências." + CRLF
	endif

	aRet := {cL1Doc, cL1Serie, lOk, nTotProd, nTotTit, nTotTroDin, cObs, aIdCorrige, nTotTroCht, nTotTroVlh}

Return aRet

//--------------------------------------------------------------------------------------
// Avalia financeiro da compensação
//--------------------------------------------------------------------------------------
Static Function AvalFinUC0(cNumComp, lEstorno)

	Local lOk := .T.
	Local aRet := {} //{cNumComp, lOk, nTotEntrada, nTotTroDin, nTotTroCht, nTotTroVlh, cObs, aIdCorrige}
	Local aIdCorrige := {}
	Local aDados := {}
	Local aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_CLIENTE","E1_LOJA","E1_VALOR","E1_VLRREAL"}
	Local nTotEntrada := nTotTroDin := nTotTroCht := nTotTroVlh := 0
	Local nPosComp := 0, nX := 0
	Local cObs := ""
	Local lCancel := .F.
	Local cPrefixComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)

	cPrefixComp := SubStr(cPrefixComp,1,TamSX3("UF2_SERIE")[1])
	nPosComp := aScan(aDadosTop[3], {|x| x[aScan(aCpoUC0,"UC0_NUM")] == cNumComp })
	if nPosComp > 0
		lCancel := aDadosTop[3][nPosComp][aScan(aCpoUC0,"UC0_ESTORN")] $ "SX"
	endif

	//verifico entradas
	aDados := BuscaSE1(aCampos,"E1_PREFIXO = '"+cPrefixComp+"' AND E1_NUM = '"+cNumComp+"' ",,,.F.,.T.,.T.)
	For nX:=1 To Len(aDados)
		if Alltrim(aDados[nX][aScan(aCampos,"E1_TIPO")]) == "NCC"
			nTotTroDin += aDados[nX][aScan(aCampos,"E1_VALOR")]
			SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
			if SE5->(DbSeek(xFilial("SE5")+cPrefixComp+cNumComp+aDados[nX][aScan(aCampos,"E1_PARCELA")]+aDados[nX][aScan(aCampos,"E1_TIPO")]+aDados[nX][aScan(aCampos,"E1_CLIENTE")]+aDados[nX][aScan(aCampos,"E1_LOJA")] ))
				if TemBxCanc() //verifica se SE5 posicionado tem estorno/cancelamento
					lOk := .F.
					cObs +=  "Titulo saída em dinheiro não baixado." + CRLF
				endif
			else
				lOk := .F.
				cObs +=  "Titulo saída em dinheiro não baixado." + CRLF
			endif
		else
			if empty(aDados[nX][aScan(aCampos,"E1_VLRREAL")])
				nTotEntrada += aDados[nX][aScan(aCampos,"E1_VALOR")]
			else
				nTotEntrada += aDados[nX][aScan(aCampos,"E1_VLRREAL")]
			endif
		endif
	Next
	if !lCancel .AND. empty(nTotEntrada)
		lOk := .F.
		cObs := "Os titulos financeiros de entrada da compensação não foram gerados!" + CRLF
	endif

	//Cheque Troco
	if SuperGetMV("TP_ACTCHT",,.F.)
		nTotTroCht := AvalUF2(cNumComp, cPrefixComp, Alltrim(SLW->LW_PDV), @lOK, @cObs, @aIdCorrige)
	endif

	//Vale Haver
	if SuperGetMV("TP_ACTVLH",,.F.)
		nTotTroVlh := U_T028TVLH(4, , , cNumComp, cPrefixComp)
	endif

	//verifico se zerou saldo
	if lOk .AND. (nTotEntrada - nTotTroDin - nTotTroCht - nTotTroVlh) <> 0
		lOk := .F.
		cObs +=  "Saldo da compensação não zerado." + CRLF
	endif

	if lEstorno .AND. (nTotEntrada + nTotTroDin + nTotTroCht + nTotTroVlh) > 0
		lOk := .F.
		cObs +=  "Compensaçao estornada, mas com financeiro ativo." + CRLF
	endif

	if lOk
		cObs +=  "Compensação sem pendências." + CRLF
	endif

	aRet := {cNumComp, lOk, nTotEntrada, nTotTroDin, nTotTroCht, nTotTroVlh, cObs, aIdCorrige}

Return aRet

//--------------------------------------------------------------------------------------
// Avalia se tem cheque troco e se gerou financeiro corretamente
//--------------------------------------------------------------------------------------
Static Function AvalUF2(cDoc, cSerie, cPdv, lOK, cObs, aIdCorrige, cChvCheq, lSoUF2)

	Local cQry
	Local nRet := 0, nX := 0
	Local nValUF2 := 0
	Local nValSEF := 0
	Local nValSEFLIB := 0
	Local nValSE5 := 0
	Local aChvsCheq := {}

	Default cDoc := ""
	Default cSerie := ""
	Default cPdv := ""
	Default lOK := .T.
	Default cObs := ""
	Default aIdCorrige := {}
	Default cChvCheq := ""
	Default lSoUF2 := .F.

	//verifico se tem UF2
	cQry:= "SELECT 'UF2' TABELA, UF2_VALOR VALOR, (UF2_BANCO||UF2_AGENCI||UF2_CONTA||UF2_NUM) CHAVCHQ, UF2.R_E_C_N_O_ RECNO, UF2_STATUS STATUS "
	cQry+= "FROM "+RetSqlName("UF2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UF2 "
	cQry+= "WHERE UF2.D_E_L_E_T_ = ' ' "
	cQry+= "  AND UF2_FILIAL = '"+xFilial("UF2")+"' "
	if cSerie == "CODBAR" .AND. !empty(cDoc)
		cQry+= "  AND UF2_CODBAR = '"+cDoc+"'"
	elseif !empty(cDoc+cSerie+cPdv)
		cQry+= "  AND (UF2_DOC||UF2_SERIE||RTRIM(UF2_PDV)) = '"+cDoc+cSerie+cPdv+"' "
	endif
	if !empty(cChvCheq)
		cQry+= "  AND (UF2_BANCO||UF2_AGENCI||UF2_CONTA||UF2_NUM) = '"+cChvCheq+"'"
	endif

	if !lSoUF2
		cQry+= "UNION "

		//verifico se tem SEF
		cQry+= "SELECT 'SEF' TABELA, EF_VALOR VALOR, (EF_BANCO||EF_AGENCIA||EF_CONTA||EF_NUM) CHAVCHQ, SEF.R_E_C_N_O_ RECNO, '' STATUS "
		cQry+= "FROM "+RetSqlName("SEF")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SEF "
		cQry+= "WHERE SEF.D_E_L_E_T_ = ' ' "
		cQry+= "  AND EF_FILIAL = '"+xFilial("SEF")+"' "
		if cSerie == "CODBAR" .AND. !empty(cDoc)
			cQry+= "  AND EF_XCODBAR = '"+cDoc+"'"
		elseif !empty(cDoc+cSerie+cPdv)
			cQry+= "  AND (EF_NUMNOTA||EF_SERIE||RTRIM(EF_XPDV)) = '"+cDoc+cSerie+cPdv+"' "
		endif
		cQry+= "  AND EF_HIST LIKE 'CHEQUE TROCO NO PDV' "
		if !empty(cChvCheq)
			cQry+= "  AND (EF_BANCO||EF_AGENCIA||EF_CONTA||EF_NUM) = '"+cChvCheq+"'"
		endif

		cQry+= "UNION "

		//verifico se tem SE5
		if cSerie == "CODBAR" .AND. !empty(cDoc)
			cQry+= "SELECT 'SE5' TABELA, E5_VALOR VALOR, (TUF2.UF2_BANCO||TUF2.UF2_AGENCI||TUF2.UF2_CONTA||TUF2.UF2_NUM) CHAVCHQ, SE5.R_E_C_N_O_ RECNO, '' STATUS "
			cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
			cQry+= "INNER JOIN "+RetSqlName("UF2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" TUF2  "
			cQry+= "	ON (TUF2.D_E_L_E_T_ = ' '  "
			cQry+= "		AND TUF2.UF2_FILIAL = SE5.E5_FILIAL  "
			cQry+= "		AND TUF2.UF2_DOC = SE5.E5_NUMERO "
			cQry+= "		AND TUF2.UF2_SERIE = SE5.E5_PREFIXO "
			cQry+= "		AND TUF2.UF2_BANCO = SE5.E5_BANCO "
			cQry+= "		AND TUF2.UF2_AGENCI = SE5.E5_AGENCIA "
			cQry+= "		AND TUF2.UF2_CONTA = SE5.E5_CONTA "
			cQry+= "		AND TUF2.UF2_NUM = SE5.E5_NUMCHEQ) "
			cQry+= "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
			cQry+= "  AND E5_TIPODOC IN ('CA','CH') "
			cQry+= "  AND E5_NUMCHEQ <> ' ' " //cheque preenchido
			cQry+= "  AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C'"
			cQry+= "  AND TUF2.UF2_CODBAR = '"+cDoc+"'"
			if !empty(cChvCheq)
				cQry+= "  AND (TUF2.UF2_BANCO||TUF2.UF2_AGENCI||TUF2.UF2_CONTA||TUF2.UF2_NUM) = '"+cChvCheq+"'"
			endif
		else
			cQry+= "SELECT 'SE5' TABELA, E5_VALOR VALOR, (E5_BANCO||E5_AGENCIA||E5_CONTA||E5_NUMCHEQ) CHAVCHQ, SE5.R_E_C_N_O_ RECNO, '' STATUS "
			cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
			cQry+= "WHERE SE5.D_E_L_E_T_ = ' ' "
			cQry+= "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
			cQry+= "  AND E5_TIPODOC IN ('CA','CH') "
			cQry+= "  AND E5_NUMCHEQ <> ' ' " //cheque preenchido
			cQry+= "  AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C'"
			if !empty(cDoc+cSerie+cPdv)
				cQry+= "  AND E5_PREFIXO = '"+cSerie+"' "
				cQry+= "  AND E5_NUMERO = '"+cDoc+"' "
				cQry+= "  AND E5_XPDV = '"+cPdv+"' "
			endif
			if !empty(cChvCheq)
				cQry+= "  AND (E5_BANCO||E5_AGENCIA||E5_CONTA||E5_NUMCHEQ) = '"+cChvCheq+"'"
			endif
		endif

	endif

	if Select("QRYCHT") > 0
		QRYCHT->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYCHT" // Cria uma nova area com o resultado do query

	SE5->(DbSetOrder(7))
	While QRYCHT->(!Eof())
		if QRYCHT->TABELA == "UF2" .AND. QRYCHT->STATUS == "2" //somente se estiver usado vou somar o valor
			nValUF2 += QRYCHT->VALOR
		elseif QRYCHT->TABELA == "SEF"
			nValSEF += QRYCHT->VALOR
			SEF->(DbGoTo(QRYCHT->RECNO))
			if SEF->(!Eof()) .and. (SEF->EF_LIBER == "S") // => considera somente os cheque troco com financeiro
				nValSEFLIB += QRYCHT->VALOR
			endif
		elseif QRYCHT->TABELA == "SE5"
			nValSE5 += QRYCHT->VALOR
		elseif QRYCHT->TABELA == "E5-" //estornos
			nValSE5 -= QRYCHT->VALOR
		endif

		//monto chave dos cheques que serão avalidados
		if !lSoUF2
			if empty(cChvCheq) .AND. aScan(aChvsCheq, QRYCHT->CHAVCHQ)==0
				aadd(aChvsCheq, QRYCHT->CHAVCHQ)
			endif
		endif
		QRYCHT->(DbSkip())
	EndDo
	QRYCHT->(DbCloseArea())

	//se valores são diferentes, está com problemas
	if !lSoUF2
		if nValUF2 <> nValSEF
			lOk := .F.
			aadd(aIdCorrige, "UF2DIFSEF")
			cObs +=  "Pendencia financeira de cheque troco (SEF)." + CRLF
		elseif (nValSE5 > 0) .and. (nValSEFLIB <> nValSE5) // considera validação, somente quando cheque troco com financeiro
			lOk := .F.
			aadd(aIdCorrige, "SEFDIFSE5")
			cObs +=  "Pendencia financeira de cheque troco (SE5)." + CRLF
		endif
	endif

	nRet := nValUF2

	//reavalio pela chave do cheque
	if !lSoUF2 .AND. lOk .AND. empty(cChvCheq)
		For nX := 1 to len(aChvsCheq)
			AvalUF2(,,,@lOK,@cObs,@aIdCorrige,aChvsCheq[nX] )
		next nX
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Avalia se recebimento está ok
//--------------------------------------------------------------------------------------
Static Function AvalFinVLS(cUIC_AMB, cUIC_COD, nVlrServico, lEstorn)

	Local lOk := .T.
	Local aRet := {} //{cChavVLS, lOk, nVlrServico, nVlrReceb, nVlrPagar, cObs}
	Local cChavVLS := cUIC_AMB + cUIC_COD
	Local nVlrReceb := nVlrPagar := 0
	Local cObs := ""
	Local cTipo := Posicione("UIC",1,xFilial("UIC")+cUIC_AMB+cUIC_COD,"UIC_TIPO")
	Local lTitPag := .T.

	//verifico se para o fornecedor tem que gerar SE2
	UH8->(DbGoTop())
	If UH8->(DbSeek(xFilial("UH8")+UIC->UIC_FORNEC+UIC->UIC_LOJAF))
		If UH8->UH8_TITAPG == "N" // Não Gera título a pagar
			lTitPag := .F.
		endif
	else
		lOk := .F.
		cObs := "Cadastro do Prestador do serviço não encontrado" + CRLF
	endif

	cQry:= " SELECT 'SE1' TAB, E1_VALOR VALOR, E1_TIPO TIPO, E1_SALDO SALDO "
	cQry+= " FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
	cQry+= " WHERE SE1.D_E_L_E_T_ = ' ' "
	cQry+= "  AND E1_FILIAL = '"+xFilial("SE1")+"' "
	cQry+= "  AND E1_PREFIXO = '"+cUIC_AMB+"' "
	cQry+= "  AND E1_NUM = '"+cUIC_COD+"' "
	cQry+= "  AND E1_TIPO = 'VLS' "
	cQry+= "  AND NOT EXISTS ( SELECT 1 FROM "+RetSqlName("SE6")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE6 WHERE SE6.D_E_L_E_T_= ' ' AND E6_FILIAL = E1_FILIAL AND E6_PREFIXO = E1_PREFIXO AND E6_NUM = E1_NUM AND E6_PARCELA = E1_PARCELA AND E6_TIPO = E1_TIPO)"

	cQry+= " UNION "

	cQry+= " SELECT 'SE2' TAB, E2_VALOR VALOR, E2_TIPO TIPO, E2_SALDO SALDO "
	cQry+= " FROM "+RetSqlName("SE2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE2 "
	cQry+= " WHERE SE2.D_E_L_E_T_ = ' ' "
	cQry+= "  AND E2_FILIAL = '"+xFilial("SE1")+"' "
	cQry+= "  AND E2_PREFIXO = '"+cUIC_AMB+"' "
	cQry+= "  AND E2_NUM = '"+cUIC_COD+"' "
	cQry+= "  AND E2_TIPO = 'VLS' "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query
	While QRYT1->(!Eof())

		if QRYT1->TAB == "SE1"
			nVlrReceb += QRYT1->VALOR

			//se pré paga deve estar baixado
			if cTipo == "R" .AND. QRYT1->SALDO > 0
				lOk := .F.
				cObs := "Titulo do recebimento do vale serviço pré-pago não baixado." + CRLF
			endif
		else
			nVlrPagar += QRYT1->VALOR
		endif

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if lEstorn .AND. (nVlrReceb+nVlrPagar) > 0
		lOk := .F.
		cObs := "Estorno do vale serviço com falhas! Ainda existem titulos referentes a este vale serviço. Tente reprocessar o vale serviço." + CRLF
	elseif !lEstorn
		if (nVlrReceb+nVlrPagar) <= 0
			lOk := .F.
			cObs := "Financeiro do vale serviço nao gerado! Tente reprocessar o vale serviço." + CRLF
		//elseif (nVlrReceb <> nVlrPagar .OR. nVlrReceb <> nVlrServico)
		elseif nVlrReceb <> nVlrServico .OR. (lTitPag .AND. nVlrPagar <> nVlrServico)
			lOk := .F.
			cObs := "Valores financeiros diferentes do valor do vale serviço. Tente reprocessar o vale serviço." + CRLF
		endif
	endif

	if lOk
		cObs := "Vale Serviço sem pendências."
	endif

	aRet := {cChavVLS, lOk, nVlrServico, nVlrReceb, nVlrPagar, cObs}

Return aRet

//--------------------------------------------------------------------------------------
// Avalia se financeiro Saque ou deposito está ok
//--------------------------------------------------------------------------------------
Static Function AvalFinU57(cU57TDoc, cU57_PFX, cU57_COD, cU57_PAR)

	Local aAreaU57 := U57->(GetArea())
	Local lOk := .T.
	Local aRet := {} //{cChavU57, lOk, nVlrU57, nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}
	Local cChavU57 := cU57TDoc + cU57_PFX + cU57_COD + cU57_PAR
	Local nVlrU57 := nVlrReceb := nVlrCredi := nVlrDin := nVlrCHT := nVlrSaque := 0
	Local cObs := "", cQry := ""
	Local lChavRA := .T.

	U57->(DBSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	if U57->(DbSeek(xFilial("U57")+cU57_PFX+cU57_COD+cU57_PAR ))
		nVlrU57 := iif(U57->U57_XGERAF=="D",0,U57->U57_VALOR)
		nVlrSaque := iif(U57->U57_XGERAF=="D" .OR. empty(U57->U57_XGERAF),0,U57->U57_VALSAQ)
	endif

	cQry := "SELECT SE1.R_E_C_N_O_ RECNO "
	cQry += "FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
	cQry += "WHERE D_E_L_E_T_ = ' ' "
	cQry += "	AND E1_XCODBAR = '"+cU57_PFX+cU57_COD+cU57_PAR+"' "

	if Select("QRYSE1") > 0
		QRYSE1->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

	SE5->(DbSetOrder(7))
	While QRYSE1->(!Eof())
		SE1->(DbGoTo(QRYSE1->RECNO))

		if SE1->E1_TIPO == "NCC" 
			if cU57TDoc != "DEPOSITO"
				nVlrDin += BuscaE5_U57() //quando saque (mutuo), busca valor credito baixado na filial destino
				if cU57TDoc == "VALE MOTORISTA"
					nVlrCredi += SE1->E1_VALOR
				endif
			endif
		elseif SE1->E1_TIPO == "RA "
			if cU57TDoc == "SAQUE"
				if SE1->E1_FILIAL == xFilial("SE1",iif(empty(U57->U57_FILSAQ),Nil,U57->U57_FILSAQ)) //propria filial
					nVlrDin += BuscaE5_U57()
				else //quando mutuo
					nVlrReceb += SE1->E1_VALOR //valor titulo do credito filial origem
					nVlrCredi += BuscaE5_U57() //busco baixa do credito filial origem
				endif
			else //deposito
				lChavRA := .T.
				nVlrCredi += BuscaE5_U57(@lChavRA)
				if !lChavRA
					lOk := .F.
					cObs += "Movimento do RA nao amarrado ao caixa. Tente reprocessar o depósito para corrigir." + CRLF
				endif
			endif
		else //outros tipos
			nVlrReceb += SE1->E1_VALOR
		endif

		QRYSE1->(DbSkip())
	EndDo
	QRYSE1->(DbCloseArea())

	//buscar cheque troco pelo codbar
	if cU57TDoc <> "DEPOSITO" .AND. SuperGetMV("TP_ACTCHT",,.F.)
		nVlrCHT := AvalUF2(cU57_PFX+cU57_COD+cU57_PAR, "CODBAR", , @lOK, @cObs)
	endif

	//verifico se zerou saldo
	if (iif(cU57TDoc<>"DEPOSITO",nVlrSaque,nVlrU57) + nVlrReceb - nVlrCredi - nVlrDin - nVlrCHT) <> 0
		lOk := .F.
		cObs +=  "O valor da requisição divergente do valor financeiro. Saldo do "+Capital(cU57TDoc)+" não zerado." + CRLF
	endif

	if lOk
		cObs +=  Capital(cU57TDoc) + " sem pendências." + CRLF
	endif

	aRet := {cChavU57, lOk, iif(cU57TDoc<>"DEPOSITO",nVlrSaque,nVlrU57), nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}

	RestArea(aAreaU57)

Return aRet

//--------------------------------------------------------------------------------------
// busca SE5 de baixa do credito do saque
//--------------------------------------------------------------------------------------
Static Function BuscaE5_U57(lChavRA)

	Local cQry
	Local nRet := 0
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Default lChavRA := .F.

	cQry := "SELECT E5_VALOR VALOR, SE5.R_E_C_N_O_ RECNO "
	cQry += "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
	cQry += "WHERE D_E_L_E_T_ = ' ' "
	cQry += "	AND E5_FILIAL = '"+SE1->E1_FILIAL+"' "
	cQry += "	AND E5_NUMERO = '"+SE1->E1_NUM+"' "
	cQry += "	AND E5_PREFIXO = '"+SE1->E1_PREFIXO+"' "
	cQry += "	AND E5_PARCELA = '"+SE1->E1_PARCELA+"' "
	cQry += "	AND E5_TIPO = '"+SE1->E1_TIPO+"' "
	if lChavRA
		cQry += "	AND E5_TIPODOC = 'RA' "
		cQry += "	AND E5_MOTBX = 'NOR' "
		cQry += "	AND E5_RECPAG = 'R' "
	else
		cQry += "	AND E5_TIPODOC = 'VL' "
		cQry += "	AND E5_MOTBX IN ('DEB','TRF') "//debito ou tranferencia mutuo
		cQry += "	AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C'"
	endif
	cQry += "	AND (E5_BANCO = '"+SLW->LW_OPERADO+"' OR E5_MOTBX = 'TRF')"

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	SE5->(DbSetOrder(7))
	While QRYT1->(!Eof())
		SE5->(DbGoTo(QRYT1->RECNO))
		If !SE5->(TemBxCanc())
			nRet += QRYT1->VALOR

			//if SE5->E5_XPDV+SE5->E5_XESTAC+SE5->E5_NUMMOV+SE5->E5_XHORA <> U57->U57_XPDV+U57->U57_XESTAC+U57->U57_XNUMMO+U57->U57_XHORA
			if Alltrim(SE5->E5_XPDV)+SE5->E5_XESTAC+SE5->E5_NUMMOV <> Alltrim(SLW->LW_PDV)+SLW->LW_ESTACAO+SLW->LW_NUMMOV .AND. SUBSTR(SE5->E5_XHORA,1,nTamHora) >= SLW->LW_HRABERT .AND. SUBSTR(SE5->E5_XHORA,1,nTamHora) <= SLW->LW_HRFECHA
				lChavRA := .F.
			endif

		endif
		QRYT1->(DbSkip())
	EndDo
	QRYT1->(DbCloseArea())

Return nRet

//--------------------------------------------------------------------------------------
// Atualiza detalhe da venda
//--------------------------------------------------------------------------------------
Static Function CarrDetVend(cOrig)

	Local nPosVenda := 0, nY := 0
	Local nPosDoc := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_DOC"})
	Local nPosSer := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_SERIE"})
	Local cDocSer := oGridSL1:aCols[oGridSL1:nAt][nPosDoc]+oGridSL1:aCols[oGridSL1:nAt][nPosSer]

	oBrrSL1Pdv:Limpa()
	oBrrSL1Top:Limpa()
	oBrrSL1Fin:Limpa()

	if !empty(cDocSer)
		//ATUALIZANDO TOTAIS PDV
		if !empty(aDadosPdv) .AND. !empty(aDadosPdv[1])
			nPosVenda := aScan(aDadosPdv[1], {|x| x[aScan(aCpoSL1,"L1_DOC")]+x[aScan(aCpoSL1,"L1_SERIE")] == cDocSer })
			if nPosVenda > 0
				//somando prodtos
				For nY := 1 to len(aDadosPdv[1][nPosVenda][nPosSL2])
					oBrrSL1Pdv:nTotPrd += aDadosPdv[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VLRITEM")]
				next nY

				//somando recebidos
				For nY := 1 to len(aDadosPdv[1][nPosVenda][nPosSL4])
					oBrrSL1Pdv:nTitRec += aDadosPdv[1][nPosVenda][nPosSL4][nY][aScan(aCpoSL4,"L4_VALOR")]
				next nY
				If aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_CREDITO")] > 0 .AND. oBrrSL1Pdv:nTitRec == 0
					oBrrSL1Pdv:nTitRec += aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_CREDITO")] + aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_XTROCVL")]
				Else
					oBrrSL1Pdv:nTitRec += aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_CREDITO")]
				EndIf

				//troco dinheiro
				oBrrSL1Pdv:nTrocoDin := aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_TROCO1")]

				//trocos posto
				if lMvPosto .AND. SuperGetMV("TP_ACTCHT",,.F.)
					oBrrSL1Pdv:nTrocoCht := aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_XTROCCH")]
				endif

				if lMvPosto .AND. SuperGetMV("TP_ACTVLH",,.F.)
					oBrrSL1Pdv:nTrocoVlh := aDadosPdv[1][nPosVenda][aScan(aCpoSL1,"L1_XTROCVL")]
				endif
			endif
		Endif

		//ATUALIZANDO TOTAIS RETAGUARDA
		if !empty(aDadosTop) .AND. !empty(aDadosTop[1])
			nPosVenda := aScan(aDadosTop[1], {|x| x[aScan(aCpoSL1,"L1_DOC")]+x[aScan(aCpoSL1,"L1_SERIE")] == cDocSer })
			if nPosVenda > 0
				//somando produtos
				For nY := 1 to len(aDadosTop[1][nPosVenda][nPosSL2])
					oBrrSL1Top:nTotPrd += aDadosTop[1][nPosVenda][nPosSL2][nY][aScan(aCpoSL2,"L2_VLRITEM")]
				next nY

				//somando recebidos
				For nY := 1 to len(aDadosTop[1][nPosVenda][nPosSL4])
					oBrrSL1Top:nTitRec += aDadosTop[1][nPosVenda][nPosSL4][nY][aScan(aCpoSL4,"L4_VALOR")]
				next nY
				if aScan(aDadosTop[1][nPosVenda][nPosSL4],{|x| Alltrim(x[1])=="CR" }) == 0
					oBrrSL1Top:nTitRec += aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_CREDITO")]
				endif

				//troco dinheiro
				oBrrSL1Top:nTrocoDin := aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_TROCO1")]

				//trocos posto
				if lMvPosto .AND. SuperGetMV("TP_ACTCHT",,.F.)
					oBrrSL1Top:nTrocoCht := aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_XTROCCH")]
				endif

				if lMvPosto .AND. SuperGetMV("TP_ACTVLH",,.F.)
					oBrrSL1Top:nTrocoVlh := aDadosTop[1][nPosVenda][aScan(aCpoSL1,"L1_XTROCVL")]
				endif
			endif
		Endif

		//ATUALIZANDO TOTAIS FINANCEIROS
		if !empty(aDadosFin) .AND. !empty(aDadosFin[1])
			//aDadosFin: {DOC, SERIE, lOk, nTotProd, nTotTit, nTotTroDin, cObs}
			nPosVenda := aScan(aDadosFin[1], {|x| x[1]+x[2] == cDocSer })
			if nPosVenda > 0
				oBrrSL1Fin:nTotPrd := aDadosFin[1][nPosVenda][4]
				oBrrSL1Fin:nTitRec := aDadosFin[1][nPosVenda][5]
				oBrrSL1Fin:nTrocoDin := aDadosFin[1][nPosVenda][6]
				if lMvPosto
					oBrrSL1Fin:nTrocoCht := aDadosFin[1][nPosVenda][9]
					oBrrSL1Fin:nTrocoVlh := aDadosFin[1][nPosVenda][10]
				endif
				cObsSL1 := aDadosFin[1][nPosVenda][7]
			endif
		endif

	endif

	oBrrSL1Pdv:Refresh()
	oBrrSL1Top:Refresh()
	oBrrSL1Fin:Refresh()
	oObsSL1:Refresh()

Return

//--------------------------------------------------------------------------------------
// Funçao que atualizad dados de troco final/inicia/suprimento/sangria SE5
//--------------------------------------------------------------------------------------
Static Function CarrDetSE5()

	Local nPosDat := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_DATA"})
	Local nPosLEG := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="LEG3"})
	Local nPosFIl := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_FILIAL"})

	if !empty(oGridSE5:aCols[oGridSE5:nAt][nPosDat])
		if oGridSE5:aCols[oGridSE5:nAt][nPosLEG] == "BR_VERMELHO"
			cObsSE5 := "Movimento de " + Capital(Alltrim(oGridSE5:aCols[oGridSE5:nAt][nPosFIl])) + " não localizado na retaguarda." + CRLF
		else
			cObsSE5 := Capital(Alltrim(oGridSE5:aCols[oGridSE5:nAt][nPosFIl])) + " sem pendências." + CRLF
		endif
	endif
	oObsSE5:Refresh()

Return

//--------------------------------------------------------------------------------------
// Atualiza detalhe compensaçao
//--------------------------------------------------------------------------------------
Static Function CarrDetComp()

	Local nPosComp := 0, nY := 0
	Local nPosNumComp := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="UC0_NUM"})
	Local cNumComp := oGridUC0:aCols[oGridUC0:nAt][nPosNumComp]

	oBrrUC0Pdv:Limpa()
	oBrrUC0Top:Limpa()
	oBrrUC0Fin:Limpa()

	if !empty(cNumComp)
		//ATUALIZANDO TOTAIS PDV
		if !empty(aDadosPdv[3])
			nPosComp := aScan(aDadosPdv[3], {|x| x[aScan(aCpoUC0,"UC0_NUM")] == cNumComp })
			if nPosComp > 0
				//somando recebidos
				For nY := 1 to len(aDadosPdv[3][nPosComp][nPosUC1])
					oBrrUC0Pdv:nValEntrada += aDadosPdv[3][nPosComp][nPosUC1][nY][aScan(aCpoUC1,"UC1_VALOR")]
				next nY

				//saidas
				oBrrUC0Pdv:nValDin := aDadosPdv[3][nPosComp][aScan(aCpoUC0,"UC0_VLDINH")]
				oBrrUC0Pdv:nValCht := aDadosPdv[3][nPosComp][aScan(aCpoUC0,"UC0_VLCHTR")]
				oBrrUC0Pdv:nValVlh := aDadosPdv[3][nPosComp][aScan(aCpoUC0,"UC0_VLVALE")]
			endif
		Endif

		//ATUALIZANDO TOTAIS RETAGUARDA
		if !empty(aDadosTop[3])
			nPosComp := aScan(aDadosTop[3], {|x| x[aScan(aCpoUC0,"UC0_NUM")] == cNumComp })
			if nPosComp > 0
				//somando recebidos
				For nY := 1 to len(aDadosTop[3][nPosComp][nPosUC1])
					oBrrUC0Top:nValEntrada += aDadosTop[3][nPosComp][nPosUC1][nY][aScan(aCpoUC1,"UC1_VALOR")]
				next nY

				//saidas
				oBrrUC0Top:nValDin := aDadosTop[3][nPosComp][aScan(aCpoUC0,"UC0_VLDINH")]
				oBrrUC0Top:nValCht := aDadosTop[3][nPosComp][aScan(aCpoUC0,"UC0_VLCHTR")]
				oBrrUC0Top:nValVlh := aDadosTop[3][nPosComp][aScan(aCpoUC0,"UC0_VLVALE")]
			endif
		Endif

		//ATUALIZANDO TOTAIS FINANCEIROS
		if !empty(aDadosFin[2])
			//aDadosFin: {cNumComp, lOk, nTotEntrada, nTotTroDin, nTotTroCht, nTotTroVlh, cObs, aIdCorrige}
			nPosComp := aScan(aDadosFin[2], {|x| x[1] == cNumComp })
			if nPosComp > 0
				oBrrUC0Fin:nValEntrada := aDadosFin[2][nPosComp][3]
				oBrrUC0Fin:nValDin := aDadosFin[2][nPosComp][4]
				oBrrUC0Fin:nValCht := aDadosFin[2][nPosComp][5]
				oBrrUC0Fin:nValVlh := aDadosFin[2][nPosComp][6]

				cObsUC0 := aDadosFin[2][nPosComp][7]
			endif
		endif

	endif

	oBrrUC0Pdv:Refresh()
	oBrrUC0Top:Refresh()
	oBrrUC0Fin:Refresh()
	oObsUC0:Refresh()

Return

//--------------------------------------------------------------------------------------
// Atualiza detalhe vale serviço
//--------------------------------------------------------------------------------------
Static Function CarrDetVlServ()

	Local nPosTipo := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_TIPO"})
	Local nPosAMB := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_AMB"})
	Local nPosCOD := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_CODIGO"})
	Local cChavVLS := oGridVLS:aCols[oGridVLS:nAt][nPosAMB]+oGridVLS:aCols[oGridVLS:nAt][nPosCOD]
	Local nPosUIC := 0

	oBrrVLS:Limpa()

	//aDadosFin {cChavVLS, lOk, nVlrServico, nVlrReceb, nVlrPagar, cObs}
	if !empty(cChavVLS)
		if !empty(aDadosFin[3])
			nPosUIC := aScan(aDadosFin[3], {|x| x[1] == cChavVLS })
			if nPosUIC > 0

				oBrrVLS:nVlrServico := aDadosFin[3][nPosUIC][3]
				oBrrVLS:nVlrReceb  := aDadosFin[3][nPosUIC][4]
				oBrrVLS:nVlrPagar := aDadosFin[3][nPosUIC][5]

				if oGridVLS:aCols[oGridVLS:nAt][nPosTipo] == "R" //se pré
					oBrrVLS:cLblReceb := "Valor Recebido"
				else
					oBrrVLS:cLblReceb := "Titulo a Receber"
				endif

				cObsVLS := aDadosFin[3][nPosUIC][6]
			endif
		endif
	endif

	oBrrVLS:Refresh()
	oObsVLS:Refresh()

Return

//--------------------------------------------------------------------------------------
// Atualiza detalhe vale serviço
//--------------------------------------------------------------------------------------
Static Function CarrDetU57()

	Local nPosTDoc := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_FILIAL"})
	Local nPosPFX := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})
	Local nPosCOD := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})
	Local nPosPRC := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})
	Local cChavU57 := oGridU57:aCols[oGridU57:nAt][nPosTDoc]+oGridU57:aCols[oGridU57:nAt][nPosPFX]+oGridU57:aCols[oGridU57:nAt][nPosCOD]+oGridU57:aCols[oGridU57:nAt][nPosPRC]
	Local nPosU57 := 0

	oBrrU57:Limpa()

	//aDadosFin {cChavU57, lOk, nVlrU57, nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}
	if !empty(cChavU57)
		if !empty(aDadosFin[4])
			nPosU57 := aScan(aDadosFin[4], {|x| x[1] == cChavU57 })
			if nPosU57 > 0

				oBrrU57:nVlrU57 := aDadosFin[4][nPosU57][3]
				oBrrU57:nVlrReceb  := aDadosFin[4][nPosU57][4]
				oBrrU57:nVlrCredi := aDadosFin[4][nPosU57][5]
				oBrrU57:nVlrDin := aDadosFin[4][nPosU57][6]
				oBrrU57:nVlrCHT := aDadosFin[4][nPosU57][7]

				cObsU57 := aDadosFin[4][nPosU57][8]
			endif
		endif
	endif

	oBrrU57:Refresh()
	oObsU57:Refresh()

Return

//--------------------------------------------------------------------------------------
// Funçao que busca pendencias nos grids e posiciona no registro
//--------------------------------------------------------------------------------------
Static Function BuscaPendencia(lAuto)

	Local lRet := .T.
	Local nX
	Local nPosLeg3 := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="LEG3"})

	Default lAuto := .F.

	//aPendencia := {{aba, linha}..}
	if empty(aPendencia) 
		
		For nX := 1 to len(oGridSL1:aCols) //pendências em vendas
			if oGridSL1:aCols[nX][nPosLeg3] == "BR_VERMELHO"
				aadd(aPendencia, {1, nX})
			endif
		Next nX

		For nX := 1 to len(oGridSE5:aCols) //pendências sumprimentos e sangrias
			if oGridSE5:aCols[nX][nPosLeg3] == "BR_VERMELHO"
				aadd(aPendencia, {2, nX})
			endif
		Next nX
		
		if lMvPosto
			if SuperGetMV("TP_ACTCMP",,.F.) //pendências compensações
				For nX := 1 to len(oGridUC0:aCols) 
					if oGridUC0:aCols[nX][nPosLeg3] == "BR_VERMELHO"
						aadd(aPendencia, {3, nX})
					endif
				Next nX
			endif

			if SuperGetMV("TP_ACTVLS",,.F.) //pendências vale serviço
				For nX := 1 to len(oGridVLS:aCols) 
					if oGridVLS:aCols[nX][nPosLeg3] == "BR_VERMELHO"
						aadd(aPendencia, {4, nX})
					endif
				Next nX
			endif

			if SuperGetMV("TP_ACTSQ",,.F.) .OR. SuperGetMV("TP_ACTDP",,.F.) //pendências saques e depósitos
				For nX := 1 to len(oGridU57:aCols)
					if oGridU57:aCols[nX][nPosLeg3] == "BR_VERMELHO"
						aadd(aPendencia, {5, nX})
					endif
				Next nX
			endif
		endif
	endif

	if !empty(aPendencia)
		if lAuto
			lRet := .F.
		else
			nPendAtual++
			if nPendAtual > len(aPendencia)
				nPendAtual := 1
			endif
			oTFolder:SetOption( aPendencia[nPendAtual][1] )
			if aPendencia[nPendAtual][1] == 1
				oGridSL1:GoTo( aPendencia[nPendAtual][2] )
				CarrDetVend("BuscaPendencia")
			elseif aPendencia[nPendAtual][1] == 2
				oGridSE5:GoTo( aPendencia[nPendAtual][2] )
				CarrDetSE5()
			elseif aPendencia[nPendAtual][1] == 3
				oGridUC0:GoTo( aPendencia[nPendAtual][2] )
				CarrDetComp()
			elseif aPendencia[nPendAtual][1] == 4
				oGridVLS:GoTo( aPendencia[nPendAtual][2] )
				CarrDetVlServ()
			elseif aPendencia[nPendAtual][1] == 5
				oGridU57:GoTo( aPendencia[nPendAtual][2] )
				CarrDetU57()
			endif
		endif
	else
		if !lAuto
			MsgInfo("Não encontradas pendências.", "Atenção")
		endif
	endif

Return lRet

//--------------------------------------------------------------------------------------
// Abre detalhamento da venda
//--------------------------------------------------------------------------------------
Static Function DetVenda(lHabBotoes, lBuscaVen, lLoadXml)

	//dimensionamento de tela e componentes
	Local aSize 	:= MsAdvSize() // Retorna a área útil das janelas Protheus
	Local aInfo 	:= {aSize[1], aSize[2], aSize[3]-20, aSize[4]-20, 2, 2}
	Local aObjects 	:= {{100,95,.T.,.T.},{100,5,.T.,.T.}}
	Local aPObj 	:= MsObjSize( aInfo, aObjects, .T. )
	Local aHeaderEx := {}
	Local aColsEx 	:= {}
	Local aDados 	:= {}
	Local aCampos	:= {}
	Local nPosDoc 	:= aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_DOC"})
	Local nPosSer 	:= aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_SERIE"})
	Local nPosLeg2 	:= aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local nValTroco	:= 0
	Local cChavL1 	:= oGridSL1:aCols[oGridSL1:nAt][nPosSer]+oGridSL1:aCols[oGridSL1:nAt][nPosDoc]+Alltrim(SLW->LW_PDV)
	Local cNumCupom := oGridSL1:aCols[oGridSL1:nAt][nPosDoc]+" / "+oGridSL1:aCols[oGridSL1:nAt][nPosSer]
	Local oGet1, oGet2, oGet3, oGet4, oGet5, oGet6, oGet7, oGet8, oGet9, oGet10, oGet11, oButton1
	Local oScrTela, nTop, nLeft
	Local bRefresh := {|| AtuDetVenda(Nil, @nValTroco, @oGet10, @oScrTela) }
	Local cNomCli := ""
	Local cLinks := "", cLinkDanfe := "", cLinkXml := ""
	Local aLinks := {}

	Default lHabBotoes := .T.
	Default lBuscaVen := .F.
	Default lLoadXml := .F.
	Private aMyCpoSL2, aCpoSE1, aCpoUF2, aCpoVLH
	Private oGridSL2, oGridSE1, oGridUF2, oGridVLH
	Private oDlgDetL1
	Private oGetXml, cGetXML := ""

	if empty(oGridSL1:aCols[oGridSL1:nAt][nPosDoc])
		Return
	endif
	if oGridSL1:aCols[oGridSL1:nAt][nPosLeg2] <> "BR_AZUL"
		MsgAlert("Registro não ativo nesta base. Ação não permitida!","Atenção")
		Return
	endif

	SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
	if !SL1->(DbSeek(xFilial("SL1")+cChavL1 ))
		MsgInfo("Venda não encontrada na base retaguarda!","Atenção")
		Return
	endif

	if SL1->L1_SITUA $ "RX,XX,YY"
		MsgInfo("Não foi processada a geração financeira dessa venda (Gravabatch). Você poderá apenas visualizar.","Atenção")
		lHabBotoes := .F.
	endif

	aPObj[1,1] -= 30
	aPObj[1,3] -= 15
	aPObj[2,1] -= 10

	DEFINE MSDIALOG oDlgDetL1 TITLE "Detalhe Cupom "+cNumCupom FROM aSize[7],aSize[1] TO aSize[6]-40,aSize[5]-40 PIXEL

	oScrTela := TScrollBox():New(oDlgDetL1,aPObj[1,1],aPObj[1,2],aPObj[2,1]-aPObj[1,1],aPObj[1,4],.T.,.F.,.T.)

	//---- Dados da Venda
	@ aPObj[1,1]+5, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+85, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "Dados da Venda" OF oScrTela COLOR 0, 16777215 PIXEL

	nTop := aPObj[1,1]+15
	nLeft := aPObj[1,2]+10

	@ nTop, nLeft SAY "Num.NF/Doc" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet1 VAR SL1->L1_DOC When .F. SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 80
	@ nTop, nLeft SAY "Serie" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet2 VAR SL1->L1_SERIE When .F. SIZE 040, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 80
	@ nTop, nLeft SAY "Num.Orçamento" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet3 VAR SL1->L1_NUM When .F. SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 80
	@ nTop, nLeft SAY "Data Emissão" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet4 VAR SL1->L1_EMISNF When .F. SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 80
	@ nTop, nLeft SAY "Pendências" SIZE 80, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft GET oGet11 VAR cObsSL1 OF oScrTela MULTILINE SIZE aPObj[1,4]-nLeft-(2*aPObj[1,2])-85, 56 COLORS 0, 16777215 PIXEL READONLY

	nTop += 22
	nLeft := aPObj[1,2]+10

	@ nTop, nLeft SAY "Cliente/Loja" SIZE 80, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet5 VAR (SL1->L1_CLIENTE+"/"+SL1->L1_LOJA) When .F. SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 80
	@ nTop, nLeft SAY "Nome Cliente" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	cNomCli := Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_NOME")
	@ nTop+8, nLeft MSGET oGet7 VAR cNomCli When .F. SIZE 150, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 160
	@ nTop, nLeft SAY "Placa" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet8 VAR SL1->L1_PLACA When .F. SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	
	nTop += 22
	nLeft := aPObj[1,2]+10

	//Troco em Dinheiro
	aDados := {}
	aCampos := {"E5_PREFIXO","E5_NUMERO","E5_NUMMOV","E5_DATA"}
	if SE5->(FieldPos("E5_XPDV")) > 0
		aadd(aCampos,"E5_XPDV")
		aadd(aCampos,"E5_XESTAC")
		aadd(aCampos,"E5_XHORA")
	endif

	// faco o calculo do valor de troco
	nValTroco := U_T028TTV(4,@aDados,aCampos,"E5_PREFIXO = '" + SL1->L1_SERIE + "' AND E5_NUMERO = '" + SL1->L1_DOC + "'", .F., .F.)

	@ nTop, nLeft SAY "Vendedor" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet6 VAR (SL1->L1_VEND+" - "+Posicione("SA3",1,xFilial("SA3")+SL1->L1_VEND,"A3_NOME")) When .F. SIZE 150, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 160
	@ nTop, nLeft SAY "Valor Total" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet9 VAR SL1->L1_VLRTOT When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL
	nLeft += 80
	@ nTop, nLeft SAY "Troco" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft MSGET oGet10 VAR nValTroco When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oScrTela HASBUTTON COLORS 0, 16777215 PIXEL

	if lHabBotoes
		TButton():New( aPObj[1,1]+15, aPObj[1,4]-(2*aPObj[1,2])-80, "Ajusta Troco", oScrTela, {|| MsAguarde( {|| AjuSL1Troco(.F., bRefresh) }, "Aguarde", "Processando...", .F. ) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( aPObj[1,1]+30, aPObj[1,4]-(2*aPObj[1,2])-80, "Altera Vendedor", oScrTela, {|| AltSL1Vend(bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	endif

	//---- Produtos Vendidos
	@ aPObj[1,1]+90, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+165, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "Produtos Vendidos" OF oScrTela COLOR 0, 16777215 PIXEL

	aMyCpoSL2 := {"L2_PRODUTO","B1_DESC","L2_QUANT","L2_VRUNIT","L2_PRCTAB","L2_DESCPRO","L2_VALDESC","L2_DESPESA","L2_VLRITEM"}
	if lMvPosto
		aadd(aMyCpoSL2, "L2_MIDCOD")
		aadd(aMyCpoSL2, "MID_ENCFIN")
	endif
	aHeaderEx := MontaHeader(aMyCpoSL2)
	aColsEx := {}
	aadd(aColsEx, MontaDados("SL2",aMyCpoSL2, .T.))
	oGridSL2 := MsNewGetDados():New( aPObj[1,1]+100, aPObj[1,2]+10, aPObj[1,1]+160, aPObj[1,4]-(2*aPObj[1,2])-85,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oScrTela, aHeaderEx, aColsEx)
	oGridSL2:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridSL2, @nCol), )}

	//---- Formas de Pagamento
	@ aPObj[1,1]+170, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+250, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "Formas de Pagamento" OF oScrTela COLOR 0, 16777215 PIXEL

	aCpoSE1 := {"E1_EMISSAO","E1_TIPO","E1_VALOR","E1_VLRREAL","E1_VENCREA","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_PREFIXO","E1_NUM","E1_PARCELA"}
	aHeaderEx := MontaHeader(aCpoSE1)
	aColsEx := {}
	aadd(aColsEx, MontaDados("SE1",aCpoSE1, .T.))
	oGridSE1 := MsNewGetDados():New( aPObj[1,1]+180, aPObj[1,2]+10, aPObj[1,1]+245, aPObj[1,4]-(2*aPObj[1,2])-85,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oScrTela, aHeaderEx, aColsEx)
	oGridSE1:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridSE1, @nCol), )}

	if lHabBotoes
		TButton():New( aPObj[1,1]+180, aPObj[1,4]-(2*aPObj[1,2])-80, "Trocar Forma", oScrTela, {|| TrocaForm(1,bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( aPObj[1,1]+195, aPObj[1,4]-(2*aPObj[1,2])-80, "Ajuste Dinheiro", oScrTela, {|| MsAguarde( {|| AjuSL1Din(3, 0, .T., .F., bRefresh) }, "Aguarde", "Processando...", .F. ) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	endif
	
	//---- Cheque Troco
	if lMvPosto .AND. SuperGetMV("TP_ACTCHT",,.F.)
		@ aPObj[1,1]+255, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+335, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "Cheque Troco" OF oScrTela COLOR 0, 16777215 PIXEL

		aCpoUF2 := {"LEGCHT","UF2_BANCO","UF2_AGENCI","UF2_CONTA","UF2_NUM","UF2_VALOR","UF2_DOC","UF2_SERIE","UF2_PDV","UF2_CODBAR"}
		aHeaderEx := MontaHeader(aCpoUF2)
		aColsEx := {}
		aadd(aColsEx, MontaDados("UF2",aCpoUF2, .T.))
		oGridUF2 := MsNewGetDados():New( aPObj[1,1]+265, aPObj[1,2]+10, aPObj[1,1]+330, aPObj[1,4]-(2*aPObj[1,2])-85,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oScrTela, aHeaderEx, aColsEx)
		oGridUF2:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridUF2, @nCol), )}

		if lHabBotoes
			TButton():New( aPObj[1,1]+265, aPObj[1,4]-(2*aPObj[1,2])-80, "Incluir", oScrTela, {|| IncChqTroco(1,,bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			TButton():New( aPObj[1,1]+280, aPObj[1,4]-(2*aPObj[1,2])-80, "Excluir", oScrTela, {|| DelChqTroco(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],1,,,bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			TButton():New( aPObj[1,1]+295, aPObj[1,4]-(2*aPObj[1,2])-80, "Substituir", oScrTela, {|| SubChqTroco(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],.T.,bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			TButton():New( aPObj[1,1]+310, aPObj[1,4]-(2*aPObj[1,2])-80, "Corrigir Fin.", oScrTela, {|| CorrigeCHT(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		endif
		nPosIni := 340
	else
		nPosIni := 255
	endif

	//---- Vale Haver
	if lMvPosto .AND. SuperGetMV("TP_ACTVLH",,.F.)
		@ aPObj[1,1]+nPosIni, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+nPosIni+80, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "Vale Haver" OF oScrTela COLOR 0, 16777215 PIXEL

		aCpoVLH := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_NATUREZ"}
		aHeaderEx := MontaHeader(aCpoVLH)
		aColsEx := {}
		aadd(aColsEx, MontaDados("SE1",aCpoVLH, .T.))
		oGridVLH := MsNewGetDados():New( aPObj[1,1]+nPosIni+10, aPObj[1,2]+10, aPObj[1,1]+nPosIni+75, aPObj[1,4]-(2*aPObj[1,2])-85,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oScrTela, aHeaderEx, aColsEx)
		oGridVLH:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridVLH, @nCol), )}

		if lHabBotoes
			TButton():New( aPObj[1,1]+nPosIni+10, aPObj[1,4]-(2*aPObj[1,2])-80, "Incluir", oScrTela, {|| IncValeHav(1,bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
			TButton():New( aPObj[1,1]+nPosIni+25, aPObj[1,4]-(2*aPObj[1,2])-80, "Excluir", oScrTela, {|| DelValeHav(oGridVLH:aCols[oGridVLH:nAt][len(aCpoVLH)+1],1,bRefresh) }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		endif
		nPosIni += 85
	endif

	//verifico se vem do Kingposto, e se tem o xml gravado
	MHQ->(DbSetOrder(1)) //MHQ_FILIAL+MHQ_ORIGEM+MHQ_CPROCE+MHQ_CHVUNI+MHQ_EVENTO+DTOS(MHQ_DATGER)+MHQ_HORGER
	if MHQ->(DbSeek(xFilial("MHQ")+PadR("KINGPOSTO",TamSX3("MHQ_ORIGEM")[1])+PadR("XML",TamSX3("MHQ_CPROCE")[1])+SL1->L1_FILIAL+SL1->L1_SERIE+SL1->L1_DOC+SL1->L1_PDV ))
		cGetXML := MHQ->MHQ_MENSAG
		cGetXML := zPrettyXML(cGetXML)
	endif
	//verifico se tem links gravados
	if MHQ->(DbSeek(xFilial("MHQ")+PadR("KINGPOSTO",TamSX3("MHQ_ORIGEM")[1])+PadR("LINKS",TamSX3("MHQ_CPROCE")[1])+SL1->L1_FILIAL+SL1->L1_SERIE+SL1->L1_DOC+SL1->L1_PDV ))
		cLinks := MHQ->MHQ_MENSAG
		aLinks := StrToKArr(cLinks, chr(13)+chr(10))
	endif

	if len(aLinks) > 0 .AND. !empty(aLinks[1])
		@ aPObj[1,1]+nPosIni, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+nPosIni+200, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "Arquivos da Nota Fiscal" OF oScrTela COLOR 0, 16777215 PIXEL

		if (nTop := aScan(aLinks, {|x| '.html' $ x })) > 0
			cLinkDanfe := aLinks[nTop]
			@ aPObj[1,1]+nPosIni+10, aPObj[1,2]+10 SAY "-> Link do DANFE (clique para ver online)" SIZE 150, 007 OF oScrTela COLORS 0, 16777215 PIXEL
			@ aPObj[1,1]+nPosIni+18, aPObj[1,2]+15 SAY cLinkDanfe SIZE aPObj[1,4]-(2*aPObj[1,2])-95, 010 OF oScrTela COLORS CLR_BLUE, 16777215 PIXEL
			oHB1 := THButton():New(aPObj[1,1]+nPosIni+18, aPObj[1,2]+15, "", oScrTela, {|| ShellExecute("Open", cLinkDanfe, "", "", 1) }, aPObj[1,4]-(2*aPObj[1,2])-95, 010,,"Abrir link DANFE externamente.")
		endif

		if (nTop := aScan(aLinks, {|x| '.xml' $ x })) > 0
			cLinkXml := aLinks[nTop]
			@ aPObj[1,1]+nPosIni+30, aPObj[1,2]+10 SAY "-> Link do XML (clique para ver online)" SIZE 150, 007 OF oScrTela COLORS 0, 16777215 PIXEL
			@ aPObj[1,1]+nPosIni+38, aPObj[1,2]+15 SAY cLinkXml SIZE aPObj[1,4]-(2*aPObj[1,2])-95, 010 OF oScrTela COLORS CLR_BLUE, 16777215 PIXEL
			oHB2 := THButton():New(aPObj[1,1]+nPosIni+38, aPObj[1,2]+15, "", oScrTela, {|| ShellExecute("Open", cLinkXml, "", "", 1) }, aPObj[1,4]-(2*aPObj[1,2])-95, 010,,"Abrir link XML externamente.")
		endif

		nPosIni += 50
		@ aPObj[1,1]+nPosIni, aPObj[1,2]+10 SAY "-> Xml da Nota" SIZE 50, 007 OF oScrTela COLORS 0, 16777215 PIXEL
	else
		@ aPObj[1,1]+nPosIni, aPObj[1,2]+5 GROUP oGroup1 TO aPObj[1,1]+nPosIni+150, aPObj[1,4]-(2*aPObj[1,2])-15 PROMPT "XML da Nota" OF oScrTela COLOR 0, 16777215 PIXEL
	endif
	
	@ aPObj[1,1]+nPosIni+10, aPObj[1,2]+10 GET oGetXml VAR cGetXML OF oScrTela MULTILINE SIZE aPObj[1,4]-(2*aPObj[1,2])-95, 135 COLORS 0, 16777215 PIXEL READONLY
	TButton():New( aPObj[1,1]+nPosIni+10, aPObj[1,4]-(2*aPObj[1,2])-80, "Carregar", oScrTela, {|| LoadXMLNf() }, 60, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	oButton1:= TButton():New( aPObj[2,1]+5, aPObj[2,4]-55, "Fechar", oDlgDetL1, {|| oDlgDetL1:End() }, 50, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton1:SetCSS( CSS_BTNAZUL )

	AtuDetVenda(lLoadXml)

	//encerra montagem DLG
	oDlgDetL1:lCentered := .T.
	oDlgDetL1:Activate()

	//atualizo grid vendas
	Processa({|| AtuConfDocs(.T.,.F.,oGridSL1:aCols[oGridSL1:nAt][nPosDoc],oGridSL1:aCols[oGridSL1:nAt][nPosSer]),,.F.,.F.,.F. },"Aguarde... este processo pode demorar...","Aguarde...")

Return

//--------------------------------------------------------------------------------------
// Atualiza dados de detalhamento da venda
//--------------------------------------------------------------------------------------
Static Function AtuDetVenda(lLoadXml, nValTroco, oGetTroco, oScrTela)

	Local aDados	:= {}
	Local aCampos	:= {}

	Default lLoadXml 	:= .F.
	Default nValTroco	:= 0
	Default oGetTroco	:= Nil
	Default oScrTela	:= Nil

	//produtos
	SL2->(DbSetOrder(1))
	If SL2->(DbSeek( xFilial("SL2") + SL1->L1_NUM ))
		oGridSL2:aCols := {}
		While SL2->(!Eof()) .And. SL2->(L2_FILIAL+L2_NUM) == xFilial("SL2") + SL1->L1_NUM
			Posicione("SB1",1,xFilial("SB1")+SL2->L2_PRODUTO,"B1_COD")
			if lMvPosto
				if !empty(MID->(IndexKey(1)))
					MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
				endif
				if !empty(SL2->L2_MIDCOD)
					MID->(DbSeek(xFilial("MID")+SL2->L2_MIDCOD))
				else
					MID->(DbSeek(xFilial("MID")+"----")) //dou seek pra ficar em EOF
				endif
			endif

			aadd(oGridSL2:aCols, MontaDados("SL2",aMyCpoSL2))
			SL2->(DbSkip())
		EndDo
	endif

	//titulos
	aDados := BuscaSE1(aCpoSE1, "E1_PREFIXO='"+SL1->L1_SERIE+"' AND E1_NUM='"+SL1->L1_DOC+"' AND E1_TIPO<>'NCC'")

	if !empty(aDados)
		oGridSE1:aCols := aClone(aDados)
	endif

	oGridSL2:oBrowse:Refresh()
	oGridSE1:oBrowse:Refresh()
	
	//Cheque Troco
	if lMvPosto .AND. SuperGetMV("TP_ACTCHT",,.F.)
		oGridUF2:aCols := {}
		UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
		if UF2->(DbSeek(xFilial("UF2")+SL1->L1_DOC+SL1->L1_SERIE+Alltrim(SL1->L1_PDV)))
			While UF2->(!Eof()) .And. UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE+Alltrim(UF2->UF2_PDV) == xFilial("UF2")+SL1->L1_DOC+SL1->L1_SERIE+Alltrim(SL1->L1_PDV)
				aadd(oGridUF2:aCols, MontaDados("UF2",aCpoUF2))
				oGridUF2:aCols[len(oGridUF2:aCols)][aScan(aCpoUF2,"LEGCHT")] := LegendUF2()
				UF2->(DbSkip())
			Enddo
		else
			aadd(oGridUF2:aCols, MontaDados("UF2",aCpoUF2, .T.))
		EndIf
		oGridUF2:oBrowse:Refresh()
	endif

	//vale Haver
	if lMvPosto .AND. SuperGetMV("TP_ACTVLH",,.F.)
		aDados := {}
		oGridVLH:aCols := {}
		if U_T028TVLH(4, @aDados, aCpoVLH, SL1->L1_DOC, SL1->L1_SERIE) > 0 //se tem vale haver
			if !empty(aDados)
				oGridVLH:aCols := aClone(aDados)
			endif
		else
			aadd(oGridVLH:aCols, MontaDados("SE1",aCpoVLH, .T.))
		endif
		oGridVLH:oBrowse:Refresh()
	endif

	If oScrTela <> Nil .And. oGetTroco <> Nil

		//Troco em Dinheiro
		aDados := {}
		aCampos := {"E5_PREFIXO","E5_NUMERO","E5_NUMMOV","E5_DATA"}
		if SE5->(FieldPos("E5_XPDV")) > 0
			aadd(aCampos,"E5_XPDV")
			aadd(aCampos,"E5_XESTAC")
			aadd(aCampos,"E5_XHORA")
		endif

		// faco o calculo do valor de troco
		nValTroco := U_T028TTV(4,@aDados,aCampos,"E5_PREFIXO = '" + SL1->L1_SERIE + "' AND E5_NUMERO = '" + SL1->L1_DOC + "'", .F., .F.)

		oScrTela:Refresh()
		oGetTroco:Refresh()

	EndIf

	if lLoadXml
		LoadXMLNf()
	endif

Return

//--------------------------------------------------------------------------------------
// Carrega o XML da nota no campo de detalhe
//--------------------------------------------------------------------------------------
Static Function LoadXMLNf()

	//verifico se vem do Kingposto, e se tem os links do Xml e Danfe
	MHQ->(DbSetOrder(1)) //MHQ_FILIAL+MHQ_ORIGEM+MHQ_CPROCE+MHQ_CHVUNI+MHQ_EVENTO+DTOS(MHQ_DATGER)+MHQ_HORGER
	if MHQ->(DbSeek(xFilial("MHQ")+PadR("KINGPOSTO",TamSX3("MHQ_ORIGEM")[1])+PadR("XML",TamSX3("MHQ_CPROCE")[1])+SL1->L1_FILIAL+SL1->L1_SERIE+SL1->L1_DOC+SL1->L1_PDV ))
		cGetXML := MHQ->MHQ_MENSAG
	else
		Processa({|lEnd| cGetXML := SpedPExp(SL1->L1_SERIE, SL1->L1_DOC, SL1->L1_DOC, @lEnd, SL1->L1_EMISNF, SL1->L1_EMISNF) },"Processando","Aguarde, buscando XML...",.F.)
	endif
	
	cGetXML := zPrettyXML(cGetXML)
	oGetXml:Refresh()

Return

//--------------------------------------------------------------------------------------
// Função que tenta corrigir problemas da venda automaticamente.
//--------------------------------------------------------------------------------------
Static Function CorrigeVenda()

	Local nPosLeg2 := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local nPosDoc := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_DOC"})
	Local nPosSer := aScan(oGridSL1:aHeader,{|x| AllTrim(x[2])=="L1_SERIE"})
	Local cSerDoc := oGridSL1:aCols[oGridSL1:nAt][nPosSer]+oGridSL1:aCols[oGridSL1:nAt][nPosDoc]
	Local nPosVenda := 0
	Local aIdCorrige
	Local nVlrAux := 0
	Local aDados, nTotTroDin, nX
	Local aCampos

	if !empty(cSerDoc)
		if oGridSL1:aCols[oGridSL1:nAt][nPosLeg2] <> "BR_AZUL"
			if ForcaIntVend(cSerDoc)
				MsgInfo("Feito alteração na venda na base do PDV para tentar integra-la. Aguarde alguns minutos e verifique o status da venda novamente.","Atenção")
			else
				MsgAlert("Registro não ativo nesta base. Ação não permitida!","Atenção")
			endif
			Return
		endif

		SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
		if !SL1->(DbSeek(xFilial("SL1")+cSerDoc+AllTrim(SLW->LW_PDV) ))
			MsgInfo("Venda não encontrada na base retaguarda!","Atenção")
			Return
		endif

		if SL1->L1_SITUA $ "RX,XX,YY"
			MsgInfo("Não foi processada a geração financeira dessa venda (Gravabatch). Aguarde alguns minutos ou entre em contato com TI.","Atenção")
			Return
		endif

		if SL1->L1_SITUA == "ER"
			Reclock("SL1", .F.)
				SL1->L1_SITUA := "RX"
			SL1->(MsUnlock())
			MsgInfo("Venda marcada para reprocessar financeiro (Gravabatch). Aguarde alguns minutos ou entre em contato com TI.","Atenção")
			Return
		endif

		//aDadosFin: {cL1Doc, cL1Serie, lOk, nTotProd, nTotTit, nTotTroDin, cObs, aIdCorrige}
		nPosVenda := aScan(aDadosFin[1], {|x| x[2]+x[1] == cSerDoc })
		if nPosVenda > 0
			if aDadosFin[1][nPosVenda][3] //se tudo ok
				MsgInfo("Não foram encontradas pendências neste cupom.","Atenção")
			else //tem problemas
				aIdCorrige := aDadosFin[1][nPosVenda][8]

				if aScan(aIdCorrige, "SL2VALOR") > 0
					DbSelectArea("SL2")
					SL2->(DbSetOrder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO
					If SL2->(DbSeek(xFilial("SL2")+SL1->L1_NUM ))
						While SL2->(!Eof()) .and. SL2->L2_FILIAL+SL2->L2_NUM == xFilial("SL2")+SL1->L1_NUM
							//nVlrAux := (NoRound(SL2->L2_QUANT*SL2->L2_PRCTAB,2)-SL2->L2_DESCPRO-SL2->L2_VALDESC+SL2->L2_DESPESA)
							nVlrAux := (Round(SL2->L2_QUANT*SL2->L2_PRCTAB,2)-SL2->L2_DESCPRO-SL2->L2_VALDESC+SL2->L2_DESPESA)
							If SL2->L2_VLRITEM <> nVlrAux
								RecLock("SL2",.F.)
								SL2->L2_VLRITEM := nVlrAux
								SL2->(MsUnlock())
							EndIf
							SL2->(DbSkip())
						EndDo
					EndIf
				endif

				//total recebido menor que total itens, lança diferença recebido em dinheiro
				//adicionado condição para nao incluir dinheiro se o credito
				if aScan(aIdCorrige, "SE1DIFSL1") > 0 .AND. SL1->L1_CREDITO <= 0
					nVlrAux := Abs(aDadosFin[1][nPosVenda][5]-aDadosFin[1][nPosVenda][4]) //titulos/itens
					AjuSL1Din(1, nVlrAux, .F.) //incluo valor recebido em dinheiro
				endif

				if aScan(aIdCorrige, "SE5TROCOCHAVE") > 0
					aDados := {}
					aCampos := {"E5_PREFIXO","E5_NUMERO","E5_NUMMOV","E5_DATA"}
					if SE5->(FieldPos("E5_XPDV")) > 0
						aadd(aCampos,"E5_XPDV")
						aadd(aCampos,"E5_XESTAC")
						aadd(aCampos,"E5_XHORA")
					endif
					nTotTroDin := U_T028TTV(4,@aDados,aCampos,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'", .F., .F.)
					if nTotTroDin > 0
						For nX := 1 to len(aDados)
							//verifico se o movimento está fora da chave do caixa
							if SE5->(FieldPos("E5_XPDV")) > 0
								if aDados[nX][3] <> SLW->LW_NUMMOV ;
									.OR. Alltrim(aDados[nX][5]) <> Alltrim(SLW->LW_PDV) ;
									.OR. aDados[nX][6] <> SLW->LW_ESTACAO;
									.OR. DTOS(aDados[nX][4])+aDados[nX][7] < DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT ;
									.OR. DTOS(aDados[nX][4])+aDados[nX][7] > DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA

									SE5->(DbGoTo(aDados[nX][8]))
									//somente corrijo se a data da SE5 for a mesma
									if SE5->E5_DATA == SL1->L1_EMISNF
										Reclock("SE5",.F.)
											SE5->E5_NUMMOV := SLW->LW_NUMMOV
											SE5->E5_XPDV := SLW->LW_PDV
											SE5->E5_XESTAC := SLW->LW_ESTACAO
											SE5->E5_XHORA := SL1->L1_HORA
										SE5->(MsUnlock())
									endif
								endif
							else
								if aDados[nX][3] <> SLW->LW_NUMMOV ;
									.OR. DTOS(aDados[nX][4]) < DTOS(SLW->LW_DTABERT) ;
									.OR. DTOS(aDados[nX][4]) > DTOS(SLW->LW_DTFECHA)

									SE5->(DbGoTo(aDados[nX][8]))
									//somente corrijo se a data da SE5 for a mesma
									if SE5->E5_DATA == SL1->L1_EMISNF
										Reclock("SE5",.F.)
											SE5->E5_NUMMOV := SLW->LW_NUMMOV
										SE5->(MsUnlock())
									endif
								endif
							endif
						next nX
					endif
				endif

				//se troco com inconsistências, aumenta ou diminui troco em dinheiro
				if aScan(aIdCorrige, "SL1TROCO") > 0
					AjuSL1Troco()
				endif

				if aScan(aIdCorrige, "SE1NOBX") > 0
					if !AjuSL1Baixa()
						MsgInfo("Existe titulo recebido não baixado/compensado. Para corrigir este caso, utilize a opção Trocar Forma no detalhamento da venda (Pode-se usar a mesma forma de pagamento se necessário).","Atenção")
					endif
				endif

				if lMvPosto
					if aScan(aIdCorrige, "SL2NOABAST") > 0
						if !CorrCodAbast(SL1->L1_NUM) //tenta corrigir
							MsgInfo("Não foi possível corrigir item de combustível sem codigo de abastecimento. Acionar equipe de TI para análise.","Atenção")
						endif
					endif

					if aScan(aIdCorrige, "SL2NOMID") > 0
						MsgInfo("Existe abastecimentos referente a esta venda que não foram encontrados na base retaguarda. Possível falha na integração. Acionar equipe de TI para análise.","Atenção")
					endif
				endif

				if aScan(aIdCorrige, "SL2DIFSL1") > 0
					MsgInfo("Total dos produtos no cabeçalho da venda não é igual ao total encontrado na tabela de itens. Possível falha na integração. Acionar equipe de TI para análise.","Atenção")
				endif

				//atualizo grid vendas
				Processa({|| AtuConfDocs(.T.,.F.,oGridSL1:aCols[oGridSL1:nAt][nPosDoc],oGridSL1:aCols[oGridSL1:nAt][nPosSer]),,.F.,.F.,.F. },"Aguarde... este processo pode demorar...","Aguarde...")

			endif
		else
			MsgInfo("Falha ao encontrar dados da venda!","Atenção")
		endif
	endif

Return

Static Function ForcaIntVend(cSerDoc)

	Local lRet := .F.
	Local cSitua := ""

	//L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
	cSitua := DoRPC_Pdv("Posicione", "SL1", 2 , xFilial("SL1")+cSerDoc, "L1_SITUA")

	if valtype(cSitua) == "C" .AND. cSitua == "ER"	
		DoRPC_Pdv("U_UREPLICA", "SL1", 2, xFilial("SL1")+cSerDoc, "A", .F.)
		lRet := .T.
	endif

	DoRpcClose() //fecha RPC

Return lRet

//--------------------------------------------------------------------------------------
// Funçao para buscar vendas que por algum motivo ficaram com hora fora do periodo do caixa
//--------------------------------------------------------------------------------------
Static Function BuscarVenda(lAuto)

	Local oPnlDet
	Local aCampos := {"MARK","L1_DOC","L1_SERIE","L1_CLIENTE","L1_LOJA","A1_NOME","L1_VLRTOT","L1_VLRLIQ","L1_NUM","L1_PLACA","L1_EMISNF","L1_HORA","L1_OPERADO","L1_PDV","L1_ESTACAO","L1_NUMMOV"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local cQry := ""
	Local nOpcX := 0
	Local nX, nY
	Local aTrocos := {}
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Local lBuscaVen := SuperGetMv("TP_CXHABBV",,.T.) //parametro para desabilitar botão de buscar venda

	Default lAuto := .F.

	Private lMARKALL := .F.
	Private oGridDet
	Private oDlgDet

	if !lBuscaVen
		if !lAuto
			MsgInfo("Funcionalidade desabilitada para esta filial.", "TP_CXHABBV")
		endif
		return
	endif

	//Danilo: Desabilitado pois caso a SLW não integre por falha do padrão, as vendas estavam sendo modificadas pra outro caixa com mesma data
	if lAuto
		Return
	endif

	//busco vendas fora do intervalo de datas do caixa
	//que podem ser que sejam desse caixa
	cQry := " SELECT SL1.R_E_C_N_O_ RECSL1 "
	cQry += " FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 "
	cQry += " LEFT JOIN "+RetSqlName("SLW")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SLW ON ( "
	cQry += " 	SLW.D_E_L_E_T_ = ' ' "
	cQry += " 	AND LW_FILIAL = L1_FILIAL "
	cQry += " 	AND L1_OPERADO = LW_OPERADO "
	cQry += " 	AND L1_NUMMOV = LW_NUMMOV "
	cQry += " 	AND RTRIM(L1_PDV) = RTRIM(LW_PDV) "
	cQry += " 	AND L1_ESTACAO = LW_ESTACAO "
	cQry += " 	AND ( (L1_EMISNF||SUBSTRING(L1_HORA,1,5) BETWEEN LW_DTABERT||LW_HRABERT AND LW_DTFECHA||LW_HRFECHA) "
	cQry += "      OR (LW_DTFECHA = ' ' AND L1_EMISNF||SUBSTRING(L1_HORA,1,5) >= LW_DTABERT||LW_HRABERT) )" //caixas nao fechados
	cQry += " ) "
	cQry += " WHERE SL1.D_E_L_E_T_ = ' ' "
	cQry += " AND L1_FILIAL = '" + xFilial("SL1") + "'"
	cQry += " AND L1_DOC <> '' "
	//cQry += " AND L1_OPERADO = '"+SLW->LW_OPERADO+"' "
	cQry += " AND (L1_PDV = '' OR RTRIM(L1_PDV) = '"+Alltrim(SLW->LW_PDV)+"') "
	cQry += " AND L1_EMISNF BETWEEN '"+DTOS(SLW->LW_DTABERT)+"' AND '"+DTOS(SLW->LW_DTFECHA)+"' " //com datas do caixa
	cQry += " AND LW_FILIAL IS NULL " //não encontrou a sua SLW
	cQry += " ORDER BY L1_FILIAL, L1_DOC "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	SA1->(DbSetOrder(1))
	While QRYT1->(!Eof())

		SL1->(DbGoTo(QRYT1->RECSL1))
		SA1->(DbSeek(xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA))

		aadd(aColsEx, MontaDados("SL1",aCampos, .F.))

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if empty(aColsEx)
		if lAuto
			Return
		endif
		aadd(aColsEx, MontaDados("SL1",aCampos, .T.))
	elseif lAuto
		MsgInfo("Existem possíveis vendas a vincular neste caixa. Favor verifique a opção Buscar Vendas.","Atenção")
		Return
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Busca Vendas não vinculadas" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Vendas encontradas fora do intervalo do caixa:" SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 158, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bLDblClick := {|| oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridDet:oBrowse:Refresh() }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, OrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}


	@ 162, 005 SAY "Obs.: Apenas aparecem aqui vendas deste PDV que não estão vinculada a nenhum outro caixa." SIZE 380, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 182, 005 BUTTON oButton1 PROMPT "Detalhar Venda" SIZE 050, 012 OF oDlgDet PIXEL Action DetXmlVenda()
	@ 182, 310 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	@ 182, 355 BUTTON oButton1 PROMPT "Vincular" SIZE 040, 012 OF oDlgDet PIXEL Action iif(aScan(oGridDet:aCols,{|x| x[1]=="LBOK"}) > 0, (nOpcX:=1,oDlgDet:End()), MsgInfo("Selecione pelo menos uma venda!", "Atenção"))
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	if nOpcX == 1

		BeginTran()

		For nX := 1 to len(oGridDet:aCols)
			if oGridDet:aCols[nX][1] == "LBOK" .AND. !empty(oGridDet:aCols[nX][len(oGridDet:aHeader)])
				SL1->(DbGoTo(oGridDet:aCols[nX][len(oGridDet:aHeader)]))

				//forço venda a ficar na hora do intervalo do caixa
				Reclock("SL1", .F.)

				//gravo log da alteração, campos antes de mudar
				If SL1->(FieldPos("L1_ERGRVBT")) > 0
					cAux := AllTrim(SL1->L1_ERGRVBT)
					SL1->L1_ERGRVBT := cAux + " / Substituicao chave caixa. Dados anteriores:" + ;
						"L1_OPERADO = ["+SL1->L1_OPERADO+"], " + ;
						"L1_PDV = ["+SL1->L1_PDV+"], " + ;
						"L1_ESTACAO = ["+SL1->L1_ESTACAO+"], " + ;
						"L1_NUMMOV = ["+SL1->L1_NUMMOV+"], " + ;
						"L1_EMISNF = ["+ DTOS(SL1->L1_EMISNF) +"], " + ;
						"L1_HORA = ["+SL1->L1_HORA+"] "
				Endif

				SL1->L1_OPERADO := SLW->LW_OPERADO
				SL1->L1_PDV := SLW->LW_PDV
				SL1->L1_ESTACAO := SLW->LW_ESTACAO
				SL1->L1_NUMMOV := SLW->LW_NUMMOV

				if DTOS(SL1->L1_EMISNF)+SL1->L1_HORA >= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA
					SL1->L1_HORA := SLW->LW_HRFECHA
				elseif DTOS(SL1->L1_EMISNF)+SL1->L1_HORA <= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT
					SL1->L1_HORA := SLW->LW_HRABERT
				endif

				SL1->(MsUnlock())

				//Verifico se tem troco no cupom para ajustar a hora também
				if SE5->(FieldPos("E5_XPDV")) > 0
					aTrocos := {}
					U_T028TTV(4, @aTrocos, {"E5_VALOR"},"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'", .F., .F.)
					for nY := 1 to len(aTrocos)
						if !empty(aTrocos[nY][2])
							SE5->(DBGoTo(aTrocos[nY][2]))
							RecLock("SE5", .F.)
							SE5->E5_XPDV := SLW->LW_PDV
							SE5->E5_XESTAC := SLW->LW_ESTACAO
							SE5->E5_XHORA := SL1->L1_HORA
							SE5->(MsUnlock())
						endif
					next nY
				endif

			endif
		next nX

		EndTran()

		//atualizo grid vendas
		Processa({|| AtuConfDocs(.T.,.F.,,,,.F.,.F.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Detalha venda XML
//--------------------------------------------------------------------------------------
Static Function DetXmlVenda()

	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea())
	Local nRecno := oGridDet:aCols[oGridDet:nAt][len(oGridDet:aHeader)]

	if nRecno > 0
		SL1->(DbGoTo( nRecno ))
		DetVenda(.F., .T.)
	endif

	RestArea(aAreaSL1)
	RestArea(aArea)
Return

//--------------------------------------------------------------------------------------
// Ações dos botões aba Trocos Iniciais/Finais da tela de conferencia documentos
//--------------------------------------------------------------------------------------
Static Function MntSE5Troco(nOpcX, nRecSE5)

	Local nPosTpDoc := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_FILIAL"})
	Local aParBox := {}
	Local aRetPar := {}
	Local bAtuGrid := {|| Processa({|| AtuConfDocs(.F.,.T.,,,,.F.,.F.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...") }

	if nOpcX == 3
		aAdd(aParBox, {3, 'Tipo Documento:', 1, {"Suprimento","Sangria"}, 100, '', .T., '.T.'})

		If ! ParamBox(aParBox, 'Inclusão Suprimento/Sangria', @aRetPar,,,,,,,.F.,.F.)
			Return Nil
		EndIf

		MntSupSang(3, aRetPar[1], , bAtuGrid)
	else
		if nRecSE5 > 0
			if Alltrim(oGridSE5:aCols[oGridSE5:nAt][nPosTpDoc]) == "SUPRIMENTO"
				MntSupSang(nOpcX, 1, nRecSE5, bAtuGrid)
			elseif Alltrim(oGridSE5:aCols[oGridSE5:nAt][nPosTpDoc]) == "SANGRIA"
				MntSupSang(nOpcX, 2, nRecSE5, bAtuGrid)
			else
				MsgAlert("Operação não permitida para esse tipo de documento!", "Atenção")
			endif
		else
			MsgAlert("Registro não encontrado na base Retaguarda. Operação não permitida!", "Atenção")
		endif
	endif

Return

//--------------------------------------------------------------------------------------
// Funçao para buscar movimentos SE5 que por algum motivo ficaram com hora fora do periodo do caixa
//--------------------------------------------------------------------------------------
Static Function BuscarSupSang()

	Local oPnlDet
	Local aCampos := {"MARK","E5_FILIAL","E5_DATA","E5_VALOR","E5_PREFIXO","E5_NUMERO","E5_SEQ","E5_NATUREZ","E5_HISTOR","E5_DATA","E5_XHORA","E5_BANCO","E5_XPDV","E5_XESTAC","E5_NUMMOV"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local cQry := ""
	Local nOpcX := 0
	Local nX
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Local nTamHora := TamSX3("LW_HRABERT")[1]

	Private lMARKALL := .F.
	Private oGridDet
	Private oDlgDet

	//busco compensaçoes fora do intervalo de datas do caixa
	cQry := "SELECT R_E_C_N_O_ RECSE5 "
	cQry += "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
	cQry += "WHERE SE5.D_E_L_E_T_ = ' ' "
	cQry += " AND E5_FILIAL = '" + xFilial("SE5") + "' "
	cQry += " AND E5_BANCO = '"+SLW->LW_OPERADO+"' AND E5_NUMMOV = '"+SLW->LW_NUMMOV+"' "
	cQry += " AND RTRIM(E5_XPDV) = '"+Alltrim(SLW->LW_PDV)+"' AND E5_XESTAC = '"+SLW->LW_ESTACAO+"' "
	cQry += " AND E5_DATA BETWEEN '"+DTOS(SLW->LW_DTABERT)+"' AND '"+DTOS(SLW->LW_DTFECHA)+"' " //com datas do caixa
	cQry += " AND (E5_DATA||SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") < '"+DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT+"' " //fora do intervalo de hora
	cQry += "   OR E5_DATA||SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") > '"+DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA+"') " //fora do intervalo de hora

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	While QRYT1->(!Eof())

		SE5->(DbGoTo(QRYT1->RECSE5))

		aadd(aColsEx, MontaDados("SE5",aCampos, .F.))

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if empty(aColsEx)
		aadd(aColsEx, MontaDados("SE5",aCampos, .T.))
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Busca Movimentos não vinculados" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Movimentos Sangria/Suprimento encontrados fora do intervalo do caixa:" SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 158, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bLDblClick := {|| oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridDet:oBrowse:Refresh() }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, OrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}

	@ 162, 005 SAY "Obs.: Apenas aparecem aqui, movimentos do mesmo operador, pdv, estacao deste caixa, que não se encaixaram no intervalo de data/hora." SIZE 380, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 182, 310 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	@ 182, 355 BUTTON oButton1 PROMPT "Vincular" SIZE 040, 012 OF oDlgDet PIXEL Action iif(aScan(oGridDet:aCols,{|x| x[1]=="LBOK"}) > 0, (nOpcX:=1,oDlgDet:End()), MsgInfo("Selecione pelo menos um movimento!", "Atenção"))
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	if nOpcX == 1

		BeginTran()

		For nX := 1 to len(oGridDet:aCols)
			if oGridDet:aCols[nX][1] == "LBOK" .AND. !empty(oGridDet:aCols[nX][len(oGridDet:aHeader)])
				SE5->(DbGoTo(oGridDet:aCols[nX][len(oGridDet:aHeader)]))

				//forço venda a ficar na hora do intervalo do caixa
				Reclock("SE5", .F.)
				if SE5->E5_DATA == SLW->LW_DTFECHA
					SE5->E5_XHORA := SLW->LW_HRFECHA
				elseif SE5->E5_DATA == SLW->LW_DTABERT
					SE5->E5_XHORA := SLW->LW_HRABERT
				endif
				SE5->(MsUnlock())
			endif
		next nX

		EndTran()

		//atualizo grid vale serviço
		Processa({|| AtuConfDocs(.F.,.T.,,,,.F.,.F.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

Static Function CorrigeSupSang()

	Local nX, nY
	Local aCampos := {}
	Local cFiltro := ""
	Local aRegSE5 := {}
	Local nPosLeg1 := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="LEG1"})
	Local nPosLeg2 := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local nPosLeg3 := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="LEG3"})
	Local nPosPfx := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_PREFIXO"})
	Local nPosNum := aScan(oGridSE5:aHeader,{|x| AllTrim(x[2])=="E5_NUMERO"})
	
	if oGridSE5:aCols[oGridSE5:nAt][nPosLeg1] == "BR_AZUL" .AND. oGridSE5:aCols[oGridSE5:nAt][nPosLeg2] == "BR_AMARELO" .AND. oGridSE5:aCols[oGridSE5:nAt][nPosLeg3] == "BR_VERMELHO"
		
		aadd(aCampos, "E5_FILIAL" )
		aadd(aCampos, "E5_FILORIG" )
		aadd(aCampos, "E5_MSFIL" )
		aadd(aCampos, "E5_MOEDA" )
		aadd(aCampos, "E5_TIPODOC" )
		aadd(aCampos, "E5_VALOR" )
		aadd(aCampos, "E5_DATA" )
		aadd(aCampos, "E5_DTDISPO" )
		aadd(aCampos, "E5_DTDIGIT" )
		aadd(aCampos, "E5_NATUREZ" )
		aadd(aCampos, "E5_VLMOED2" )
		aadd(aCampos, "E5_BANCO" )
		aadd(aCampos, "E5_AGENCIA" )
		aadd(aCampos, "E5_CONTA" )
		aadd(aCampos, "E5_RECPAG" )
		aadd(aCampos, "E5_HISTOR" )
		aadd(aCampos, "E5_SITUA" )
		aadd(aCampos, "E5_SEQ" )
		aadd(aCampos, "E5_PREFIXO" )
		aadd(aCampos, "E5_NUMERO" )
		aadd(aCampos, "E5_PARCELA" )
		aadd(aCampos, "E5_TIPO" )
		aadd(aCampos, "E5_CLIFOR" )
		aadd(aCampos, "E5_LOJA" )
		aadd(aCampos, "E5_NUMMOV" )
		aadd(aCampos, "E5_ORIGEM" )
		aadd(aCampos, "E5_XPDV" )
		aadd(aCampos, "E5_XESTAC" )
		aadd(aCampos, "E5_XHORA" )
		aadd(aCampos, "E5_OPERAD" )

		cFiltro := "D_E_L_E_T_ = ' ' AND E5_PREFIXO='"+oGridSE5:aCols[oGridSE5:nAt][nPosPfx]+"' AND E5_NUMERO = '"+oGridSE5:aCols[oGridSE5:nAt][nPosNum]+"'"
		aRegSE5 := DoRPC_Pdv("STDQueryDB", aCampos, {"SE5"}, cFiltro)

		SE5->(DbSetOrder(2)) //E5_FILIAL+E5_TIPODOC+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DATA)+E5_CLIFOR+E5_LOJA+E5_SEQ
		For nX := 1 to len(aRegSE5)
			
			cChavSE5 := aRegSE5[nX][aScan(aCampos,"E5_FILIAL")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_TIPODOC")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_PREFIXO")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_NUMERO")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_PARCELA")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_TIPO")]
			cChavSE5 += DTOS(aRegSE5[nX][aScan(aCampos,"E5_DATA")])
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_CLIFOR")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_LOJA")]
			cChavSE5 += aRegSE5[nX][aScan(aCampos,"E5_SEQ")]

			if SE5->(!DbSeek(cChavSE5))
				If RecLock('SE5',.T.)
					for nY := 1 to len(aCampos)
						SE5->&(aCampos[nY]) := aRegSE5[nX][nY]
					next nY
					SE5->(MsUnlock())
				EndIf
			endif
		next nX	

		//atualizo grid sangria e suprimento
		Processa({|| AtuConfDocs(.F.,.T.,,,,.F.,.F.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")

		DoRpcClose()
	endif

Return

//--------------------------------------------------------------------------------------
// Funçao para buscar compensações que por algum motivo ficaram com hora fora do periodo do caixa
//--------------------------------------------------------------------------------------
Static Function BuscarComp()

	Local oPnlDet
	Local aCampos := {"MARK","UC0_NUM","UC0_CLIENT","UC0_LOJA","A1_NOME","UC0_PLACA","UC0_VLDINH","UC0_VLVALE","UC0_VLCHTR","UC0_VLTOT","UC0_DATA","UC0_HORA","UC0_OPERAD","UC0_PDV","UC0_ESTACA","UC0_NUMMOV"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local cQry := ""
	Local nOpcX := 0
	Local nX
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Local nTamHora := TamSX3("LW_HRABERT")[1]

	Private lMARKALL := .F.
	Private oGridDet
	Private oDlgDet

	if UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
		aadd(aCampos, "UC0_DOC")
		aadd(aCampos, "UC0_SERIE")
	endif

	//busco compensaçoes fora do intervalo de datas do caixa
	//que podem ser que sejam desse caixa
	cQry := "SELECT UC0.R_E_C_N_O_ RECUC0 "
	cQry += "FROM "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0 "
	cQry += " LEFT JOIN "+RetSqlName("SLW")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SLW ON (
	cQry += " 	SLW.D_E_L_E_T_ = ' ' "
	cQry += " 	AND LW_FILIAL = UC0_FILIAL "
	cQry += " 	AND UC0_OPERAD = LW_OPERADO "
	cQry += " 	AND UC0_NUMMOV = LW_NUMMOV "
	cQry += " 	AND RTRIM(UC0_PDV) = RTRIM(LW_PDV) "
	cQry += " 	AND UC0_ESTACA = LW_ESTACAO "
	cQry += " 	AND UC0_DATA||SUBSTRING(UC0_HORA,1,"+cValToChar(nTamHora)+") BETWEEN LW_DTABERT||LW_HRABERT AND LW_DTFECHA||LW_HRFECHA "
	cQry += " ) "
	cQry += "WHERE UC0.D_E_L_E_T_ = ' ' "
	cQry += " AND UC0_FILIAL = '" + xFilial("UC0") + "'"
	cQry += " AND UC0_ESTORN <> 'S' AND UC0_ESTORN <> 'X' "
	//cQry += " AND UC0_OPERAD = '"+SLW->LW_OPERADO+"' "
	cQry += " AND (UC0_PDV = '' OR RTRIM(UC0_PDV) = '"+Alltrim(SLW->LW_PDV)+"') "
	cQry += " AND UC0_DATA BETWEEN '"+DTOS(SLW->LW_DTABERT)+"' AND '"+DTOS(SLW->LW_DTFECHA)+"' " //com datas do caixa
	cQry += " AND LW_FILIAL IS NULL " //não encontrou a sua SLW
	cQry += " ORDER BY UC0_FILIAL, UC0_NUM "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	SA1->(DbSetOrder(1))
	While QRYT1->(!Eof())

		UC0->(DbGoTo(QRYT1->RECUC0))
		SA1->(DbSeek(xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA))

		aadd(aColsEx, MontaDados("UC0",aCampos, .F.))

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if empty(aColsEx)
		aadd(aColsEx, MontaDados("UC0",aCampos, .T.))
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Busca Compensações não vinculadas" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Compensações encontradas fora do intervalo do caixa:" SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 158, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bLDblClick := {|| oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridDet:oBrowse:Refresh() }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, OrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}

	@ 162, 005 SAY "Obs.: Apenas aparecem aqui, compensações do mesmo PDV deste caixa, que não estão vinculada a nenhum outro caixa." SIZE 380, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 182, 310 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	@ 182, 355 BUTTON oButton1 PROMPT "Vincular" SIZE 040, 012 OF oDlgDet PIXEL Action iif(aScan(oGridDet:aCols,{|x| x[1]=="LBOK"}) > 0, (nOpcX:=1,oDlgDet:End()), MsgInfo("Selecione pelo menos uma compensação!", "Atenção"))
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	if nOpcX == 1

		BeginTran()

		For nX := 1 to len(oGridDet:aCols)
			if oGridDet:aCols[nX][1] == "LBOK" .AND. !empty(oGridDet:aCols[nX][len(oGridDet:aHeader)])
				UC0->(DbGoTo(oGridDet:aCols[nX][len(oGridDet:aHeader)]))

				//forço venda a ficar na hora do intervalo do caixa
				Reclock("UC0", .F.)

				//gravo log da alteração, campos antes de mudar
				If UC0->(FieldPos("UC0_JUSTIF")) > 0
					cAux := AllTrim(UC0->UC0_JUSTIF)
					UC0->UC0_JUSTIF := cAux + " / Substituicao chave caixa. Dados anteriores:" + ;
						"UC0_OPERAD = ["+UC0->UC0_OPERAD+"], " + ;
						"UC0_PDV = ["+UC0->UC0_PDV+"], " + ;
						"UC0_ESTACA = ["+UC0->UC0_ESTACA+"], " + ;
						"UC0_NUMMOV = ["+UC0->UC0_NUMMOV+"], " + ;
						"UC0_DATA = ["+ DTOS(UC0->UC0_DATA) +"], " + ;
						"UC0_HORA = ["+UC0->UC0_HORA+"] "
				Endif

				UC0->UC0_OPERAD := SLW->LW_OPERADO
				UC0->UC0_PDV := SLW->LW_PDV
				UC0->UC0_ESTACA := SLW->LW_ESTACAO
				UC0->UC0_NUMMOV := SLW->LW_NUMMOV

				if DTOS(UC0->UC0_DATA)+UC0->UC0_HORA >= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA
					UC0->UC0_HORA := SLW->LW_HRFECHA
				elseif DTOS(UC0->UC0_DATA)+UC0->UC0_HORA <= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT
					UC0->UC0_HORA := SLW->LW_HRABERT
				endif

				UC0->(MsUnlock())
			endif
		next nX

		EndTran()

		//atualizo grid compensações
		Processa({|| AtuConfDocs(.F.,.F.,,,,.T.,.F.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Ações dos botões aba Compensações da tela de conferencia documentos
//--------------------------------------------------------------------------------------
Static Function MntCompensacao(nOpcX)

	Local nPosCod := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="UC0_NUM"})
	Local nPosLeg2 := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="LEG2"})

	if nOpcX == 3 //inclui
		TelaComp(nOpcX)
	else
		if empty(oGridUC0:aCols[oGridUC0:nAt][nPosCod])
			Return
		endif
		if oGridUC0:aCols[oGridUC0:nAt][nPosLeg2] <> "BR_AZUL" .AND. nOpcX != 2 .AND. nOpcX != 6
			MsgAlert("Registro não ativo nesta base. Ação não permitida!","Atenção")
			Return
		endif
		UC0->(DbSetOrder(1))
		if UC0->(Dbseek(xFilial("UC0")+oGridUC0:aCols[oGridUC0:nAt][nPosCod] ))
			if nOpcX == 2 //visualiza
				TelaComp(nOpcX)
			elseif nOpcX == 5 //estornar
				DelComp(UC0->(Recno()))
			elseif nOpcX == 6 //reprocessa
				ReprocComp(UC0->(Recno()))
			elseif nOpcX == 7 //troca cliente
				TrocaCliCmp()
			elseif nOpcX == 8 //troca Entrada
				TrocaForm(2)
			elseif nOpcX == 9 //troca Saida
				AltComp(UC0->(Recno()))
			endif
		else
			if nOpcX == 6 .AND. oGridUC0:aCols[oGridUC0:nAt][nPosLeg2] == "BR_AMARELO" //reprocessa
				if ForcaIntComp()
					ReprocComp(UC0->(Recno()))
				else
					MsgAlert("Falha ao encontrar compensação!","Atenção")
				endif
			else
				MsgAlert("Falha ao encontrar compensação!","Atenção")
			endif
			
		endif
	endif

	if nOpcX != 2
		Processa({|| AtuConfDocs(.F.,.F.,,,,.T.,.F.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Inclusao de Compensação de Valores
//--------------------------------------------------------------------------------------
Static Function TelaComp(nOpcX)

	Local lOk := .T.
	Local dBkpDbase := dDataBase
	Local cMsgErro := ""
	Local nRecnoUC0 := 0
	Local bConfirm := {|| nRecnoUC0 := UC0->(Recno()) , oDlgAux:end() }
	Local bCancel := {|| oDlgAux:end() }
	Local oPnlAux
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local cCliente, cLoja
	Private oDlgAux

	dDataBase := SLW->LW_DTABERT

	DEFINE MSDIALOG oDlgAux TITLE "Compensação de Valores" FROM 000, 000  TO 570, 800 COLORS 0, 16777215 PIXEL STYLE DS_MODALFRAME

	@ 000, 000 MSPANEL oPnlAux SIZE (oDlgAux:nWidth/2), (oDlgAux:nHeight/2)-12 OF oDlgAux
	oPnlAux:SetCSS( "TPanel{border: none; background-color: #f4f4f4;}" )
	U_TPDVA005(oPnlAux, .T., bConfirm, bCancel, nOpcX) //monta tela de compensação

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if nRecnoUC0 > 0 .AND. nOpcX == 3 //se retornou recno é pq incluiu
		if lLogCaixa 
			cLogCaixa += "FORMAS ENTRADA:" + CRLF
			UC1->(DbSetOrder(1))
			UC1->(DbSeek( xFilial("UC1") + UC0->UC0_NUM ))
			While UC1->(!Eof()) .And. UC1->UC1_FILIAL+UC1->UC1_NUM == xFilial("UC1")+UC0->UC0_NUM
				if Alltrim(UC1->UC1_FORMA) == "CH"
					cCliente := UC0->UC0_CLIENT
					cLoja := UC0->UC0_LOJA
				elseif Alltrim(UC1->UC1_FORMA) $ "CC/CD"
					if Posicione("SAE",1,xFilial("SAE")+UC1->UC1_ADMFIN, "AE_FINPRO" )=="S"
						cCliente := UC0->UC0_CLIENT 
						cLoja := UC0->UC0_LOJA 
					else
						cCliente := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] )
						cLoja := PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
					endif
				elseif Alltrim(UC1->UC1_FORMA) == "CF"
					cCliente := Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_COD")
					cLoja := SA1->A1_LOJA
				endif
					
				cLogCaixa += Space(4) + UC1->UC1_SEQ + " | " + UC1->UC1_FORMA + " | " +;
								Transform(UC1->UC1_VALOR ,"@E 999,999,999.99") + ;
								" | " + cCliente +" | "+cLoja+" | "+Alltrim(Posicione("SA1",1,xFilial("SA1")+cCliente+cLoja, "A1_NREDUZ")) + CRLF

				UC1->(DbSkip())
			EndDo

			cLogCaixa += "FORMAS SAIDA:" + CRLF
			if UC0->UC0_VLDINH > 0
				cLogCaixa += Space(4) + "DINHEIRO (R$) " + " | " + Transform(UC0->UC0_VLDINH ,"@E 999,999,999.99") + CRLF
			endif
			if UC0->UC0_VLCHTR > 0
				cLogCaixa += Space(4) + "CHEQUE TROCO  " + " | " + Transform(UC0->UC0_VLCHTR ,"@E 999,999,999.99") + CRLF
			endif
			if UC0->UC0_VLVALE > 0
				cLogCaixa += Space(4) + "VALE HAVER    " + " | " + Transform(UC0->UC0_VLVALE ,"@E 999,999,999.99") + CRLF
			endif
			
		endif

		//gera financeiro compensaçao
		MsAguarde( {|| lOk := U_TRETE024(UC0->UC0_NUM,@cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
		if lOk
			MsgInfo("Inclusao da Compensação realizada com sucesso!","Atenção")

			if lLogCaixa
				GrvLogConf("4","I", cLogCaixa, UC0->UC0_NUM,cPfxCmp)
			endif
		else
			MsgAlert("Falha ao gerar financeiro da compensação! Operação abortada. " + cMsgErro, "Atenção")
		endif

	endif

	dDataBase := dBkpDbase

Return

//--------------------------------------------------------------------------------------
// Exclusão de Compensação
//--------------------------------------------------------------------------------------
Static Function DelComp(nRecUC0, lAuto)

	Local lOk := .T.
	Local cMsgErro := ""
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local cChavUF2 := ""
	Local cMsgPerg := ""
	Local aRecnoUF2 := {}
	Local nX
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo
	Local cCliente, cLoja
	Default lAuto := .F.

	if empty(nRecUC0)
		Return
	endif

	UC0->(DbSetOrder(1))
	UC0->(DBGoTo(nRecUC0))

	//Verifica se existe cheque troco conciliado na compensação
	UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
	cChavUF2 := xFilial("UF2")+PadR(UC0->UC0_NUM,TamSX3("UF2_DOC")[1])+PadR(cPfxComp,TamSX3("UF2_SERIE")[1])+PadR(SLW->LW_PDV,TamSX3("UF2_PDV")[1])
	if UF2->(DbSeek(cChavUF2))
		SE5->(Dbsetorder(1))
		While UF2->(!Eof()) .And. UF2->(UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV) == cChavUF2
			If SE5->(DbSeek(xFilial("SE5")+;
				DTOS(UF2->UF2_DATAMO)+;
				PadR(UF2->UF2_BANCO,TamSX3("E5_BANCO")[1])+;
				PadR(UF2->UF2_AGENCI,TamSX3("E5_AGENCIA")[1])+;
				PadR(UF2->UF2_CONTA,TamSX3("E5_CONTA")[1])+;
				PadR(UF2->UF2_NUM,TamSX3("E5_NUMCHEQ")[1]))) .And. SE5->E5_RECPAG = "P" .And. SE5->E5_SITUACA <> "C"

				If Upper(SE5->E5_RECONC) == "X"
					MsgAlert("Estorno negado. Cheque troco da compensação já se encontra conciliado!","Atenção")
					Return
				ElseIf lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
					MsgAlert("Estorno negado. Cheque troco da compensação já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
					Return
				EndIf

				aadd(aRecnoUF2, UF2->(Recno()))
			EndIf
			UF2->(DbSkip())
		Enddo
	EndIf

	cMsgPerg := "Deseja realmente estornar a compensação "+UC0->UC0_NUM+" ?"
	If UC0->UC0_VLVALE > 0 .Or. UC0->UC0_VLCHTR > 0
		cMsgPerg := "Esta compensação possui cheque troco ou vale haver que serão excluidos. Deseja realmente estornar a compensação "+UC0->UC0_NUM+" ? "
	endif

	if lAuto .OR. MsgYesNo(cMsgPerg,"Atenção")

		if !lAuto .AND. lLogCaixa 
			cLogCaixa += "FORMAS ENTRADA:" + CRLF
			UC1->(DbSetOrder(1))
			UC1->(DbSeek( xFilial("UC1") + UC0->UC0_NUM ))
			While UC1->(!Eof()) .And. UC1->UC1_FILIAL+UC1->UC1_NUM == xFilial("UC1")+UC0->UC0_NUM
				if Alltrim(UC1->UC1_FORMA) == "CH"
					cCliente := UC0->UC0_CLIENT
					cLoja := UC0->UC0_LOJA
				elseif Alltrim(UC1->UC1_FORMA) $ "CC/CD"
					if Posicione("SAE",1,xFilial("SAE")+UC1->UC1_ADMFIN, "AE_FINPRO" )=="S"
						cCliente := UC0->UC0_CLIENT 
						cLoja := UC0->UC0_LOJA 
					else
						cCliente := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] )
						cLoja := PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
					endif
				elseif Alltrim(UC1->UC1_FORMA) == "CF"
					cCliente := Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_COD")
					cLoja := SA1->A1_LOJA
				endif
					
				cLogCaixa += Space(4) + UC1->UC1_SEQ + " | " + UC1->UC1_FORMA + " | " +;
								Transform(UC1->UC1_VALOR ,"@E 999,999,999.99") + ;
								" | " + cCliente +" | "+cLoja+" | "+Alltrim(Posicione("SA1",1,xFilial("SA1")+cCliente+cLoja, "A1_NREDUZ")) + CRLF

				UC1->(DbSkip())
			EndDo

			cLogCaixa += "FORMAS SAIDA:" + CRLF
			if UC0->UC0_VLDINH > 0
				cLogCaixa += Space(4) + "DINHEIRO (R$) " + " | " + Transform(UC0->UC0_VLDINH ,"@E 999,999,999.99") + CRLF
			endif
			if UC0->UC0_VLCHTR > 0
				cLogCaixa += Space(4) + "CHEQUE TROCO  " + " | " + Transform(UC0->UC0_VLCHTR ,"@E 999,999,999.99") + CRLF
			endif
			if UC0->UC0_VLVALE > 0
				cLogCaixa += Space(4) + "VALE HAVER    " + " | " + Transform(UC0->UC0_VLVALE ,"@E 999,999,999.99") + CRLF
			endif
			
		endif

		BeginTran()

		//estorno primeiro os cheques troco
		for nX := 1 to len(aRecnoUF2)
			UF2->(DbGoTo(aRecnoUF2[nX]))
			LjMsgRun("Estornando cheque troco...","Aguarde...",{|| lOk := U_TRETE29G(.F., .F., .T., .F., @cMsgErro) })
			if !lOk
				DisarmTransaction()
				MsgAlert("Não foi possível estornar a compensaçao! Falha ao excluir cheque troco." + CRLF + cMsgErro,"Atenção")
				EXIT
			endif
		next nX

		if lOk
			Reclock("UC0",.F.)
			UC0->UC0_ESTORN := "X"
			UC0->(MsUnLock())

			MsAguarde( {|| lOk := U_TRETE024(UC0->UC0_NUM,@cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
			if lOk
				if !lAuto .AND. lLogCaixa
					GrvLogConf("4","E", cLogCaixa, UC0->UC0_NUM,cPfxComp)
				endif
			else
				DisarmTransaction()
				MsgAlert("Não foi possível estornar a compensaçao! Falha ao excluir financeiro." + CRLF + cMsgErro,"Atenção")
			endif
		endif

		EndTran()
	endif

Return

//--------------------------------------------------------------------------------------
// Reprocessar financeiro da Compensação
//--------------------------------------------------------------------------------------
Static Function ReprocComp(nRecUC0)

	Local lOk := .T.
	Local cMsgErro := ""

	if empty(nRecUC0)
		Return
	endif

	UC0->(DbSetOrder(1))
	UC0->(DBGoTo(nRecUC0))

	if UC0->UC0_ESTORN $ "S,X"
		DelComp(nRecUC0, .T.)
	else
		BeginTran()

		RecLock("UC0", .F.)
		UC0->UC0_GERFIN := "R"
		UC0->(MsUnlock())

		//gera financeiro
		MsAguarde( {|| lOk := U_TRETE024(UC0->UC0_NUM,@cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
		if lOk
			MsgInfo("Financeiro reprocessado com sucesso!","Atenção")
		else
			DisarmTransaction()
			MsgAlert("Falha ao reprocessar financeiro! "+ CRLF +cMsgErro,"Atenção")
		endif

		EndTran()
	endif

Return

//Força integraçao da compensação
Static Function ForcaIntComp()

	Local lRet := .F.
	Local nX, nY
	Local aCamposUC0 := {}
	Local aCamposUC1 := {}
	Local cFiltro := ""
	Local aRegUC0 := {}
	Local aRegUC1 := {}
	Local nPosLeg2 := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local nPosLeg3 := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="LEG3"})
	Local nPosCod := aScan(oGridUC0:aHeader,{|x| AllTrim(x[2])=="UC0_NUM"})
	Local cChavUC0
	Local cChavUC1

	if oGridUC0:aCols[oGridUC0:nAt][nPosLeg2] == "BR_AMARELO" .AND. oGridUC0:aCols[oGridUC0:nAt][nPosLeg3] == "BR_VERMELHO"

		aadd(aCamposUC0, "UC0_FILIAL" )
		aadd(aCamposUC0, "UC0_NUM" )
		aadd(aCamposUC0, "UC0_DATA" )
		aadd(aCamposUC0, "UC0_HORA" )
		aadd(aCamposUC0, "UC0_PDV" )
		aadd(aCamposUC0, "UC0_OPERAD" )
		aadd(aCamposUC0, "UC0_NUMMOV" )
		aadd(aCamposUC0, "UC0_ESTACA" )
		aadd(aCamposUC0, "UC0_CLIENT" )
		aadd(aCamposUC0, "UC0_LOJA" )
		aadd(aCamposUC0, "UC0_PLACA" )
		aadd(aCamposUC0, "UC0_VLDINH" )
		aadd(aCamposUC0, "UC0_VLVALE" )
		aadd(aCamposUC0, "UC0_VLCHTR" )
		aadd(aCamposUC0, "UC0_VLTOT" )
		aadd(aCamposUC0, "UC0_GERFIN" )
		aadd(aCamposUC0, "UC0_ESTORN" )
		aadd(aCamposUC0, "UC0_VEND" )
		if UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
			aadd(aCamposUC0, "UC0_DOC" )
			aadd(aCamposUC0, "UC0_SERIE" )
		endif

		aadd(aCamposUC1, "UC1_FILIAL" )
		aadd(aCamposUC1, "UC1_NUM" )
		aadd(aCamposUC1, "UC1_FORMA" )
		aadd(aCamposUC1, "UC1_SEQ" )
		aadd(aCamposUC1, "UC1_VENCTO" )
		aadd(aCamposUC1, "UC1_VALOR" )
		aadd(aCamposUC1, "UC1_CFRETE" )
		aadd(aCamposUC1, "UC1_ADMFIN" )
		aadd(aCamposUC1, "UC1_NSUDOC" )
		aadd(aCamposUC1, "UC1_CODAUT" )
		aadd(aCamposUC1, "UC1_BANCO" )
		aadd(aCamposUC1, "UC1_AGENCI" )
		aadd(aCamposUC1, "UC1_CONTA" )
		aadd(aCamposUC1, "UC1_NUMCH" )
		aadd(aCamposUC1, "UC1_CGC" )
		aadd(aCamposUC1, "UC1_RG" )
		aadd(aCamposUC1, "UC1_TEL1" )
		aadd(aCamposUC1, "UC1_COMPEN" )
		aadd(aCamposUC1, "UC1_CMC7" )
		aadd(aCamposUC1, "UC1_OBS" )
		
		cFiltro := "D_E_L_E_T_ = ' ' AND UC0_FILIAL='"+xFilial("UC0")+"' AND UC0_NUM = '"+oGridUC0:aCols[oGridUC0:nAt][nPosCod]+"'"
		aRegUC0 := DoRPC_Pdv("STDQueryDB", aCamposUC0, {"UC0"}, cFiltro)

		cFiltro := "D_E_L_E_T_ = ' ' AND UC1_FILIAL='"+xFilial("UC1")+"' AND UC1_NUM = '"+oGridUC0:aCols[oGridUC0:nAt][nPosCod]+"'"
		aRegUC1 := DoRPC_Pdv("STDQueryDB", aCamposUC1, {"UC1"}, cFiltro)

		if !empty(aRegUC0) .AND. !empty(aRegUC1)

			UC0->(DbSetOrder(1)) //UC0_FILIAL+UC0_NUM
			For nX := 1 to len(aRegUC0)
				
				cChavUC0 := aRegUC0[nX][aScan(aCamposUC0,"UC0_FILIAL")]
				cChavUC0 += aRegUC0[nX][aScan(aCamposUC0,"UC0_NUM")]

				if UC0->(!DbSeek(cChavUC0))
					If RecLock('UC0',.T.)
						for nY := 1 to len(aCamposUC0)
							UC0->&(aCamposUC0[nY]) := aRegUC0[nX][nY]
						next nY
						UC0->(MsUnlock())
					EndIf
				endif
			next nX	

			UC1->(DbSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
			For nX := 1 to len(aRegUC1)
				
				cChavUC1 := aRegUC1[nX][aScan(aCamposUC1,"UC1_FILIAL")]
				cChavUC1 += aRegUC1[nX][aScan(aCamposUC1,"UC1_NUM")]
				cChavUC1 += aRegUC1[nX][aScan(aCamposUC1,"UC1_FORMA")]
				cChavUC1 += aRegUC1[nX][aScan(aCamposUC1,"UC1_SEQ")]

				if UC1->(!DbSeek(cChavUC1))
					If RecLock('UC1',.T.)
						for nY := 1 to len(aCamposUC1)
							UC1->&(aCamposUC1[nY]) := aRegUC1[nX][nY]
						next nY
						UC1->(MsUnlock())
					EndIf
				endif
			next nX	

			lRet := .T.

		endif

		DoRpcClose()
	endif

Return lRet

//--------------------------------------------------------------------------------------
// Tela Altera saida da compensação
//--------------------------------------------------------------------------------------
Static Function AltComp(nRecUC0, bRefresh)

	Local oNumCmp, oEmissao, oCliente, oPlaca, oVlrSaida, oVlrDin
	Local aCpoUF2 := {"LEGCHT","UF2_BANCO","UF2_AGENCI","UF2_CONTA","UF2_NUM","UF2_VALOR","UF2_DOC","UF2_SERIE","UF2_PDV"}
	Local aCpoVLH := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","E1_NATUREZ"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local bAtuTela := {|| AtuDetCMP(aCpoUF2,aCpoVLH) }
	Private oDlgAux
	Private oGridUF2//, oGridVlh

	if empty(nRecUC0)
		Return
	endif

	UC0->(DbSetOrder(1))
	UC0->(DBGoTo(nRecUC0))

	DEFINE MSDIALOG oDlgAux TITLE "Alterar Saída da Compensação" STYLE DS_MODALFRAME FROM 000, 000  TO 500, 800 COLORS 0, 16777215 PIXEL

	//---- Dados Cabeçalho
	@ 05, 05 GROUP oGroup1 TO 060, 395 PROMPT "Dados da Compensação" OF oDlgAux COLOR 0, 16777215 PIXEL

	@ 015, 010 SAY "Num.Compensação" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 023, 010 MSGET oNumCmp VAR UC0->UC0_NUM When .F. SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 095 SAY "Cliente" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 023, 095 MSGET oCliente VAR (UC0->UC0_CLIENT+"/"+UC0->UC0_LOJA+" - "+Posicione("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_NOME")) When .F. SIZE 200, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 037, 010 SAY "Dt.Emissão" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 045, 010 MSGET oEmissao VAR UC0->UC0_DATA When .F. SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 037, 095 SAY "Placa" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 045, 095 MSGET oPlaca VAR UC0->UC0_PLACA When .F. SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 037, 180 SAY "Valor Total" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 045, 180 MSGET oVlrSaida VAR UC0->UC0_VLTOT When .F. Picture "@E 999,999,999.99" SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 037, 265 SAY "Valor Dinheiro" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 045, 265 MSGET oVlrDin VAR UC0->UC0_VLDINH When .F. Picture "@E 999,999,999.99" SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	//---- Cheque Troco
	@ 065, 005 GROUP oGroup1 TO 145, 395 PROMPT "Cheque Troco" OF oDlgAux COLOR 0, 16777215 PIXEL

	if SuperGetMV("TP_ACTCHT",,.F.)
		aHeaderEx := MontaHeader(aCpoUF2)
		aColsEx := {}
		aadd(aColsEx, MontaDados("UF2",aCpoUF2, .T.))
		oGridUF2 := MsNewGetDados():New( 075, 010, 140, 330,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgAux, aHeaderEx, aColsEx)
		oGridUF2:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridUF2, @nCol), )}

		TButton():New( 075, 335, "Incluir", oDlgAux, {|| IncChqTroco(2,,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( 090, 335, "Excluir", oDlgAux, {|| DelChqTroco(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],2,,,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( 105, 335, "Substituir", oDlgAux, {|| SubChqTroco(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],.T.,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( 120, 335, "Corrigir Fin.", oDlgAux, {|| CorrigeCHT(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	else
		@ 075, 020 SAY "Cheque Troco não Habilitado!" SIZE 100, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	endif

	//---- Vale Haver
	@ 150, 005 GROUP oGroup1 TO 230, 395 PROMPT "Vale Haver" OF oDlgAux COLOR 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCpoVLH)
	aColsEx := {}
	aadd(aColsEx, MontaDados("SE1",aCpoVLH, .T.))
	oGridVLH := MsNewGetDados():New( 160, 010, 225, 330,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgAux, aHeaderEx, aColsEx)
	oGridVLH:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridVLH, @nCol), )}

	TButton():New( 160, 335, "Incluir", oDlgAux, {|| IncValeHav(2,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 175, 335, "Excluir", oDlgAux, {|| DelValeHav(oGridVLH:aCols[oGridVLH:nAt][len(aCpoVLH)+1],2,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	@ 235, 355 BUTTON oButton1 PROMPT "Fechar" SIZE 040, 012 OF oDlgAux PIXEL Action oDlgAux:End()
	oButton1:SetCSS( CSS_BTNAZUL )

	AtuDetCMP(aCpoUF2,aCpoVLH, .F.)

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Carrega dados na tela de Alterar Compensação (Altera Saída)
//--------------------------------------------------------------------------------------
Static Function AtuDetCMP(aCpoUF2,aCpoVLH, lRefresh)

	Local aDados := {}
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default lRefresh := .T.

	cPfxComp := PadR(cPfxComp,TamSX3("E1_PREFIXO")[1])

	//Cheque Troco
	if SuperGetMV("TP_ACTCHT",,.F.)
		oGridUF2:aCols := {}
		UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
		if UF2->(DbSeek(xFilial("UF2")+UC0->UC0_NUM+cPfxComp+Alltrim(UC0->UC0_PDV)))
			While UF2->(!Eof()) .And. UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE+Alltrim(UF2->UF2_PDV) == xFilial("UF2")+UC0->UC0_NUM+cPfxComp+Alltrim(UC0->UC0_PDV)

				aadd(oGridUF2:aCols, MontaDados("UF2",aCpoUF2))
				oGridUF2:aCols[len(oGridUF2:aCols)][aScan(aCpoUF2,"LEGCHT")] := LegendUF2()

				UF2->(DbSkip())
			EndDO
		else
			aadd(oGridUF2:aCols, MontaDados("UF2",aCpoUF2, .T.))
		endif
	endif

	//vale Haver
	oGridVLH:aCols := {}
	if U_T028TVLH(4, @aDados, aCpoVLH, UC0->UC0_NUM, cPfxComp) > 0 //se tem vale haver
		if !empty(aDados)
			oGridVLH:aCols := aClone(aDados)
		else
			aadd(oGridVLH:aCols, MontaDados("SE1",aCpoVLH, .T.))
		endif
	else
		aadd(oGridVLH:aCols, MontaDados("SE1",aCpoVLH, .T.))
	endif

	if lRefresh
		if SuperGetMV("TP_ACTCHT",,.F.)
			oGridUF2:oBrowse:Refresh()
		endif
		if SuperGetMV("TP_ACTVLH",,.F.)
			oGridVLH:oBrowse:Refresh()
		endif
		oDlgAux:Refresh()
	endif

Return

//-------------------------------------------------------------------------
//faz alteração do cliente da compensação e dos títulos relacionados
//posicionar na compensação antes de chamar função
//-------------------------------------------------------------------------
Static Function TrocaCliCmp()

	Local cPrefixComp 	:= SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local nOpcA   := 0
	Local cNumCmp := UC0->UC0_NUM
	Local oNumCmp
	Local cCliCmp := UC0->UC0_CLIENT
	Local oCliCmp
	Local cLojCmp := UC0->UC0_LOJA
	Local oLojCmp
	Local cNomeCmp := Posicione("SA1",1,xFilial("SA1")+cCliCmp+cLojCmp,"A1_NOME")
	Local oNomeCmp
	Local cPlacaCmp := UC0->UC0_PLACA
	Local oPlacaCmp
	Local cJustCmp := UC0->UC0_JUSTIF
	Local oJustCmp
	Local oTrocaNum
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa

	cLogCaixa += "CLIENTE ANTERIOR: " 
	cLogCaixa += cCliCmp + "/" + cLojCmp + " - " + cNomeCmp + CRLF

	DEFINE MSDIALOG oTrocaNum TITLE "Alterar Cliente Compensação" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 600 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oTrocaNum,05,05,172,290,.F.,.T.,.T.)

	@ 005, 010 SAY "Compensação" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 010 MSGET oNumCmp VAR cNumCmp When .F. SIZE 095, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 026, 002 SAY Replicate("_",284) SIZE 284, 007 OF oPnlDet COLORS CLR_HGRAY, 16777215 PIXEL

	@ 037, 010 SAY "Cliente" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 045, 010 MSGET oCliCmp VAR cCliCmp SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL F3 "SA1" VALID VldTrCliCmp(@cCliCmp, @cLojCmp, @cNomeCmp, @oTrocaNum)

	@ 037, 075 SAY "Loja" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 045, 075 MSGET oLojCmp VAR cLojCmp SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL  VALID VldTrCliCmp(@cCliCmp, @cLojCmp, @cNomeCmp, @oTrocaNum) 

	@ 037, 110 SAY "Nome Cliente" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 045, 110 MSGET oNomeCmp VAR cNomeCmp When .F. SIZE 150, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 059, 010 SAY "Placa" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 067, 010 MSGET oPlacaCmp VAR cPlacaCmp SIZE 095, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL Picture "@!R NNN-9N99"

	@ 081, 010 SAY "Observações" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 089, 010 GET oJustCmp VAR cJustCmp OF oPnlDet MULTILINE SIZE 250, 030 COLORS 0, 16777215 HSCROLL NO VSCROLL NOBORDER PIXEL

	@ 182, 255 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oTrocaNum PIXEL Action iif(empty(cCliCmp) .OR. empty(cNomeCmp) .OR. empty(cPlacaCmp) .OR. empty(cJustCmp),MsgInfo("Campos obrigatórios nao foram preenchidos!","Atenção"),(nOpcA:=1,oTrocaNum:End()))
	oButton1:SetCSS( CSS_BTNAZUL )
	@ 182, 210 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oTrocaNum PIXEL Action oTrocaNum:End()

	ACTIVATE MSDIALOG oTrocaNum CENTERED

	if nOpcA == 1

		SA1->(DbSetOrder(1))
		if SA1->(DbSeek(xFilial("SA1")+cCliCmp+cLojCmp))

			//Altera SE1
			DbSelectArea("SE1")
			SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			If SE1->(dbSeek(xFilial("SE1")+UC0->UC0_CLIENT+UC0->UC0_LOJA+SubStr(cPrefixComp,1,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM ))
				While SE1->(!EOF()) .And. SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM == xFilial("SE1")+UC0->UC0_CLIENT+UC0->UC0_LOJA+SubStr(cPrefixComp,1,TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM
					RecLock("SE1",.F.)
					 	SE1->E1_CLIENTE := cCliCmp
					 	SE1->E1_LOJA	:= cLojCmp
					 	SE1->E1_NOMCLI	:= SA1->A1_NOME
					 	SE1->E1_XPLACA  := cPlacaCmp
				 	SE1->(MsUnlock())

					SE1->(dbSkip())
				EndDo
			Endif

			//Altera SE1 - Vale em haver
			If SE1->(dbSeek(xFilial("SE1")+UC0->UC0_CLIENT+UC0->UC0_LOJA+UC0->UC0_ESTACA+UC0->UC0_NUM+SubStr("VLH",1,TamSx3("E1_PARCELA")[1])+"NCC"))
				While SE1->(!EOF()) .And. SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) == ;
									xFilial("SE1")+UC0->UC0_CLIENT+UC0->UC0_LOJA+UC0->UC0_ESTACA+UC0->UC0_NUM+SubStr("VLH",1,TamSx3("E1_PARCELA")[1])+"NCC"

				 	RecLock("SE1",.F.)
					 	SE1->E1_CLIENTE := cCliCmp
					 	SE1->E1_LOJA	:= cLojCmp
					 	SE1->E1_NOMCLI	:= SA1->A1_NOME
				 	SE1->(MsUnlock())

					SE1->(dbSkip())
				EndDo
			Endif

			//Altera UF2
			If Select("QRYUF2") > 0
	  			QRYUF2->(DbCloseArea())
			Endif
			cQry := "SELECT R_E_C_N_O_ AS REG"
			cQry += " FROM "+RetSqlName("UF2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""
			cQry += " WHERE D_E_L_E_T_	<> '*'"
			cQry += " AND UF2_FILIAL		= '"+xFilial("UF2")+"'"
			cQry += " AND UF2_SERIE 	= '"+SubStr(cPrefixComp,1,TamSx3("UF2_SERIE")[1])+"'"
			cQry += " AND UF2_DOC	 	= '"+UC0->UC0_NUM+"'"
			cQry += " AND UF2_CLIENT 	= '"+UC0->UC0_CLIENT+"'"
			cQry += " AND UF2_LOJACL	= '"+UC0->UC0_LOJA+"'"
			cQry := ChangeQuery(cQry)
			TcQuery cQry NEW Alias "QRYUF2"
			If QRYUF2->(!EOF())
				While QRYUF2->(!EOF())
					UF2->(dbGoTo(QRYUF2->REG))
					RecLock("UF2",.F.)
						UF2->UF2_CLIENT	:= cCliCmp
						UF2->UF2_LOJACL	:= cLojCmp
					UF2->(MsUnlock())
	             	QRYUF2->(dbSkip())
				EndDo
			Endif
			If Select("QRYUF2") > 0
	   			QRYUF2->(DbCloseArea())
			Endif

			//Altera SEF
			If Select("QRYSEF") > 0
	  			QRYSEF->(DbCloseArea())
			Endif
			cQry := "SELECT R_E_C_N_O_ AS REG"
			cQry += " FROM "+RetSqlName("SEF")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""
			cQry += " WHERE D_E_L_E_T_	<> '*'"
			cQry += " AND EF_FILIAL		= '"+xFilial("SEF")+"'"
			cQry += " AND EF_PREFIXO 	= '"+SubStr(cPrefixComp,1,TamSx3("E1_PREFIXO")[1])+"'"
			cQry += " AND EF_TITULO 	= '"+UC0->UC0_NUM+"'"
			cQry += " AND EF_CLIENTE 	= '"+UC0->UC0_CLIENT+"'"
			cQry += " AND EF_LOJACLI	= '"+UC0->UC0_LOJA+"'"
			cQry := ChangeQuery(cQry)
			TcQuery cQry NEW Alias "QRYSEF"
			If QRYSEF->(!EOF())
				While QRYSEF->(!EOF())
					SEF->(dbGoTo(QRYSEF->REG))
					RecLock("SEF",.F.)
						SEF->EF_CLIENTE	:= cCliCmp
						SEF->EF_LOJACLI	:= cLojCmp
					SEF->(MsUnlock())
	             	QRYSEF->(dbSkip())
				EndDo
			Endif
			If Select("QRYSEF") > 0
	   			QRYSEF->(DbCloseArea())
			Endif

			//Altera SE5
			If Select("QRYSE5") > 0
	   			QRYSE5->(DbCloseArea())
			Endif
			cQry := "SELECT R_E_C_N_O_ AS REG"
			cQry += " FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+""
			cQry += " WHERE D_E_L_E_T_	<> '*'"
			cQry += " AND E5_FILIAL		= '"+xFilial("SE5")+"'"
			cQry += " AND E5_PREFIXO 	= '"+SubStr(cPrefixComp,1,TamSx3("E1_PREFIXO")[1])+"'"
			cQry += " AND E5_NUMERO 	= '"+UC0->UC0_NUM+"'"
			cQry += " AND E5_CLIFOR 	= '"+UC0->UC0_CLIENT+"'"
			cQry += " AND E5_LOJA	 	= '"+UC0->UC0_LOJA+"'"
			cQry := ChangeQuery(cQry)
			TcQuery cQry NEW Alias "QRYSE5"
			If QRYSE5->(!EOF())
				While QRYSE5->(!EOF())
					SE5->(dbGoTo(QRYSE5->REG))
					RecLock("SE5",.F.)
						SE5->E5_CLIFOR	:= cCliCmp
						SE5->E5_LOJA	:= cLojCmp
					SE5->(MsUnlock())
	             	QRYSE5->(dbSkip())
				EndDo
			Endif
			If Select("QRYSE5") > 0
	  			QRYSE5->(DbCloseArea())
			Endif

			//Por último, altera na compensação
			RecLock("UC0", .F.)
				UC0->UC0_CLIENT := cCliCmp
				UC0->UC0_LOJA 	:= cLojCmp
				UC0->UC0_PLACA 	:= cPlacaCmp
				UC0->UC0_JUSTIF := cJustCmp
			UC0->(MsUnlock())

			cLogCaixa += "NOVO CLIENTE: " 
			cLogCaixa += cCliCmp + "/" + cLojCmp + " - " + cNomeCmp + CRLF

			MsgInfo("Alteração dos dados cliente concluída com sucesso!","Sucesso")

			if lLogCaixa
				GrvLogConf("4","A", cLogCaixa, UC0->UC0_NUM, cPrefixComp)
			endif

		endif
	endif

Return

Static Function VldTrCliCmp(cCliCmp, cLojCmp, cNomeCmp, oTrocaNum)

	Local lRet := .T.
	Local lCMPCPAD := SuperGetMv("TP_CMPCPAD",,.F.) //Habilita compensação para cliente padrão
	
	if lRet .AND. !empty(cCliCmp+cLojCmp) .AND. cCliCmp+cLojCmp == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
		if !lCMPCPAD
			lRet := .F.
			MsgInfo("A Compensação não pode ser vinculada ao cliente consumidor padrão!")			
		elseif UC0->UC0_VLVALE > 0
			lRet := .F.
			MsgInfo("A Compensação possui titulo de vale haver, e não poderá ser alterado cliente para consumidor padrão.")
		endif
	endif

	cNomeCmp := Posicione("SA1",1,xFilial("SA1")+cCliCmp+cLojCmp,"A1_NOME")
	oTrocaNum:Refresh()

Return lRet
//--------------------------------------------------------------------------------------
// Ações dos botões aba Vale Serviço da tela de conferencia documentos
//--------------------------------------------------------------------------------------
Static Function MntValeSrv(nOpcX)

	Local lRefresh := .F.
	Local nPosAmb := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_AMB"})
	Local nPosCod := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="UIC_CODIGO"})
	Local nPosLeg2 := aScan(oGridVLS:aHeader,{|x| AllTrim(x[2])=="LEG2"})

	if nOpcX == 3 //inclui
		TelaVls(nOpcX)
		lRefresh := .T.
	else
		if empty(oGridVLS:aCols[oGridVLS:nAt][nPosCod])
			Return
		endif
		if oGridVLS:aCols[oGridVLS:nAt][nPosLeg2] == "BR_AMARELO" .AND. nOpcX != 2
			MsgAlert("Registro não ativo nesta base. Ação não permitida!","Atenção")
			Return
		endif
		UIC->(DbSetOrder(1))
		if UIC->(Dbseek(xFilial("UIC")+oGridVLS:aCols[oGridVLS:nAt][nPosAmb]+oGridVLS:aCols[oGridVLS:nAt][nPosCod] ))
			if nOpcX == 2 //visualiza
				TelaVls(nOpcX)
			elseif nOpcX == 5 //exclui
				EstornaVLS(UIC->(Recno()))
				lRefresh := .T.
			elseif nOpcX == 6 //reprocessa
				ReprocVLS(UIC->(Recno()))
				lRefresh := .T.
			endif
		else
			MsgAlert("Falha ao encontrar vale serviço!","Atenção")
		endif
	endif

	if lRefresh
		Processa({|| AtuConfDocs(.F.,.F.,,,,.F.,.T.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Funçao para buscar vales serviço que por algum motivo ficaram com hora fora do periodo do caixa
//--------------------------------------------------------------------------------------
Static Function BuscarVLS()

	Local oPnlDet
	Local aCampos := {"MARK","UIC_AMB","UIC_CODIGO","UIC_TIPO","UIC_PRODUT","UIC_DESCRI","UIC_PRCPRO","UIC_CLIENT","UIC_LOJAC","UIC_NOMEC","UIC_FORNEC","UIC_LOJAF","UIC_NOMEF","UIC_DATA","UIC_HORA","UIC_OPERAD","UIC_PDV","UIC_ESTACA","UIC_NUMMOV"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local cQry := ""
	Local nOpcX := 0
	Local nX
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Local nTamHora := TamSX3("LW_HRABERT")[1]

	Private lMARKALL := .F.
	Private oGridDet
	Private oDlgDet

	//busco vales servico fora do intervalo de datas do caixa
	//que podem ser que sejam desse caixa
	cQry := "SELECT UIC.R_E_C_N_O_ RECUIC "
	cQry += "FROM "+RetSqlName("UIC")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UIC "
	cQry += " LEFT JOIN "+RetSqlName("SLW")+" SLW "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" ON (
	cQry += " 	SLW.D_E_L_E_T_ = ' ' "
	cQry += " 	AND LW_FILIAL = UIC_FILIAL "
	cQry += " 	AND UIC_OPERAD = LW_OPERADO "
	cQry += " 	AND UIC_NUMMOV = LW_NUMMOV "
	cQry += " 	AND RTRIM(UIC_PDV) = RTRIM(LW_PDV) "
	cQry += " 	AND UIC_ESTACA = LW_ESTACAO "
	cQry += " 	AND UIC_DATA+SUBSTRING(UIC_HORA,1,"+cValToChar(nTamHora)+") BETWEEN LW_DTABERT||LW_HRABERT AND LW_DTFECHA||LW_HRFECHA "
	cQry += " ) "
	cQry += "WHERE UIC.D_E_L_E_T_ = ' ' "
	cQry += " AND UIC_FILIAL = '" + xFilial("UIC") + "'"
	cQry += " AND UIC_STATUS <> 'C' " //nao cancelados
	//cQry += " AND UIC_OPERAD = '"+SLW->LW_OPERADO+"' "
	cQry += " AND (UIC_PDV = '' OR RTRIM(UIC_PDV) = '"+Alltrim(SLW->LW_PDV)+"') "
	cQry += " AND UIC_DATA BETWEEN '"+DTOS(SLW->LW_DTABERT)+"' AND '"+DTOS(SLW->LW_DTFECHA)+"' " //com datas do caixa
	cQry += " AND LW_FILIAL IS NULL " //não encontrou a sua SLW
	cQry += " ORDER BY UIC_FILIAL, UIC_CODIGO "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	While QRYT1->(!Eof())

		UIC->(DbGoTo(QRYT1->RECUIC))

		aadd(aColsEx, MontaDados("UIC",aCampos, .F.))

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if empty(aColsEx)
		aadd(aColsEx, MontaDados("UIC",aCampos, .T.))
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Busca Vales Serviço não vinculados" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Vales Serviço encontrados fora do intervalo do caixa:" SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 158, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bLDblClick := {|| oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridDet:oBrowse:Refresh() }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, OrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}

	@ 162, 005 SAY "Obs.: Apenas aparecem aqui, vales serviço do mesmo PDV deste caixa, que não estão vinculados a nenhum outro caixa." SIZE 380, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 182, 310 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	@ 182, 355 BUTTON oButton1 PROMPT "Vincular" SIZE 040, 012 OF oDlgDet PIXEL Action iif(aScan(oGridDet:aCols,{|x| x[1]=="LBOK"}) > 0, (nOpcX:=1,oDlgDet:End()), MsgInfo("Selecione pelo menos um vale serviço!", "Atenção"))
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	if nOpcX == 1

		BeginTran()

		For nX := 1 to len(oGridDet:aCols)
			if oGridDet:aCols[nX][1] == "LBOK" .AND. !empty(oGridDet:aCols[nX][len(oGridDet:aHeader)])
				UIC->(DbGoTo(oGridDet:aCols[nX][len(oGridDet:aHeader)]))

				Reclock("UIC", .F.)

				//gravo log da alteração, campos antes de mudar
				If UIC->(FieldPos("UIC_OBS")) > 0
					cAux := AllTrim(UIC->UIC_OBS)
					UIC->UIC_OBS := " Subst. chave caixa. Dados:" + ;
						"UIC_OPERAD = ["+UIC->UIC_OPERAD+"], " + ;
						"UIC_PDV = ["+UIC->UIC_PDV+"], " + ;
						"UIC_ESTACA = ["+UIC->UIC_ESTACA+"], " + ;
						"UIC_NUMMOV = ["+UIC->UIC_NUMMOV+"], " + ;
						"UIC_DATA = ["+ DTOS(UIC->UIC_DATA) +"], " + ;
						"UIC_HORA = ["+UIC->UIC_HORA+"] "
				Endif

				UIC->UIC_OPERAD := SLW->LW_OPERADO
				UIC->UIC_PDV := SLW->LW_PDV
				UIC->UIC_ESTACA := SLW->LW_ESTACAO
				UIC->UIC_NUMMOV := SLW->LW_NUMMOV

				if DTOS(UIC->UIC_DATA)+UIC->UIC_HORA >= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA
					UIC->UIC_HORA := SLW->LW_HRFECHA
				elseif DTOS(UIC->UIC_DATA)+UIC->UIC_HORA <= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT
					UIC->UIC_HORA := SLW->LW_HRABERT
				endif

				UIC->(MsUnlock())
			endif
		next nX

		EndTran()

		//atualizo grid vale serviço
		Processa({|| AtuConfDocs(.F.,.F.,,,,.F.,.T.,.F.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Inclusao de vale serviço
//--------------------------------------------------------------------------------------
Static Function TelaVls(nOpcX, bRefresh)

	Local lOk := .T.
	Local dBkpDbase := dDataBase
	Local cMsgErro := ""
	Local aRecUIC := {}
	Local bConfirm := {|| aRecUIC := U_TPDVA6RI() , oDlgAux:end() }
	Local bCancel := {|| oDlgAux:end() }
	Local oPnlAux
	Local nI := 0
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Private oDlgAux

	dDataBase := SLW->LW_DTABERT

	DEFINE MSDIALOG oDlgAux TITLE "Vale Serviço" FROM 000, 000  TO 570, 800 COLORS 0, 16777215 PIXEL STYLE DS_MODALFRAME

	@ 000, 000 MSPANEL oPnlAux SIZE (oDlgAux:nWidth/2), (oDlgAux:nHeight/2)-12 OF oDlgAux
	oPnlAux:SetCSS( "TPanel{border: none; background-color: #f4f4f4;}" )
	U_TPDVA006(oPnlAux, .T., bConfirm, bCancel, nOpcX) //monta tela de vale servico

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if len(aRecUIC) > 0 .AND. nOpcX == 3 //se retornou recno é pq incluiu
		//gera financeiro vale servico
		For nI := 1 to len(aRecUIC)
			UIC->(DbGoTo(aRecUIC[nI]))

			cLogCaixa := "CLIENTE: " + UIC->UIC_CLIENT +" | "+UIC->UIC_LOJAC +" | "+Alltrim(UIC->UIC_NOMEC) + CRLF
			cLogCaixa += "VALOR: " + Transform(UIC->UIC_PRCPRO ,"@E 999,999,999.99") + CRLF

			MsAguarde( {|| lOk := U_TRETE034(UIC->UIC_AMB, UIC->UIC_CODIGO, .T., .F.) }, "Aguarde", "Processando Financeiro... "+UIC->UIC_AMB+UIC->UIC_CODIGO, .F. ) //JOB processa financeiro
			if lOk
				MsgInfo("Inclusao do Vale Servico "+UIC->UIC_AMB+UIC->UIC_CODIGO+" realizada com sucesso!","Atenção")
				if lLogCaixa
					GrvLogConf("7","I", cLogCaixa, UIC->UIC_AMB+UIC->UIC_CODIGO, "VLS")
				endif
			else
				MsgAlert("Falha ao gerar financeiro do Vale Servico "+UIC->UIC_AMB+UIC->UIC_CODIGO+"! Tente reprocessar novamente!" + cMsgErro, "Atenção")
			endif
		next nI
	endif

	dDataBase := dBkpDbase

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Reprocessa financeiro de vale serviço
//--------------------------------------------------------------------------------------
Static Function EstornaVLS(nRecUIC, bRefresh)

	Local aAreaSE1 := SE1->(GetArea())
	Local aAreaSE2 := SE2->(GetArea())
	Local lOk := .T.
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa

	if empty(nRecUIC)
		Return
	endif

	UIC->(DbSetOrder(1))
	UIC->(DBGoTo(nRecUIC))

	if UIC->UIC_STATUS == "C" //cancelado
		MsgInfo("Vale serviço já estornado!","")
	endif

	If MsgYesNo("Confirma estorno do vale servico?","Atenção")
		cLogCaixa := "CLIENTE: " + UIC->UIC_CLIENT +" | "+UIC->UIC_LOJAC +" | "+Alltrim(UIC->UIC_NOMEC) + CRLF
		cLogCaixa += "VALOR: " + Transform(UIC->UIC_PRCPRO ,"@E 999,999,999.99") + CRLF

		BeginTran()

		RecLock("UIC", .F.)
			UIC->UIC_STATUS := "C" //cancelado
			UIC->UIC_PROCEX := "C" //conferencia
		UIC->(MsUnlock())

		//gera financeiro
		MsAguarde( {|| lOk := U_TRETE034(UIC->UIC_AMB, UIC->UIC_CODIGO, .F., .T.) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
		if lOk
			MsgInfo("Financeiro processado com sucesso!","Atenção")
			if lLogCaixa
				GrvLogConf("7","E", cLogCaixa, UIC->UIC_AMB+UIC->UIC_CODIGO, "VLS")
			endif
		else
			DisarmTransaction()
		endif

		EndTran()
	endif

	RestArea(aAreaSE2)
	RestArea(aAreaSE1)

	if bRefresh <> Nil
		EVal(bRefresh)
	endif
Return

//--------------------------------------------------------------------------------------
// Reprocessa financeiro de vale serviço
//--------------------------------------------------------------------------------------
Static Function ReprocVLS(nRecUIC, bRefresh)

	Local aAreaSE1 := SE1->(GetArea())
	Local aAreaSE2 := SE2->(GetArea())
	Local lOk := .T.

	if empty(nRecUIC)
		Return
	endif

	UIC->(DbSetOrder(1))
	UIC->(DBGoTo(nRecUIC))

	BeginTran()

	if UIC->UIC_STATUS == "C" //cancelado
		RecLock("UIC", .F.)
			UIC->UIC_PROCEX := "C" //conferencia
		UIC->(MsUnlock())
	else
		RecLock("UIC", .F.)
			UIC->UIC_STATUS := "A" //aberto
			UIC->UIC_PROCES := "2"
			UIC->UIC_PROCBX := "C" //conferencia
		UIC->(MsUnlock())
	endif

	//gera financeiro
	MsAguarde( {|| lOk := U_TRETE034(UIC->UIC_AMB, UIC->UIC_CODIGO, UIC->UIC_STATUS == "A", UIC->UIC_STATUS == "C") }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
	if lOk
		MsgInfo("Financeiro reprocessado com sucesso!","Atenção")
	else
		DisarmTransaction()
	endif

	EndTran()

	RestArea(aAreaSE2)
	RestArea(aAreaSE1)

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Funçao para buscar Requisiçoes que por algum motivo ficaram com hora fora do periodo do caixa
//--------------------------------------------------------------------------------------
Static Function BuscarU57()

	Local oPnlDet
	Local aCampos := {"MARK","U57_FILIAL","U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALOR","U57_VALSAQ","U56_CODCLI","U56_LOJA","U56_NOME","U57_MOTORI","U57_PLACA","U56_REQUIS","U57_DATAMO","U57_XHORA","U57_XOPERA","U57_XPDV","U57_XESTAC","U57_XNUMMO"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local cQry := ""
	Local nOpcX := 0
	Local nX
	Local aLinAux := {}
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Local nTamHora := TamSX3("LW_HRABERT")[1]

	Private lMARKALL := .F.
	Private oGridDet
	Private oDlgDet

	//busco saques/vale motorista fora do intervalo de datas do caixa
	if SuperGetMV("TP_ACTSQ",,.F.)
		cQry := "SELECT U57.R_E_C_N_O_ RECU57, U56.R_E_C_N_O_ RECU56 "
		cQry += "FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
		cQry += "INNER JOIN "+RetSqlName("U56")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U56 ON (U56.D_E_L_E_T_ = ' ' AND U56_FILIAL = U57_FILIAL AND U56_PREFIX = U57_PREFIX AND U56_CODIGO = U57_CODIGO) "
		cQry += " LEFT JOIN "+RetSqlName("SLW")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SLW ON (
		cQry += " 	SLW.D_E_L_E_T_ = ' ' "
		cQry += " 	AND LW_FILIAL = U57_FILSAQ "
		cQry += " 	AND U57_XOPERA = LW_OPERADO "
		cQry += " 	AND U57_XNUMMO = LW_NUMMOV "
		cQry += " 	AND RTRIM(U57_XPDV) = RTRIM(LW_PDV) "
		cQry += " 	AND U57_XESTAC = LW_ESTACAO "
		cQry += " 	AND U57_DATAMO+SUBSTRING(U57_XHORA,1,"+cValToChar(nTamHora)+") BETWEEN LW_DTABERT||LW_HRABERT AND LW_DTFECHA||LW_HRFECHA "
		cQry += " ) "
		cQry += "WHERE U57.D_E_L_E_T_ = ' ' "
		cQry += " AND U57_FILIAL = '" + xFilial("U57") + "' "
		cQry += " AND U57_TUSO = 'S' " //Saque
		//cQry += " AND U57_MOTIVO <> ' ' "
		cQry += " AND U57_FILSAQ = '"+cFilAnt+"' "
		cQry += " AND (U57_XPDV = '' OR RTRIM(U57_XPDV) = '"+Alltrim(SLW->LW_PDV)+"') "
		cQry += " AND U57_DATAMO BETWEEN '"+DTOS(SLW->LW_DTABERT)+"' AND '"+DTOS(SLW->LW_DTFECHA)+"' " //com datas do caixa
		cQry += " AND LW_FILIAL IS NULL " //não encontrou a sua SLW
		cQry += " ORDER BY U57_PREFIX, U57_CODIGO "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif
		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())

			U56->(DbGoTo(QRYT1->RECU56))
			U57->(DbGoTo(QRYT1->RECU57))
			aLinAux := MontaDados("U57",aCampos, .F.)
			aLinAux[2] := iif(U56->U56_TIPO == "1", "SAQUE", "VALE MOTORISTA") //U57_FILIAL
			aadd(aColsEx, aLinAux)

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())
	endif

	//busco Depósitos motorista fora do intervalo de datas do caixa
	if SuperGetMV("TP_ACTDP",,.F.)

		cQry := "SELECT U57.R_E_C_N_O_ RECU57, U56.R_E_C_N_O_ RECU56 "
		cQry += "FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
		cQry += "INNER JOIN "+RetSqlName("U56")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U56 ON (U56.D_E_L_E_T_ = ' ' AND U56_FILIAL = U57_FILIAL AND U56_PREFIX = U57_PREFIX AND U56_CODIGO = U57_CODIGO) "
		cQry += " LEFT JOIN "+RetSqlName("SLW")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SLW ON (
		cQry += " 	SLW.D_E_L_E_T_ = ' ' "
		cQry += " 	AND LW_FILIAL = U57_FILDEP "
		cQry += " 	AND U57_OPEDEP = LW_OPERADO "
		cQry += " 	AND U57_NUMDEP = LW_NUMMOV "
		cQry += " 	AND RTRIM(U57_PDVDEP) = RTRIM(LW_PDV) "
		cQry += " 	AND U57_ESTDEP = LW_ESTACAO "
		cQry += " 	AND U57_DATDEP+SUBSTRING(U57_HORDEP,1,"+cValToChar(nTamHora)+") BETWEEN LW_DTABERT||LW_HRABERT AND LW_DTFECHA||LW_HRFECHA "
		cQry += " ) "
		cQry += "WHERE U57.D_E_L_E_T_ = ' ' "
		cQry += " AND U57_FILIAL = '" + xFilial("U57") + "' "
		cQry += " AND U57_FILDEP = '"+cFilAnt+"' "
		cQry += " AND (U57_PDVDEP = '' OR RTRIM(U57_PDVDEP) = '"+Alltrim(SLW->LW_PDV)+"') "
		cQry += " AND U57_DATDEP BETWEEN '"+DTOS(SLW->LW_DTABERT)+"' AND '"+DTOS(SLW->LW_DTFECHA)+"' " //com datas do caixa
		cQry += " AND LW_FILIAL IS NULL " //não encontrou a sua SLW
		cQry += " ORDER BY U57_PREFIX, U57_CODIGO "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif
		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())

			U56->(DbGoTo(QRYT1->RECU56))
			U57->(DbGoTo(QRYT1->RECU57))
			aLinAux := MontaDados("U57",aCampos, .F.)
			aLinAux[2] := "DEPOSITO" //U57_FILIAL
			aadd(aColsEx, aLinAux)

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())
	endif

	if empty(aColsEx)
		aadd(aColsEx, MontaDados("U57",aCampos, .T.))
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Busca Saques/Depósitos não vinculados" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Saques/Depósitos encontrados fora do intervalo do caixa:" SIZE 200, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	aHeaderEx[aScan(aCampos,"U57_FILIAL")][1] := "TIPO DOC."
	aHeaderEx[aScan(aCampos,"U57_FILIAL")][4] := 15
	oGridDet := MsNewGetDados():New( 015, 002, 158, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bLDblClick := {|| oGridDet:aCols[oGridDet:nAt][1] := iif(oGridDet:aCols[oGridDet:nAt][1]=="LBNO", iif(!empty(oGridDet:aCols[oGridDet:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridDet:oBrowse:Refresh() }
	oGridDet:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol > 1, OrdGrid(@oGridDet, @nCol), iif(lMARKALL .AND. !empty(oGridDet:aCols[1][2]), (aEval(oGridDet:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL), lMARKALL:=!lMARKALL) )}

	@ 162, 005 SAY "Obs.: Apenas aparecem aqui, saques/depósitos do mesmo PDV deste caixa, que não estão vinculados a nenhum outro caixa." SIZE 380, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	@ 182, 310 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	@ 182, 355 BUTTON oButton1 PROMPT "Vincular" SIZE 040, 012 OF oDlgDet PIXEL Action iif(aScan(oGridDet:aCols,{|x| x[1]=="LBOK"}) > 0, (nOpcX:=1,oDlgDet:End()), MsgInfo("Selecione pelo menos um registro!", "Atenção"))
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	if nOpcX == 1

		BeginTran()

		For nX := 1 to len(oGridDet:aCols)
			if oGridDet:aCols[nX][1] == "LBOK" .AND. !empty(oGridDet:aCols[nX][len(oGridDet:aHeader)])

				U57->(DbGoTo(oGridDet:aCols[nX][len(oGridDet:aHeader)]))

				//gravo log da alteração, campos antes de mudar
				If U56->(FieldPos("U56_OBS")) > 0
					cAux := Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_OBS")

					Reclock("U56", .F.)
					U56->U56_OBS += " Subst. chave caixa parcela "+U57->U57_PARCEL+". Dados:" + ;
						"U57_XOPERA = ["+U57->U57_XOPERA+"], " + ;
						"U57_XPDV = ["+U57->U57_XPDV+"], " + ;
						"U57_XESTAC = ["+U57->U57_XESTAC+"], " + ;
						"U57_XNUMMO = ["+U57->U57_XNUMMO+"], " + ;
						"U57_DATAMO = ["+ DTOS(U57->U57_DATAMO) +"], " + ;
						"U57_XHORA = ["+U57->U57_XHORA+"] "
					U56->(MsUnlock())
				Endif

				//forço venda a ficar na hora do intervalo do caixa
				Reclock("U57", .F.)

				U57->U57_XOPERA := SLW->LW_OPERADO
				U57->U57_XPDV := SLW->LW_PDV
				U57->U57_XESTAC := SLW->LW_ESTACAO
				U57->U57_XNUMMO := SLW->LW_NUMMOV

				if DTOS(U57->U57_DATAMO)+U57->U57_XHORA >= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA
					U57->U57_XHORA := SLW->LW_HRFECHA
				elseif DTOS(U57->U57_DATAMO)+U57->U57_XHORA <= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT
					U57->U57_XHORA := SLW->LW_HRABERT
				endif

				U57->(MsUnlock())

			endif
		next nX

		EndTran()

		//atualizo grid requisições
		Processa({|| AtuConfDocs(.F.,.F.,,,,.F.,.F.,.T.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Ações dos botões aba Trocos Saques/Depositos da tela de conferencia documentos
//--------------------------------------------------------------------------------------
Static Function MntRequis(nOpcX)

	Local nPosTpDoc := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_FILIAL"})
	Local nPosPfx := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})
	Local nPosCod := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})
	Local nPosPar := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})
	Local nPosLeg2 := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local aParBox := {}
	Local aRetPar := {}
	Local lBkpInc := iif(type("INCLUI")=="L",INCLUI,.F.)
	Local lBkbAlt := iif(type("ALTERA")=="L",ALTERA,.F.)

	if nOpcX == 3
		aAdd(aParBox, {3, 'Tipo Documento:', 1, {"Depósito PDV","Saque/Vale Motorista"}, 100, '', .T., '.T.'})

		If ! ParamBox(aParBox, 'Inclusão Requisição', @aRetPar)
			Return Nil
		EndIf

		if aRetPar[1] == 1 //deposito
			If SuperGetMV("TP_ACTDP",,.F.)
				TelaDeposito(3)
			else
				MsgAlert("Depósito  não habilitado! Verifique parametro TP_ACTDP.","Atenção")
				Return
			endif
		elseif aRetPar[1] == 2 //Saque/Vale Motorista
			If SuperGetMV("TP_ACTSQ",,.F.)
				TelaSaque(3)
			else
				MsgAlert("Saque/Vale Motorista não habilitado! Verifique parametro TP_ACTSQ.","Atenção")
				Return
			endif
		endif
	else
		if empty(oGridU57:aCols[oGridU57:nAt][nPosCod])
			Return
		endif
		if oGridU57:aCols[oGridU57:nAt][nPosLeg2] <> "BR_AZUL" .AND. nOpcX != 2 .AND. nOpcX != 6
			MsgAlert("Registro não ativo nesta base. Ação não permitida!","Atenção")
			Return
		endif

		if nOpcX == 6 .AND. oGridU57:aCols[oGridU57:nAt][nPosLeg2] == "BR_AMARELO" //reprocessa
			ForcaIntU57()
		endif

		//Posiciono na requisição
		U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
		if U57->(DbSeek(xFilial("U57")+oGridU57:aCols[oGridU57:nAt][nPosPfx]+oGridU57:aCols[oGridU57:nAt][nPosCod]+oGridU57:aCols[oGridU57:nAt][nPosPar] ))

			U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
			U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

			if nOpcX == 2 //visualizar

				INCLUI := .F.
				ALTERA := .F.

				FWExecView('Cadastro de Requisição', 'TRETA032', 1,, {|| .T. /*fecha janela no ok*/})

				INCLUI := lBkpInc
				ALTERA := lBkbAlt

			elseif nOpcX == 5 //Estorno
				if oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "DEPOSITO"
					DelDeposito(U57->(Recno()))
				elseif oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "VALE MOTORISTA" .OR. oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "SAQUE"
					DelVLMSQ(U57->(Recno()))
				endif
			elseif nOpcX == 6 //Reprocessar
				if oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "DEPOSITO"
					MsAguarde( {|| ReprocDP() }, "Aguarde", "Reprocessando Financeiro...", .F. )
				elseif oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "VALE MOTORISTA"
					MsAguarde( {|| ReprocVLM() }, "Aguarde", "Reprocessando Financeiro...", .F. )
				elseif oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "SAQUE"
					MsAguarde( {|| ReprocSQ() }, "Aguarde", "Reprocessando Financeiro...", .F. )
				endif
			elseif nOpcX == 7 //Alterar Saida
				if oGridU57:aCols[oGridU57:nAt][nPosTpDoc] == "DEPOSITO"
					MsgInfo("Ação não permitida para Deposito no PDV.","Atenção")
				else
					AltTrocSQ(U57->(Recno()))
				endif
			endif
		else
			MsgAlert("Falha ao encontrar requisição!","Atenção")
		endif
	endif

	if nOpcX != 2
		Processa({|| AtuConfDocs(.F.,.F.,,,,.F.,.F.,.T.) },"Aguarde... este processo pode demorar...","Aguarde...")
	endif

Return

//--------------------------------------------------------------------------------------
// Inclusao de saque/vale motorista
//--------------------------------------------------------------------------------------
Static Function TelaSaque(nOpcX, bRefresh)

	Local lOk := .T.
	Local dBkpDbase := dDataBase
	Local cMsgErro := ""
	Local nRecnoU57 := 0
	Local bConfirm := {|| nRecnoU57 := U57->(Recno()) , oDlgAux:end() }
	Local bCancel := {|| oDlgAux:end() }
	Local oPnlAux, cChavU57, cTipo
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Private oDlgAux

	dDataBase := SLW->LW_DTABERT

	DEFINE MSDIALOG oDlgAux TITLE "Inclusão de Saque" FROM 000, 000  TO 570, 800 COLORS 0, 16777215 PIXEL STYLE DS_MODALFRAME

	@ 000, 000 MSPANEL oPnlAux SIZE (oDlgAux:nWidth/2), (oDlgAux:nHeight/2)-12 OF oDlgAux
	oPnlAux:SetCSS( "TPanel{border: none; background-color: #f4f4f4;}" )
	U_TPDVA007(oPnlAux, .T., bConfirm, bCancel) //monta tela de saque

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if nRecnoU57 > 0 .AND. nOpcX == 3 //se retornou recno é pq incluiu
		
		cChavU57 := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL
		cTipo := Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_TIPO")

		if cTipo == "2" //somente pos paga
			RecLock("U57", .F.)
			U57->U57_XGERAF := "C" //gerar pela conferencia
			U57->(MsUnlock())
			
			//gera financeiro vale motorista
			MsAguarde( {|| lOk := U_TRETE023(cChavU57, @cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
		endif

		cLogCaixa := "CLIENTE: " + U56->U56_CODCLI +" | "+U56->U56_LOJA +" | "+Alltrim(U56->U56_NOME) + CRLF
		cLogCaixa += "VALOR: " + Transform(U57->U57_VALOR ,"@E 999,999,999.99") + CRLF
	
		if lOk
			MsgInfo("Inclusao do "+iif(cTipo=="1","Saque","Vale Motorista")+" realizada com sucesso!","Atenção")
			
			if lLogCaixa
				GrvLogConf("5","I", cLogCaixa, , , cChavU57)
			endif
		else
			MsgAlert("Falha ao gerar financeiro do Vale Motorista!"+ CRLF +cMsgErro,"Atenção")
		endif

	endif

	dDataBase := dBkpDbase

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Faz Exclusao de um saque Vale Motorista VLM e Saque SQ
//--------------------------------------------------------------------------------------
Static Function DelVLMSQ(nRecU57, bRefresh)

	Local cPfRqSaq   := AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) // Prefixo de Titulo de Requisicoes de Saque
	Local cChavU57 := "", cChavUF2 :=""
	Local lOk := .F.
	Local cMsgErro := ""
	Local cTipo
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo

	if empty(nRecU57)
		Return
	endif

	U57->(DbGoTo(nRecU57))
	cChavU57 := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL
	cTipo := Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_TIPO")

	if U57->U57_XGERAF $ 'X,Z,D'
		MsgAlert(iif(cTipo=="1","Saque","Vale Motorista")+" já estornado.","Atenção")
		Return
	endif

	if cTipo == "2" //pos pago
		SE1->(DbSetOrder(1))
		SE1->(DbSeek(xFilial("SE1")+cPfRqSaq+SubStr(U57->U57_PREFIX,1,1)+U57->U57_CODIGO))
		While SE1->(!Eof()) .AND. SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM == xFilial("SE1")+cPfRqSaq+SubStr(U57->U57_PREFIX,1,1)+U57->U57_CODIGO
			if SE1->E1_XCODBAR == cChavU57 .AND. SE1->E1_TIPO == "RP "
				if !empty(SE1->E1_BAIXA)
					MsgAlert("O titulo a receber referente a esta requisição está baixado. Ação não permitida!","Atenção")
					Return
				endif
				EXIT
			endif
			SE1->(DBSkip())
		enddo
	endif

	//Verifica se existe cheque troco conciliado na requisição
	UF2->(DbSetOrder(4)) //UF2_FILIAL+UF2_CODBAR
	cChavUF2 := xFilial("UF2")+cChavU57
	if UF2->(DbSeek(cChavUF2))
		SE5->(Dbsetorder(1))
		While UF2->(!Eof()) .And. UF2->(UF2_FILIAL+UF2_CODBAR) == cChavUF2
			If SE5->(DbSeek(xFilial("SE5")+;
				DTOS(UF2->UF2_DATAMO)+;
				PadR(UF2->UF2_BANCO,TamSX3("E5_BANCO")[1])+;
				PadR(UF2->UF2_AGENCI,TamSX3("E5_AGENCIA")[1])+;
				PadR(UF2->UF2_CONTA,TamSX3("E5_CONTA")[1])+;
				PadR(UF2->UF2_NUM,TamSX3("E5_NUMCHEQ")[1]))) .And. SE5->E5_RECPAG = "P" .And. SE5->E5_SITUACA <> "C"

				If Upper(SE5->E5_RECONC) == "X"
					MsgAlert("Estorno negado. Cheque troco do "+iif(cTipo=="1","saque","vale motorista")+" já se encontra conciliado!","Atenção")
					Return
				ElseIf lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
					MsgAlert("Estorno negado. Cheque troco da "+iif(cTipo=="1","saque","vale motorista")+" já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
					Return
				EndIf
			EndIf
			UF2->(DbSkip())
		Enddo
	EndIf

	if MsgYesNo("Deseja realmente estornar/cancelar o "+iif(cTipo=="1","saque","vale motorista")+" selecionado?","Atenção")
		
		cLogCaixa := "CLIENTE: " + U56->U56_CODCLI +" | "+U56->U56_LOJA +" | "+Alltrim(U56->U56_NOME) + CRLF
		cLogCaixa += "VALOR: " + Transform(U57->U57_VALOR ,"@E 999,999,999.99") + CRLF

		BeginTran()

		RecLock("U57",.F.)
		U57->U57_XGERAF := "Z" //estorno conferencia
		U57->(MsUnLock())

		//gera financeiro
		MsAguarde( {|| lOk := U_TRETE023(cChavU57, @cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro

		if lOk
			MsgInfo(iif(cTipo=="1","Saque","Vale Motorista")+" excluido com sucesso!","Atenção")
			if lLogCaixa
				GrvLogConf("5","E", cLogCaixa, , , cChavU57)
			endif
		else
			MsgAlert("Falha ao excluir o financeiro! "+ CRLF +cMsgErro,"Atenção")
			DisarmTransaction()
		endif

		EndTran()

		if bRefresh <> Nil
			EVal(bRefresh)
		endif
	EndIf

Return

//--------------------------------------------------------------------------------------
// Faz Exclusao de um saque Vale Motorista VLM e Saque SQ
//--------------------------------------------------------------------------------------
Static Function DelDeposito(nRecU57, bRefresh)

	Local cChavU57 := ""
	Local lOk := .F.
	Local cMsgErro := ""
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa

	if empty(nRecU57)
		Return
	endif

	U57->(DbGoTo(nRecU57))
	cChavU57 := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL

	if U57->U57_XGERAF $ 'X,Z,D'
		MsgAlert("Depósito já estornado.","Atenção")
		Return
	elseif !empty(U57->U57_FILSAQ)
		MsgAlert("Depósito já utilizado para Saque ou Venda. Ação não permitida","Atenção")
		Return
	endif

	if MsgYesNo("Deseja realmente estornar/cancelar o Deposito PDV selecionado?","Atenção")

		cLogCaixa := "CLIENTE: " + Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_CODCLI") +" | "+U56->U56_LOJA +" | "+Alltrim(U56->U56_NOME) + CRLF
		cLogCaixa += "VALOR: " + Transform(U57->U57_VALOR ,"@E 999,999,999.99") + CRLF

		BeginTran()

		RecLock("U57",.F.)
		U57->U57_XGERAF := "Z" //estorno conferencia
		U57->(MsUnLock())

		//gera financeiro
		MsAguarde( {|| lOk := U_TRETE023(cChavU57, @cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro

		if lOk
			MsgInfo("Depósito PDV estornado com sucesso!","Atenção")

			if lLogCaixa
				GrvLogConf("6","E", cLogCaixa, , , cChavU57)
			endif
		else
			MsgAlert("Falha ao excluir o financeiro! "+ CRLF +cMsgErro,"Atenção")
			DisarmTransaction()
		endif

		EndTran()

		if bRefresh <> Nil
			EVal(bRefresh)
		endif
	EndIf

Return

//--------------------------------------------------------------------------------------
// Reprocessa financeiro do vale motorista
//--------------------------------------------------------------------------------------
Static Function ReprocVLM()

	Local lOk := .T.
	Local aRet
	Local cChavU57 := ""
	Local dBkpDBase := dDataBase
	Local cMsgErro := ""

	//aRet := {cChavU57, lOk, nVlrU57, nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}
	aRet := AvalFinU57("VALE MOTORISTA", U57->U57_PREFIX, U57->U57_CODIGO, U57->U57_PARCEL)

	if aRet[2]
		MsgInfo("Financeiro do vale motorista está correto. Não precisa ser reprocessado!","Atenção")
		Return
	endif

	if "cheque troco" $ aRet[8] //se pendencia de cheque troco
		MsgInfo("Pendência financeira de Cheque Troco do vale motorista! Utilize a opção de reprocessar cheque troco em 'Altera Saida' do saque.","Atenção")
		Return
	endif

	dDataBase := U57->U57_DATAMO
	cChavU57 := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL //vem posicionado em caso de sucesso

	BeginTran()

	if U57->U57_XGERAF $ 'X,Z,D'
		RecLock("U57", .F.)
		U57->U57_XGERAF := "Z" //estornar pela conferencia
		U57->(MsUnlock())
	else
		RecLock("U57", .F.)
		U57->U57_XGERAF := "C" //gerar pela conferencia
		U57->(MsUnlock())
	endif

	//gera financeiro
	MsAguarde( {|| lOk := U_TRETE023(cChavU57, @cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro

	if lOk
		//vejo se corrigiu
		aRet := AvalFinU57("VALE MOTORISTA", U57->U57_PREFIX, U57->U57_CODIGO, U57->U57_PARCEL)
		if aRet[2]
			MsgInfo("Financeiro do Vale Motorista reprocessado com sucesso!","Atenção")
		else
			DisarmTransaction()
			MsgAlert("Falha ao reprocessar financeiro!","Atenção")
		endif
	else
		MsgAlert("Falha ao reprocessar financeiro! "+ CRLF +cMsgErro,"Atenção")
		DisarmTransaction()
	endif

	EndTran()

	dDataBase := dBkpDBase

Return

//--------------------------------------------------------------------------------------
// Reprocessa financeiro do saque
//--------------------------------------------------------------------------------------
Static Function ReprocSQ()

	Local lOk := .T.
	Local aRet
	Local dBkpDBase := dDataBase

	//aRet := {cChavU57, lOk, nVlrU57, nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}
	aRet := AvalFinU57("SAQUE", U57->U57_PREFIX, U57->U57_CODIGO, U57->U57_PARCEL)

	if aRet[2]
		MsgInfo("Financeiro do vale motorista está correto. Não precisa ser reprocessado!","Atenção")
		Return
	endif

	if "cheque troco" $ aRet[8] //se pendencia de cheque troco
		MsgInfo("Pendência financeira de Cheque Troco do vale motorista! Utilize a opção de reprocessar cheque troco em 'Altera Saida' do saque.","Atenção")
		Return
	endif

	dDataBase := U57->U57_DATAMO

	BeginTran()

	//se tudo zerado, nao processou financeiro
	if empty(aRet[4]) .AND. empty(aRet[5]) .AND. empty(aRet[6]) .AND. empty(aRet[7])
		lOk := .F.
	else
		//tenta ajsutar saldo do saque quando tem cheque troco
		if U57->U57_CHTROC <> aRet[7] .OR. aRet[3] <> aRet[6]+aRet[7]
			lOk := U_TRETE29D(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)
		endif
	endif

	if lOk
		//vejo se corrigiu
		aRet := AvalFinU57("SAQUE", U57->U57_PREFIX, U57->U57_CODIGO, U57->U57_PARCEL)

		if aRet[2]
			MsgInfo("Financeiro do Saque reprocessado com sucesso!","Atenção")
		else
			lOk := .F.
		endif
	endif

	if !lOk
		DisarmTransaction()
		MsgAlert("Não foi possível reprocessar Saque. Tente excluir e lança-lo novamente.","Atenção")
	endif

	EndTran()

	dDataBase := dBkpDBase

Return

Static Function ForcaIntU57()
	
	Local lRet := .F.
	Local nX, nY
	Local aCamposU56 := {}
	Local aCamposU57 := {}
	Local cFiltro := ""
	Local aRegU56 := {}
	Local aRegU57 := {}
	Local nPosLeg2 := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="LEG2"})
	Local nPosLeg3 := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="LEG3"})
	Local nPosPfx := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PREFIX"})
	Local nPosCod := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_CODIGO"})
	Local nPosParc := aScan(oGridU57:aHeader,{|x| AllTrim(x[2])=="U57_PARCEL"})
	Local cChavU56
	Local cChavU57
	//aCpoGdU57	:= {"LEG1-PDV","LEG2-RET.","LEG3-PEND.","U57_FILIAL","U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALOR","U57_VALSAQ","U56_CODCLI","U56_LOJA","U56_NOME","U57_MOTORI","U57_PLACA","U56_REQUIS","U57_VEND","A3_NOME"}

	if oGridU57:aCols[oGridU57:nAt][nPosLeg2] == "BR_AMARELO" .AND. oGridU57:aCols[oGridU57:nAt][nPosLeg3] == "BR_VERMELHO"

		aadd(aCamposU56, "U56_FILIAL" )
		aadd(aCamposU56, "U56_PREFIX" )
		aadd(aCamposU56, "U56_CODIGO" )
		aadd(aCamposU56, "U56_TIPO" )
		aadd(aCamposU56, "U56_DTEMIS" )
		aadd(aCamposU56, "U56_CODCLI" )
		aadd(aCamposU56, "U56_LOJA" )
		aadd(aCamposU56, "U56_NOME" )
		aadd(aCamposU56, "U56_FILAUT" )
		aadd(aCamposU56, "U56_REQUIS" )
		aadd(aCamposU56, "U56_CARGO" )
		aadd(aCamposU56, "U56_BANCO" )
		aadd(aCamposU56, "U56_AGENCI" )
		aadd(aCamposU56, "U56_NUMCON" )
		aadd(aCamposU56, "U56_HIST" )
		aadd(aCamposU56, "U56_CONDSA" )
		aadd(aCamposU56, "U56_TOTAL" )
		aadd(aCamposU56, "U56_NPARC" )
		aadd(aCamposU56, "U56_TOTSAQ" )
		aadd(aCamposU56, "U56_STATUS" )

		aadd(aCamposU57, "U57_FILIAL" )
		aadd(aCamposU57, "U57_PREFIX" )
		aadd(aCamposU57, "U57_CODIGO" )
		aadd(aCamposU57, "U57_PARCEL" )
		aadd(aCamposU57, "U57_VALOR" )
		aadd(aCamposU57, "U57_TUSO" )
		aadd(aCamposU57, "U57_PLACA" )
		aadd(aCamposU57, "U57_MOTORI" )
		aadd(aCamposU57, "U57_MOTIVO" )
		aadd(aCamposU57, "U57_DATAMO" )
		aadd(aCamposU57, "U57_FILSAQ" )
		aadd(aCamposU57, "U57_VALSAQ" )
		aadd(aCamposU57, "U57_CHTROC" )
		aadd(aCamposU57, "U57_XGERAF" )
		aadd(aCamposU57, "U57_XOPERA" )
		aadd(aCamposU57, "U57_XPDV" )
		aadd(aCamposU57, "U57_XESTAC" )
		aadd(aCamposU57, "U57_XNUMMO" )
		aadd(aCamposU57, "U57_XHORA" )
		aadd(aCamposU57, "U57_OPEDEP" )
		aadd(aCamposU57, "U57_PDVDEP" )
		aadd(aCamposU57, "U57_ESTDEP" )
		aadd(aCamposU57, "U57_NUMDEP" )
		aadd(aCamposU57, "U57_DATDEP" )
		aadd(aCamposU57, "U57_HORDEP" )
		aadd(aCamposU57, "U57_FILDEP" )
		aadd(aCamposU57, "U57_VEND" )
		
		cFiltro := "D_E_L_E_T_ = ' ' AND U56_FILIAL='"+xFilial("U56")+"' AND U56_PREFIX = '"+oGridU57:aCols[oGridU57:nAt][nPosPfx]+"' AND U56_CODIGO = '"+oGridU57:aCols[oGridU57:nAt][nPosCod]+"'"
		aRegU56 := DoRPC_Pdv("STDQueryDB", aCamposU56, {"U56"}, cFiltro)

		cFiltro := "D_E_L_E_T_ = ' ' AND U57_FILIAL='"+xFilial("U57")+"' AND U57_PREFIX = '"+oGridU57:aCols[oGridU57:nAt][nPosPfx]+"' AND U57_CODIGO = '"+oGridU57:aCols[oGridU57:nAt][nPosCod]+"' AND U57_PARCEL = '"+oGridU57:aCols[oGridU57:nAt][nPosParc]+"'"
		aRegU57 := DoRPC_Pdv("STDQueryDB", aCamposU57, {"U57"}, cFiltro)

		if !empty(aRegU56) .AND. !empty(aRegU57)

			U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
			For nX := 1 to len(aRegU56)
				
				cChavU56 := aRegU56[nX][aScan(aCamposU56,"U56_FILIAL")]
				cChavU56 += aRegU56[nX][aScan(aCamposU56,"U56_PREFIX")]
				cChavU56 += aRegU56[nX][aScan(aCamposU56,"U56_CODIGO")]

				if U56->(!DbSeek(cChavU56))
					If RecLock('U56',.T.)
						for nY := 1 to len(aCamposU56)
							U56->&(aCamposU56[nY]) := aRegU56[nX][nY]
						next nY
						U56->(MsUnlock())
					EndIf
				endif
			next nX	

			U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
			For nX := 1 to len(aRegU57)
				
				cChavU57 := aRegU57[nX][aScan(aCamposU57,"U57_FILIAL")]
				cChavU57 += aRegU57[nX][aScan(aCamposU57,"U57_PREFIX")]
				cChavU57 += aRegU57[nX][aScan(aCamposU57,"U57_CODIGO")]
				cChavU57 += aRegU57[nX][aScan(aCamposU57,"U57_PARCEL")]

				if U57->(!DbSeek(cChavU57))
					If RecLock('U57',.T.)
						for nY := 1 to len(aCamposU57)
							U57->&(aCamposU57[nY]) := aRegU57[nX][nY]
						next nY
						U57->(MsUnlock())
					EndIf
				endif
			next nX	

			lRet := .T.

		endif

		DoRpcClose()
	endif

Return lRet

//--------------------------------------------------------------------------------------
// Tela Altera saida do saque
//--------------------------------------------------------------------------------------
Static Function AltTrocSQ(nRecU57, bRefresh)

	Local oCodBar, oEmissao, oCliente, oPlaca, oMotorista, oVlrSaida, oVlrDin, oRequis, oCargo
	Local aCpoUF2 := {"LEGCHT","UF2_BANCO","UF2_AGENCI","UF2_CONTA","UF2_NUM","UF2_VALOR","UF2_DOC","UF2_SERIE","UF2_PDV"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local bAtuTela := {|| AtuDetSQ(aCpoUF2) }
	Private oDlgAux
	Private oGridUF2
	Private nValDinh := 0

	if empty(nRecU57)
		Return
	endif

	if !SuperGetMV("TP_ACTCHT",,.F.)
		MsgInfo("Rotina de Cheque troco desabilitada. Não há como alterar saida de Saque!","Atenção")
		Return
	endif

	U57->(DbSetOrder(1))
	U57->(DBGoTo(nRecU57))

	U56->(DbSetOrder(1))
	U56->(DbSeek(xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO))

	DEFINE MSDIALOG oDlgAux TITLE "Alterar Saída do Saque" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	//---- Dados Cabeçalho
	@ 05, 05 GROUP oGroup1 TO 095, 395 PROMPT "Dados do Saque" OF oDlgAux COLOR 0, 16777215 PIXEL

	@ 015, 010 SAY "Codigo Barras" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 023, 010 MSGET oCodBar VAR (U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) When .F. SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 095 SAY "Cliente" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 023, 095 MSGET oCliente VAR (U56->U56_CODCLI+"/"+U56->U56_LOJA+" - "+U56->U56_NOME) When .F. SIZE 200, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 300 SAY "Dt.Emissão" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 023, 300 MSGET oEmissao VAR U57->U57_DATAMO When .F. SIZE 050, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 040, 010 SAY "Placa" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 048, 010 MSGET oPlaca VAR U57->U57_PLACA When .F. SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 040, 095 SAY "Motorista" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 048, 095 MSGET oMotorista VAR (U57->U57_MOTORI+" - "+Posicione("DA4",3,xFilial("DA4")+U57->U57_MOTORI,"DA4_NOME")) When .F. SIZE 200, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 040, 300 SAY "Valor Total Saque" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 048, 300 MSGET oVlrSaida VAR U57->U57_VALSAQ When .F. Picture "@E 999,999,999.99" SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 065, 010 SAY "Requisitante" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 073, 010 MSGET oRequis VAR U56->U56_REQUIS When .F. SIZE 140, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 065, 155 SAY "Cargo" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 073, 155 MSGET oCargo VAR U56->U56_CARGO When .F. SIZE 140, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	@ 065, 300 SAY "Valor Dinheiro" SIZE 50, 007 OF oDlgAux COLORS 0, 16777215 PIXEL
	@ 073, 300 MSGET oVlrDin VAR nValDinh When .F. Picture "@E 999,999,999.99" SIZE 080, 010 OF oDlgAux HASBUTTON COLORS 0, 16777215 PIXEL

	//---- Cheque Troco
	@ 100, 005 GROUP oGroup1 TO 180, 395 PROMPT "Cheque Troco" OF oDlgAux COLOR 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCpoUF2)
	aColsEx := {}
	aadd(aColsEx, MontaDados("UF2",aCpoUF2, .T.))
	oGridUF2 := MsNewGetDados():New( 110, 010, 175, 330,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgAux, aHeaderEx, aColsEx)
	oGridUF2:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridUF2, @nCol), )}

	TButton():New( 110, 335, "Incluir", oDlgAux, {|| IncChqTroco(3,,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 125, 335, "Excluir", oDlgAux, {|| DelChqTroco(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],3,,,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 140, 335, "Substituir", oDlgAux, {|| SubChqTroco(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],.T.,bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 155, 335, "Corrigir Fin.", oDlgAux, {|| CorrigeCHT(oGridUF2:aCols[oGridUF2:nAt][len(aCpoUF2)+1],bAtuTela) }, 55, 12,,,.F.,.T.,.F.,,.F.,,,.F. )

	@ 185, 355 BUTTON oButton1 PROMPT "Fechar" SIZE 040, 012 OF oDlgAux PIXEL Action oDlgAux:End()
	oButton1:SetCSS( CSS_BTNAZUL )

	AtuDetSQ(aCpoUF2, .F.)

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Carrega dados na tela de Alterar Saida Saque
//--------------------------------------------------------------------------------------
Static Function AtuDetSQ(aCpoUF2, lRefresh)

	Local nTotCHT := 0
	Default lRefresh := .T.

	//Cheque Troco
	oGridUF2:aCols := {}
	UF2->(DbSetOrder(4)) //UF2_FILIAL+UF2_CODBAR
	if UF2->(DbSeek(xFilial("UF2")+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL ))
		While UF2->(!Eof()) .AND. UF2->UF2_FILIAL+UF2->UF2_CODBAR == xFilial("UF2")+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL

			aadd(oGridUF2:aCols, MontaDados("UF2",aCpoUF2))
			nTotCHT += UF2->UF2_VALOR
			oGridUF2:aCols[len(oGridUF2:aCols)][aScan(aCpoUF2,"LEGCHT")] := LegendUF2()

			UF2->(DbSkip())
		EndDO
	else
		aadd(oGridUF2:aCols, MontaDados("UF2",aCpoUF2, .T.))
	endif

	nValDinh := U57->U57_VALSAQ - nTotCHT
	if nValDinh < 0
		nValDinh := U57->U57_VALSAQ - U57->U57_CHTROC
	endif

	if lRefresh
		oGridUF2:oBrowse:Refresh()
		oDlgAux:Refresh()
	endif

Return

//--------------------------------------------------------------------------------------
// Inclusao de deposito
//--------------------------------------------------------------------------------------
Static Function TelaDeposito(nOpcX, bRefresh)

	Local lOk := .T.
	Local dBkpDbase := dDataBase
	Local cMsgErro := ""
	Local nRecnoU57 := 0
	Local bConfirm := {|| nRecnoU57 := U57->(Recno()) , oDlgAux:end() }
	Local bCancel := {|| oDlgAux:end() }
	Local oPnlAux, cChavU57
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Private oDlgAux

	dDataBase := SLW->LW_DTABERT

	DEFINE MSDIALOG oDlgAux TITLE "Inclusão de Depósito PDV" FROM 000, 000  TO 570, 800 COLORS 0, 16777215 PIXEL STYLE DS_MODALFRAME

	@ 000, 000 MSPANEL oPnlAux SIZE (oDlgAux:nWidth/2), (oDlgAux:nHeight/2)-12 OF oDlgAux
	oPnlAux:SetCSS( "TPanel{border: none; background-color: #f4f4f4;}" )
	U_TPDVA008(oPnlAux, .T., bConfirm, bCancel) //monta tela de deposito

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if nRecnoU57 > 0 .AND. nOpcX == 3 //se retornou recno é pq incluiu

		if Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_TIPO") == "1" //somente pre paga
			RecLock("U57", .F.)
			U57->U57_XGERAF := "C" //gerar pela conferencia
			U57->(MsUnlock())

			cLogCaixa := "CLIENTE: " + U56->U56_CODCLI +" | "+U56->U56_LOJA +" | "+Alltrim(U56->U56_NOME) + CRLF
			cLogCaixa += "VALOR: " + Transform(U57->U57_VALOR ,"@E 999,999,999.99") + CRLF

			cChavU57 := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL

			//gera financeiro vale motorista
			MsAguarde( {|| lOk := U_TRETE023(cChavU57, @cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro
		endif

		if lOk
			MsgInfo("Inclusao do Depósito PDV realizada com sucesso!","Atenção")
			if lLogCaixa
				GrvLogConf("6","I", cLogCaixa, , , cChavU57)
			endif
		else
			MsgAlert("Falha ao gerar financeiro do Depósito PDV!"+ CRLF +cMsgErro,"Atenção")
		endif

	endif

	dDataBase := dBkpDbase

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Reprocessa financeiro do vale motorista
//--------------------------------------------------------------------------------------
Static Function ReprocDP()

	Local lOk := .T.
	Local aRet
	Local cChavU57 := ""
	Local dBkpDBase := dDataBase
	Local cMsgErro := ""

	//aRet := {cChavU57, lOk, nVlrU57, nVlrReceb, nVlrCredi, nVlrDin, nVlrCHT, cObs}
	aRet := AvalFinU57("DEPOSITO", U57->U57_PREFIX, U57->U57_CODIGO, U57->U57_PARCEL)

	if aRet[2]
		MsgInfo("Financeiro do deposito está correto. Não precisa ser reprocessado!","Atenção")
		Return
	endif

	dDataBase := U57->U57_DATDEP
	cChavU57 := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL //vem posicionado em caso de sucesso

	BeginTran()

	if U57->U57_XGERAF $ 'X,Z,D'
		RecLock("U57", .F.)
		U57->U57_XGERAF := "Z" //estornar pela conferencia
		U57->(MsUnlock())
	else
		RecLock("U57", .F.)
		U57->U57_XGERAF := "C" //gerar pela conferencia
		U57->(MsUnlock())
	endif

	//gera financeiro
	MsAguarde( {|| lOk := U_TRETE023(cChavU57, @cMsgErro) }, "Aguarde", "Processando Financeiro...", .F. ) //JOB processa financeiro

	if lOk
		//vejo se corrigiu
		aRet := AvalFinU57("VALE MOTORISTA", U57->U57_PREFIX, U57->U57_CODIGO, U57->U57_PARCEL)
		if aRet[2]
			MsgInfo("Financeiro do Vale Motorista reprocessado com sucesso!","Atenção")
		else
			DisarmTransaction()
			MsgAlert("Falha ao reprocessar financeiro!","Atenção")
		endif
	else
		MsgAlert("Falha ao reprocessar financeiro! "+ CRLF +cMsgErro,"Atenção")
		DisarmTransaction()
	endif

	EndTran()

	dDataBase := dBkpDBase

Return

//--------------------------------------------------------------------------------------
// Funçao para estorno do caixa
//--------------------------------------------------------------------------------------
User Function TRA028ES(lEstorna)

	Local _dData
	Local cQry := ""
	Local _lRet 	:= .F.
	Local aArea		:= GetArea()
	Local aAreaSE5  := SE5->(GetArea())
	Local aAreaSLW  := SLW->(GetArea())
	Local dMvDtFin := GETMV("MV_DATAFIN")
	Local dMvDtRec := GETMV("MV_DATAREC")
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lVldAcess := SuperGetMv("MV_XCONFAC",.F.,.F.) .OR. SuperGetMv("MV_XMARAJO",.F.,.F.)
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo

	Private lMsErroAuto:=.F.

	Default lEstorna := .T.

	if lEstorna .AND. lVldAcess
		U_TRETA37B("ESTOCX", "PERMITE ESTORNAR O CAIXA")
		if !U_VLACESS2("ESTOCX", RetCodUsr()) 
			MsgAlert("Usuário sem permissão para estornar caixa.","Atenção")
			return(.F.)
		endif
	endif

	//Verificar se ja esta fechado
	If (SLW->LW_CONFERE=='1' .And. lEstorna) .OR. (SLW->LW_CONFERE=='2' .And. !lEstorna)

		//Busca movimentos na SE5, de falta/sobra de caixa
		cQry:=" SELECT E5_RECONC, E5_LA, R_E_C_N_O_ RECNO_ FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5"
		cQry+=" WHERE D_E_L_E_T_<> '*' AND E5_DATA = '"+Dtos(SLW->LW_DTABERT)+"'"
		if SE5->(FieldPos("E5_XPDV")) > 0
			cQry+=" AND E5_FILIAL = '"+xFilial("SE5")+"' AND E5_NUMMOV='"+SLW->LW_NUMMOV+"'"
			cQry+=" AND E5_XESTAC = '"+SLW->LW_ESTACAO+"' AND E5_XPDV='"+SLW->LW_PDV+"'"
		Else
			cQry+=" AND E5_FILIAL = '"+xFilial("SE5")+"' AND E5_NUMMOV='"+SLW->LW_NUMMOV+"'"
		EndIf
		cQry+=" AND E5_MOEDA = 'M1'"
		cQry+=" AND E5_NUMERO = ' '" // movimento de diferença de caixa não tem DOC
		cQry+=" AND E5_BANCO = '"+SLW->LW_OPERADO+"'" //campo criado somente para possibilitar o estorno
		cQry+=" AND E5_SITUACA = ' '"
		cQry := ChangeQuery(cQry)

		If Select("DataSe5")>0
			DataSe5->(DbCloseArea())
		Endif
		Tcquery cQry New alias "DataSe5"

		If DataSe5->(!Eof()) //se ouve falta ou sobra
			If !lEstorna .OR. MsgYesno("Confirma estorno da Conferência? Operação não poderá ser desfeita!","Atenção")

				BeginTran()

				While DataSe5->(!Eof())

					RestArea(aAreaSLW) //forço manter posicionado na SLW, pois algum PE no processo pode desposicionar

					If UPPER(DataSe5->E5_RECONC) == "X" .And. lEstorna
						MsgAlert("Estorno de caixa negado. O movimento de diferença de caixa já se encontra conciliado!","Atenção")
						_lRet := .F.
						DisarmTransaction()
						Exit //sai do While
					ElseIf lVldLA .AND. Upper(Alltrim(DataSe5->E5_LA)) == "S" .And. lEstorna
						MsgAlert("Estorno de caixa negado. O movimento de diferença de caixa já se encontra contabilizado!","Atenção")
						_lRet := .F.
						DisarmTransaction()
						Exit //sai do While
					Else

						If !lEstorna
							//Alert("Este caixa possuí movimentos de diferença de caixa não estornados corretamente. Aguarde enquanto o estorno é processado!")
							If UPPER(DataSe5->E5_RECONC) == "X"
								MsgAlert("Existem movimentos de diferença de caixa que já foram conciliados. Não será possível confirmar este caixa. Favor realizar o estorno das conciliações do caixa.","Atenção")
								_lRet := .F.
								DisarmTransaction()
								EndTran()
								Return _lRet
							ElseIf lVldLA .AND. Upper(Alltrim(DataSe5->E5_LA)) == "S"
								MsgAlert("Existem movimentos de diferença de caixa que já foram contabilizados. Não será possível confirmar este caixa. Favor realizar o estorno das contabilizações do caixa.","Atenção")
								_lRet := .F.
								DisarmTransaction()
								EndTran()
								Return _lRet
							EndIf
						EndIf

						If SLW->LW_DTABERT < dMvDtFin //Fabio Pires - 23-02-16
							MsgAlert("Não é possível estornar o caixa. A data limite p/ realização de operações financeiras se encontra fechada [MV_DATAFIN].","Atenção")
							_lRet := .F.
							DisarmTransaction()
							EndTran()
							Return _lRet
						ElseIf SLW->LW_DTABERT < dMvDtRec //Fabio Pires - 23-02-16
							MsgAlert("Não é possível estornar o caixa. A data limite p/ realização de operações financeiras se encontra fechada [MV_DATAREC].","Atenção")
							_lRet := .F.
							DisarmTransaction()
							EndTran()
							Return _lRet
						EndIf

						DbSelectArea("SE5")
						SE5->(DbGoto(DataSe5->RECNO_))

						aFINA100 := {   {"E5_DATA"					,SE5->E5_DATA		,Nil},;
										{"E5_MOEDA"             	,SE5->E5_MOEDA		,Nil},;
										{"E5_VALOR"             	,SE5->E5_VALOR		,Nil},;
										{"E5_NATUREZ"        		,SE5->E5_NATUREZ	,Nil},;
										{"E5_BANCO"            		,SE5->E5_BANCO		,Nil},;
										{"E5_AGENCIA"         		,SE5->E5_AGENCIA	,Nil},;
										{"E5_CONTA"         		,SE5->E5_CONTA		,Nil},;
										{"E5_HISTOR"        		,SE5->E5_HISTOR		,Nil},;
										{"E5_TIPOLAN"        		,SE5->E5_TIPOLAN	,Nil} }

						_dData := dDataBase
						dDataBase := SE5->E5_DATA

						MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,6) //estorno

						If lMsErroAuto
							MostraErro()
							_lRet := .F.
							DisarmTransaction()
							Exit //sai do While
						Else

							/*Reclock("SE5", .F.)
								if SE5->(FieldPos("E5_XPDV")) > 0
									SE5->E5_XPDV	:= SLW->LW_PDV
									SE5->E5_XESTAC	:= SLW->LW_ESTACAO
									SE5->E5_NUMMOV	:= SLW->LW_NUMMOV
								Else
									SE5->E5_NUMMOV	:= SLW->LW_NUMMOV
								Endif
							SE5->(MsUnLock())*/

							_lRet := .T.

						EndIf

						dDataBase := _dData

					EndIf

					DataSe5->(DbSkip())
				EndDo

				If _lRet
					Reclock("SLW",.F.)
					SLW->LW_CONFERE := '2'
					if SLW->(FieldPos("LW_XFALTCX")) > 0
						SLW->LW_XFALTCX := 0
					endif
					if SLW->(FieldPos("LW_XFLTCX")) > 0
						SLW->LW_XFLTCX  := 0
					endif
					SLW->(MsUnLock())

					if lLogCaixa
						GrvLogConf("1","E")
					endif

					MsgInfo("Estorno do caixa realizado com sucesso!","Atenção")
				EndIf

				EndTran()

			EndIf

		//se nao tem o campo ou ele está vazio
		Elseif (SLW->(FieldPos("LW_XFLTCX")) == 0 .OR. SLW->LW_XFLTCX == 0) .and. lEstorna
			Reclock("SLW",.F.)
			SLW->LW_CONFERE := '2'
			if SLW->(FieldPos("LW_XFALTCX")) > 0
				SLW->LW_XFALTCX := 0
			endif
			if SLW->(FieldPos("LW_XFLTCX")) > 0
				SLW->LW_XFLTCX  := 0
			endif
			SLW->(MsUnLock())
			if lLogCaixa
				GrvLogConf("1","E")
			endif
			MsgInfo("Estorno do caixa realizado com sucesso!","Atenção")
		Elseif SLW->(FieldPos("LW_XFLTCX")) > 0 .AND. SLW->LW_XFLTCX > 0 .and. lEstorna
			MsgAlert("Estorno negado. O movimento de diferença de caixa não encontrado!","Atenção")
		ElseIf !lEstorna
			_lRet := .T.
		Endif
	ElseIf lEstorna
		MsgAlert("Caixa não esta Conferido!","Atenção")
	ElseIf !lEstorna
		_lRet := .T.
	Endif

	If Select("DataSe5")>0
		DataSe5->(DbCloseArea())
	Endif

	RestArea(aArea)
	RestArea(aAreaSE5)
	RestArea(aAreaSLW)

Return _lRet


/***************************************************************************************************
************************ FUNÇÕES DE DETALHAMENTO DAS FORMAS PADRÕES ********************************
***************************************************************************************************/

//--------------------------------------------------------------------------------------
// Totalizador de Suprimento (SU)
//--------------------------------------------------------------------------------------
User Function T028TSU(nOpcX, aDados, aCampos, cCondAux)

	Local nRet := 0
	Local cCondicao, bCondicao, nSA6REC

	Local aArea := GetArea()
	Local aAreaSA6 := SA6->(GetArea())
	Local lFilVend := type("__CFILVEND")=="C"

	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default cCondAux := ""

	if lSrvPDV
		cCondicao := GetFilSE5("PDV")
		cCondicao += " .AND. (E5_TIPODOC == 'TR' .OR. E5_TIPODOC == 'TE') .AND. E5_MOEDA == 'TC' .AND. E5_RECPAG == 'R' .AND. E5_SITUACA <> 'C' "
		if !empty(cCondAux)
			cCondicao += " .AND. " + cCondAux
		endif
		if lFilVend
			cCondicao += " .AND. E5_OPERAD == '"+__CFILVEND+"'" 
		endif

		bCondicao 	:= "{|| " + cCondicao + " }"

		SE5->(DbClearFilter())
		SE5->(DbSetFilter(&bCondicao,cCondicao))
		SE5->(DbGoTop())

		While SE5->(!Eof())

			nRet += SE5->E5_VALOR

			if !empty(aCampos)
				Posicione("SA3",1,xFilial("SA3")+SE5->E5_OPERAD,"A3_COD")
				aadd(aDados, MontaDados("SE5", aCampos, .F.))
			endif

			SE5->(DbSkip())
		EndDo

		SE5->(DbClearFilter())
	else
		cCondicao := GetFilSE5("TOP")

		//Confirmo se tem movimento na SE5
		cQry:= "SELECT E5_VALOR, R_E_C_N_O_ RECSE5 "
		cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
		cQry+= "WHERE SE5.D_E_L_E_T_ = ' ' "
		cQry+= cCondicao
		cQry+= "  AND (E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') "
		cQry+= "  AND E5_MOEDA = 'TC' "
		cQry+= "  AND E5_RECPAG = 'R' AND E5_SITUACA <> 'C' "
		if !empty(cCondAux)
			cQry += " AND " + cCondAux
		endif
		if lFilVend
			cQry += " AND E5_OPERAD = '"+__CFILVEND+"'" 
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		nSA6REC := SA6->(RecNo())

		While QRYT1->(!Eof())

			nRet += QRYT1->E5_VALOR

			if !empty(aCampos)

				//-- posiciona no banco que fez o suprimento
				SE5->(DbGoTo(QRYT1->RECSE5))
				cChvPag := SE5->(E5_FILIAL+E5_NATUREZ+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DTDIGIT))+'P'+ SE5->(E5_CLIFOR+E5_LOJA)
				SE5->(DbSetOrder(4)) //E5_FILIAL+E5_NATUREZ+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DTDIGIT)+E5_RECPAG+E5_CLIFOR+E5_LOJA
				SE5->(DbSeek(cChvPag))
				SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
				SA6->(DbSeek(xFilial("SA6")+SE5->(E5_BANCO+E5_AGENCIA+E5_CONTA)))

				SE5->(DbGoTo(QRYT1->RECSE5))

				Posicione("SA3",1,xFilial("SA3")+SE5->E5_OPERAD,"A3_COD")
				aadd(aDados, MontaDados("SE5", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		SA6->(DbGoTo(nSA6REC))
		QRYT1->(DbCloseArea())
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE5",aCampos, .T.))
	endif

	RestArea(aAreaSA6)
	RestArea(aArea)

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Sangria (SG)
//--------------------------------------------------------------------------------------
User Function T028TSG(nOpcX, aDados, aCampos, cCondAux)

	Local nRet := 0
	Local cCondicao, bCondicao, nSA6REC

	Local aArea := GetArea()
	Local aAreaSA6 := SA6->(GetArea())
	Local lFilVend := type("__CFILVEND")=="C"

	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default cCondAux := ""

	if lSrvPDV
		cCondicao := GetFilSE5("PDV")
		cCondicao += " .AND. (E5_TIPODOC == 'SG' .OR. E5_TIPODOC == 'TR' .OR. E5_TIPODOC == 'TE') .AND. E5_MOEDA == '"+SIMBDIN+"' .AND. E5_RECPAG == 'P' .AND. E5_SITUACA <> 'C'  "
		if !empty(cCondAux)
			cCondicao += " .AND. " + cCondAux
		endif
		if lFilVend
			cCondicao += " .AND. E5_OPERAD == '"+__CFILVEND+"'" 
		endif

		bCondicao 	:= "{|| " + cCondicao + " }"

		SE5->(DbClearFilter())
		SE5->(DbSetFilter(&bCondicao,cCondicao))
		SE5->(DbGoTop())

		While SE5->(!Eof())

			nRet += SE5->E5_VALOR

			if !empty(aCampos)
				Posicione("SA3",1,xFilial("SA3")+SE5->E5_OPERAD,"A3_COD")
				aadd(aDados, MontaDados("SE5", aCampos, .F.))
			endif

			SE5->(DbSkip())
		EndDo

		SE5->(DbClearFilter())
	else
		cCondicao := GetFilSE5("TOP")

		//Confirmo se tem movimento na SE5
		cQry:= "SELECT E5_VALOR, R_E_C_N_O_ RECSE5 "
		cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
		cQry+= "WHERE SE5.D_E_L_E_T_ = ' ' "
		cQry+= cCondicao
		cQry+= "  AND (E5_TIPODOC = 'SG' OR E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') "
		cQry+= "  AND E5_MOEDA = '"+SIMBDIN+"' "
		cQry+= "  AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C' "
		if !empty(cCondAux)
			cQry += " AND " + cCondAux
		endif
		if lFilVend
			cQry += " AND E5_OPERAD = '"+__CFILVEND+"'" 
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query
		nSA6REC := SA6->(RecNo())

		While QRYT1->(!Eof())

			nRet += QRYT1->E5_VALOR

			if !empty(aCampos)

				//-- posiciona no banco que fez o suprimento
				SE5->(DbGoTo(QRYT1->RECSE5))
				cChvPag := SE5->(E5_FILIAL+E5_NATUREZ+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DTDIGIT))+'R'+ SE5->(E5_CLIFOR+E5_LOJA)
				SE5->(DbSetOrder(4)) //E5_FILIAL+E5_NATUREZ+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DTDIGIT)+E5_RECPAG+E5_CLIFOR+E5_LOJA
				SE5->(DbSeek(cChvPag))
				SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
				SA6->(DbSeek(xFilial("SA6")+SE5->(E5_BANCO+E5_AGENCIA+E5_CONTA)))

				SE5->(DbGoTo(QRYT1->RECSE5))
				
				Posicione("SA3",1,xFilial("SA3")+SE5->E5_OPERAD,"A3_COD")
				aadd(aDados, MontaDados("SE5", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		SA6->(DbGoTo(nSA6REC))
		QRYT1->(DbCloseArea())
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE5",aCampos, .T.))
	endif

	RestArea(aAreaSA6)
	RestArea(aArea)

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Troco de Vendas (TV)
//--------------------------------------------------------------------------------------
User Function T028TTV(nOpcX, aDados, aCampos, cFiltro, lChvCx, lSoData)

	Local nRet := 0
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local cCondicao, bCondicao
	Local lActCHT := SuperGetMV("TP_ACTCHT",,.F.)
	Local lActVLH := SuperGetMV("TP_ACTVLH",,.F.)
	Local lFilVend := type("__CFILVEND")=="C"

	Local lRelGeral := type("_aListSLW")=="A" .and. Len(_aListSLW)>0 .and. IsInCallStack('U_TRETR022') //chamado pelo relatório geral de caixa: U_TRETR022 
	Local nX := 0
	Local aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,nTamHora),SLW->LW_HRFECHA)}

	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default cFiltro := ""
	Default lChvCx := .T.
	Default lSoData := .F.

	if lSrvPDV
		cCondicao := GetFilSL1("PDV",, .T.)
		if !empty(cFiltro)
			cCondicao += " .AND. " + cFiltro
		endif
		if lFilVend
			cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"' "
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"
		SL1->(DbClearFilter())
		SL1->(DbSetFilter(&bCondicao,cCondicao))
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())
		While SL1->(!Eof())
			nRet += (SL1->L1_TROCO1 - iif(lMvPosto .AND. lActCHT,SL1->L1_XTROCCH,0) - iif(lMvPosto .AND. lActVLH,SL1->L1_XTROCVL,0))
			if !empty(aCampos)
				aadd(aDados, MontaDados("SL1", aCampos, .F.))
			endif
			SL1->(DbSkip())
		EndDo
		SL1->(DbClearFilter())
	else
		//Confirmo se tem movimento na SE5
		cQry:= "SELECT E5_VALOR, R_E_C_N_O_ RECSE5 "
		cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
		cQry+= "WHERE SE5.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
		
		if !lRelGeral //legado...
			cQry+= "  AND E5_BANCO = '"+aSLW[1]+"' "
			if lChvCx
				if SE5->(FieldPos("E5_XPDV")) > 0
					cQry+= "  AND E5_NUMMOV = '"+aSLW[2]+"' "
					//caso XPDV nao preenchido
					cQry+= "  AND ((E5_XPDV = ' ' AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
					cQry+= "  AND E5_DATA <= '"+DTOS(aSLW[7])+"') "
					//caso XPDV preenchido
					cQry+= "  OR (RTRIM(E5_XPDV) = '"+Alltrim(aSLW[3])+"' "
					cQry+= "  AND E5_XESTAC = '"+aSLW[4]+"' "
					cQry+= "  AND E5_DATA||SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cQry+= "  AND E5_DATA||SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"')) "
				Else
					cQry+= "  AND E5_NUMMOV = '"+aSLW[2]+"' "
					cQry+= "  AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
					cQry+= "  AND E5_DATA <= '"+DTOS(aSLW[7])+"' "
				EndIf
			elseif lSoData //senao, pelo menos compara a data
				cQry+= "  AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
				cQry+= "  AND E5_DATA <= '"+DTOS(aSLW[7])+"' "
			endif
		else //chamado pelo relatório geral de caixa: U_TRETR022 
			cQry+= " AND ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cQry+= iif(nX>1," OR (","(")
				cQry+= " E5_BANCO = '"+aSLW[1]+"' "
				if lChvCx
					if SE5->(FieldPos("E5_XPDV")) > 0
						cQry+= "  AND E5_NUMMOV = '"+aSLW[2]+"' "
						//caso XPDV nao preenchido
						cQry+= "  AND ((E5_XPDV = ' ' AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
						cQry+= "  AND E5_DATA <= '"+DTOS(aSLW[7])+"') "
						//caso XPDV preenchido
						cQry+= "  OR (RTRIM(E5_XPDV) = '"+Alltrim(aSLW[3])+"' "
						cQry+= "  AND E5_XESTAC = '"+aSLW[4]+"' "
						cQry+= "  AND E5_DATA||SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
						cQry+= "  AND E5_DATA||SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"')) "
					Else
						cQry+= "  AND E5_NUMMOV = '"+aSLW[2]+"' "
						cQry+= "  AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
						cQry+= "  AND E5_DATA <= '"+DTOS(aSLW[7])+"' "
					EndIf
				elseif lSoData //senao, pelo menos compara a data
					cQry+= "  AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
					cQry+= "  AND E5_DATA <= '"+DTOS(aSLW[7])+"' "
				endif
				cQry+= ")"
			Next nX
			cQry +=")"
		endif

		cQry+= "  AND (E5_TIPODOC = 'TR' OR E5_TIPODOC = 'VL') "
		cQry+= "  AND E5_MOEDA = 'TC' "
		cQry+= "  AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C' "
		if !Empty(cFiltro)
			cQry+= "  AND " + cFiltro
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			SE5->(DbGoTo(QRYT1->RECSE5))

			if lFilVend
				cQry += " AND E5_OPERAD = '"+__CFILVEND+"'" 
				cVendL1 := Posicione("SL1",2,xFilial("SL1")+SE5->E5_PREFIXO+SE5->E5_NUMERO, "L1_VEND")
				if cVendL1 <> __CFILVEND
					QRYT1->(DbSkip())
					LOOP
				endif
			endif

			nRet += QRYT1->E5_VALOR

			if !empty(aCampos)
				aadd(aDados, MontaDados("SE5", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE5",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Vendas Combustiveis (VC)
//--------------------------------------------------------------------------------------
User Function T028TVC(nOpcX, aDados, aCampos, lAbastOk)

	Local nRet := 0
	Local nX := 0
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {"L2_VLRITEM"}
	Default lAbastOk := .T.

	if lSrvPDV
		aDados := BuscaSL2("PDV", nOpcX, aCampos,,"!empty(SL2->L2_MIDCOD)", @lAbastOk)
	else
		aDados := BuscaSL2("TOP", nOpcX, aCampos,"L2_MIDCOD<>''",, @lAbastOk)
	endif

	For nX:=1 To Len(aDados)
		nRet+= aDados[nX][aScan(aCampos,"L2_VLRITEM")]
	Next

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SL2",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Vendas Produtos (VP)
//--------------------------------------------------------------------------------------
User Function T028TVP(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local nX := 0
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {"L2_VLRITEM"}

	if lSrvPDV
		aDados := BuscaSL2("PDV", nOpcX, aCampos,,"empty(SL2->L2_MIDCOD)")
	else
		aDados := BuscaSL2("TOP", nOpcX, aCampos,"L2_MIDCOD=''")
	endif

	For nX:=1 To Len(aDados)
		nRet+= aDados[nX][aScan(aCampos,"L2_VLRITEM")]
	Next

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SL2",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de VALE SERVIÇO (EMITIDO)
//--------------------------------------------------------------------------------------
User Function T028TVLS(nOpcX, aDados, aCampos, lSoPosPago, lSoPrePago)

	Local nRet := 0
	Local cQry
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lSoPosPago := .F.
	Default lSoPrePago := .F.

	if lSrvPDV

		cCondicao := GetFilUIC("PDV")
		if lSoPosPago
			cCondicao += " .AND. UIC_TIPO == 'O' " //vale Pós
		endif
		if lSoPrePago
			cCondicao += " .AND. UIC_TIPO == 'R' " //vale pre
		endif
		if lFilVend
			cCondicao += " .AND. UIC_VEND == '"+__CFILVEND+"' " 
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"

		UIC->(DbClearFilter())
		UIC->(DbSetFilter(&bCondicao,cCondicao))
		UIC->(DbSetOrder(1))
		UIC->(DbGoTop())
		While UIC->(!Eof())
			nRet += UIC->UIC_PRCPRO

			if !empty(aCampos)
				Posicione("SA3",1,xFilial("SA3")+UIC->UIC_VEND,"A3_COD")
				aadd(aDados, MontaDados("UIC", aCampos, .F.))
			endif
			UIC->(DbSkip())
		EndDo
		UIC->(DbClearFilter())

	else //TOP

		DbSelectArea("UIC")
		cCondicao := GetFilUIC("TOP")

		//Confirmo se tem movimento na SE5
		cQry:= "SELECT UIC.UIC_PRCPRO, UIC.R_E_C_N_O_ RECUIC "
		cQry+= "FROM "+RetSqlName("UIC")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UIC "
		cQry+= "WHERE UIC.D_E_L_E_T_ = ' ' "
		cQry+= "  AND "+cCondicao+" "
		if lSoPosPago
			cQry+= "  AND UIC_TIPO = 'O' " //Vale Pós
		endif
		if lSoPrePago
			cQry+= "  AND UIC_TIPO = 'R' " //Vale Pós
		endif
		if lFilVend
			cQry += " AND UIC_VEND = '"+__CFILVEND+"' " 
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->UIC_PRCPRO

			if !empty(aCampos)
				UIC->(DbGoTo(QRYT1->RECUIC))
				Posicione("SA3",1,xFilial("SA3")+UIC->UIC_VEND,"A3_COD")
				aadd(aDados, MontaDados("UIC", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("UIC",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Cheque Troco  (CHT)
//--------------------------------------------------------------------------------------
User Function T028TCHT(nOpcX, aDados, aCampos, lVenda, lComp, lSaque)

	Local nRet := 0
	Local cQry
	Local lLegenda := .F.
	Local cPrefixComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local lFilVend := type("__CFILVEND")=="C"
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lVenda := .T.
	Default lComp := .T.
	Default lSaque := .T.

	if lSrvPDV

		//buscar das vendas
		if lVenda
			cCondicao := GetFilSL1("PDV")
			cCondicao += " .AND. L1_XTROCCH > 0 "
			if lFilVend
				cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"' "
			endif
			bCondicao 	:= "{|| " + cCondicao + " }"
			SL1->(DbClearFilter())
			SL1->(DbSetFilter(&bCondicao,cCondicao))
			SL1->(DbSetOrder(1))
			SL1->(DbGoTop())
			While SL1->(!Eof())
				if !empty(aCampos)
					UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
					if UF2->(DbSeek(xFilial("UF2")+SL1->L1_DOC+SL1->L1_SERIE+Alltrim(SL1->L1_PDV)))
						While UF2->(!Eof()) .And. UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE+Alltrim(UF2->UF2_PDV) == xFilial("UF2")+SL1->L1_DOC+SL1->L1_SERIE+Alltrim(SL1->L1_PDV)
							aadd(aDados, MontaDados("UF2",aCampos, .F.))
							nRet += UF2->UF2_VALOR
							UF2->(DbSkip())
						EndDo
					EndIf
				else
					nRet += SL1->L1_XTROCCH
				endif
				SL1->(DbSkip())
			EndDo
			SL1->(DbClearFilter())
		endif

		//buscar das compensações
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.)
			cCondicao := GetFilUC0("PDV")
			cCondicao += " .AND. UC0_VLCHTR > 0 "
			if lFilVend
				cCondicao += " .AND. UC0_VEND == '"+__CFILVEND+"' "
			endif
			bCondicao 	:= "{|| " + cCondicao + " }"
			UC0->(DbClearFilter())
			UC0->(DbSetFilter(&bCondicao,cCondicao))
			UC0->(DbSetOrder(1))
			UC0->(DbGoTop())
			While UC0->(!Eof())
				nRet += UC0->UC0_VLCHTR //Comentar essa linha caso queira apurar pela UF2
				UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV
				if UF2->(DbSeek(xFilial("UF2")+UC0->UC0_NUM+SubStr(cPrefixComp,1,TamSX3("UF2_SERIE")[1])+Alltrim(UC0->UC0_PDV)))
					While UF2->(!Eof()) .And. UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE+Alltrim(UF2->UF2_PDV) == xFilial("UF2")+UC0->UC0_NUM+SubStr(cPrefixComp,1,TamSX3("UF2_SERIE")[1])+Alltrim(UC0->UC0_PDV)
						aadd(aDados, MontaDados("UF2",aCampos, .F.))
						UF2->(DbSkip())
					EndDO
				EndIf
				UC0->(DbSkip())
			EndDo
			UC0->(DbClearFilter())
		endif

		//Buscar dos Saques Pré e Pós
		if lSaque .AND. SuperGetMV("TP_ACTSQ",,.F.)
			cCondicao := GetFilU57("PDV")
			cCondicao += "  .AND. U57_TUSO = 'S' " //Saque
			cCondicao += "  .AND. U57_FILSAQ = '"+cFilAnt+"' " //Usada
			if lFilVend
				cCondicao += " .AND. U57_VEND == '"+__CFILVEND+"' "
			endif
			//cCondicao += "  .AND. !empty(U57_MOTIVO) " //Financeiro gerado ou pendente
			bCondicao 	:= "{|| " + cCondicao + " }"
			U57->(DbClearFilter())
			U57->(DbSetFilter(&bCondicao,cCondicao))
			U57->(DbSetOrder(1))
			U57->(DbGoTop())
			While U57->(!Eof())
				nRet += U57->U57_CHTROC //Comentar essa linha caso queira apurar pela UF2

				UF2->(DbSetOrder(4)) //UF2_FILIAL+UF2_CODBAR
				if UF2->(DbSeek(xFilial("UF2")+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL ))
					While UF2->(!Eof()) .And. UF2->UF2_FILIAL+UF2->UF2_CODBAR == xFilial("UF2")+U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL

						aadd(aDados, MontaDados("UF2",aCampos, .F.))

						UF2->(DbSkip())
					EndDO
				EndIf

				U57->(DbSkip())
			EndDo
			U57->(DbClearFilter())
		endif

	else //Retaguarda

		lLegenda := aScan(aCampos,"LEGCHT")>0

		cQry := ""

		//das vendas
		if lVenda
			cCondicao := GetFilSL1("TOP")
			if lFilVend
				cCondicao += " AND L1_VEND = '"+__CFILVEND+"' "
			endif
			cQry:= "SELECT UF2_VALOR, UF2.R_E_C_N_O_ RECUF2 "
			cQry+= "FROM "+RetSqlName("UF2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UF2 "
			cQry+= " INNER JOIN "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 ON ("
			cQry+= "  SL1.D_E_L_E_T_= ' ' AND L1_DOC=UF2_DOC AND L1_SERIE=UF2_SERIE AND RTRIM(L1_PDV)=RTRIM(UF2_PDV) AND "+cCondicao+" ) "
			cQry+= "WHERE UF2.D_E_L_E_T_ = ' ' "
			cQry+= "  AND UF2_FILIAL = '"+xFilial("UF2")+"' "

			if (lComp .AND. SuperGetMV("TP_ACTCMP",,.F.)) .OR. (lSaque .AND. SuperGetMV("TP_ACTSQ",,.F.))
				cQry+= " UNION "
			endif
		endif

		//das compensações
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.)
			cCondicao := GetFilUC0("TOP")
			if lFilVend
				cCondicao += " AND UC0_VEND = '"+__CFILVEND+"' "
			endif
			cQry+= "SELECT UF2_VALOR, UF2.R_E_C_N_O_ RECUF2 "
			cQry+= "FROM "+RetSqlName("UF2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UF2 "
			cQry+= " INNER JOIN "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0 ON ("
			cQry+= "  UC0.D_E_L_E_T_= ' ' AND UF2_DOC=UC0_NUM AND UF2_PDV=UC0_PDV AND "+cCondicao+" ) "
			cQry+= "WHERE UF2.D_E_L_E_T_ = ' ' "
			cQry+= "  AND UF2_FILIAL = '"+xFilial("UF2")+"' "
			cQry+= "  AND UF2_SERIE = '"+SubStr(cPrefixComp,1,TamSX3("UF2_SERIE")[1])+"'"

			if lSaque .AND. SuperGetMV("TP_ACTSQ",,.F.)
				cQry+= " UNION "
			endif
		endif

		//das requisiçoes saque pre/pos
		if lSaque .AND. SuperGetMV("TP_ACTSQ",,.F.)
			cCondicao := GetFilU57("TOP")
			cCondicao += "  AND U57_TUSO = 'S' " //Saque
			cCondicao += "  AND U57_FILSAQ = '"+cFilAnt+"' " //Usada
			if lFilVend
				cCondicao += " AND U57_VEND = '"+__CFILVEND+"' "
			endif
			cQry+= "SELECT UF2_VALOR, UF2.R_E_C_N_O_ RECUF2 "
			cQry+= "FROM "+RetSqlName("UF2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UF2 "
			cQry+= " INNER JOIN "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 ON ("
			cQry+= "  U57.D_E_L_E_T_= ' ' AND UF2_CODBAR=(U57_PREFIX||U57_CODIGO||U57_PARCEL) AND "+cCondicao+" ) "
			cQry+= "WHERE UF2.D_E_L_E_T_ = ' ' "
			cQry+= "  AND UF2_FILIAL = '"+xFilial("UF2")+"' "
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->UF2_VALOR

			if !empty(aCampos)
				UF2->(DbGoTo(QRYT1->RECUF2))
				aadd(aDados, MontaDados("UF2", aCampos, .F.))
				if lLegenda
					aDados[len(aDados)][aScan(aCampos,"LEGCHT")] := LegendUF2()
				endif
			endif
			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Vale Haver Emitido  (VLH)
//--------------------------------------------------------------------------------------
User Function T028TVLH(nOpcX, aDados, aCampos, cL1Doc, cL1Serie)

Local nRet := 0
Local cParcVLH := SubStr("VLH",1,TamSX3("E1_PARCELA")[1])
Local cQry := ""
Local lFilVend := type("__CFILVEND")=="C"
Default nOpcX := ParamIxb[1]
Default aDados := {}
Default aCampos := {}
Default cL1Doc := ""
Default cL1Serie := ""

if lSrvPDV

	//buscar das vendas
	if cL1Serie <> "CMP"
		cCondicao := GetFilSL1("PDV")
		if empty(cL1Doc+cL1Serie)
			cCondicao += " .AND. L1_XTROCVL > 0 "
		else
			cCondicao += " .AND. L1_DOC == '"+cL1Doc+"' .AND. L1_SERIE == '"+cL1Serie+"' "
		endif
		if lFilVend
			cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"' "
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"
		SL1->(DbClearFilter())
		SL1->(DbSetFilter(&bCondicao,cCondicao))
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())
		While SL1->(!Eof())
			nRet += SL1->L1_XTROCVL //Comentar essa linha caso queira apurar pela SL1
			
			if !empty(aCampos)
				Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_COD")
				aadd(aDados, MontaDados("SL1", aCampos, .F.))
			endif

			SL1->(DbSkip())
		EndDo
		SL1->(DbClearFilter())
	endif

	//buscar das compensações
	if SuperGetMV("TP_ACTCMP",,.F.) .AND. (empty(cL1Serie) .OR. cL1Serie == "CMP")
		cCondicao := GetFilUC0("PDV")
		if empty(cL1Doc)
			cCondicao += " .AND. UC0_VLVALE > 0 "
		else
			cCondicao += " .AND. UC0_NUM == '"+cL1Doc+"' "
		endif
		if lFilVend
			cCondicao += " .AND. UC0_VEND == '"+__CFILVEND+"' "
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"
		UC0->(DbClearFilter())
		UC0->(DbSetFilter(&bCondicao,cCondicao))
		UC0->(DbSetOrder(1))
		UC0->(DbGoTop())
		While UC0->(!Eof())
			nRet += UC0->UC0_VLVALE

			UC0->(DbSkip())
		EndDo
		UC0->(DbClearFilter())
	endif

else //TOP

	//das vendas
	if cL1Serie <> "CMP"
		cCondicao := GetFilSL1("TOP")
		if !empty(cL1Doc+cL1Serie)
			cCondicao += " AND L1_DOC = '"+cL1Doc+"' AND L1_SERIE = '"+cL1Serie+"' "
		endif
		if lFilVend
			cCondicao += " AND L1_VEND = '"+__CFILVEND+"' "
		endif
		cQry:= "SELECT E1_VALOR, SE1.R_E_C_N_O_ RECSE1 "
		cQry+= "FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
		cQry+= " INNER JOIN "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 ON ("
		cQry+= "  SL1.D_E_L_E_T_= ' ' AND E1_PREFIXO=L1_SERIE AND E1_NUM=L1_DOC AND E1_EMISSAO=L1_EMISNF AND "+cCondicao+" ) "

		cQry+= "WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry+= "  AND E1_PARCELA = '"+cParcVLH+"'"
		cQry+= "  AND E1_TIPO = 'NCC'"
		cQry+= "  AND E1_ORIGEM <> 'FINA630'" //ignoro transferencias de vale haver
	endif
	
	//das compensações
	if SuperGetMV("TP_ACTCMP",,.F.) .AND. (empty(cL1Serie) .OR. cL1Serie == "CMP")
		if !empty(cQry)
			cQry+= " UNION "
		endif
	
		cCondicao := GetFilUC0("TOP")
		if empty(cL1Doc)
			cCondicao += " AND UC0_VLVALE > 0 "
		else
			cCondicao += " AND UC0_NUM = '"+cL1Doc+"' "
		endif
		if lFilVend
			cCondicao += " AND UC0_VEND = '"+__CFILVEND+"' "
		endif
		cQry+= "SELECT E1_VALOR, SE1.R_E_C_N_O_ RECSE1 "
		cQry+= "FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
		cQry+= "INNER JOIN "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0 ON ("
		cQry+= "  UC0.D_E_L_E_T_= ' ' AND E1_PREFIXO=UC0_ESTACA AND E1_NUM=UC0_NUM AND E1_EMISSAO=UC0_DATA AND "+cCondicao+" ) "
		cQry+= "WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry+= "  AND E1_PARCELA = '"+cParcVLH+"'"
		cQry+= "  AND E1_TIPO = 'NCC'"
		cQry+= "  AND E1_ORIGEM <> 'FINA630'" //ignoro transferencias de vale haver

	endif

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	While QRYT1->(!Eof())
		nRet += QRYT1->E1_VALOR

		if !empty(aCampos)
			SE1->(DbGoTo(QRYT1->RECSE1))
			aadd(aDados, MontaDados("SE1", aCampos, .F.))
		endif
		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

endif

if !empty(aCampos) .AND. empty(aDados)
	aadd(aDados, MontaDados("SE1",aCampos, .T.))
endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Cartão Credito (CC)
//--------------------------------------------------------------------------------------
User Function T028TCC(nOpcX, aDados, aCampos, lVenda, lComp)

	Local nRet := 0
	Local nX := 0
	Local aDadosAux
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lVenda := .T.
	Default lComp := .T.

	if lSrvPDV
		if lVenda
			if aScan(aCampos, "L4_VALOR") == 0
				aadd(aCampos, "L4_VALOR")
			endif
			aDadosAux := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == 'CC'")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"L4_VALOR")]
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.) //das compensações
			if aScan(aCampos, "UC1_VALOR") == 0
				aadd(aCampos, "UC1_VALOR")
			endif
			aDadosAux := BuscaUC1("PDV", nOpcX, aCampos,,"Alltrim(UC1->UC1_FORMA) == 'CC'")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"UC1_VALOR")]
				//preencho a serie
				if aScan(aCampos," ") > 0
					aDadosAux[nX][aScan(aCampos," ")] := cPfxCmp
				endif
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'CC'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Cartão Debito (CD)
//--------------------------------------------------------------------------------------
User Function T028TCD(nOpcX, aDados, aCampos, lVenda, lComp)

	Local nRet := 0
	Local nX := 0
	Local aDadosAux
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lVenda := .T.
	Default lComp := .T.

	if lSrvPDV
		if lVenda
			if aScan(aCampos, "L4_VALOR") == 0
				aadd(aCampos, "L4_VALOR")
			endif
			aDadosAux := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == 'CD'")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"L4_VALOR")]
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.)//das compensações
			if aScan(aCampos, "UC1_VALOR") == 0
				aadd(aCampos, "UC1_VALOR")
			endif
			aDadosAux := BuscaUC1("PDV", nOpcX, aCampos,,"Alltrim(UC1->UC1_FORMA) == 'CD'")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"UC1_VALOR")]
				//preencho a serie
				if aScan(aCampos," ") > 0
					aDadosAux[nX][aScan(aCampos," ")] := cPfxCmp
				endif
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'CD'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Cheque a Vista (CH)
//--------------------------------------------------------------------------------------
User Function T028TCH(nOpcX, aDados, aCampos, lVenda, lComp)

	Local nRet := 0
	Local nX := 0
	Local aDadosAux
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lVenda := .T.
	Default lComp := .T.

	if lSrvPDV
		if lVenda
			if aScan(aCampos, "L4_VALOR") == 0
				aadd(aCampos, "L4_VALOR")
			endif
			aDadosAux := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA)=='CH' .AND. DTOS(SL4->L4_DATA) <= '"+DTOS((DataValida(SLW->LW_DTABERT)+1))+"' ")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"L4_VALOR")]
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.)//das compensações
			if aScan(aCampos, "UC1_VALOR") == 0
				aadd(aCampos, "UC1_VALOR")
			endif
			aDadosAux := BuscaUC1("PDV", nOpcX, aCampos,,"Alltrim(UC1->UC1_FORMA)=='CH' .AND. DTOS(UC1->UC1_VENCTO) <= '"+DTOS((DataValida(SLW->LW_DTABERT)+1))+"' ")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"UC1_VALOR")]
				//preencho a serie
				if aScan(aCampos," ") > 0
					aDadosAux[nX][aScan(aCampos," ")] := cPfxCmp
				endif
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
	else
		if aScan(aCampos, "E1_VALOR") == 0
			aadd(aCampos, "E1_VALOR")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'CH' AND E1_VENCREA <= '"+DTOS((DataValida(SLW->LW_DTABERT)+1))+"'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VALOR")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Cheque a Prazo (CHP)
//--------------------------------------------------------------------------------------
User Function T028TCHP(nOpcX, aDados, aCampos, lVenda, lComp)

	Local nRet := 0
	Local nX := 0
	Local aDadosAux
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lVenda := .T.
	Default lComp := .T.

	if lSrvPDV
		if lVenda
			if aScan(aCampos, "L4_VALOR") == 0
				aadd(aCampos, "L4_VALOR")
			endif
			aDadosAux := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA)=='CH' .AND. DTOS(SL4->L4_DATA) > '"+DTOS((DataValida(SLW->LW_DTABERT)+1))+"' ")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"L4_VALOR")]
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.) //das compensações
			if aScan(aCampos, "UC1_VALOR") == 0
				aadd(aCampos, "UC1_VALOR")
			endif
			aDadosAux := BuscaUC1("PDV", nOpcX, aCampos,,"Alltrim(UC1->UC1_FORMA)=='CH' .AND. DTOS(UC1->UC1_VENCTO) > '"+DTOS((DataValida(SLW->LW_DTABERT)+1))+"' ")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"UC1_VALOR")]
				//preencho a serie
				if aScan(aCampos," ") > 0
					aDadosAux[nX][aScan(aCampos," ")] := cPfxCmp
				endif
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
	else
		if aScan(aCampos, "E1_VALOR") == 0
			aadd(aCampos, "E1_VALOR")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'CH' AND E1_VENCREA > '"+DTOS((DataValida(SLW->LW_DTABERT)+1))+"'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VALOR")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Forma Generico
//--------------------------------------------------------------------------------------
User Function T028TDIN(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local nX := 0
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	if lSrvPDV
		if aScan(aCampos, "L4_VALOR") == 0
			aadd(aCampos, "L4_VALOR")
		endif

		aDados := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == '"+SIMBDIN+"'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"L4_VALOR")]
		Next
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = '"+SIMBDIN+"'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Forma Generico
//--------------------------------------------------------------------------------------
User Function T028TGEN(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local nX := 0
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	if lSrvPDV
		if aScan(aCampos, "L4_VALOR") == 0
			aadd(aCampos, "L4_VALOR")
		endif

		aDados := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == '"+__cFORMAATU+"'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"L4_VALOR")]
		Next
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = '"+__cFORMAATU+"'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Nota a Prazo (NP)
//--------------------------------------------------------------------------------------
User Function T028TNP(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local nX := 0
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	if lSrvPDV
		if aScan(aCampos, "L4_VALOR") == 0
			aadd(aCampos, "L4_VALOR")
		endif

		aDados := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == 'NP'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"L4_VALOR")]
		Next
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'NP'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de CTF (CT)
//--------------------------------------------------------------------------------------
User Function T028TCT(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local nX := 0
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	if lSrvPDV
		if aScan(aCampos, "L4_VALOR") == 0
			aadd(aCampos, "L4_VALOR")
		endif

		aDados := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == 'CT'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"L4_VALOR")]
		Next
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'CT'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Carta Frete (CF)
//--------------------------------------------------------------------------------------
User Function T028TCF(nOpcX, aDados, aCampos, lVenda, lComp)

	Local nRet := 0
	Local nX := 0
	Local aDadosAux
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lVenda := .T.
	Default lComp := .T.

	if lSrvPDV
		if lVenda
			if aScan(aCampos, "L4_VALOR") == 0
				aadd(aCampos, "L4_VALOR")
			endif
			aDadosAux := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == 'CF'")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"L4_VALOR")]
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
		if lComp .AND. SuperGetMV("TP_ACTCMP",,.F.)//das compensações
			if aScan(aCampos, "UC1_VALOR") == 0
				aCampos := {"UC1_VALOR"}
			endif
			aDadosAux := BuscaUC1("PDV", nOpcX, aCampos,,"Alltrim(UC1->UC1_FORMA) == 'CF'")
			For nX:=1 To Len(aDadosAux)
				nRet+= aDadosAux[nX][aScan(aCampos,"UC1_VALOR")]
				//preencho a serie
				if aScan(aCampos," ") > 0
					aDadosAux[nX][aScan(aCampos," ")] := cPfxCmp
				endif
				aadd(aDados, aClone(aDadosAux[nX]))
			Next
		endif
	else
		if aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		endif

		aDados := BuscaSE1(aCampos, "E1_TIPO = 'CF'")

		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de REQ. PRE-PAGA SAQUE ( DEPOSITO EM CONTA SAQUE ) (SQ)
//--------------------------------------------------------------------------------------
User Function T028TSQ(nOpcX, aDados, aCampos, lEstorno, aSLW)

	Local nRet := 0
	Local cQry
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lEstorno := .F.

	if lSrvPDV

		cCondicao := GetFilU57("PDV", lEstorno, aSLW)
		cCondicao += "  .AND. U57_TUSO = 'S' " //Saque
		cCondicao += "  .AND. U57_FILSAQ = '"+cFilAnt+"' "
		if lFilVend
			cCondicao += " .AND. U57_VEND == '"+__CFILVEND+"' "
		endif

		bCondicao 	:= "{|| " + cCondicao + " }"

		U57->(DbClearFilter())
		U57->(DbSetFilter(&bCondicao,cCondicao))
		U57->(DbSetOrder(1))
		U57->(DbGoTop())

		While U57->(!Eof())
			if Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_TIPO") == "1" //somente pré paga
				nRet += U57->U57_VALSAQ

				if !empty(aCampos)
					Posicione("SA3",1,xFilial("SA3")+U57->U57_VEND,"A3_COD")
					aadd(aDados, MontaDados("U57", aCampos, .F.))
				endif
			endif
			U57->(DbSkip())
		EndDo
		U57->(DbClearFilter())

	else //TOP

		cCondicao := GetFilU57("TOP", lEstorno, aSLW)
		if lFilVend
			cCondicao += " AND U57_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT U57.U57_VALSAQ, U57.R_E_C_N_O_ RECU57, U56.R_E_C_N_O_ RECU56 "
		cQry+= "FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
		cQry+= "INNER JOIN "+RetSqlName("U56")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U56 ON (U56.D_E_L_E_T_ = ' ' AND U56_FILIAL = U57_FILIAL AND U56_PREFIX = U57_PREFIX AND U56_CODIGO = U57_CODIGO) "
		cQry+= "WHERE  "+cCondicao+" "
		cQry+= "  AND U56_TIPO = '1' " //Pré paga
		cQry+= "  AND U57_TUSO = 'S' " //Saque
		cQry+= "  AND U57_FILSAQ = '"+cFilAnt+"' "
		//cQry+= "  AND U57_MOTIVO <> ' ' "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->U57_VALSAQ

			if !empty(aCampos)
				U56->(DbGoTo(QRYT1->RECU56))
				U57->(DbGoTo(QRYT1->RECU57))
				Posicione("SA3",1,xFilial("SA3")+U57->U57_VEND,"A3_COD")
				aadd(aDados, MontaDados("U57", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("U57",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de REQUISIÇÃO POS-PAGA SAQUE (VALE MOTORISTA) (VLM)
//--------------------------------------------------------------------------------------
User Function T028TVLM(nOpcX, aDados, aCampos, lEstorno, aSLW)

	Local nRet := 0
	Local cQry
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lEstorno := .F.

	if lSrvPDV

		cCondicao := GetFilU57("PDV", lEstorno, aSLW)
		cCondicao += "  .AND. U57_TUSO = 'S' " //Saque
		cCondicao += "  .AND. U57_FILSAQ = '"+cFilAnt+"' "
		if lFilVend
			cCondicao += " .AND. U57_VEND == '"+__CFILVEND+"' "
		endif

		bCondicao 	:= "{|| " + cCondicao + " }"

		U57->(DbClearFilter())
		U57->(DbSetFilter(&bCondicao,cCondicao))
		U57->(DbSetOrder(1))
		U57->(DbGoTop())

		While U57->(!Eof())
			if Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_TIPO") == "2" //somente pós paga
				nRet += U57->U57_VALSAQ

				if !empty(aCampos)
					Posicione("SA3",1,xFilial("SA3")+U57->U57_VEND,"A3_COD")
					aadd(aDados, MontaDados("U57", aCampos, .F.))
				endif
			endif
			U57->(DbSkip())
		EndDo
		U57->(DbClearFilter())

	else //TOP

		cCondicao := GetFilU57("TOP", lEstorno, aSLW)
		if lFilVend
			cCondicao += " AND U57_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT U57.U57_VALSAQ, U57.R_E_C_N_O_ RECU57, U56.R_E_C_N_O_ RECU56 "
		cQry+= "FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
		cQry+= "INNER JOIN "+RetSqlName("U56")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U56 ON (U56.D_E_L_E_T_ = ' ' AND U56_FILIAL = U57_FILIAL AND U56_PREFIX = U57_PREFIX AND U56_CODIGO = U57_CODIGO) "
		cQry+= "WHERE  "+cCondicao+" "
		cQry+= "  AND U56_TIPO = '2' " //Pós paga
		cQry+= "  AND U57_TUSO = 'S' " //Saque
		cQry+= "  AND U57_FILSAQ = '"+cFilAnt+"' "
		//cQry+= "  AND U57_MOTIVO <> ' ' "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->U57_VALSAQ

			if !empty(aCampos)
				U56->(DbGoTo(QRYT1->RECU56))
				U57->(DbGoTo(QRYT1->RECU57))
				Posicione("SA3",1,xFilial("SA3")+U57->U57_VEND,"A3_COD")
				aadd(aDados, MontaDados("U57", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("U57",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Depósito no PDV (DCX)
//--------------------------------------------------------------------------------------
User Function T028TDP(nOpcX, aDados, aCampos, lEstorno, aSLW)

	Local nRet := 0
	Local cQry
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}
	Default lEstorno := .F.

	if lSrvPDV

		cCondicao := GetFilU57("PDV",lEstorno, aSLW,.T.)
		cCondicao += " .AND. U57_PREFIX == 'P"+cFilAnt+"' " //incluida no PDV
		cCondicao += " .AND. U57_FILDEP == '"+cFilAnt+"' "
		if lFilVend
			cCondicao += " .AND. U57_VEND == '"+__CFILVEND+"' "
		endif

		bCondicao 	:= "{|| " + cCondicao + " }"

		U57->(DbClearFilter())
		U57->(DbSetFilter(&bCondicao,cCondicao))
		U57->(DbSetOrder(1))
		U57->(DbGoTop())

		While U57->(!Eof())
			if Posicione("U56",1,xFilial("U56")+U57->U57_PREFIX+U57->U57_CODIGO,"U56_TIPO") == "1" //somente pré paga
				nRet += U57->U57_VALOR

				if !empty(aCampos)
					Posicione("SA3",1,xFilial("SA3")+U57->U57_VEND,"A3_COD")
					aadd(aDados, MontaDados("U57", aCampos, .F.))
				endif
			endif
			U57->(DbSkip())
		EndDo
		U57->(DbClearFilter())

	else //TOP

		cCondicao := GetFilU57("TOP", lEstorno, aSLW,.T.)
		if lFilVend
			cCondicao += " AND U57_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT U57.U57_VALOR, U57.R_E_C_N_O_ RECU57, U56.R_E_C_N_O_ RECU56 "
		cQry+= "FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
		cQry+= "INNER JOIN "+RetSqlName("U56")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U56 ON (U56.D_E_L_E_T_ = ' ' AND U56_FILIAL = U57_FILIAL AND U56_PREFIX = U57_PREFIX AND U56_CODIGO = U57_CODIGO) "
		cQry+= "WHERE  "+cCondicao+" "
		cQry+= "  AND U56_TIPO = '1' " //Pre paga
		cQry+= "  AND U57_FILDEP = '"+cFilAnt+"' "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->U57_VALOR

			if !empty(aCampos)
				U56->(DbGoTo(QRYT1->RECU56))
				U57->(DbGoTo(QRYT1->RECU57))
				Posicione("SA3",1,xFilial("SA3")+U57->U57_VEND,"A3_COD")
				aadd(aDados, MontaDados("U57", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("U57",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de VALE SERVIÇO PÓS-PAGO (FINANCEIRO)
//--------------------------------------------------------------------------------------
User Function T028TVSF(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local cQry, cCondicao
	Local lFilVend := type("__CFILVEND")=="C"
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	if lSrvPDV

		nRet := U_T028TVLS(nOpcX, aDados, aCampos, .T.) //somente pós

	else //TOP

		cCondicao := GetFilUIC("TOP",,.T.)
		cCondicao += "  AND UIC_TIPO = 'O' " //Vale Pós
		if lFilVend
			cCondicao += " AND UIC_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT E1_VALOR, SE1.R_E_C_N_O_ RECSE1 "
		cQry+= "FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
		cQry+= "INNER JOIN "+RetSqlName("UIC")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UIC ON ("
		cQry+= "  UIC.D_E_L_E_T_= ' ' AND E1_PREFIXO=UIC_AMB AND E1_NUM=UIC_CODIGO AND "+cCondicao+" ) "

		cQry+= "WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry+= "  AND E1_TIPO = 'VLS' "
		cQry+= "  AND NOT EXISTS ( SELECT 1 FROM "+RetSqlName("SE6")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE6 WHERE SE6.D_E_L_E_T_= ' ' AND E6_FILIAL = E1_FILIAL AND E6_PREFIXO = E1_PREFIXO AND E6_NUM = E1_NUM AND E6_PARCELA = E1_PARCELA AND E6_TIPO = E1_TIPO)"

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->E1_VALOR

			if !empty(aCampos)
				SE1->(DbGoTo(QRYT1->RECSE1))
				aadd(aDados, MontaDados("SE1", aCampos, .F.))
			endif

			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

	if !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	endif

Return nRet

//--------------------------------------------------------------------------------------
// Totalizador de Credito Usados em Venda (CR)
//--------------------------------------------------------------------------------------
User Function T028TCR(nOpcX, aDados, aCampos)

	Local nX := 0
	Local nRet := 0
	Local aCamposAux
	Local aDadosAux
	Local cInSE1 := "'XXXXXX'"
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"

	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	if lSrvPDV

		cCondicao := GetFilSL1("PDV",, .T.)
		cCondicao += " .AND. L1_CREDITO > 0 "
		if lFilVend
			cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"' "
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"
		SL1->(DbClearFilter())
		SL1->(DbSetFilter(&bCondicao,cCondicao))
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())
		While SL1->(!Eof())
			nRet += SL1->L1_CREDITO

			if !empty(aCampos)
				Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_COD")
				aadd(aDados, MontaDados("SL1", aCampos, .F.))
			endif

			SL1->(DbSkip())
		EndDo
		SL1->(DbClearFilter())
	else

		//busco os titulos do tipo CR para localizar movimentos
		aCamposAux := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_CLIENTE","E1_LOJA"}
		aDadosAux := BuscaSE1(aCamposAux, "E1_TIPO = 'CR'",,,.T.,.F.)
		For nX := 1 to len(aDadosAux)
			if nX==1
				cInSE1 := ""
			else
				cInSE1 += ","
			endif
			cInSE1 += "'"+aDadosAux[nX][1]+aDadosAux[nX][2]+aDadosAux[nX][3]+aDadosAux[nX][4]+aDadosAux[nX][5]+aDadosAux[nX][6]+"'"
		next nX

		//Confirmo se tem movimento na SE5
		cQry:= "SELECT E5_VALOR, SE5.R_E_C_N_O_ RECSE5, SE1.R_E_C_N_O_ RECSE1 "
		cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
		cQry+= "LEFT JOIN "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 ON (SE1.D_E_L_E_T_ = ' ' AND E1_FILIAL = E5_FILIAL AND E5_DOCUMEN LIKE E1_PREFIXO||E1_NUM||E1_PARCELA||E1_TIPO+'%' ) "
		cQry+= "WHERE SE5.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
		cQry+= "  AND (E5_PREFIXO||E5_NUMERO||E5_PARCELA||E5_TIPO||E5_CLIFOR+E5_LOJA) IN ("+cInSE1+")"

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			nRet += QRYT1->E5_VALOR

			if !empty(aCampos)
				SE5->(DbGoTo(QRYT1->RECSE5))
				SE1->(DbGoTo(QRYT1->RECSE1))

				aadd(aDados, MontaDados("SE1", aCampos, .F.))
			endif
			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

		if !empty(aCampos) .AND. empty(aDados)
			aadd(aDados, MontaDados("SE1",aCampos, .T.))
		endif

	endif

Return nRet

//--------------------------------------------------------------------------------------
// Detalhamento de Suprimento (SU)
//--------------------------------------------------------------------------------------
User Function T028DSU

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos := {"E5_DATA","E5_VALOR","A6_COD","A6_NOME","E5_NATUREZ","E5_OPERAD","A3_NOME","E5_HISTOR","E5_PREFIXO","E5_NUMERO"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local bAtuGrid := {|| oGridDet:aCols := {}, nTotSup := U_T028TSU(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotSup:Refresh() }

	Private oTotSup := 0
	Private nTotSup := 0
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Suprimentos" STYLE DS_MODALFRAME FROM 000, 000  TO 300, 600 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,122,290,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",284) SIZE 284, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	aHeaderEx[aScan(aCampos,"A3_NOME")][1] := "Vendedor"
	nTotSup := U_T028TSU(nOpcX, @aColsEx, aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 100, 286,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	if nOpcX == 4
		@ 110, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action MntSupSang(3, 1, , bAtuGrid)
		@ 110, 060 BUTTON oButton1 PROMPT "Excluir" SIZE 045, 012 OF oDlgDet PIXEL Action MntSupSang(5, 1, oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuGrid)
		@ 110, 110 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action MntSupSang(4, 1, oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuGrid)
	endif

	@ 108, 170 SAY "Total Suprimentos:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 105, 225 MSGET oTotSup VAR nTotSup When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 132, 255 BUTTON oButton1 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("SU", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Sangria (SG)
//--------------------------------------------------------------------------------------
User Function T028DSG

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos := {"E5_DATA","E5_VALOR","A6_COD","A6_NOME","E5_NATUREZ","E5_OPERAD","A3_NOME","E5_HISTOR","E5_PREFIXO","E5_NUMERO"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local bAtuGrid := {|| oGridDet:aCols := {}, nTotSang := U_T028TSG(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotSang:Refresh() }

	Private oTotSang := 0
	Private nTotSang := 0
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Sangrias" STYLE DS_MODALFRAME FROM 000, 000  TO 300, 600 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,122,290,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",284) SIZE 284, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	aHeaderEx[aScan(aCampos,"A3_NOME")][1] := "Vendedor"
	nTotSang := U_T028TSG(nOpcX, @aColsEx, aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 100, 286,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	if nOpcX == 4
		@ 110, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action MntSupSang(3, 2, , bAtuGrid)
		@ 110, 060 BUTTON oButton1 PROMPT "Excluir" SIZE 045, 012 OF oDlgDet PIXEL Action MntSupSang(5, 2, oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuGrid)
		@ 110, 110 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action MntSupSang(4, 2, oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuGrid)
	endif

	@ 108, 170 SAY "Total Sangrias:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 105, 225 MSGET oTotSang VAR nTotSang When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 132, 255 BUTTON oButton1 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("SG", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Troco em Dinheiro (Vendas)
//--------------------------------------------------------------------------------------
User Function T028DTV

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos := {"E5_DATA","E5_VALOR","E5_NATUREZ","E5_OPERAD","E5_HISTOR","E5_PREFIXO","E5_NUMERO"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	//Local bAtuGrid := {|| oGridDet:aCols := {}, nTotTroc := U_T028TTV(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotTroc:Refresh() }

	Private oTotTroc := 0
	Private nTotTroc := 0
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Troco em Dinheiro (Vendas)" STYLE DS_MODALFRAME FROM 000, 000  TO 300, 600 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,122,290,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",284) SIZE 284, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotTroc := U_T028TTV(nOpcX, @aColsEx, aCampos)
	oGridDet := MsNewGetDados():New( 015, 002, 100, 286,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 108, 170 SAY "Total Trocos:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 105, 225 MSGET oTotTroc VAR nTotTroc When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 132, 255 BUTTON oButton1 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton1:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("SG", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Venda Combustivel (VC)
//--------------------------------------------------------------------------------------
User Function T028DVC

	Local nX, nPosAux
	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local aCampos := {"MID_CODBIC","L2_PRODUTO","B1_DESC","MID_ENCFIN","L2_QUANT","L2_VALDESC","L2_VLRITEM","L2_SERIE","L2_DOC"}
	Local aHeaderEx := {}
	Local lAbastOk := .T.
	Private aColsDet := {}
	Private aColsAglut := {}
	Private lViewDet := .T.
	Private oTotalPro := 0
	Private nTotalPro := 0
	Private oButAglu
	Private oButDeta
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Venda Combustível" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalPro := U_T028TVC(nOpcX, @aColsDet, aCampos, @lAbastOk)

	//montando aglutinado
	For nX := 1 to len(aColsDet)
		if (nPosAux := aScan(aColsAglut, {|x| x[1] == aColsDet[nX][1] })) > 0
			aColsAglut[nPosAux][aScan(aCampos,"L2_QUANT")] += aColsDet[nX][aScan(aCampos,"L2_QUANT")]
			aColsAglut[nPosAux][aScan(aCampos,"L2_VALDESC")] += aColsDet[nX][aScan(aCampos,"L2_VALDESC")]
			aColsAglut[nPosAux][aScan(aCampos,"L2_VLRITEM")] += aColsDet[nX][aScan(aCampos,"L2_VLRITEM")]
			//deixar com o maior encerrante
			If aColsAglut[nPosAux][aScan(aCampos,"MID_ENCFIN")] < aColsDet[nX][aScan(aCampos,"MID_ENCFIN")]
				aColsAglut[nPosAux][aScan(aCampos,"MID_ENCFIN")] := aColsDet[nX][aScan(aCampos,"MID_ENCFIN")]
			EndIf
		else
			aadd(aColsAglut, aClone(aColsDet[nX]) )
			aColsAglut[len(aColsAglut)][aScan(aCampos,"L2_SERIE")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"L2_DOC")] := ""
			aColsAglut[len(aColsAglut)][len(aCampos)+1] := 0
		endif
	next nX

	aSort(aColsDet,,,{|x,y| x[2] < y[2] }) //ordena detalhado por produto
	aSort(aColsAglut,,,{|x,y| x[1] < y[1] }) //ordena aglutinado por BICO

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Produtos:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalPro VAR nTotalPro When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL
	@ 160, 010 BUTTON oButAglu PROMPT "Ver Aglutinado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
	@ 160, 010 BUTTON oButDeta PROMPT "Ver Detalhado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
	oButDeta:Hide()

	if !lAbastOk
		@ 158, 060 SAY "* Há abastecimentos não localizados nessa base." SIZE 150, 007 OF oPnlDet COLORS CLR_RED, 16777215 PIXEL
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Venda Produtos (VP)
//--------------------------------------------------------------------------------------
User Function T028DVP

	Local nX, nPosAux
	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local aCampos := {"L2_PRODUTO","B1_DESC","L2_LOCAL","L2_QUANT","L2_UM","L2_VALDESC","L2_VLRITEM","L2_SERIE","L2_DOC"}
	Local aHeaderEx := {}
	Private aColsDet := {}
	Private aColsAglut := {}
	Private lViewDet := .T.
	Private oTotalPro := 0
	Private nTotalPro := 0
	Private oButAglu
	Private oButDeta
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Venda Produtos" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalPro := U_T028TVP(nOpcX, @aColsDet, aCampos)

	//montando aglutinado
	For nX := 1 to len(aColsDet)
		if (nPosAux := aScan(aColsAglut, {|x| x[1] == aColsDet[nX][1] })) > 0
			aColsAglut[nPosAux][aScan(aCampos,"L2_QUANT")] += aColsDet[nX][aScan(aCampos,"L2_QUANT")]
			aColsAglut[nPosAux][aScan(aCampos,"L2_VALDESC")] += aColsDet[nX][aScan(aCampos,"L2_VALDESC")]
			aColsAglut[nPosAux][aScan(aCampos,"L2_VLRITEM")] += aColsDet[nX][aScan(aCampos,"L2_VLRITEM")]
		else
			aadd(aColsAglut, aClone(aColsDet[nX]) )
			aColsAglut[len(aColsAglut)][aScan(aCampos,"L2_SERIE")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"L2_DOC")] := ""
			aColsAglut[len(aColsAglut)][len(aCampos)+1] := 0
		endif
	next nX

	aSort(aColsDet,,,{|x,y| x[1] < y[1] }) //ordena detalhado por produto
	aSort(aColsAglut,,,{|x,y| x[1] < y[1] }) //ordena aglutinado por produto

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Produtos:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalPro VAR nTotalPro When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL
	@ 160, 010 BUTTON oButAglu PROMPT "Ver Aglutinado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
	@ 160, 010 BUTTON oButDeta PROMPT "Ver Detalhado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()

	oButDeta:Hide()

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

Return

//--------------------------------------------------------------------------------------
// Detalhamento de VALE SERVIÇO (EMITIDO) (VLS)
//--------------------------------------------------------------------------------------
User Function T028DVLS

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuVSR := {|| oGridDet:aCols := {}, nTotalVSR := U_T028TVLS(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalVSR:Refresh() }
	Private aColsDet := {}
	Private oTotalVSR := 0
	Private nTotalVSR := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	aCampos := {"UIC_TIPO","UIC_AMB","UIC_CODIGO","UIC_PRODUT","UIC_DESCRI","UIC_PRCPRO","A1_CGC","UIC_CLIENT","UIC_LOJAC","UIC_NOMEC","UIC_FORNEC","UIC_LOJAF","UIC_NOMEF","UIC_VEND","A3_NOME"}

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Vale Serviço Pré/Pós Emitido" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalVSR := U_T028TVLS(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Vales Serviço:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalVSR VAR nTotalVSR When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV .AND. nOpcX == 4
		@ 160, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action TelaVls(3, bAtuVSR)
		@ 160, 060 BUTTON oButton1 PROMPT "Visualizar" SIZE 045, 012 OF oDlgDet PIXEL Action TelaVls(2, bAtuVSR)
		@ 160, 110 BUTTON oButton1 PROMPT "Estornar" SIZE 045, 012 OF oDlgDet PIXEL Action EstornaVLS(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuVSR)
		@ 160, 160 BUTTON oButton1 PROMPT "Reprocessar" SIZE 045, 012 OF oDlgDet PIXEL Action ReprocVLS(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuVSR)
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("VLS", nOpcX, .T.)
	AtuVlrGrid("VSF", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Cheque Troco (CHT)
//--------------------------------------------------------------------------------------
User Function T028DCHT

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos := {"LEGCHT","UF2_BANCO","UF2_AGENCI","UF2_CONTA","UF2_NUM","UF2_VALOR","UF2_DOC","UF2_SERIE","UF2_PDV","UF2_CODBAR"}
	Local aHeaderEx := {}
	Local bAtuCHT := {|| oGridDet:aCols := {}, nTotalCHT := U_T028TCHT(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalCHT:Refresh() }
	Private aColsDet := {}
	Private oTotalCHT := 0
	Private nTotalCHT := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		//removo legenda
		aDel(aCampos, 1)
		aSize(aCampos, len(aCampos)-1)
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Cheques Troco" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalCHT := U_T028TCHT(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Cheques Troco:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCHT VAR nTotalCHT When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV .AND. nOpcX == 4
		@ 160, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action IncChqTroco(,,bAtuCHT)
		@ 160, 060 BUTTON oButton1 PROMPT "Excluir" SIZE 045, 012 OF oDlgDet PIXEL Action DelChqTroco(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1],,,,bAtuCHT)
		@ 160, 110 BUTTON oButton1 PROMPT "Substituir" SIZE 045, 012 OF oDlgDet PIXEL Action SubChqTroco(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1],.F.,bAtuCHT)
		@ 160, 160 BUTTON oButton1 PROMPT "Corrigir Fin." SIZE 050, 012 OF oDlgDet PIXEL Action CorrigeCHT(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1],bAtuCHT)
	endif

	if !lSrvPDV
		@ 182, 010 BITMAP oLeg ResName "BR_VERDE" OF oDlgDet Size 10, 10 NoBorder When .F. PIXEL
		@ 183, 020 SAY "Financeiro OK" SIZE 100, 007 OF oDlgDet COLORS 0, 16777215 PIXEL

		@ 182, 060 BITMAP oLeg ResName "BR_VERMELHO" OF oDlgDet Size 10, 10 NoBorder When .F. PIXEL
		@ 183, 070 SAY "Pend. Financeira" SIZE 100, 007 OF oDlgDet COLORS 0, 16777215 PIXEL
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CHT", nOpcX, .T.)
Return

//--------------------------------------------------------------------------------------
// Detalhamento de Vale Haver Emitido (VLH)
//--------------------------------------------------------------------------------------
User Function T028DVLH

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuVLH := {|| oGridDet:aCols := {}, nTotalVLH := U_T028TVLH(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalVLH:Refresh() }
	Private aColsDet := {}
	Private oTotalVLH := 0
	Private nTotalVLH := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L1_DOC","L1_SERIE","L1_EMISNF","L1_XTROCVL","L1_CLIENTE","L1_LOJA","A1_NOME"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_NATUREZ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Vales Haver Emitidos" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalVLH := U_T028TVLH(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 275 SAY "Total Vales Haver:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalVLH VAR nTotalVLH When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action IncValeHav(,bAtuVLH)
			@ 160, 110 BUTTON oButton1 PROMPT "Excluir" SIZE 045, 012 OF oDlgDet PIXEL Action DelValeHav(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1],,bAtuVLH)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("VLH", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Cartão de Credito (CC)
//--------------------------------------------------------------------------------------
User Function T028DCC

	Local nX
	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aCamposCmp
	Local aHeaderEx := {}
	Local bAtuCC := {|| oGridDet:aCols := {}, nTotalCC := U_T028TCC(nOpcX, @oGridDet:aCols, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCC(nOpcX, @oGridDet:aCols, aCamposCmp,.F.,.T.),0), oGridDet:oBrowse:Refresh(), oTotalCC:Refresh() }
	Private aColsDet := {}
	Private aColsAglut := {}
	Private oTotalCC := 0
	Private nTotalCC := 0
	Private lViewDet := .T.
	Private oButView
	Private oButAglu
	Private oButDeta
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","A1_COD","A1_LOJA","A1_NOME","L4_NSUTEF","L4_AUTORIZ","L1_DOC","L1_SERIE"}
		aCamposCmp := {"UC1_VENCTO","UC1_VALOR","A1_COD","A1_LOJA","A1_NOME","UC1_NSUDOC","UC1_CODAUT","UC1_NUM"," "}
	else
		aCampos := {"E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VLRREAL","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_NSUTEF","E1_CARTAUT"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Cartão Credito" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalCC := U_T028TCC(nOpcX, @aColsDet, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCC(nOpcX, @aColsDet, aCamposCmp,.F.,.T.),0)

	//montando aglutinado
	For nX := 1 to len(aColsDet)
		if (nPosAux := aScan(aColsAglut, {|x| x[1] == aColsDet[nX][1] .AND. x[2] == aColsDet[nX][2] })) > 0
			aColsAglut[nPosAux][aScan(aCampos,"E1_VLRREAL")] += aColsDet[nX][aScan(aCampos,"E1_VLRREAL")]
		else
			aadd(aColsAglut, aClone(aColsDet[nX]) )
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_PREFIXO")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_NUM")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_PARCELA")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_NSUTEF")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_CARTAUT")] := ""
			aColsAglut[len(aColsAglut)][len(aCampos)+1] := 0
		endif
	next nX

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 260 SAY "Total Cartão Crédito:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCC VAR nTotalCC When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManCartao("CC", oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuCC)
		endif
		@ 160, 110 BUTTON oButAglu PROMPT "Ver Aglutinado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
		@ 160, 110 BUTTON oButDeta PROMPT "Ver Detalhado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
		oButDeta:Hide()
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CC", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Cartão de Debito (CD)
//--------------------------------------------------------------------------------------
User Function T028DCD

	Local nX
	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aCamposCmp
	Local aHeaderEx := {}
	Local bAtuCD := {|| oGridDet:aCols := {}, nTotalCD := U_T028TCD(nOpcX, @oGridDet:aCols, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCD(nOpcX, @oGridDet:aCols, aCamposCmp,.F.,.T.),0), oGridDet:oBrowse:Refresh(), oTotalCD:Refresh() }
	Private aColsDet := {}
	Private aColsAglut := {}
	Private oTotalCD := 0
	Private nTotalCD := 0
	Private lViewDet := .T.
	Private oButView
	Private oButAglu
	Private oButDeta
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","A1_COD","A1_LOJA","A1_NOME","L4_NSUTEF","L4_AUTORIZ","L1_DOC","L1_SERIE"}
		aCamposCmp := {"UC1_VENCTO","UC1_VALOR","A1_COD","A1_LOJA","A1_NOME","UC1_NSUDOC","UC1_CODAUT","UC1_NUM"," "}
	else
		aCampos := {"E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VLRREAL","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_NSUTEF","E1_CARTAUT"}
	Endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Cartão Débito" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalCD := U_T028TCD(nOpcX, @aColsDet, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCD(nOpcX, @aColsDet, aCamposCmp,.F.,.T.),0)

	//montando aglutinado
	For nX := 1 to len(aColsDet)
		if (nPosAux := aScan(aColsAglut, {|x| x[1] == aColsDet[nX][1] .AND. x[2] == aColsDet[nX][2] })) > 0
			aColsAglut[nPosAux][aScan(aCampos,"E1_VLRREAL")] += aColsDet[nX][aScan(aCampos,"E1_VLRREAL")]
		else
			aadd(aColsAglut, aClone(aColsDet[nX]) )
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_PREFIXO")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_NUM")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_PARCELA")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_NSUTEF")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_CARTAUT")] := ""
			aColsAglut[len(aColsAglut)][len(aCampos)+1] := 0
		endif
	next nX

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 260 SAY "Total Cartão Débito:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCD VAR nTotalCD When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManCartao("CD", oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuCD)
		endif
		@ 160, 110 BUTTON oButAglu PROMPT "Ver Aglutinado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
		@ 160, 110 BUTTON oButDeta PROMPT "Ver Detalhado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
		oButDeta:Hide()
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CD", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Cheque a Vista (CH)
//--------------------------------------------------------------------------------------
User Function T028DCH

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aCamposCmp
	Local aHeaderEx := {}
	Local bAtuCHP := {|| oGridDet:aCols := {}, nTotalCH := U_T028TCH(nOpcX, @oGridDet:aCols, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCH(nOpcX, @oGridDet:aCols, aCamposCmp,.F.,.T.),0), oGridDet:oBrowse:Refresh(), oTotalCH:Refresh() }
	Private aColsDet := {}
	Private oTotalCH := 0
	Private nTotalCH := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","L4_NUMCART","L4_ADMINIS","L4_AGENCIA","L4_CONTA","L4_CGC","L4_NOMECLI","L1_DOC","L1_SERIE"}
		aCamposCmp := {"UC1_VENCTO","UC1_VALOR","UC1_NUMCH","UC1_BANCO","UC1_AGENCI","UC1_CONTA","UC1_CGC","A1_NOME","UC1_NUM"," "}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","E1_VENCREA","E1_XCGCEMI","E1_EMITCHQ","E1_NUMCART","E1_BCOCHQ","E1_AGECHQ","E1_CTACHQ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Cheques à Vista" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	if lSrvPDV
		aHeaderEx[aScan(aCampos,"L4_NUMCART")][1] := "Num. Cheque"
		aHeaderEx[aScan(aCampos,"L4_ADMINIS")][1] := "Banco"
	else
		aHeaderEx[aScan(aCampos,"E1_NUMCART")][1] := "Num. Cheque"
	endif
	nTotalCH := U_T028TCH(nOpcX, @aColsDet, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCH(nOpcX, @aColsDet, aCamposCmp,.F.,.T.),0)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 280 SAY "Total Cheques:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCh VAR nTotalCh When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManCheque(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuCHP)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCss(CSS_BTNAZUL)

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CH", nOpcX, .T.)
	AtuVlrGrid("CHP", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Cheque a Prazo (CHP)
//--------------------------------------------------------------------------------------
User Function T028DCHP

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos := {}
	Local aCamposCmp := {}
	Local aHeaderEx := {}
	Local bAtuCHP := {|| oGridDet:aCols := {}, nTotalCH := U_T028TCHP(nOpcX, @oGridDet:aCols, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCHP(nOpcX, @oGridDet:aCols, aCamposCmp,.F.,.T.),0), oGridDet:oBrowse:Refresh(), oTotalCH:Refresh() }
	Private aColsDet := {}
	Private oTotalCH := 0
	Private nTotalCH := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","L4_NUMCART","L4_ADMINIS","L4_AGENCIA","L4_CONTA","L4_CGC","L4_NOMECLI","L1_DOC","L1_SERIE"}
		aCamposCmp := {"UC1_VENCTO","UC1_VALOR","UC1_NUMCH","UC1_BANCO","UC1_AGENCI","UC1_CONTA","UC1_CGC","A1_NOME","UC1_NUM"," "}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","E1_VENCREA","E1_XCGCEMI","E1_EMITCHQ","E1_NUMCART","E1_BCOCHQ","E1_AGECHQ","E1_CTACHQ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Cheques à Prazo" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	if lSrvPDV
		aHeaderEx[aScan(aCampos,"L4_NUMCART")][1] := "Num. Cheque"
		aHeaderEx[aScan(aCampos,"L4_ADMINIS")][1] := "Banco"
	else
		aHeaderEx[aScan(aCampos,"E1_NUMCART")][1] := "Num. Cheque"
	endif
	nTotalCH := U_T028TCHP(nOpcX, @aColsDet, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCHP(nOpcX, @aColsDet, aCamposCmp,.F.,.T.),0)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 280 SAY "Total Cheques:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCh VAR nTotalCh When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManCheque(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuCHP)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCss(CSS_BTNAZUL)

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CH", nOpcX, .T.)
	AtuVlrGrid("CHP", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de formas Generico
//--------------------------------------------------------------------------------------
User Function T028DGEN

	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local nPosFunc := aScan(aFormasHab, {|x| x[1] == __CFORMAATU })
	Local cDsForma := Capital(aFormasHab[nPosFunc][2])
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuNP := {|| oGridDet:aCols := {}, nTotalNP := U_T028TGEN(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalNP:Refresh() }
	Private aColsDet := {}
	Private oTotalNP := 0
	Private nTotalNP := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","A1_COD","A1_LOJA","A1_NOME","L1_DOC","L1_SERIE"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VENCREA","E1_NATUREZ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE ("Detalhamento "+cDsForma) STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalNP := U_T028TGEN(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total "+cDsForma+":" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalNP VAR nTotalNP When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManutForma(__CFORMAATU, oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], .T., .F., .F.,bAtuNP)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid(__CFORMAATU, nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de formas Generico
//--------------------------------------------------------------------------------------
User Function T028DDIN

	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local nPosFunc := aScan(aFormasHab, {|x| x[1] == "DIN" })
	Local cDsForma := Capital(aFormasHab[nPosFunc][2])
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuDin := {|| oGridDet:aCols := {}, nTotalDIN := U_T028TDIN(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalDIN:Refresh() }
	Private aColsDet := {}
	Private oTotalDIN
	Private nTotalDIN := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","A1_COD","A1_LOJA","A1_NOME","L1_DOC","L1_SERIE"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VENCREA","E1_NATUREZ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE ("Detalhamento "+cDsForma) STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalDIN := U_T028TDIN(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Dinheiro:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalDIN VAR nTotalDIN When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Trocar Forma" SIZE 045, 012 OF oDlgDet PIXEL Action {|| TrcDinForm(oGridDet,bAtuDin) }
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("", nOpcX, .T.)

Return

Static Function TrcDinForm(oGridDet,bAtuDin)

	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea())

	Local nPosDoc := aScan(oGridDet:aHeader,{|x| AllTrim(x[2])=="E1_NUM"})
	Local nPosSer := aScan(oGridDet:aHeader,{|x| AllTrim(x[2])=="E1_PREFIXO"})
	Local cChavL1 := oGridDet:aCols[oGridDet:nAt][nPosSer]+oGridDet:aCols[oGridDet:nAt][nPosDoc]

	SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC
	if !SL1->(DbSeek(xFilial("SL1")+cChavL1 ))
		MsgInfo("Venda não encontrada na base retaguarda!","Atenção")
		Return
	else
		TrocaForm(1,bAtuDin)
	endif

	RestArea(aAreaSL1)
	RestArea(aArea)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Nota a Prazo (NP)
//--------------------------------------------------------------------------------------
User Function T028DNP

	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuNP := {|| oGridDet:aCols := {}, nTotalNP := U_T028TNP(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalNP:Refresh() }
	Private aColsDet := {}
	Private oTotalNP := 0
	Private nTotalNP := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","A1_COD","A1_LOJA","A1_NOME","L1_DOC","L1_SERIE"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VENCREA","E1_NATUREZ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Notas à Prazo" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalNP := U_T028TNP(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Notas a Prazo:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalNP VAR nTotalNP When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManutForma("NP", oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], .T., .F., .F.,bAtuNP)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("NP", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de CTF (CT)
//--------------------------------------------------------------------------------------
User Function T028DCT

	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuCT := {|| oGridDet:aCols := {}, nTotalCT := U_T028TCT(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalCT:Refresh() }
	Private aColsDet := {}
	Private oTotalCT := 0
	Private nTotalCT := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","A1_COD","A1_LOJA","A1_NOME","L1_DOC","L1_SERIE"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VENCREA","E1_NATUREZ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Notas à Prazo" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalCT := U_T028TCT(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Notas a Prazo:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCT VAR nTotalCT When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManutForma("CT", oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], .T., .F., .F.,bAtuCT)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CT", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Carta Frete (CF)
//--------------------------------------------------------------------------------------
User Function T028DCF

	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local aCampos
	Local aCamposCmp
	Local aHeaderEx := {}
	Local bAtuCF := {|| oGridDet:aCols := {}, nTotalCF := U_T028TCF(nOpcX, @oGridDet:aCols, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCF(nOpcX, @oGridDet:aCols, aCamposCmp,.F.,.T.),0), oGridDet:oBrowse:Refresh(), oTotalCF:Refresh() }
	Private aColsDet := {}
	Private oTotalCF := 0
	Private nTotalCF := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","L4_NUMCART","L4_CGC","A1_NOME","L1_DOC","L1_SERIE","L4_OBS"}
		aCamposCmp := {"UC1_VENCTO","UC1_VALOR","UC1_CFRETE","UC1_CGC","A1_NOME","UC1_NUM"," ","UC1_OBS"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","E1_NUMCART","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VENCREA","E1_NATUREZ","E1_HIST"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Cartas Frete" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	if lSrvPDV
		aHeaderEx[aScan(aCampos,"L4_NUMCART")][1] := "Numero Carta Frete"
		aHeaderEx[aScan(aCampos,"L4_CGC")][1] := "CNPJ Emitente"
	else
		aHeaderEx[aScan(aCampos,"E1_NUMCART")][1] := "Numero Carta Frete"
		aHeaderEx[aScan(aCampos,"E1_CLIENTE")][1] := "Emitente"
	endif
	nTotalCF := U_T028TCF(nOpcX, @aColsDet, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCF(nOpcX, @aColsDet, aCamposCmp,.F.,.T.),0)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Cartas Frete:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCF VAR nTotalCF When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		if nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManCartaFrete(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuCF)
		endif
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("CF", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de REQ. PRE-PAGA SAQUE ( DEPOSITO EM CONTA SAQUE )
//--------------------------------------------------------------------------------------
User Function T028DSQ

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuSQ := {|| oGridDet:aCols := {}, nTotalSQ := U_T028TSQ(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalSQ:Refresh() }
	Private aColsDet := {}
	Private oTotalSQ := 0
	Private nTotalSQ := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	aCampos := {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALSAQ","U57_CHTROC","A1_CGC","U56_CODCLI","U56_LOJA","U56_NOME","U57_MOTORI","U57_PLACA","U56_REQUIS","U57_VEND","A3_NOME"}

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Requisiçao Pré-Paga Saque" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalSQ := U_T028TSQ(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 280 SAY "Total Saque:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalSQ VAR nTotalSQ When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV .AND. nOpcX == 4
		@ 160, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action TelaSaque(3, bAtuSQ)
		@ 160, 060 BUTTON oButton1 PROMPT "Excluir" SIZE 045, 012 OF oDlgDet PIXEL Action DelVLMSQ(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuSQ)
		@ 160, 110 BUTTON oButton1 PROMPT "Altera Saida" SIZE 045, 012 OF oDlgDet PIXEL Action AltTrocSQ(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuSQ)
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("SQ", nOpcX, .T.)
	AtuVlrGrid("VLM", nOpcX, .T.)
	AtuVlrGrid("CHT", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de REQUISIÇÃO POS-PAGA SAQUE (VALE MOTORISTA) (VLM)
//--------------------------------------------------------------------------------------
User Function T028DVLM

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuVLM := {|| oGridDet:aCols := {}, nTotalVLM := U_T028TVLM(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalVLM:Refresh() }
	Private aColsDet := {}
	Private oTotalVLM := 0
	Private nTotalVLM := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	aCampos := {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALSAQ","U57_CHTROC","A1_CGC","U56_CODCLI","U56_LOJA","U56_NOME","U57_MOTORI","U57_PLACA","U56_REQUIS","U57_VEND","A3_NOME"}

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Requisiçao Pós-Paga Saque (Vale Motorista)" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalVLM := U_T028TVLM(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 280 SAY "Total Vales:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalVLM VAR nTotalVLM When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV .AND. nOpcX == 4
		@ 160, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action TelaSaque(3, bAtuVLM)
		@ 160, 060 BUTTON oButton1 PROMPT "Excluir" SIZE 045, 012 OF oDlgDet PIXEL Action DelVLMSQ(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuVLM)
		@ 160, 110 BUTTON oButton1 PROMPT "Altera Saida" SIZE 045, 012 OF oDlgDet PIXEL Action AltTrocSQ(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuVLM)
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("SQ", nOpcX, .T.)
	AtuVlrGrid("VLM", nOpcX, .T.)
	AtuVlrGrid("CHT", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Deposito no PDV (DP)
//--------------------------------------------------------------------------------------
User Function T028DDP

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos := {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U57_VALOR","A1_CGC","U56_CODCLI","U56_LOJA","U56_NOME","U57_PLACA","U56_REQUIS","U57_VEND","A3_NOME"}
	Local aHeaderEx := {}
	Local bAtuDCX := {|| oGridDet:aCols := {}, nTotalDCX := U_T028TDP(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalDCX:Refresh() }
	Private aColsDet := {}
	Private oTotalDCX := 0
	Private nTotalDCX := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Depósitos no PDV" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalDCX := U_T028TDP(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 280 SAY "Total Depósitos:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalDCX VAR nTotalDCX When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV .AND. nOpcX == 4
		@ 160, 010 BUTTON oButton1 PROMPT "Incluir" SIZE 045, 012 OF oDlgDet PIXEL Action TelaDeposito(3, bAtuDCX) 
		@ 160, 060 BUTTON oButton1 PROMPT "Estornar" SIZE 045, 012 OF oDlgDet PIXEL Action DelDeposito(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuDCX)
	endif

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("DP", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Vale Serviço Financeiro
//--------------------------------------------------------------------------------------
User Function T028DVSF

	Local nOpcX := ParamIxb[1]
	Local oPnlDet, oButton2
	Local aCampos
	Local aHeaderEx := {}
	Private aColsDet := {}
	Private oTotalVSF := 0
	Private nTotalVSF := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		MsgInfo("Não habilitado detalhamento dessa forma", "Atenção")
		Return
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_VENCREA","E1_NATUREZ"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Financeiro Vale Serviço Pós-Pago" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalVSF := U_T028TVSF(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Vales Serviço:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalVSF VAR nTotalVSF When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

Return

//--------------------------------------------------------------------------------------
// Detalhamento de Credito Usados na Venda (CR)
//--------------------------------------------------------------------------------------
User Function T028DCR

	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aHeaderEx := {}
	Private aColsDet := {}
	Private oTotalCR := 0
	Private nTotalCR := 0
	Private oButView
	Private oGridDet
	Private oDlgDet

	if lSrvPDV
		aCampos := {"L1_DOC","L1_SERIE","L1_EMISNF","L1_CREDITO","L1_CLIENTE","L1_LOJA","A1_NOME"}
	else
		aCampos := {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VALOR","A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E5_PREFIXO","E5_NUMERO"}
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento Creditos Usados na Venda" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	if !lSrvPDV
		aHeaderEx[aScan(aCampos,"E5_PREFIXO")][1] := "Serie NF"
		aHeaderEx[aScan(aCampos,"E5_NUMERO")][1] := "Numero NF"
	endif
	nTotalCR := U_T028TCR(nOpcX, @aColsDet, aCampos)

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 270 SAY "Total Creditos Usados:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalCR VAR nTotalCR When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	if !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
	endif
	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

Return

//--------------------------------------------------------------------------------------
// Busca registros para detalhar documento
//--------------------------------------------------------------------------------------
User Function T028DOCS(aSLW, lPDV, aCpoSL1, aCpoSL2, aCpoSL4, aCpoSE5, cDocSL1, cSerie, aCpoUC0, aCpoUC1, aCpoUIC, aCpoU57)

	Local nX, nY
	Local aAux1 := {}
	Local aAux2 := {}
	Local aRet := {}
	Local aSL1 := {}
	Local aSL2 := {}
	Local aSL4 := {}
	Local aSE5 := {}
	Local aUC0 := {}
	Local aUC1 := {}
	Local aUIC := {}
	Local aU57 := {}
	Local cCondicao, bCondicao, cQry
	//Local nPosDoc := aScan(aCpoSL1, "L1_DOC")
	//Local nPosSer := aScan(aCpoSL1, "L1_SERIE")
	Local cAliSL1 := "SL1"
	Local cAliSE5 := "SE5"
	Local cAliUC0 := "UC0"
	Local cAliUIC := "UIC"
	Local lFilVend := type("__CFILVEND")=="C"
	Default cDocSL1 := ""
	Default cSerie := ""
	
	ChkFile("SLW")

	if type("SIMBDIN") == "U"
		SIMBDIN := Alltrim(SuperGetMV("MV_SIMB1",,"R$"))
	endif

	//BUSCANDO VENDAS
	if aCpoSL1 <> Nil .AND. aCpoSL2 <> Nil .AND. aCpoSL4 <> NIl
		ChkFile("SL1")
		ChkFile("SL2")
		ChkFile("SL4")
		
		DbSelectArea("SL1")
		DbSelectArea("SL2")
		DbSelectArea("SL4")
		if lPDV
			//SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
			cCondicao := GetFilSL1("PDV", aSLW, .F.)
			if !empty(cDocSL1+cSerie)
				cCondicao += " .AND. SL1->L1_DOC == '"+cDocSL1+"' .AND. SL1->L1_SERIE == '"+cSerie+"' "
			endif
			if lFilVend
				cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"'"
			endif
			bCondicao 	:= "{|| " + cCondicao + " }"
			SL1->(DbClearFilter())
			SL1->(DbSetFilter(&bCondicao,cCondicao))
		else
			cAliSL1 := "TSL1"
			cCondicao := GetFilSL1("TOP", aSLW, .F.)
			if !empty(cDocSL1+cSerie)
				cCondicao += " AND L1_DOC = '"+cDocSL1+"' AND L1_SERIE = '"+cSerie+"' "
			endif
			if lFilVend
				cCondicao += " AND L1_VEND = '"+__CFILVEND+"'"
			endif
			cQry := "SELECT R_E_C_N_O_ RECSL1 FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 WHERE SL1.D_E_L_E_T_= ' ' AND "+cCondicao
			cQry += " ORDER BY L1_SERIE, L1_DOC"
			if Select("TSL1") > 0
				TSL1->(DbCloseArea())
			Endif
			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "TSL1" // Cria uma nova area com o resultado do query
		endif
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())
		While (cAliSL1)->(!Eof())
			if cAliSL1 == "TSL1"
				SL1->(DbGoto(TSL1->RECSL1))
			endif

			//if !SL1->(Deleted()) .OR. (SL1->L1_SITUA == "07" .or. SL1->L1_STORC == "A") //se venda cencelada
			//if aScan(aSL1, {|x| x[nPosDoc]+x[nPosSer] == SL1->L1_DOC+SL1->L1_SERIE }) == 0

				//dados da SL1
				aAux1 := {}
				for nX := 1 to len(aCpoSL1)
					aadd(aAux1, SL1->&(aCpoSL1[nX]) )
				next nX

				//dados da SL2
				aSL2 := {}
				SL2->(DbSetOrder(1))
				If SL2->(DbSeek( xFilial("SL2") + SL1->L1_NUM ))
					While SL2->(!Eof()) .And. SL2->(L2_FILIAL+L2_NUM) == xFilial("SL2") + SL1->L1_NUM

						if !SL2->(Deleted()) .OR. SL2->L2_VENDIDO = 'S'
							aAux2 := {}
							for nX := 1 to len(aCpoSL2)
								aadd(aAux2, SL2->&(aCpoSL2[nX]) )
							next nX

							aadd(aSL2, aClone(aAux2) )
						endif

						SL2->(DbSkip())
					EndDo
				endif
				aadd(aAux1, aClone(aSL2) )

				//dados da SL4
				aSL4 := {}
				SL4->(DbSetOrder(1))
				If SL4->(DbSeek( xFilial("SL4") + SL1->L1_NUM ))
					While SL4->(!Eof()) .And. SL4->L4_FILIAL+SL4->L4_NUM == xFilial("SL4") + SL1->L1_NUM

						aAux2 := {}
						for nX := 1 to len(aCpoSL4)
							aadd(aAux2, SL4->&(aCpoSL4[nX]) )
						next nX

						aadd(aSL4, aClone(aAux2) )

						SL4->(DbSkip())
					EndDo
				endif
				aadd(aAux1, aClone(aSL4) )

				aadd(aSL1, aClone(aAux1) )

			//endif

			(cAliSL1)->(DbSkip())
		EndDo
		if lPDV
			SL1->(DbClearFilter())
			//SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
		else
			TSL1->(DbCloseArea())
		endif
	endif

	//BUSCANDO SANGRIAS/SUPRIMENTOS
	if aCpoSE5 <> Nil
		ChkFile("SE5")
		DbSelectArea("SE5")
		if lPDV
			cCondicao := GetFilSE5("PDV", aSLW)
			cCondicao += " .AND. ("
			cCondicao += " ((E5_TIPODOC == 'TR' .OR. E5_TIPODOC == 'TE') .AND. E5_MOEDA == 'TC' .AND. E5_RECPAG == 'R') "
			cCondicao += " .OR. "
			cCondicao += " ((E5_TIPODOC == 'SG' .OR. E5_TIPODOC == 'TR' .OR. E5_TIPODOC == 'TE') .AND. E5_MOEDA == '"+SIMBDIN+"' .AND. E5_RECPAG == 'P' .AND. E5_SITUACA <> 'C') "
			cCondicao += " ) "
			bCondicao 	:= "{|| " + cCondicao + " }"
			SE5->(DbClearFilter())
			SE5->(DbSetFilter(&bCondicao,cCondicao))
		else
			cAliSE5 := "TSE5"
			cCondicao := GetFilSE5("TOP", aSLW)
			cQry := "SELECT R_E_C_N_O_ RECSE5, D_E_L_E_T_ ISDEL FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 WHERE 1=1 " //SE5.D_E_L_E_T_ = ' '
			cQry += cCondicao
			cQry += "  AND ( "
			cQry += "  ((E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') AND E5_MOEDA = 'TC' AND E5_RECPAG = 'R')"
			cQry += " OR "
			cQry += "  ((E5_TIPODOC = 'SG' OR E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') AND E5_MOEDA = '"+SIMBDIN+"' AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C') "
			cQry += " ) "
			if Select("TSE5") > 0
				TSE5->(DbCloseArea())
			Endif
			cQry := ChangeQuery(cQry)
			TcQuery cQry New Alias "TSE5" // Cria uma nova area com o resultado do query
		endif

		if cAliSE5 == "TSE5"
			SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
		endif
		SE5->(DbSetOrder(1))
		SE5->(DbGoTop())
		While (cAliSE5)->(!Eof())
			if cAliSE5 == "TSE5"
				SE5->(DbGoto(TSE5->RECSE5))
			endif

			//dados da SE5
			aAux1 := {}
			for nX := 1 to len(aCpoSE5)
				if aCpoSE5[nX] == "E5_FILIAL"
					if (SE5->E5_TIPODOC == 'TR' .OR. SE5->E5_TIPODOC == 'TE') .AND. SE5->E5_MOEDA == 'TC' .AND. SE5->E5_RECPAG == 'R'
						aadd(aAux1, "SUPRIMENTO" )
					else
						aadd(aAux1, "SANGRIA" )
					endif
				elseif aCpoSE5[nX] == "D_E_L_E_T_"
					aadd(aAux1, iif(cAliSE5=="TSE5",TSE5->ISDEL,"") )
				else
					aadd(aAux1, SE5->&(aCpoSE5[nX]) )
				endif
			next nX
			aadd(aAux1, SE5->(Recno()) )

			aadd(aSE5, aClone(aAux1) )

			(cAliSE5)->(DbSkip())
		EndDo
		if cAliSE5 == "TSE5"
			SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
		endif
		if lPDV
			SE5->(DbClearFilter())
		else
			TSE5->(DbCloseArea())
		endif
	endif

	if lMvPosto

		//BUSCANDO COMPENSAÇÕES
		if aCpoUC0 <> Nil .AND. aCpoUC1 <> Nil .AND. SuperGetMV("TP_ACTCMP",,.F.)
			ChkFile("UC0")
			ChkFile("UC1")
			DbSelectArea("UC0")
			DbSelectArea("UC1")
			if lPDV
				cCondicao := GetFilUC0("PDV", .T., aSLW)
				if lFilVend
					cCondicao += " .AND. UC0_VEND == '"+__CFILVEND+"'"
				endif
				bCondicao 	:= "{|| " + cCondicao + " }"
				UC0->(DbClearFilter())
				UC0->(DbSetFilter(&bCondicao,cCondicao))
			else
				cAliUC0 := "TUC0"
				cCondicao := GetFilUC0("TOP", .T., aSLW)
				if lFilVend
					cCondicao += " AND UC0_VEND = '"+__CFILVEND+"'"
				endif
				cQry := "SELECT R_E_C_N_O_ RECUC0 FROM "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0 WHERE UC0.D_E_L_E_T_= ' ' AND "+cCondicao
				if Select("TUC0") > 0
					TUC0->(DbCloseArea())
				Endif
				cQry := ChangeQuery(cQry)
				TcQuery cQry New Alias "TUC0" // Cria uma nova area com o resultado do query
			endif
			UC0->(DbSetOrder(1))
			UC0->(DbGoTop())
			While (cAliUC0)->(!Eof())
				if cAliUC0 == "TUC0"
					UC0->(DbGoto(TUC0->RECUC0))
				endif

				//dados da UC0
				aAux1 := {}
				for nX := 1 to len(aCpoUC0)
					if UC0->(FieldPos(aCpoUC0[nX])) > 0 
						aadd(aAux1, UC0->&(aCpoUC0[nX]) )
					else
						aadd(aAux1, "") 
					endif
				next nX

				//dados da UC1
				aUC1 := {}
				UC1->(DbSetOrder(1))
				If UC1->(DbSeek( xFilial("UC1") + UC0->UC0_NUM ))
					While UC1->(!Eof()) .And. UC1->UC1_FILIAL+UC1->UC1_NUM == xFilial("UC1")+UC0->UC0_NUM
						aAux2 := {}
						for nX := 1 to len(aCpoUC1)
							aadd(aAux2, UC1->&(aCpoUC1[nX]) )
						next nX

						aadd(aUC1, aClone(aAux2) )
						UC1->(DbSkip())
					EndDo
				endif
				aadd(aAux1, aClone(aUC1) )
				aadd(aUC0, aClone(aAux1) )

				(cAliUC0)->(DbSkip())
			EndDo
			if lPDV
				UC0->(DbClearFilter())
			else
				TUC0->(DbCloseArea())
			endif
		endif

		//BUSCANDO VALES SERVIÇO
		if aCpoUIC <> Nil .AND. SuperGetMV("TP_ACTVLS",,.F.)
			ChkFile("UIC")
			DbSelectArea("UIC")
			if lPDV
				cCondicao := GetFilUIC("PDV", aSLW, .T.) //considera os estornados
				bCondicao 	:= "{|| " + cCondicao + " }"
				UIC->(DbClearFilter())
				UIC->(DbSetFilter(&bCondicao,cCondicao))
			else
				cAliUIC := "TUIC"
				cCondicao := GetFilUIC("TOP", aSLW, .T.) //considera os estornados
				cQry := "SELECT R_E_C_N_O_ RECUIC FROM "+RetSqlName("UIC")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UIC WHERE "+cCondicao
				if Select("TUIC") > 0
					TUIC->(DbCloseArea())
				Endif
				cQry := ChangeQuery(cQry)
				TcQuery cQry New Alias "TUIC" // Cria uma nova area com o resultado do query
			endif
			UIC->(DbSetOrder(1))
			UIC->(DbGoTop())
			While (cAliUIC)->(!Eof())
				if cAliUIC == "TUIC"
					UIC->(DbGoto(TUIC->RECUIC))
				endif

				//dados da UIC
				aAux1 := {}
				for nX := 1 to len(aCpoUIC)
					aadd(aAux1, UIC->&(aCpoUIC[nX]) )
				next nX

				aadd(aUIC, aClone(aAux1) )

				(cAliUIC)->(DbSkip())
			EndDo
			if lPDV
				UIC->(DbClearFilter())
			else
				TUIC->(DbCloseArea())
			endif
		endif

		//BUSCANDO SAQUES E DEPOSITOS PDV
		if aCpoU57 <> Nil

			//Vale Motorista (pos pago)
			If SuperGetMV("TP_ACTSQ",,.F.)
				ChkFile("U56")
				ChkFile("U57")
				DbSelectArea("U56")
				DbSelectArea("U57")
				aAux1 := {}
				U_T028TVLM(4, @aAux1, aCpoU57, .T., aSLW)
				if !empty(aAux1) .AND. !empty(aAux1[1][aScan(aCpoU57, "U57_CODIGO")])
					nY := aScan(aCpoU57, "U57_FILIAL")
					aEval(aAux1, {|x| x[nY] := "VALE MOTORISTA" })
					aEval(aAux1, {|x| aadd(aU57, aClone(x)) })
				endif

				//Saque (pre pago)
				aAux1 := {}
				U_T028TSQ(4, @aAux1, aCpoU57, .T., aSLW)
				if !empty(aAux1) .AND. !empty(aAux1[1][aScan(aCpoU57, "U57_CODIGO")])
					nY := aScan(aCpoU57, "U57_FILIAL")
					aEval(aAux1, {|x| x[nY] := "SAQUE" })
					aEval(aAux1, {|x| aadd(aU57, aClone(x)) })
				endif
			endif

			//Depósitos (pre pago)
			If SuperGetMV("TP_ACTDP",,.F.)
				ChkFile("U56")
				ChkFile("U57")
				DbSelectArea("U56")
				DbSelectArea("U57")
				aAux1 := {}
				U_T028TDP(4, @aAux1, aCpoU57, .T., aSLW)
				if !empty(aAux1) .AND. !empty(aAux1[1][aScan(aCpoU57, "U57_CODIGO")])
					nY := aScan(aCpoU57, "U57_FILIAL")
					aEval(aAux1, {|x| x[nY] := "DEPOSITO" })
					aEval(aAux1, {|x| aadd(aU57, aClone(x)) })
				endif
			endif

		endif

	endif

	aadd(aRet, aSL1)
	aadd(aRet, aSE5)
	aadd(aRet, aUC0)
	aadd(aRet, aUIC)
	aadd(aRet, aU57)

Return aRet

/***************************************************************************************************
********************************* FUNÇÕES UTEIS DE USO COMUM ***************************************
***************************************************************************************************/

//--------------------------------------------------------------------------------------
// Monta aHeader de acordo com campos passados
//--------------------------------------------------------------------------------------
Static Function MontaHeader(aCampos, lRecno)

	Local aAuxLeg := {}
	Local aHeadRet := {}
	Local nX := 0
	Default lRecno := .T.

	For nX := 1 to Len(aCampos)
		If !("LEG_" $ aCampos[nX]) .AND. SubStr(aCampos[nX],1,3) == "LEG"
			aAuxLeg := StrToKArr(aCampos[nX],"-")
			if len(aAuxLeg) = 1
				aadd(aAuxLeg, ' ')
			endif
			Aadd(aHeadRet,{aAuxLeg[2],aAuxLeg[1],'@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
		elseif aCampos[nX] == "MARK"
			Aadd(aHeadRet,{" ","MARK",'@BMP',3,0,'','€€€€€€€€€€€€€€','C','','','',''})
		elseif !empty(GetSx3Cache( aCampos[nX] ,"X3_CAMPO"))
			aadd(aHeadRet, U_UAHEADER(aCampos[nX]) )
		EndIf
	Next nX

	if lRecno
		Aadd(aHeadRet, {"RecNo", "RECNO", "9999999999", 10, 0, "", "€€€€€€€€€€€€€€", "N", "","V", "", ""})
	endif

Return aHeadRet

//--------------------------------------------------------------------------------------
// Monta linha dados de acordo com campos passados
//--------------------------------------------------------------------------------------
Static Function MontaDados(_cALIAS, aCampos, lEmpty, cFunLeg, lRecno)

	Local aFieldFill := {}
	Local cTabCp := ""
	Local nX := 0
	Local cTipo := ""
	Default lEmpty := .F.
	Default cFunLeg := "'BR_BRANCO'"
	Default lRecno := .T.

	if lEmpty
		For nX := 1 to Len(aCampos)
			if !empty(aCampos[nX])
				If !("LEG_" $ aCampos[nX]) .AND. Substr(aCampos[nX],1,3) == "LEG"
					Aadd(aFieldFill, "BR_BRANCO")
				elseif aCampos[nX] == "MARK"
					Aadd(aFieldFill, "LBNO")
				elseif !empty(GetSx3Cache( aCampos[nX] ,"X3_CAMPO"))
					cTipo := GetSx3Cache( aCampos[nX] ,"X3_TIPO")
					if cTipo == "N"
						Aadd(aFieldFill,0)
					elseif cTipo == "D"
						Aadd(aFieldFill,CTOD(""))
					elseif cTipo == "L"
						Aadd(aFieldFill,.F.)
					else
						Aadd(aFieldFill,"")
					endif
				EndIf
			else
				Aadd(aFieldFill,"")
			endif
		Next nX

		if lRecno
			Aadd(aFieldFill, 0)//Recno
		endif
	else
		For nX := 1 to Len(aCampos)
			if !empty(aCampos[nX])
				if !("LEG_" $ aCampos[nX]) .AND. Substr(aCampos[nX],1,3) == "LEG"
					Aadd(aFieldFill, &cFunLeg )
				elseif aCampos[nX] == "MARK"
					Aadd(aFieldFill, "LBNO")
				else
					If GetSx3Cache(aCampos[nX],"X3_CONTEXT") = "V" //X3_CONTEXT -> virtual
						Aadd(aFieldFill, CriaVar(aCampos[nX]) )
					else
						cTabCp := iif((At("_",aCampos[nX])-1)==2,"S"+SubStr(aCampos[nX],1,2),SubStr(aCampos[nX],1,3))
						Aadd(aFieldFill, (cTabCp)->&(aCampos[nX]) )
					endif
				endif
			else
				Aadd(aFieldFill,"")
			endif
		Next nX
		if lRecno
			Aadd(aFieldFill, (_cALIAS)->(Recno()))//Recno
		endif
	endif

	Aadd(aFieldFill, .F.) //deleted

Return aFieldFill

//--------------------------------------------------------------------------------------
// Busca string de filtro para registros da SL1 do caixa
//--------------------------------------------------------------------------------------
Static Function GetFilSL1(cOrigem, aSLW, lSitua)

	Local cRet := ""
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local lRelGeral := type("_aListSLW")=="A" .and. Len(_aListSLW)>0 .and. IsInCallStack('U_TRETR022') //chamado pelo relatório geral de caixa: U_TRETR022 
	Local nX := 0
	Default aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,nTamHora),SLW->LW_HRFECHA)}
	Default lSitua := .T. //define se olha o L1_SITUA e vendas canceladas

	if !lRelGeral //legado...
		if cOrigem == "PDV"

			cRet := " L1_FILIAL = '" + xFilial("SL1") + "'"
			cRet += " .AND. L1_OPERADO == '"+aSLW[1]+"' .AND. L1_NUMMOV == '"+aSLW[2]+"' "
			cRet += " .AND. Alltrim(L1_PDV) == '"+Alltrim(aSLW[3])+"' .AND. L1_ESTACAO == '"+aSLW[4]+"' "
			cRet += " .AND. DTOS(L1_EMISNF)+SUBSTR(L1_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
			cRet += " .AND. DTOS(L1_EMISNF)+SUBSTR(L1_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			cRet += " .AND. !Empty(SL1->L1_TIPO) "
			cRet += " .AND. ((L1_TIPO == 'P' .AND. !Empty(L1_DOCPED)) "
			cRet += "   .OR. (L1_TIPO == 'V' .AND. !Empty(L1_DOC))) "
			cRet += " .AND. L1_SITUA <> ' ' "
			if lSitua
				cRet += " .AND. (L1_SITUA == 'TX' .OR. L1_SITUA == '00')" //feito integraçao ou nao
				cRet += " .AND. L1_STORC <> 'C' .AND. L1_STORC <> 'A' " //não cancelado
			endif

		else //TOP

			cRet := " L1_FILIAL = '" + xFilial("SL1") + "'"
			cRet += " AND L1_OPERADO = '"+aSLW[1]+"' AND L1_NUMMOV = '"+aSLW[2]+"' "
			cRet += " AND RTRIM(L1_PDV) = '"+Alltrim(aSLW[3])+"' AND L1_ESTACAO = '"+aSLW[4]+"' "
			cRet += " AND L1_EMISNF+SUBSTRING(L1_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
			cRet += " AND L1_EMISNF+SUBSTRING(L1_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			cRet += " AND L1_TIPO <> '' "
			cRet += " AND ((L1_TIPO = 'P' AND L1_DOCPED <> '') "
			cRet += "   OR (L1_TIPO = 'V' AND L1_DOC <> '')) "
			cRet += " AND L1_SITUA <> ' ' "
			if lSitua
				//cRet += " AND L1_SITUA IN ('OK','T4') "
				cRet += " AND L1_SITUA NOT IN ('X2') " //não cancelados e sem erro na explosao
			endif

		endif
	else //chamado pelo relatório geral de caixa: U_TRETR022 
		if cOrigem == "PDV"

			cRet := " L1_FILIAL = '" + xFilial("SL1") + "'"
			cRet += " .AND. ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," .OR. (","(")
				cRet += " L1_OPERADO == '"+aSLW[1]+"' .AND. L1_NUMMOV == '"+aSLW[2]+"' "
				cRet += " .AND. Alltrim(L1_PDV) == '"+Alltrim(aSLW[3])+"' .AND. L1_ESTACAO == '"+aSLW[4]+"' "
				cRet += " .AND. DTOS(L1_EMISNF)+SUBSTR(L1_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " .AND. DTOS(L1_EMISNF)+SUBSTR(L1_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				cRet += ")"
			Next nX
			cRet += ")"
			cRet += " .AND. !Empty(SL1->L1_TIPO) "
			cRet += " .AND. ((L1_TIPO == 'P' .AND. !Empty(L1_DOCPED)) "
			cRet += "   .OR. (L1_TIPO == 'V' .AND. !Empty(L1_DOC))) "
			cRet += " .AND. L1_SITUA <> ' ' "
			if lSitua
				cRet += " .AND. (L1_SITUA == 'TX' .OR. L1_SITUA == '00')" //feito integraçao ou nao
				cRet += " .AND. L1_STORC <> 'C' .AND. L1_STORC <> 'A' " //não cancelado
			endif

		else //TOP

			cRet := " L1_FILIAL = '" + xFilial("SL1") + "'"
			cRet += " AND ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," OR (","(")
				cRet += " L1_OPERADO = '"+aSLW[1]+"' AND L1_NUMMOV = '"+aSLW[2]+"' "
				cRet += " AND RTRIM(L1_PDV) = '"+Alltrim(aSLW[3])+"' AND L1_ESTACAO = '"+aSLW[4]+"' "
				cRet += " AND L1_EMISNF+SUBSTRING(L1_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " AND L1_EMISNF+SUBSTRING(L1_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				cRet += ")"
			Next nX
			cRet += ")"
			cRet += " AND L1_TIPO <> '' "
			cRet += " AND ((L1_TIPO = 'P' AND L1_DOCPED <> '') "
			cRet += "   OR (L1_TIPO = 'V' AND L1_DOC <> '')) "
			cRet += " AND L1_SITUA <> ' ' "
			if lSitua
				//cRet += " AND L1_SITUA IN ('OK','T4') "
				cRet += " AND L1_SITUA NOT IN ('X2') " //não cancelados e sem erro na explosao
			endif

		endif
	endif

Return cRet

//--------------------------------------------------------------------------------------
// Busca string de filtro para registros da SE5 do caixa (troco inicial... etc)
//--------------------------------------------------------------------------------------
Static Function GetFilSE5(cOrigem, aSLW, lBanco)

	Local cRet := ""
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local lRelGeral := type("_aListSLW")=="A" .and. Len(_aListSLW)>0 .and. IsInCallStack('U_TRETR022') //chamado pelo relatório geral de caixa: U_TRETR022 
	Local nX := 0
	Default aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,nTamHora),SLW->LW_HRFECHA)}
	Default lBanco := .T.

	if !lRelGeral //legado...

		if cOrigem == "PDV"

			cRet := " E5_FILIAL = '" + xFilial("SE5") + "'"
			if lBanco
				cRet += " .AND. E5_BANCO == '"+aSLW[1]+"' "
			endif
			cRet += " .AND. E5_NUMMOV == '"+aSLW[2]+"' "
			if SE5->(FieldPos("E5_XPDV")) > 0
				cRet += " .AND. Alltrim(E5_XPDV) == '"+Alltrim(aSLW[3])+"' .AND. E5_XESTAC == '"+aSLW[4]+"' "
				cRet += " .AND. DTOS(E5_DATA)+SUBSTR(E5_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " .AND. DTOS(E5_DATA)+SUBSTR(E5_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			else
				cRet += " .AND. DTOS(E5_DATA) >= '"+DTOS(aSLW[5])+"' "
				cRet += " .AND. DTOS(E5_DATA) <= '"+DTOS(aSLW[7])+"' "
			endif

		else //TOP

			if SE5->(FieldPos("E5_XPDV")) > 0
				cRet := "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
				if lBanco
					cRet += "  AND E5_BANCO = '"+aSLW[1]+"' "
				endif
				cRet += "  AND E5_NUMMOV = '"+aSLW[2]+"' "
				//caso XPDV não preenchido
				cRet += "  AND ((E5_XPDV = ' ' AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
				cRet += "  AND E5_DATA <= '"+DTOS(aSLW[7])+"') "
				//caso XPDV preenchido
				cRet += "  OR (RTRIM(E5_XPDV) = '"+Alltrim(aSLW[3])+"' "
				cRet += "  AND E5_XESTAC = '"+aSLW[4]+"' "
				cRet += "  AND E5_DATA+SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += "  AND E5_DATA+SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"')) "
			Else
				cRet := "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
				if lBanco
					cRet += "  AND E5_BANCO = '"+aSLW[1]+"' "
				endif
				cRet += "  AND E5_NUMMOV = '"+aSLW[2]+"' "
				cRet += "  AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
				cRet += "  AND E5_DATA <= '"+DTOS(aSLW[7])+"' "
			EndIf

		endif

	else //chamado pelo relatório geral de caixa: U_TRETR022 
		
		if cOrigem == "PDV"

			cRet := " E5_FILIAL = '" + xFilial("SE5") + "'"
			cRet += " .AND. ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," .OR. (","(")
				if lBanco
					cRet += " E5_BANCO == '"+aSLW[1]+"' .AND. "
				endif
				cRet += " E5_NUMMOV == '"+aSLW[2]+"' .AND. "
				if SE5->(FieldPos("E5_XPDV")) > 0
					cRet += " Alltrim(E5_XPDV) == '"+Alltrim(aSLW[3])+"' .AND. E5_XESTAC == '"+aSLW[4]+"' "
					cRet += " .AND. DTOS(E5_DATA)+SUBSTR(E5_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cRet += " .AND. DTOS(E5_DATA)+SUBSTR(E5_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				else
					cRet += " DTOS(E5_DATA) >= '"+DTOS(aSLW[5])+"' "
					cRet += " .AND. DTOS(E5_DATA) <= '"+DTOS(aSLW[7])+"' "
				endif
				cRet += ")"
			Next nX
			cRet += ")"
		else //TOP

			if SE5->(FieldPos("E5_XPDV")) > 0
				cRet := " AND E5_FILIAL = '"+xFilial("SE5")+"' "
				cRet += " AND ("
				For nX:=1 to Len(_aListSLW)
					aSLW := _aListSLW[nX]
					cRet += iif(nX>1," OR (","(")
					if lBanco
						cRet += " E5_BANCO = '"+aSLW[1]+"' AND "
					endif
					cRet += " E5_NUMMOV = '"+aSLW[2]+"' "
					//caso XPDV não preenchido
					cRet += "  AND ((E5_XPDV = ' ' AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
					cRet += "  AND E5_DATA <= '"+DTOS(aSLW[7])+"') "
					//caso XPDV preenchido
					cRet += "  OR (RTRIM(E5_XPDV) = '"+Alltrim(aSLW[3])+"' "
					cRet += "  AND E5_XESTAC = '"+aSLW[4]+"' "
					cRet += "  AND E5_DATA+SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cRet += "  AND E5_DATA+SUBSTRING(E5_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"')) "
					cRet += ")"
				Next nX
				cRet += ")"
			Else
				cRet := " AND E5_FILIAL = '"+xFilial("SE5")+"' "
				cRet += " AND ("
				For nX:=1 to Len(_aListSLW)
					aSLW := _aListSLW[nX]
					cRet += iif(nX>1," OR (","(")
					if lBanco
						cRet += " E5_BANCO = '"+aSLW[1]+"' AND "
					endif
					cRet += " E5_NUMMOV = '"+aSLW[2]+"' "
					cRet += " AND E5_DATA >= '"+DTOS(aSLW[5])+"' "
					cRet += " AND E5_DATA <= '"+DTOS(aSLW[7])+"' "
					cRet += ")"
				Next nX
				cRet += ")"
			EndIf

		endif

	endif

Return cRet

//--------------------------------------------------------------------------------------
// Busca string de filtro para registros da UC0 do caixa
//--------------------------------------------------------------------------------------
Static Function GetFilUC0(cOrigem, lEstorno, aSLW)

	Local cRet := ""
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local lRelGeral := type("_aListSLW")=="A" .and. Len(_aListSLW)>0 .and. IsInCallStack('U_TRETR022') //chamado pelo relatório geral de caixa: U_TRETR022 
	Local nX := 0
	Default lEstorno := .F.
	Default aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,nTamHora),SLW->LW_HRFECHA)}

	if !lRelGeral //legado...
	
		if cOrigem == "PDV"

			cRet := " UC0_FILIAL = '" + xFilial("UC0") + "'"
			cRet += " .AND. UC0_OPERAD == '"+aSLW[1]+"' .AND. UC0_NUMMOV == '"+aSLW[2]+"' "
			cRet += " .AND. Alltrim(UC0_PDV) == '"+Alltrim(aSLW[3])+"' .AND. UC0_ESTACA == '"+aSLW[4]+"' "
			cRet += " .AND. DTOS(UC0_DATA)+SUBSTR(UC0_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
			cRet += " .AND. DTOS(UC0_DATA)+SUBSTR(UC0_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			if !lEstorno
				cRet += " .AND. UC0_ESTORN <> 'S' .AND. UC0_ESTORN <> 'X' "
			endif

		else //TOP

			cRet := " UC0_FILIAL = '" + xFilial("UC0") + "'"
			cRet += " AND UC0_OPERAD = '"+aSLW[1]+"' AND UC0_NUMMOV = '"+aSLW[2]+"' "
			cRet += " AND RTRIM(UC0_PDV) = '"+Alltrim(aSLW[3])+"' AND UC0_ESTACA = '"+aSLW[4]+"' "
			cRet += " AND UC0_DATA+SUBSTRING(UC0_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
			cRet += " AND UC0_DATA+SUBSTRING(UC0_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			if !lEstorno
				cRet += " AND UC0_ESTORN <> 'S' AND UC0_ESTORN <> 'X' "
			endif

		endif

	else //chamado pelo relatório geral de caixa: U_TRETR022 

		if cOrigem == "PDV"

			cRet := " UC0_FILIAL = '" + xFilial("UC0") + "'"
			cRet += " .AND. ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," .OR. (","(")
				cRet += " UC0_OPERAD == '"+aSLW[1]+"' .AND. UC0_NUMMOV == '"+aSLW[2]+"' "
				cRet += " .AND. Alltrim(UC0_PDV) == '"+Alltrim(aSLW[3])+"' .AND. UC0_ESTACA == '"+aSLW[4]+"' "
				cRet += " .AND. DTOS(UC0_DATA)+SUBSTR(UC0_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " .AND. DTOS(UC0_DATA)+SUBSTR(UC0_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				if !lEstorno
					cRet += " .AND. UC0_ESTORN <> 'S' .AND. UC0_ESTORN <> 'X' "
				endif
				cRet += ")"
			Next nX
			cRet += ")"

		else //TOP

			cRet := " UC0_FILIAL = '" + xFilial("UC0") + "'"
			cRet += " AND ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," OR (","(")
				cRet += " UC0_OPERAD = '"+aSLW[1]+"' AND UC0_NUMMOV = '"+aSLW[2]+"' "
				cRet += " AND RTRIM(UC0_PDV) = '"+Alltrim(aSLW[3])+"' AND UC0_ESTACA = '"+aSLW[4]+"' "
				cRet += " AND UC0_DATA+SUBSTRING(UC0_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " AND UC0_DATA+SUBSTRING(UC0_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				if !lEstorno
					cRet += " AND UC0_ESTORN <> 'S' AND UC0_ESTORN <> 'X' "
				endif
				cRet += ")"
			Next nX
			cRet += ")"

		endif

	endif

Return cRet

//--------------------------------------------------------------------------------------
// Busca string de filtro para registros da U57 do caixa
//--------------------------------------------------------------------------------------
Static Function GetFilU57(cOrigem, lEstorno, aSLW, lDeposito)

	Local cRet := ""
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local lRelGeral := type("_aListSLW")=="A" .and. Len(_aListSLW)>0 .and. IsInCallStack('U_TRETR022') //chamado pelo relatório geral de caixa: U_TRETR022 
	Local nX := 0
	Default lEstorno := .F.
	Default aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,nTamHora),SLW->LW_HRFECHA)}
	Default lDeposito := .F.

	if !lRelGeral //legado...

		if cOrigem == "PDV"
			if lDeposito
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " .AND. U57_OPEDEP == '"+aSLW[1]+"' .AND. U57_NUMDEP == '"+aSLW[2]+"' "
				cRet += " .AND. Alltrim(U57_PDVDEP) == '"+Alltrim(aSLW[3])+"' .AND. U57_ESTDEP == '"+aSLW[4]+"' "
				cRet += " .AND. DTOS(U57_DATDEP)+SUBSTR(U57_HORDEP,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " .AND. DTOS(U57_DATDEP)+SUBSTR(U57_HORDEP,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				if !lEstorno
					cRet += " .AND. !(U57_XGERAF $ 'X,D') " //retiro estornados
				endif
			else
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " .AND. U57_XOPERA == '"+aSLW[1]+"' .AND. U57_XNUMMO == '"+aSLW[2]+"' "
				cRet += " .AND. Alltrim(U57_XPDV) == '"+Alltrim(aSLW[3])+"' .AND. U57_XESTAC == '"+aSLW[4]+"' "
				cRet += " .AND. DTOS(U57_DATAMO)+SUBSTR(U57_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " .AND. DTOS(U57_DATAMO)+SUBSTR(U57_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				if !lEstorno
					cRet += " .AND. !(U57_XGERAF $ 'X,D') " //retiro estornados
				endif
			endif
		else //TOP
			if lDeposito
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " AND U57_OPEDEP = '"+aSLW[1]+"' AND U57_NUMDEP = '"+aSLW[2]+"' "
				cRet += " AND RTRIM(U57_PDVDEP) = '"+Alltrim(aSLW[3])+"' AND U57_ESTDEP = '"+aSLW[4]+"' "
				cRet += " AND U57_DATDEP+SUBSTRING(U57_HORDEP,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " AND U57_DATDEP+SUBSTRING(U57_HORDEP,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				if !lEstorno
					cRet += " AND U57_XGERAF <> 'D' "
				endif
			else
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " AND U57_XOPERA = '"+aSLW[1]+"' AND U57_XNUMMO = '"+aSLW[2]+"' "
				cRet += " AND RTRIM(U57_XPDV) = '"+Alltrim(aSLW[3])+"' AND U57_XESTAC = '"+aSLW[4]+"' "
				cRet += " AND U57_DATAMO+SUBSTRING(U57_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " AND U57_DATAMO+SUBSTRING(U57_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				if !lEstorno
					cRet += " AND U57_XGERAF <> 'D' "
				endif
			endif
		endif

	else //chamado pelo relatório geral de caixa: U_TRETR022 

		if cOrigem == "PDV"
			if lDeposito
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " .AND. ("
				For nX:=1 to Len(_aListSLW)
					aSLW := _aListSLW[nX]
					cRet += iif(nX>1," .OR. (","(")
					cRet += " U57_OPEDEP == '"+aSLW[1]+"' .AND. U57_NUMDEP == '"+aSLW[2]+"' "
					cRet += " .AND. Alltrim(U57_PDVDEP) == '"+Alltrim(aSLW[3])+"' .AND. U57_ESTDEP == '"+aSLW[4]+"' "
					cRet += " .AND. DTOS(U57_DATDEP)+SUBSTR(U57_HORDEP,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cRet += " .AND. DTOS(U57_DATDEP)+SUBSTR(U57_HORDEP,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
					cRet += ")"
				Next nX
				cRet += ")"
				if !lEstorno
					cRet += " .AND. !(U57_XGERAF $ 'X,D') " //retiro estornados
				endif
			else
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " .AND. ("
				For nX:=1 to Len(_aListSLW)
					aSLW := _aListSLW[nX]
					cRet += iif(nX>1," .OR. (","(")
					cRet += " U57_XOPERA == '"+aSLW[1]+"' .AND. U57_XNUMMO == '"+aSLW[2]+"' "
					cRet += " .AND. Alltrim(U57_XPDV) == '"+Alltrim(aSLW[3])+"' .AND. U57_XESTAC == '"+aSLW[4]+"' "
					cRet += " .AND. DTOS(U57_DATAMO)+SUBSTR(U57_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cRet += " .AND. DTOS(U57_DATAMO)+SUBSTR(U57_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
					cRet += ")"
				Next nX
				cRet += ")"
				if !lEstorno
					cRet += " .AND. !(U57_XGERAF $ 'X,D') " //retiro estornados
				endif
			endif
		else //TOP
			if lDeposito
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " AND ("
				For nX:=1 to Len(_aListSLW)
					aSLW := _aListSLW[nX]
					cRet += iif(nX>1," OR (","(")
					cRet += " U57_OPEDEP = '"+aSLW[1]+"' AND U57_NUMDEP = '"+aSLW[2]+"' "
					cRet += " AND RTRIM(U57_PDVDEP) = '"+Alltrim(aSLW[3])+"' AND U57_ESTDEP = '"+aSLW[4]+"' "
					cRet += " AND U57_DATDEP+SUBSTRING(U57_HORDEP,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cRet += " AND U57_DATDEP+SUBSTRING(U57_HORDEP,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
					cRet += ")"
				Next nX
				cRet += ")"
				if !lEstorno
					cRet += " AND U57_XGERAF <> 'D' "
				endif
			else
				cRet := " U57_FILIAL = '" + xFilial("U57") + "'"
				cRet += " AND ("
				For nX:=1 to Len(_aListSLW)
					aSLW := _aListSLW[nX]
					cRet += iif(nX>1," OR (","(")
					cRet += " U57_XOPERA = '"+aSLW[1]+"' AND U57_XNUMMO = '"+aSLW[2]+"' "
					cRet += " AND RTRIM(U57_XPDV) = '"+Alltrim(aSLW[3])+"' AND U57_XESTAC = '"+aSLW[4]+"' "
					cRet += " AND U57_DATAMO+SUBSTRING(U57_XHORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
					cRet += " AND U57_DATAMO+SUBSTRING(U57_XHORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
					cRet += ")"
				Next nX
				cRet += ")"
				if !lEstorno
					cRet += " AND U57_XGERAF <> 'D' "
				endif
			endif
		endif
	
	endif

Return cRet

//--------------------------------------------------------------------------------------
// Busca string de filtro para registros da UIC do caixa
//--------------------------------------------------------------------------------------
Static Function GetFilUIC(cOrigem, aSLW, lEstorn)

	Local cRet := ""
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local lRelGeral := type("_aListSLW")=="A" .and. Len(_aListSLW)>0 .and. IsInCallStack('U_TRETR022') //chamado pelo relatório geral de caixa: U_TRETR022 
	Local nX := 0
	Default aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, iif(empty(SLW->LW_DTFECHA),dDataBase,SLW->LW_DTFECHA), iif(empty(SLW->LW_HRFECHA),SubStr(Time(),1,nTamHora),SLW->LW_HRFECHA)}
	Default lEstorn := .F.


	if !lRelGeral //legado...

		if cOrigem == "PDV"

			cRet := " UIC_FILIAL = '" + xFilial("UIC") + "' "
			cRet += " .AND. UIC_OPERAD == '"+aSLW[1]+"' .AND. UIC_NUMMOV == '"+aSLW[2]+"' "
			cRet += " .AND. Alltrim(UIC_PDV) == '"+Alltrim(aSLW[3])+"' .AND. UIC_ESTACA == '"+aSLW[4]+"' "
			cRet += " .AND. DTOS(UIC_DATA)+SUBSTR(UIC_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
			cRet += " .AND. DTOS(UIC_DATA)+SUBSTR(UIC_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			if !lEstorn //se nao é pra traze estornados
				cRet += " .AND. UIC_STATUS <> 'C' " //não cancelados
			endif

		else //TOP

			cRet := " UIC_FILIAL = '" + xFilial("UIC") + "' "
			cRet += " AND UIC_OPERAD = '"+aSLW[1]+"' AND UIC_NUMMOV = '"+aSLW[2]+"' "
			cRet += " AND RTRIM(UIC_PDV) = '"+Alltrim(aSLW[3])+"' AND UIC_ESTACA = '"+aSLW[4]+"' "
			cRet += " AND UIC_DATA+SUBSTRING(UIC_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
			cRet += " AND UIC_DATA+SUBSTRING(UIC_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
			if !lEstorn //se nao é pra traze estornados
				cRet += " AND UIC_STATUS <> 'C' " //não cancelados
			endif

		endif

	else //chamado pelo relatório geral de caixa: U_TRETR022 

		if cOrigem == "PDV"

			cRet := " UIC_FILIAL = '" + xFilial("UIC") + "' "
			cRet += " .AND. ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," .OR. (","(")
				cRet += " UIC_OPERAD == '"+aSLW[1]+"' .AND. UIC_NUMMOV == '"+aSLW[2]+"' "
				cRet += " .AND. Alltrim(UIC_PDV) == '"+Alltrim(aSLW[3])+"' .AND. UIC_ESTACA == '"+aSLW[4]+"' "
				cRet += " .AND. DTOS(UIC_DATA)+SUBSTR(UIC_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " .AND. DTOS(UIC_DATA)+SUBSTR(UIC_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				cRet += ")"
			Next nX
			cRet += ")"
			if !lEstorn //se nao é pra traze estornados
				cRet += " .AND. UIC_STATUS <> 'C' " //não cancelados
			endif

		else //TOP

			cRet := " UIC_FILIAL = '" + xFilial("UIC") + "' "
			cRet += " AND ("
			For nX:=1 to Len(_aListSLW)
				aSLW := _aListSLW[nX]
				cRet += iif(nX>1," OR (","(")
				cRet += " UIC_OPERAD = '"+aSLW[1]+"' AND UIC_NUMMOV = '"+aSLW[2]+"' "
				cRet += " AND RTRIM(UIC_PDV) = '"+Alltrim(aSLW[3])+"' AND UIC_ESTACA = '"+aSLW[4]+"' "
				cRet += " AND UIC_DATA+SUBSTRING(UIC_HORA,1,"+cValToChar(nTamHora)+") >= '"+DTOS(aSLW[5])+aSLW[6]+"' "
				cRet += " AND UIC_DATA+SUBSTRING(UIC_HORA,1,"+cValToChar(nTamHora)+") <= '"+DTOS(aSLW[7])+aSLW[8]+"' "
				cRet += ")"
			Next nX
			cRet += ")"
			if !lEstorn //se nao é pra traze estornados
				cRet += " AND UIC_STATUS <> 'C' " //não cancelados
			endif

		endif
		
	endif

Return cRet

//--------------------------------------------------------------------------------------
// Busca informações na SL2 e retorna em um array
//--------------------------------------------------------------------------------------
Static Function BuscaSL2(cOrigem, nOpcX, aCampos, cFiltTop, cFiltPdv, lAbastOk)

	Local aRet := {}
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"
	Default lAbastOk := .T.
	Default cFiltTop := ""
	Default cFiltPdv := ""

	if cOrigem == "PDV"

		cCondicao := GetFilSL1(cOrigem)
		if lFilVend
			cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"'"
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"

		SL1->(DbClearFilter())
		SL1->(DbSetFilter(&bCondicao,cCondicao))
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())

		While SL1->(!Eof())

			SL2->(DbSetOrder(1))
			if SL2->(DbSeek( xFilial("SL2") + SL1->L1_NUM ))
				While SL2->(!Eof()) .And. SL2->L2_FILIAL+SL2->L2_NUM == xFilial("SL2") + SL1->L1_NUM

					Posicione("SB1",1,xFilial("SB1")+SL2->L2_PRODUTO,"B1_COD")//posiciono no produto
					if lMvPosto
						if !empty(MID->(IndexKey(1)))
							MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
						endif
						if !empty(SL2->L2_MIDCOD)
							//posiciono no abastecimento
							if !MID->(DbSeek(xFilial("MID")+SL2->L2_MIDCOD))
								lAbastOk := .F.
							endif
						else
							MID->(DbSeek(xFilial("MID")+"----")) //dou seek pra ficar em EOF
						endif
					endif

					if empty(cFiltPdv) .OR. &cFiltPdv
						aadd(aRet, MontaDados("SL2", aCampos, .F.))
					endif

					SL2->(DbSkip())
				EndDo
			endif

			SL1->(DbSkip())
		EndDo

		SL1->(DbClearFilter())

	else //TOP

		cCondicao := GetFilSL1(cOrigem)
		if lFilVend
			cCondicao += " AND L1_VEND = '"+__CFILVEND+"'"
		endif

		//Confirmo se tem movimento na SE5
		cQry:= "SELECT SL2.R_E_C_N_O_ RECSL2 "
		cQry+= "FROM "+RetSqlName("SL2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2 "
		cQry+= "INNER JOIN "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 ON ("
		cQry+= "  SL1.D_E_L_E_T_= ' ' AND L2_FILIAL=L1_FILIAL AND L2_NUM=L1_NUM AND "+cCondicao+" ) "
		cQry+= "INNER JOIN "+RetSqlName("SB1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SB1 ON (SB1.D_E_L_E_T_= ' ' AND B1_FILIAL='"+xFilial("SB1")+"' AND B1_COD = L2_PRODUTO)"
		cQry+= "WHERE SL2.D_E_L_E_T_ = ' ' "
		cQry+= "  AND L2_FILIAL = '"+xFilial("SL2")+"' "
		if !empty(cFiltTop)
			cQry+= "  AND "+cFiltTop+" "
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			if !empty(aCampos)

				SL2->(DbGoTo(QRYT1->RECSL2))
				Posicione("SB1",1,xFilial("SB1")+SL2->L2_PRODUTO,"B1_COD")//posiciono no produto
				if lMvPosto
					if !empty(MID->(IndexKey(1)))
						MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
					endif
					if !empty(SL2->L2_MIDCOD)
						//posiciono no abastecimento
						if !MID->(DbSeek(xFilial("MID")+SL2->L2_MIDCOD))
							lAbastOk := .F.
						endif
					else
						MID->(DbSeek(xFilial("MID")+"----")) //dou seek pra ficar em EOF
					endif
				endif

				aadd(aRet, MontaDados("SL2", aCampos, .F.))
			endif
			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

Return aRet

//--------------------------------------------------------------------------------------
// Busca informações na SL4 e retorna em um array
//--------------------------------------------------------------------------------------
User Function TR028BE4(cOrigem, nOpcX, aCampos, cFiltTop, cFiltPdv, cFiltSL1)
	aRet := BuscaSL4(cOrigem, nOpcX, aCampos, cFiltTop, cFiltPdv, cFiltSL1)
Return aRet 
Static Function BuscaSL4(cOrigem, nOpcX, aCampos, cFiltTop, cFiltPdv, cFiltSL1)

	Local aRet := {}
	Local cCondicao, bCondicao
	Local lFinProp
	Local lFilVend := type("__CFILVEND")=="C"
	Default cFiltTop := ""
	Default cFiltPdv := ""
	Default cFiltSL1 := ""

	if cOrigem == "PDV"

		cCondicao := GetFilSL1(cOrigem)
		if !empty(cFiltSL1)
			cCondicao += " .AND. " + cFiltSL1
		endif
		if lFilVend
			cCondicao += " .AND. L1_VEND == '"+__CFILVEND+"' "
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"

		SL1->(DbClearFilter())
		SL1->(DbSetFilter(&bCondicao,cCondicao))
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())

		While SL1->(!Eof())

			SL4->(DbSetOrder(1)) //L4_FILIAL+L4_NUM+L4_ORIGEM
			if SL4->(DbSeek( xFilial("SL4") + SL1->L1_NUM ))
				While SL4->(!Eof()) .And. SL4->(L4_FILIAL+L4_NUM) == xFilial("SL4")+SL1->L1_NUM

					if empty(cFiltPdv) .OR. &cFiltPdv

						//se tem campos da SA1, posiciono
						if aScan(aCampos, {|x| "A1_" == Left(x,3)}) > 0
							if Alltrim(SL4->L4_FORMA) == "CF" //especifico carta frete
								Posicione("SA1",3,xFilial("SA1")+SL4->L4_CGC,"A1_COD")
							else
								lFinProp := Alltrim(SL4->L4_FORMA)$ (SIMBDIN+"CH") .OR. Posicione("SAE",1,xFilial("SAE")+SubStr(SL4->L4_ADMINIS,1,TamSX3("AE_COD")[1]),"AE_FINPRO") == "S"
								if lFinProp
									Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_COD")
								else
									Posicione("SA1",1,xFilial("SA1")+PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] )+PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] ),"A1_COD")
								endif
							endif
						endif

						aadd(aRet, MontaDados("SL4", aCampos, .F.))
					endif

					SL4->(DbSkip())
				EndDo
			endif

			SL1->(DbSkip())
		EndDo

		SL1->(DbClearFilter())

	else //TOP

		cCondicao := GetFilSL1(cOrigem)
		if !empty(cFiltSL1)
			cCondicao += " AND " + cFiltSL1
		endif
		if lFilVend
			cCondicao += " AND L1_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT SL4.R_E_C_N_O_ RECSL4 "
		cQry+= "FROM "+RetSqlName("SL4")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL4 "
		cQry+= "INNER JOIN "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 ON ("
		cQry+= "  SL1.D_E_L_E_T_= ' ' AND L4_FILIAL = L1_FILIAL AND L4_NUM=L1_NUM AND "+cCondicao+" ) "
		cQry+= "WHERE SL4.D_E_L_E_T_ = ' ' "
		cQry+= "  AND L4_FILIAL = '"+xFilial("SL4")+"' "
		if !empty(cFiltTop)
			cQry+= "  AND "+cFiltTop+" "
		endif

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			if !empty(aCampos)

				SL4->(DbGoTo(QRYT1->RECSL4))
				Posicione("SL1",1,xFilial("SL1")+SL4->L4_NUM,"L1_NUM")

				//se tem campos da SA1, posiciono
				if aScan(aCampos, {|x| "A1_" == Left(x,3)}) > 0
					if Alltrim(SL4->L4_FORMA) == "CF" //especifico carta frete
						Posicione("SA1",3,xFilial("SA1")+SL4->L4_CGC,"A1_COD")
					else
						lFinProp := Alltrim(SL4->L4_FORMA)==SIMBDIN .OR. Posicione("SAE",1,xFilial("SAE")+SubStr(SL4->L4_ADMINIS,1,TamSX3("AE_COD")[1]),"AE_FINPRO") == "S"
						if lFinProp
							Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_COD")
						else
							Posicione("SA1",1,xFilial("SA1")+PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] )+PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] ),"A1_COD")
						endif
					endif
				endif

				aadd(aRet, MontaDados("SL4", aCampos, .F.))
			endif
			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

Return aRet

//--------------------------------------------------------------------------------------
// Busca informações na SE1 e retorna em um array
//--------------------------------------------------------------------------------------
User Function TR028BE1(aCampos, cFiltTop, bAntesAdd, aSLW, lVenda, lCompen, lEstorno)
	aRet := BuscaSE1(aCampos, cFiltTop, bAntesAdd, aSLW, lVenda, lCompen, lEstorno)
Return aRet
Static Function BuscaSE1(aCampos, cFiltTop, bAntesAdd, aSLW, lVenda, lCompen, lEstorno)

	Local nPosAux := 0
	Local aRet := {}
	Local cCondicao
	Local cPrefixComp
	Local lFilVend := type("__CFILVEND")=="C"
	Default cFiltTop := ""
	Default bAntesAdd := Nil
	Default lVenda := .T.
	Default lCompen := .T.
	Default lEstorno := .F.

	if type("SIMBDIN") == "U"
		SIMBDIN := Alltrim(SuperGetMV("MV_SIMB1",,"R$"))
	endif

	if lVenda
		//BUSCANDO TITULOS GERADOS POR VENDAS
		cCondicao := GetFilSL1("TOP",aSLW)
		if lFilVend
			cCondicao += " AND L1_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT DISTINCT SE1.R_E_C_N_O_ RECSE1 "
		cQry+= "FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
		cQry+= "INNER JOIN "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1  ON ("
		cQry+= "  SL1.D_E_L_E_T_= ' ' AND E1_PREFIXO = L1_SERIE AND E1_NUM = L1_DOC AND E1_NUMNOTA = L1_DOC AND "+cCondicao+" ) "
		cQry+= "WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E1_FILIAL = '"+xFilial("SE1")+"' "
		If !IsInCallStack("U_TRETR022")
			cQry+= "  AND E1_EMISSAO >= '"+DTOS(SLW->LW_DTABERT)+"' " // Felipe Sousa - Maracanã 16/11/2023
			if !empty(SLW->LW_DTFECHA)
				cQry+= "  AND E1_EMISSAO <= '"+DTOS(SLW->LW_DTFECHA)+"' " // Felipe Sousa - Maracanã 16/11/2023
			endif
		EndIf
		if !empty(cFiltTop)
			cQry+= "  AND "+cFiltTop+" "
		endif
		cQry+= "  AND NOT EXISTS ( SELECT 1 FROM "+RetSqlName("SE6")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE6 WHERE SE6.D_E_L_E_T_= ' ' AND E6_FILIAL = E1_FILIAL AND E6_PREFIXO = E1_PREFIXO AND E6_NUM = E1_NUM AND E6_PARCELA = E1_PARCELA AND E6_TIPO = E1_TIPO)"
		cQry+= "  ORDER BY SE1.R_E_C_N_O_ "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			if !empty(aCampos)
				SE1->(DbGoTo(QRYT1->RECSE1))

				//se tem campos da SA1, posiciono
				if aScan(aCampos, {|x| "A1_" == Left(x,3)}) > 0
					Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_COD")
					if Alltrim(SE1->E1_TIPO) == "CH"
						SEF->(DbSetOrder(3)) //EF_FILIAL+EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_NUM+EF_SEQUENC
						if SEF->(DbSeek(SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
							Posicione("SA1",3,xFilial("SA1")+SEF->EF_CPFCNPJ,"A1_COD")
						endif
					endif
				endif

				if bAntesAdd != Nil
					EVal(bAntesAdd)
				endif

				aadd(aRet, MontaDados("SE1", aCampos, .F.))

				if (nPosAux:=aScan(aCampos, "E1_VLRREAL")) > 0 .AND. empty(aRet[len(aRet)][nPosAux])
					aRet[len(aRet)][nPosAux] := SE1->E1_VALOR
				endif
			endif
			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

	//BUSCANDO TITULOS GERADOS POR COMPENSACAO DE VALORES
	if lMvPosto .AND. lCompen .AND. SuperGetMV("TP_ACTCMP",,.F.)
		cPrefixComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
		cPrefixComp := SubStr(cPrefixComp,1,TamSX3("E1_PREFIXO")[1])
		cCondicao := GetFilUC0("TOP",lEstorno)
		if lFilVend
			cCondicao += " AND UC0_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT DISTINCT SE1.R_E_C_N_O_ RECSE1 "
		cQry+= "FROM "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
		cQry+= "INNER JOIN "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0  ON ("
		cQry+= "  UC0.D_E_L_E_T_= ' ' AND UC0_NUM = E1_NUM AND "+cCondicao+" ) "
		cQry+= "WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry+= "  AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry+= "  AND E1_PREFIXO = '"+cPrefixComp+"' "
		cQry+= "  AND E1_EMISSAO >= '"+DTOS(SLW->LW_DTABERT)+"' " // Felipe Sousa - Maracanã 16/11/2023
		if !empty(SLW->LW_DTFECHA)
			cQry+= "  AND E1_EMISSAO <= '"+DTOS(SLW->LW_DTFECHA)+"' " // Felipe Sousa - Maracanã 16/11/2023
		endif
		if !empty(cFiltTop)
			cQry+= "  AND "+cFiltTop+" "
		endif
		cQry+= "  AND NOT EXISTS ( SELECT 1 FROM "+RetSqlName("SE6")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE6 WHERE SE6.D_E_L_E_T_= ' ' AND E6_FILIAL = E1_FILIAL AND E6_PREFIXO = E1_PREFIXO AND E6_NUM = E1_NUM AND E6_PARCELA = E1_PARCELA AND E6_TIPO = E1_TIPO)"
		cQry+= "  ORDER BY SE1.R_E_C_N_O_ "

		if Select("QRYT2") > 0
			QRYT2->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT2" // Cria uma nova area com o resultado do query

		While QRYT2->(!Eof())
			if !empty(aCampos)
				SE1->(DbGoTo(QRYT2->RECSE1))

				//se tem campos da SA1, posiciono
				if aScan(aCampos, {|x| "A1_" == Left(x,3)}) > 0
					Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_COD")
					if Alltrim(SE1->E1_TIPO) == "CH"
						SEF->(DbSetOrder(3)) //EF_FILIAL+EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_NUM+EF_SEQUENC
						if SEF->(DbSeek(SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
							Posicione("SA1",3,xFilial("SA1")+SEF->EF_CPFCNPJ,"A1_COD")
						endif
					endif
				endif

				if bAntesAdd != Nil
					EVal(bAntesAdd)
				endif

				aadd(aRet, MontaDados("SE1", aCampos, .F.))

				if (nPosAux:=aScan(aCampos, "E1_VLRREAL")) > 0 .AND. empty(aRet[len(aRet)][nPosAux])
					aRet[len(aRet)][nPosAux] := SE1->E1_VALOR
				endif
			endif
			QRYT2->(DbSkip())
		EndDo

		QRYT2->(DbCloseArea())

	endif

Return aRet

//--------------------------------------------------------------------------------------
// Busca informações na UC1 e retorna em um array
//--------------------------------------------------------------------------------------
Static Function BuscaUC1(cOrigem, nOpcX, aCampos, cFiltTop, cFiltPdv)

	Local aRet := {}
	Local cCondicao, bCondicao
	Local lFilVend := type("__CFILVEND")=="C"

	if cOrigem == "PDV"

		cCondicao := GetFilUC0(cOrigem)
		if lFilVend
			cCondicao += " .AND. UC0_VEND == '"+__CFILVEND+"' "
		endif
		bCondicao 	:= "{|| " + cCondicao + " }"

		UC0->(DbClearFilter())
		UC0->(DbSetFilter(&bCondicao,cCondicao))
		UC0->(DbSetOrder(1)) //UC0_FILIAL+UC0_NUM
		UC0->(DbGoTop())

		While UC0->(!Eof())

			UC1->(DbSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
			if UC1->(DbSeek( xFilial("UC1")+UC0->UC0_NUM ))
				While UC1->(!Eof()) .And. UC1->(UC1_FILIAL+UC1_NUM) == xFilial("UC1")+UC0->UC0_NUM

					if &cFiltPdv

						//se tem campos da SA1, posiciono
						if aScan(aCampos, {|x| "A1_" == Left(x,3)}) > 0
							if Alltrim(UC1->UC1_FORMA) $ "CF,CH"
								Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_COD")
							else
								Posicione("SA1",1,xFilial("SA1")+PADR(UC1->UC1_ADMFIN, TamSX3("A1_COD")[1])+PADR("01",TamSX3("A1_LOJA")[1]),"A1_COD")
							endif
						endif

						aadd(aRet, MontaDados("UC1", aCampos, .F.))
					endif

					UC1->(DbSkip())
				EndDo
			endif

			UC0->(DbSkip())
		EndDo

		UC0->(DbClearFilter())

	else //TOP

		cCondicao := GetFilUC0(cOrigem)
		if lFilVend
			cCondicao += " AND UC0_VEND = '"+__CFILVEND+"' "
		endif

		cQry:= "SELECT UC1.R_E_C_N_O_ RECUC1 "
		cQry+= "FROM "+RetSqlName("UC1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC1 "
		cQry+= "INNER JOIN "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0 ON ( "
		cQry+= "  UC0.D_E_L_E_T_= ' ' AND UC1_NUM = UC0_NUM AND "+cCondicao+" ) "
		cQry+= "WHERE UC1.D_E_L_E_T_ = ' ' "
		cQry+= "  AND UC1_FILIAL = '"+xFilial("UC1")+"' "
		cQry+= "  AND "+cFiltTop+" "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		While QRYT1->(!Eof())
			if !empty(aCampos)

				UC1->(DbGoTo(QRYT1->RECUC1))

				aadd(aRet, MontaDados("UC1", aCampos, .F.))
			endif
			QRYT1->(DbSkip())
		EndDo

		QRYT1->(DbCloseArea())

	endif

Return aRet

//--------------------------------------------------------------------------------------
// Ação dos botões de Ver Aglutinado/Detalhado
// Deve ser private as variaveis: lViewDet, oGridDet, oButDeta, oButAglu
//--------------------------------------------------------------------------------------
Static Function AtuAglDet()

	if lViewDet
		oGridDet:aCols := aClone(aColsAglut)
		oButDeta:Show()
		oButAglu:Hide()
	else
		oGridDet:aCols := aClone(aColsDet)
		oButDeta:Hide()
		oButAglu:Show()
	endif

	lViewDet := !lViewDet

	oGridDet:oBrowse:Refresh()

Return

//--------------------------------------------------------------------------------------
// Função para definir legenda do cheque troco. deve estar posicionado na UF2
//--------------------------------------------------------------------------------------
Static Function LegendUF2()

	Local aArea := GetArea()
	Local lOK := .T.
	Local cLegRet := "BR_VERDE"
	Local cChavCheq := UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM
	Local cMsgErro := ""

	//AvalUF2(cDoc, cSerie, cPdv, lOK, cObs, aIdCorrige, cChvCheq)
	AvalUF2(,,,@lOK, @cMsgErro,,cChavCheq)

	//verifico pela chave do documento também
	if lOK
		if !empty(UF2->UF2_DOC)
			AvalUF2(UF2->UF2_DOC,UF2->UF2_SERIE,UF2->UF2_PDV,@lOK, @cMsgErro)
		elseif !empty(UF2->UF2_CODBAR)
			AvalUF2(UF2->UF2_CODBAR,"CODBAR",,@lOK, @cMsgErro)
		endif
	endif

	if !lOK
		cLegRet := "BR_VERMELHO"
	endif

	RestArea(aArea)

Return cLegRet

//--------------------------------------------------------------------------------------
// Visualiza o titulo a receber SE1 a partir do recno
//--------------------------------------------------------------------------------------
Static Function VerTitSE1(nRecSE1, nIndice, cChave)

	Local lBkpInc := iif(type("INCLUI")=="L",INCLUI,.F.)
	Local lBkbAlt := iif(type("ALTERA")=="L",ALTERA,.F.)
	Local cBkpCad := iif(type("cCadastro")=="C",cCadastro,"")
	Local lAchou := .F.
	Default nRecSE1 := 0
	Default nIndice := 1
	Default cChave := ""

	cCadastro := "Título a Receber - VISUALIZAR"

	if nRecSE1 > 0
		SE1->(DbGoTo(nRecSE1))
		lAchou := .T.
	elseif !empty(cChave)
		SE1->(DbSetOrder(nIndice))
		if SE1->(DbSeek(xFilial("SE1")+cChave))
			lAchou := .T.
		else
			MsgInfo("Título não encontrado na base!", "Atenção")
		endif
	endif

	if lAchou
		INCLUI := .F.
		ALTERA := .F.
		FA280Visua("SE1",SE1->(RECNO()), 2)
		INCLUI := lBkpInc
		ALTERA := lBkbAlt
	endif

	cCadastro := cBkpCad

Return

//--------------------------------------------------------------------------------------
//Cancela baixa do título posicionado
//--------------------------------------------------------------------------------------
User Function TR028CBX()
Return CancBxSE1()
Static Function CancBxSE1()

	Local lRet := .T.
	Local aFin070 := {}
	Local cChvE1 := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO
	Local dBkpDBase := dDataBase
	
	dDataBase := SE1->E1_EMISSAO

	AADD( aFin070, {"E1_FILIAL"  , SE1->E1_FILIAL	, Nil})
	AADD( aFin070, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
	AADD( aFin070, {"E1_NUM"     , SE1->E1_NUM 		, Nil})
	AADD( aFin070, {"E1_PARCELA" , SE1->E1_PARCELA	, Nil})
	AADD( aFin070, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

	//Assinatura de variáveis que controlarão a exclusão automática do título;
	lMsErroAuto := .F.
	lMsHelpAuto := .T.

	//rotina automática para exclusão da baixa do título;
	MSExecAuto({|x,y| Fina070(x,y)}, aFin070, 6)

	//Quando houver erros, exibí-los em tela;
	if lMsErroAuto
		MostraErro()
	endif

	SE1->(DbSetOrder(1))
	if SE1->(DbSeek(cChvE1))
		if SE1->E1_SALDO == 0 //verifica se realmente foi cancelada a baixa
			lRet := .F.
			MsgInfo("Não foi possível cancelar a baixa do título. Pode ser restrição de usuário quanto a exclusão de baixa do contas a receber.","Atenção")
		endif
	endif

	dDataBase := dBkpDBase

Return lRet

//--------------------------------------------------------------------------------------
// Função para Manutençao de Suprimento e Sangria
// nAcao : 3=Incluir;4=ALterar;5=Excluir
// nTipo : 1=Suprimento;2=Sangria
//--------------------------------------------------------------------------------------
Static Function MntSupSang(nAcao, nTipo, nRecSE5, bRefresh)

	Local lOk := .T.
	Local nOpcX := 0
	Local nNovoValor := 0
	Local nValAtual := 0
	Local oPnlDet, oBanco, oDsBanco, oDsVend
	Local cBanco := Space(TamSX3("A6_COD")[1]+TamSX3("A6_AGENCIA")[1]+TamSX3("A6_NUMCON")[1])
	Local cDsBanco := ""
	Local cDsVend := ""
	Local cSXBSA6 := "SA6"
	Local cLogCaixa := ""
	Local cHistBkp := ""
	Local cHistorico := Space(TamSX3("E5_HISTOR")[1])
	Local aHistor := {"TROCO PARA O CAIXA "+SLW->LW_OPERADO+" - RETAGUARDA" ,"SANGRIA DO CAIXA "+SLW->LW_OPERADO+" - RETAGUARDA"}
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo
	Local cDoc, cSerie
	Local oHistorico := Nil
	Private oDlgAux
	Private oGetVende
	Private cGetVende := Space(TamSX3("A3_COD")[1])

	if SXB->(DbSeek("SA6GER"))
		cSXBSA6 := "SA6GER"
	endif

	//Busca o Codigo do vendedor
	if nAcao == 3
		SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
		PswOrder(2) // ordena pelo nome de usuário
		PswSeek(AllTrim(cGetNom)) // Posiciona no usuário desejado
		_xCodusr = PswID() // Recebe o nome completo do usuário.
		if _xCodusr == Nil
			_xCodusr:=""
		Endif
		if !Empty(_xCodusr)
			If SA3->(DbSeek(xFilial("SA3") + _xCodusr))
				cGetVende := SA3->A3_COD
			EndIf
		EndIf
		cHistorico := PadR(aHistor[nTipo], TamSX3("E5_HISTOR")[1])
	EndIf

	if nAcao <> 3
		if empty(nRecSE5)
			Return
		endif
		SE5->(DbGoTo(nRecSE5)) //posiciono no registro da SE5
		cBanco := SE5->E5_BANCO+SE5->E5_AGENCIA+SE5->E5_CONTA
		cDsBanco := Posicione("SA6",1,xFilial("SA6")+cBanco,"A6_NOME")
		nNovoValor := SE5->E5_VALOR
		nValAtual  := SE5->E5_VALOR
		cDoc := SE5->E5_NUMERO
		cSerie := SE5->E5_PREFIXO
		cHistorico := SE5->E5_HISTOR
		cHistBkp := SE5->E5_HISTOR
		
		if Upper(SE5->E5_RECONC) == "X"
			MsgAlert("Ação não permitida. Movimento já se encontra conciliado!","Atenção")
			Return
		ElseIf lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
			MsgAlert("Ação não permitida. Movimento já se encontra contabilizado!","Atenção")
			Return
		EndIf
		cGetVende := SE5->E5_OPERAD
		cDsVend := Posicione("SA3",1,xFilial("SA3")+cGetVende,"A3_NOME")
	endif

	if nAcao == 5 //se exclusao
		if MsgYesNo("Confirma exclusão " + iif(nTipo==1,"do Suprimento","da Sangria") + " no valor de "+SIMBDIN+" " + Alltrim(Transform(SE5->E5_VALOR, "@E 999,999,999.99")) + "?", "Atenção")
			nOpcX := 1
		endif
	else //mostra tela
		DEFINE MSDIALOG oDlgAux TITLE iif(nAcao == 3,"Inclusão ","Manutenção ") + iif(nTipo==1,"Suprimento","Sangria") STYLE DS_MODALFRAME FROM 000, 000  TO 220, 400 COLORS 0, 16777215 PIXEL

		oPnlDet := TScrollBox():New(oDlgAux,05,05,82,190,.F.,.T.,.T.)

		@ 010, 010 SAY "Banco:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
		@ 008, 050 MSGET oBanco VAR cBanco WHEN (nAcao==3) SIZE 035, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL F3 cSXBSA6 VALID VldBcoSang(cBanco, @cDsBanco, oDlgAux)
		@ 008, 090 MSGET oDsBanco VAR cDsBanco WHEN .F. SIZE 90, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

		@ 027, 010 SAY "Vendedor:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
		@ 025, 050 MSGET oGetVende VAR cGetVende WHEN .T. SIZE 035, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL F3 "SA3" VALID empty(cGetVende) .OR. (!empty(cDsVend := Posicione("SA3",1,xFilial("SA3")+cGetVende,"A3_NOME")) .AND. oDlgAux:Refresh() )
		@ 025, 090 MSGET oDsVend VAR cDsVend WHEN .F. SIZE 90, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

		@ 044, 010 SAY "Valor:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
		@ 042, 050 MSGET oValor VAR nNovoValor Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL VALID nNovoValor >= 0

		@ 061, 010 SAY "Histórico:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
		@ 059, 050 MSGET oHistorico VAR cHistorico Picture "@!" SIZE 095, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL 

		@ 092, 105 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgAux PIXEL Action oDlgAux:End()
		@ 092, 150 BUTTON oButton2 PROMPT "Salvar" SIZE 040, 012 OF oDlgAux PIXEL Action iif( nNovoValor > 0 .AND. !empty(cDsBanco) .AND. !empty(cGetVende),(nOpcX := 1, oDlgAux:End()) , MsgInfo("Dados não informados corretamente.", "Atenção"))
		oButton2:SetCSS( CSS_BTNAZUL )

		ACTIVATE MSDIALOG oDlgAux CENTERED
	endif

	if nOpcX == 0
		Return
	endif

	BeginTran()

	if nAcao == 3 //Se inclusao

		//Função que faz inclusao dos movimentos (saida/entrada) na SE5
		IncSE5SupSang(nTipo, nNovoValor, Alltrim(cBanco), SLW->LW_OPERADO, SLW->LW_DTABERT, SLW->LW_HRABERT, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, "TRETA028",cHistorico)
		cDoc := SE5->E5_NUMERO
		cSerie := SE5->E5_PREFIXO

		cLogCaixa += "VALOR: " + Transform(nNovoValor ,"@E 999,999,999.99") + CRLF

	else

		Reclock("SE5", .F.)
		if nAcao == 5 //Se exclusao
			cLogCaixa += "VALOR: " + Transform(nValAtual ,"@E 999,999,999.99") + CRLF
			SE5->(DbDelete())
		elseif nAcao == 4 //Se alteraçao
			SE5->E5_VALOR := nNovoValor
			SE5->E5_OPERAD := cGetVende
			SE5->E5_HISTOR := cHistorico
			cLogCaixa += "VALOR ANTERIOR: " + Transform(nValAtual ,"@E 999,999,999.99") + CRLF
			cLogCaixa += "NOVO VALOR: " + Transform(nNovoValor ,"@E 999,999,999.99") + CRLF
		endif
		SE5->(MsUnlock())

		//Funçao que faz alteração ou exclusao do movimento do caixa gerencial
		if !AltSE5Ger(nAcao, nTipo, nNovoValor, SLW->LW_OPERADO, DTOS(SE5->E5_DATA), SE5->E5_PREFIXO, SE5->E5_NUMERO, cHistBkp, nValAtual, SE5->E5_HISTOR)
			MsgAlert("Falha na manutenção " + iif(nTipo==1,"do Suprimento","da Sangria") + "! Não foi possível encontrar movimento do caixa gerencial.", "Atenção")
			lOk := .F.
			DisarmTransaction()
		endif

	endif

	EndTran()

	if lOk .AND. lLogCaixa
		GrvLogConf(iif(nTipo==1,"9","8"), iif(nAcao==3,"I",iif(nAcao==4,"A","E")), cLogCaixa, cDoc, cSerie)
	endif

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

Static Function VldBcoSang(cBanco, cDsBanco, oDlgAux)

	Local lRet := .T.

	if empty(cBanco)
		cDsBanco := ""
	else
		cDsBanco := Posicione("SA6",1,xFilial("SA6")+Alltrim(cBanco),"A6_NOME")
		if empty(cDsBanco)
			MsgInfo("Banco nao cadastrado!")
			lRet := .F.
		endif
		if lRet .And. SubStr(cBanco,1,3) == SubStr(cGetCxa,1,3)
			MsgInfo("Banco deve ser diferente do caixa do operador!")
			lRet := .F.
		endif

		if lRet .AND. SA6->(FieldPos("A6_XGERENT")) > 0 .AND. SXB->(DbSeek("SA6GER"))
			if SA6->A6_XGERENT <> '1'
				MsgInfo("Banco selecionado deve ser do tipo gerencial!","A6_XGERENT")
				lRet := .F.
			endif
		endif
		
		//tratamento para Decio (financeiro compartilhado)
		if lRet .AND. SA6->(FieldPos("A6_Z_FIL")) > 0 .AND. !empty(SA6->A6_Z_FIL) .AND. SA6->A6_Z_FIL <> cFilAnt
			MsgInfo("Banco informado não é referente a filial logada!")
			lRet := .F.
		endif
	endif
	
	oDlgAux:Refresh()

Return lRet

//--------------------------------------------------------------------------------------
// Função para incluir movimento de sangria ou suprimento no caixa
// nTipo : 1=Suprimento;2=Sangria
//--------------------------------------------------------------------------------------
User Function TRA028SG(nTipo, nNovoValor, cBancoGer, cBancoOper, dDataMov, cHoraMov, cNumMov, cPdv, cEstacao, cOrigem)
	IncSE5SupSang(nTipo, nNovoValor, cBancoGer, cBancoOper, dDataMov, cHoraMov, cNumMov, cPdv, cEstacao, cOrigem)
Return
Static Function IncSE5SupSang(nTipo, nNovoValor, cBancoGer, cBancoOper, dDataMov, cHoraMov, cNumMov, cPdv, cEstacao, cOrigem, cHistorico)

	Local nX := 1
	Local aBanco
	Local aRecPag := {"P","R"}
	Local aMoeda := {"TC", SIMBDIN}
	Local aNaturez := {StrTran(StrTran(GetMV("MV_NATTROC"),"'"),'"'), StrTran(StrTran(GetMV("MV_NATSANG"),"'"),'"')}
	Local aHistor := {"TROCO PARA O CAIXA "+cBancoOper+" - RETAGUARDA" ,"SANGRIA DO CAIXA "+cBancoOper+" - RETAGUARDA"}
	Local cE5Num := cBancoOper + StrTran(Time(),":","")
	Local lGetVend := type("cGetVende")<>"U
	Default cHistorico := ""

	if nTipo == 1
		aBanco := {cBancoGer, cBancoOper}
	else
		aBanco := {cBancoOper, cBancoGer}
	endif

	//1=SAÍDA DO TROCO NO CAIXA GERENTE;2=ENTRADA DO TROCO NO CAIXA DO OPERADOR
	For nX := 1 to 2
		Reclock("SE5",.T.)
		SE5->E5_FILIAL  := xFilial("SE5")
		SE5->E5_FILORIG := cFilAnt
		SE5->E5_MOEDA   := aMoeda[nTipo]
		SE5->E5_TIPODOC := "TR"
		SE5->E5_VALOR   := nNovoValor
		SE5->E5_DATA    := dDataMov
		SE5->E5_DTDISPO := dDataMov
		SE5->E5_DTDIGIT := dDataMov
		SE5->E5_NATUREZ := aNaturez[nTipo]
		SE5->E5_VLMOED2 := nNovoValor
		SE5->E5_BANCO   := aBanco[nX]
		SE5->E5_AGENCIA := Posicione("SA6",1,xFilial("SA6")+aBanco[nX],"A6_AGENCIA")
		SE5->E5_CONTA   := Posicione("SA6",1,xFilial("SA6")+aBanco[nX],"A6_NUMCON")
		SE5->E5_RECPAG  := aRecPag[nX]
		SE5->E5_HISTOR  := Iif(!Empty(cHistorico),AllTrim(cHistorico),aHistor[nTipo])
		SE5->E5_SITUA   := "OK"
		SE5->E5_SEQ     := StrZero(nX,2)
		SE5->E5_PREFIXO := "RET" //DEVERIA SER A SERIE DO CF
		SE5->E5_NUMERO  := cE5Num //DEVERIA SER O NR DO CF
		SE5->E5_NUMMOV  := cNumMov
		SE5->E5_ORIGEM := cOrigem
		if SE5->(FieldPos("E5_XPDV")) > 0
			SE5->E5_XPDV    := cPdv
			SE5->E5_XESTAC  := cEstacao
			SE5->E5_XHORA   := cHoraMov
		EndIf
		//TODO ver como tratar devolucoes, caixa multi vendedor
		if lGetVend
			SE5->E5_OPERAD := cGetVende
		endif
		SE5->(MsUnlock())
	next nX

Return

//--------------------------------------------------------------------------------------
// Função para localizar e alterar/deletar o movimento de sangria/suprimento do caixa gerencial
// nAcao : 4=Alterar;5=Excluir
// nTipo : 1=Suprimento;2=Sangria
//--------------------------------------------------------------------------------------
Static Function AltSE5Ger(nAcao, nTipo, nNovoValor, cBancoOper, cData, cPrefix, cNumero, cHistOld, nValAtual, cHistNew)

	Local lRet := .F.
	Local cQry := ""
	Local cValor := cValToChar(nValAtual)
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo

	//Procurando registro do caixa gerencial
	cQry:= "SELECT R_E_C_N_O_ RECSE5 "
	cQry+= "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
	cQry+= "WHERE SE5.D_E_L_E_T_ = ' ' "
	cQry+= GetFilSE5("TOP",,.F.) //filtros do caixa
	cQry+= "  AND E5_BANCO <> '"+cBancoOper+"' " //diferente do banco do operador
	cQry+= "  AND E5_DATA = '"+cData+"' "
	cQry+= "  AND E5_PREFIXO = '"+cPrefix+"' "
	cQry+= "  AND E5_NUMERO = '"+cNumero+"' "
	cQry+= "  AND ROUND(E5_VALOR,2) = "+cValor+" "
	cQry+= "  AND E5_HISTOR = '"+cHistOld+"' "
	if nTipo == 1 //suprimento
		cQry+= "  AND (E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') "
		cQry+= "  AND E5_MOEDA = 'TC' "
		cQry+= "  AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C' "
	else //sangria
		cQry+= "  AND (E5_TIPODOC = 'SG' OR E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') "
		cQry+= "  AND E5_MOEDA = '"+SIMBDIN+"' "
		cQry+= "  AND E5_RECPAG = 'R' "
	endif

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	if QRYT1->(!Eof()) .AND. QRYT1->RECSE5 > 0
		SE5->(DbGoTo(QRYT1->RECSE5))

		if Upper(SE5->E5_RECONC) == "X"
			MsgAlert("Ação não permitida. Movimento caixa Gerencial já se encontra conciliado!","Atenção")
		ElseIf lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
			MsgAlert("Ação não permitida. Movimento caixa Gerencial já se encontra contabilizado!","Atenção")
		else
			Reclock("SE5", .F.)
			if nAcao == 5 //Se Exclusao
				SE5->(DbDelete())
			elseif nAcao == 4 //Se alteraçao
				SE5->E5_VALOR := nNovoValor
				SE5->E5_OPERAD := cGetVende
				SE5->E5_HISTOR := cHistNew
			endif
			SE5->(MsUnlock())

			lRet := .T.
		endif
	elseif nAcao == 5 //se exclusao e nao tem o registro.. continua
		lRet := .T.
	endif

	QRYT1->(DbCloseArea())

Return lRet

//--------------------------------------------------------------------------------------
// Função para Ajustar titulo em dinheiro no cupom. Ja deve estar posicionado na SL1.
// nOpc : 1=Add Valor; 2=Subitrai Valor; 3=Valor Total
//--------------------------------------------------------------------------------------
Static Function AjuSL1Din(nOpc, nValor, lAtuTroco, lAuto, bRefresh)

	Local aArea := GetArea()
	Local aAreaSE1 := SE1->(GetArea())
	Local lOk := .T.
	Local nRecSE1Din := 0
	Local aDadosAux := {}
	Local aFin040 := {}
	Local cBanco, cAgencia, cNumCon
	Local nNovoValor := 0
	Local cLogCaixa := "AJUSTE VALOR DINHEIRO VENDA:" + CRLF
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local cBkpOrigem := ""
	Private oDlgAux, oValor
	Default lAuto := .T.

	//verifico se ja existe titulo SE1 de dinheiro para esta venda
	aDadosAux := BuscaSE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = '"+SIMBDIN+"' AND E1_PREFIXO = '"+SL1->L1_SERIE+"' AND E1_NUM = '"+SL1->L1_DOC+"'")
	if len(aDadosAux) > 0
		nRecSE1Din := aDadosAux[1][2]
		SE1->(DbGoTo(nRecSE1Din))
		if nOpc==3 .AND. !lAuto .AND. nValor == 0
			nValor := SE1->E1_VALOR
		endif
	endif

	SA6->(DbSetOrder(1))
	If (SA6->(DbSeek( xFilial("SA6") + SL1->L1_OPERADO))) //posiciona no banco do caixa (operador) que finalizou a venda
		cBanco    := SA6->A6_COD
		cAgencia  := SA6->A6_AGENCIA
		cNumCon   := SA6->A6_NUMCON
	else
		if !lAuto
			MsgInfo("Não foi possível encontrar banco do operador para realizar movimento.","Atenção")
		endif
		RestArea(aAreaSE1)
		RestArea(aArea)
		Return .F.
	endif

	if !lAuto
		lOk:= .F.
		cLogCaixa += "VALOR ANTERIOR: " + Transform(nValor ,"@E 999,999,999.99") + CRLF
		DEFINE MSDIALOG oDlgAux TITLE "Ajuste Recebido Dinheiro da Venda" STYLE DS_MODALFRAME FROM 000, 000  TO 200, 400 COLORS 0, 16777215 PIXEL

		oPnlDet := TScrollBox():New(oDlgAux,05,05,72,190,.F.,.T.,.T.)

		@ 027, 010 SAY "Valor:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
		@ 025, 050 MSGET oValor VAR nValor Picture "@E 999,999,999.99" SIZE 090, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL VALID nValor >= 0

		@ 082, 150 BUTTON oButton2 PROMPT "Salvar" SIZE 040, 012 OF oDlgAux PIXEL Action iif( nValor >= 0, (lOk:= .T., oDlgAux:End()) , MsgInfo("Dados não informados corretamente.", "Atenção"))
		oButton2:SetCSS( CSS_BTNAZUL )
		@ 082, 105 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgAux PIXEL Action (lOk:= .F., oDlgAux:End())

		ACTIVATE MSDIALOG oDlgAux CENTERED
	endif

	if lOk

		if nOpc==3 .AND. nRecSE1Din > 0 .AND. SE1->E1_VALOR == nValor
			if !lAuto
				MsgInfo("Valor titulo dinheiro nao precisa ser alterado!","Atenção")
			endif
			RestArea(aAreaSE1)
			RestArea(aArea)
			Return .T. //nao precisa ajustar
		endif

		BeginTran()
		
		cLogCaixa += "NOVO VALOR    : " + Transform(nValor ,"@E 999,999,999.99") + CRLF

		if nRecSE1Din == 0 .AND. nOpc <> 2 .AND. nValor > 0 //inclui

			//Montando array para execauto
			AADD(aFin040, {"E1_FILIAL"	,xFilial("SE1")				,Nil } )
			AADD(aFin040, {"E1_PREFIXO"	,IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE) ,Nil } )
			AADD(aFin040, {"E1_NUM"		,IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC)		,Nil } )
			AADD(aFin040, {"E1_PARCELA"	,Space(TamSx3("E1_PARCELA")[1]),Nil } )
			AADD(aFin040, {"E1_TIPO"	,SIMBDIN			  	    ,Nil } )
			AADD(aFin040, {"E1_NATUREZ"	,&(GetMV("MV_NATDINH"))		,Nil } )
			AADD(aFin040, {"E1_CLIENTE"	,SL1->L1_CLIENTE			,Nil } )
			AADD(aFin040, {"E1_LOJA"	,SL1->L1_LOJA				,Nil } )
			If SE1->(FieldPos("E1_DTLANC")) > 0
				AADD(aFin040, {"E1_DTLANC"	,SL1->L1_EMISNF			,Nil } )
			EndIf
			AADD(aFin040, {"E1_EMISSAO"	,SL1->L1_EMISNF				,Nil } )
			AADD(aFin040, {"E1_PORTADO"	, cBanco						,Nil } )
			AADD(aFin040, {"E1_AGEDEP"	, cAgencia						,Nil } )
			AADD(aFin040, {"E1_CONTA"	, cNumCon						,Nil } )
			AADD(aFin040, {"E1_VALOR"   ,nValor						,Nil})
			AADD(aFin040, {"E1_VENCTO"	,SL1->L1_EMISNF				,Nil } )
			AADD(aFin040, {"E1_VENCREA"	,DataValida(SL1->L1_EMISNF)	,Nil } )
			AADD(aFin040, {"E1_VEND1" 	,SL1->L1_VEND				,Nil } )
			AADD(aFin040, {"E1_COMIS1" 	,SL1->L1_COMIS				,Nil } )
			AADD(aFin040, {"E1_HIST" 	,"VENDA EM DINHEIRO"		,Nil } )
			AADD(aFin040, {"E1_BASCOM1" ,nValor						,Nil } )
			AADD(aFin040, {"E1_NUMNOTA" ,SL1->L1_DOC				,Nil } )
			AADD(aFin040, {"E1_SERIE" 	,SL1->L1_SERIE				,Nil } )
			AADD(aFin040, {"E1_VLRREAL" ,0							,Nil } )
			If SE1->(FieldPos("E1_XPLACA")) > 0
				AADD(aFin040, {"E1_XPLACA" 	,SL1->L1_PLACA			,Nil } )
			endif
			AADD(aFin040, {"E1_ORIGEM" 	,"TRETA028"		   			,Nil } )

			lMsErroAuto := .F. // variavel interna da rotina automatica
			lMsHelpAuto := .F.

			//Chama a funcao de gravacao automatica do FINA040
			SA3->(DbSetOrder(1)) //forço indice para nao dar erro no ExistCpo da validacao padrao.
			MSExecAuto({|x,y| FINA040(x,y)},aFin040,3)

			if lMsErroAuto
				MostraErro()
				DisarmTransaction()
				lOk := .F.
			Else
				//Baixar recebimento em dinheiro
				if !BxDinheiro(SE1->(RECNO()),cBanco,cAgencia,cNumCon, SL1->L1_HORA, "BAIXA REF VENDA EM DINHEIRO")
					DisarmTransaction()
					lOk := .F.
				endif
			EndIf

		else //alterar ou excluir titulo ja existente

			SE1->(DbGoTo(nRecSE1Din))

			if CancBxSE1() // Cancela baixa.
				SE1->(DbGoTo(nRecSE1Din))

				if nOpc == 1
					nNovoValor := SE1->E1_VALOR + nValor
				elseif nOpc == 2
					nNovoValor := SE1->E1_VALOR - nValor
				else
					nNovoValor := nValor
				endif

				//Montando array para execauto para alteção do valor
				AADD(aFin040, {"E1_FILIAL"	,SE1->E1_FILIAL				,Nil } )
				AADD(aFin040, {"E1_PREFIXO"	,SE1->E1_PREFIXO   		 	,Nil } )
				AADD(aFin040, {"E1_NUM"		,SE1->E1_NUM				,Nil } )
				AADD(aFin040, {"E1_PARCELA"	,SE1->E1_PARCELA			,Nil } )
				AADD(aFin040, {"E1_TIPO"	,SE1->E1_TIPO	  	    	,Nil } )
				AADD(aFin040, {"E1_CLIENTE" ,SE1->E1_CLIENTE 			,Nil } )
				AADD(aFin040, {"E1_LOJA" 	,SE1->E1_LOJA 				,Nil } )
				AADD(aFin040, {"E1_VALOR"   ,nNovoValor					,Nil } )
				AADD(aFin040, {"E1_BASCOM1" ,nNovoValor					,Nil } )
				AADD(aFin040, {"E1_VLRREAL" ,0						,Nil } )

				lMsErroAuto := .F. // variavel interna da rotina automatica
				lMsHelpAuto := .F.

				//apaga a origem para ser possível alteração/exclusão do titulo
				cBkpOrigem := SE1->E1_ORIGEM
				RecLock("SE1",.F.)
					SE1->E1_ORIGEM := ""
				SE1->(MsUnlock())

				//Chama a funcao de gravacao automatica do FINA040
				MSExecAuto({|x,y| FINA040(x,y)},aFin040, iif(nNovoValor > 0,4,5))

				//volta a origem 
				if nNovoValor > 0
					RecLock("SE1",.F.)
						SE1->E1_ORIGEM := cBkpOrigem
					SE1->(MsUnlock())
				endif
				
				If lMsErroAuto
					MostraErro()
					DisarmTransaction()
					lOk := .F.
				Else
					//Baixar recebimento em dinheiro
					if nNovoValor > 0 .AND. !BxDinheiro(SE1->(RECNO()),cBanco,cAgencia,cNumCon, SL1->L1_HORA, "BAIXA REF VENDA EM DINHEIRO")
						DisarmTransaction()
						lOk := .F.
					endif
				EndIf
			else
				DisarmTransaction()
				lOk := .F.
			EndIf

		endif

		if lOk .AND. lAtuTroco
			if !AjuSL1Troco(lAuto)
				DisarmTransaction()
				lOk := .F.
			endif
		endif

		if lOk .AND. !lAuto .AND. lLogCaixa
			GrvLogConf("2","A", cLogCaixa, IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC), IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE))
		endif

		EndTran()

	endif

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

	RestArea(aAreaSE1)
	RestArea(aArea)

Return lOk

//--------------------------------------------------------------------------------------
// Função para baixa de um titulo dinheiro
//--------------------------------------------------------------------------------------
Static Function BxDinheiro(nRec,cBanco,cAgencia,cNumCon,cHora,cHist)

	Local lRet := .T.
	Local aBaixa
	Local cBkpFunNam := FunName()
	Local dBkpDBase := dDataBase
	Default cHora := SLW->LW_HRABERT

	dDataBase := SE1->E1_EMISSAO

	SE1->(DbGoto(nRec))

	aBaixa := {;
	{"E1_PREFIXO"   ,SE1->E1_PREFIXO	,Nil},;
	{"E1_NUM"       ,SE1->E1_NUM		,Nil},;
	{"E1_PARCELA"   ,SE1->E1_PARCELA	,Nil},;
	{"E1_TIPO"      ,SE1->E1_TIPO		,Nil},;
	{"E1_CLIENTE" 	,SE1->E1_CLIENTE 	,Nil},;
	{"E1_LOJA" 		,SE1->E1_LOJA 		,Nil},;
	{"AUTMOTBX"     ,"NOR" 				,Nil},;
	{"AUTBANCO"     ,cBanco 			,Nil},;
	{"AUTAGENCIA"   ,cAgencia			,Nil},;
	{"AUTCONTA"     ,cNumCon			,Nil},;
	{"AUTDTBAIXA"   ,dDataBase      	,Nil},;
	{"AUTDTCREDITO" ,dDataBase      	,Nil},;
	{"AUTHIST"      ,cHist				,Nil},;
	{"AUTJUROS"     ,0                  ,Nil},;
	{"AUTVALREC"    ,SE1->E1_VALOR		,Nil}}

	lMsErroAuto := .F. // variavel interna da rotina automatica
	lMsHelpAuto := .F.

	SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)					
	MSExecAuto({|x,y| Fina070(x,y)}, aBaixa, 3) //Baixa conta a receber
	SetFunName(cBkpFunNam)

	If lMsErroAuto
		MostraErro()
		lRet := .F.
	Else
		Reclock("SE5",.F.) //grava dados caixa
		SE5->E5_NUMMOV  := SLW->LW_NUMMOV
		if SE5->(FieldPos("E5_XPDV")) > 0
			SE5->E5_XPDV 	:= SLW->LW_PDV
			SE5->E5_XESTAC 	:= SLW->LW_ESTACAO
			SE5->E5_XHORA 	:= cHora
		endif
		SE5->(MsUnlock())
	EndIf

	dDataBase := dBkpDBase
Return lRet

//--------------------------------------------------------------------------------------
// Função que faz ajuste de troco. Ja deve estar posicionado na SL1.
//--------------------------------------------------------------------------------------
User Function T028AJTR(lAuto, bRefresh)
	lOk := AjuSL1Troco(lAuto, bRefresh)
Return lOk
Static Function AjuSL1Troco(lAuto, bRefresh)

	Local lOk := .T.
	Local lAchouSE5 := .F.
	Local nTotTroco := 0
	Local nDifTroco := 0
	Local aValores := {} //{cL1Doc, cL1Serie, lOk, nTotProd, nTotTit, nTotTroDin, cObs, aIdCorrige, nTotTroCht}
	Local aDados := {}
	Local cDescErro:=""
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo
	Local cIdFKAux := ""
	Default lAuto := .T.

	SA6->(DbSetOrder(1))
	If (SA6->(DbSeek( xFilial("SA6") + SL1->L1_OPERADO))) //posiciona no banco do caixa (operador) que finalizou a venda
		cBanco    := SA6->A6_COD
		cAgencia  := SA6->A6_AGENCIA
		cNumCon   := SA6->A6_NUMCON
	else
		if !lAuto
			MsgInfo("Não foi possível encontrar banco do operador para realizar movimento.","Atenção")
		endif
		Return .F.
	endif
	
	aSL1 := SL1->(GetArea())
	aValores := AvalFinSL1(SL1->L1_DOC, SL1->L1_SERIE, .T.) //pegando valores financeiros do cupom
	RestArea(aSL1)

	if !empty(aValores)
		nTotTroco := aValores[5] - aValores[4] //verifico o total do troco que deveria ser

		if nTotTroco >= 0 //somente se total recebido for maior que total dos produtos

			if nTotTroco == 0 //se nao deve ter troco, vejo se tem que excluir algo

				//Posiciono no SE5 do troco
				lAchouSE5 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'",.f.,.f.) > 0

				if lAchouSE5 //removo troco
					if Upper(SE5->E5_RECONC) == "X"
						if !lAuto
							MsgAlert("Ação não permitida. Movimento de troco já se encontra conciliado!","Atenção")
						endif
						lOk := .F.
					elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
						if !lAuto
							MsgAlert("Ação não permitida. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
						endif
						lOk := .F.
					else
						cIdFKAux := SE5->E5_IDORIG
						If ExistFunc("LjNewGrvTC") .And. LjNewGrvTC() //Verifica se o sistema est?atualizado para executar o novo procedimento para grava?o dos movimentos de troco.
							aDados := {}
							cDescErro:=""
							lMsErroAuto := .F.
							aAdd( aDados, {"E5_DATA"    , SE5->E5_DATA     	, NIL} )
							aAdd( aDados, {"E5_MOEDA" 	, SE5->E5_MOEDA    	, NIL} )
							aAdd( aDados, {"E5_VALOR"   , SE5->E5_VALOR    	, NIL} )
							aAdd( aDados, {"E5_NATUREZ" , SE5->E5_NATUREZ  	, NIL} )
							aAdd( aDados, {"E5_BANCO" 	, SE5->E5_BANCO  	, NIL} )
							aAdd( aDados, {"E5_AGENCIA" , SE5->E5_AGENCIA  	, NIL} )
							aAdd( aDados, {"E5_CONTA" 	, SE5->E5_CONTA  	, NIL} )
							aAdd( aDados, {"E5_HISTOR" 	, SE5->E5_HISTOR  	, NIL} )
							aAdd( aDados, {"E5_TIPOLAN" , SE5->E5_TIPOLAN  	, NIL} )

							MsExecAuto( {|w,x, y| FINA100(w, x, y)}, 0, aDados, 5 ) //5=Exclusão de Movimento

							If lMsErroAuto
								cDescErro:= MostraErro("\")
								cDescErro := "Erro de Exclusão do troco na Rotina Automatica FINA100:" + Chr(13) + cDescErro 
								lOk := .F.
							EndIf
							If !lOk .AND. !lAuto
								MsgAlert(cDescErro,"Atenção")
							EndIf
						else
							RecLock("SE5", .F.)
							SE5->(DbDelete())
							SE5->(MsUnlock())
						endif

						//Excluindo as FK5 que fica la (são duas, do mov e estorno)
						if lOk .AND. !empty(cIdFKAux)
							FKA->(DbSetOrder(3)) //FKA_FILIAL+FKA_TABORI+FKA_IDORIG
							FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
							if FKA->(DbSeek(xFilial("FKA") +"FK5"+ cIdFKAux ))
								cIdFKAux := FKA->FKA_IDPROC
								FKA->(DbSetOrder(2)) //FKA_FILIAL+FKA_IDPROC+FKA_IDORIG+FKA_TABORI
								if FKA->(DbSeek(xFilial("FKA") + cIdFKAux ))
									While FKA->(!Eof()) .AND. FKA->FKA_FILIAL+FKA->FKA_IDPROC == xFilial("FKA") + cIdFKAux
										if FKA->FKA_TABORI == "FK5" .AND. FK5->(DbSeek(xFilial("FK5") + FKA->FKA_IDORIG ))
											RecLock("FK5", .F.)
											FK5->(DbDelete())
											FK5->(MsUnlock())
										endif
										FKA->(DbSkip())
									enddo
								endif
							endif
						endif
					endif
				elseif !lAuto
					MsgInfo("Não há divergências de troco nesta venda!","Atenção")
				endif

			elseif nTotTroco > (aValores[6] + aValores[9] + aValores[10]) //se troco é maior do que ja tem

				//Incluir diferença do troco
				nDifTroco := nTotTroco - (aValores[6] + aValores[9] + aValores[10])

				//Vejo se ja tem SE5 do troco, com as chaves corretas
				lAchouSE5 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'",.f., .f.) > 0

				if lAchouSE5 //se ja existe movimento, com chaves ok, apenas ajusto valor
					if Upper(SE5->E5_RECONC) == "X"
						if !lAuto
							MsgAlert("Ação não permitida. Movimento de troco já se encontra conciliado!","Atenção")
						endif
						lOk := .F.
					elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
						if !lAuto
							MsgAlert("Ação não permitida. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
						endif
						lOk := .F.
					else
						RecLock("SE5", .F.)
						SE5->E5_VALOR += nDifTroco
						SE5->(MsUnlock())
						
						FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
						if !empty(SE5->E5_IDORIG) .AND. FK5->(DbSeek(xFilial("FK5") + SE5->E5_IDORIG ))
							RecLock("FK5", .F.)
							FK5->FK5_VALOR += nDifTroco
							FK5->(MsUnlock())
						endif
					endif
				else

					//verifico se o movimento existe, mas sem as chaves do caixa, para ajustar chave
					lAchouSE5 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'", .F., .T.) > 0
					if lAchouSE5
						if Upper(SE5->E5_RECONC) == "X"
							if !lAuto
								MsgAlert("Ação não permitida. Movimento de troco já se encontra conciliado!","Atenção")
							endif
							lOk := .F.
						elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
							if !lAuto
								MsgAlert("Ação não permitida. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
							endif
							lOk := .F.
						else
							RecLock("SE5", .F.)
							SE5->E5_NUMMOV	:=	SLW->LW_NUMMOV
							SE5->E5_VALOR	:= nTotTroco - aValores[9] - aValores[10]
							if SE5->(FieldPos("E5_XPDV")) > 0
								SE5->E5_XPDV	:=	SLW->LW_PDV
								SE5->E5_XESTAC	:=	SLW->LW_ESTACAO
								SE5->E5_XHORA	:=	SL1->L1_HORA
							endif
							SE5->(MsUnlock())
							
							FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
							if !empty(SE5->E5_IDORIG) .AND. FK5->(DbSeek(xFilial("FK5") + SE5->E5_IDORIG ))
								RecLock("FK5", .F.)
								FK5->FK5_VALOR := nTotTroco - aValores[9] - aValores[10]
								FK5->(MsUnlock())
							endif
						endif
					else
						If ExistFunc("LjNewGrvTC") .And. LjNewGrvTC() //Verifica se o sistema est?atualizado para executar o novo procedimento para grava?o dos movimentos de troco.
							aDados := {}
							cDescErro:=""
							lMsErroAuto := .F.
							aAdd( aDados, {"E5_DATA"    , SL1->L1_EMISNF  , NIL} )
							aAdd( aDados, {"E5_DTDIGIT" , SL1->L1_EMISNF  , NIL} )
							aAdd( aDados, {"E5_DTDISPO" , SL1->L1_EMISNF  , NIL} )
							aAdd( aDados, {"E5_VALOR"   , nDifTroco    	  , NIL} )
							aAdd( aDados, {"E5_MOEDA"   , "TC"      , NIL} )
							aAdd( aDados, {"E5_MOTBX"   , "NOR"     , NIL} )
							if SuperGetMv("TP_MTPDOCT",,.T.) //muda troco de VL para TR?
								aAdd( aDados, {"E5_TIPODOC" , "TR"  , NIL} )
							else
								aAdd( aDados, {"E5_TIPODOC" , "VL"  , NIL} )
							endif
							aAdd( aDados, {"E5_BANCO"   , SLW->LW_OPERADO   , NIL} )
							aAdd( aDados, {"E5_AGENCIA" , SA6->A6_AGENCIA  	, NIL} )
							aAdd( aDados, {"E5_CONTA"   , SA6->A6_NUMCON  	, NIL} )
							aAdd( aDados, {"E5_NATUREZ" , StrTran(StrTran(GetMV("MV_NATTROC"),"'"),'"') , NIL} )
							aAdd( aDados, {"E5_HISTOR"  , "Registro de Saida de Troco"   , NIL} )
							aAdd( aDados, {"E5_PREFIXO" , IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)  , NIL} )
							aAdd( aDados, {"E5_NUMERO"  , IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC)   , NIL} )
							aAdd( aDados, {"E5_PARCELA" , PadR("", TamSx3("E5_PARCELA")[1])  , NIL} )
							aAdd( aDados, {"E5_TIPO"    , PadR("", TamSx3("E5_TIPO"   )[1])  , NIL} )
							aAdd( aDados, {"E5_SITUA"   , ""    , NIL} )
							aAdd( aDados, {"E5_NUMMOV"  , SLW->LW_NUMMOV   , NIL} )
							aAdd( aDados, {"E5_SEQ"     , StrZero(1,TamSX3("E5_SEQ")[1]), NIL} )

							//Efetua a inclusão do Troco via Rotina Automática FINA100 (Movimentos Bancários)
							MsExecAuto( {|w,x, y| FINA100(w, x, y)}, 0, aDados, 3 )//3=Inclusão de Movimento "Pagar"
							
							If lMsErroAuto
								cDescErro:= MostraErro("\")
								cDescErro := "Erro de Inclusao do troco na Rotina Automatica FINA100:" + Chr(13) + cDescErro 
								lOk := .F.
							Else 
								/* A gravação do campo SE5->E5_CLIFOR neste ponto, foi necessária devido, se passada via MsExecAuto para função FINA100(),
								iria efetuar a consulta da informação, a ser gravada no campo E5_CLIFOR, na tabela SA2.
								Desta forma, por se tratar de um registro de troco, entenderia ser uma saída ou pagamento e na função FINA100, 
								realizaria a consulta de forma errada na tabela SA2. 
								*/
								RecLock("SE5",.F.)
								SE5->E5_CLIFOR  := SL1->L1_CLIENTE
								SE5->E5_LOJA    := SL1->L1_LOJA
								SE5->E5_ORIGEM	:=	"TRETA028"
								if SE5->(FieldPos("E5_XPDV")) > 0
									SE5->E5_XPDV	:=	SLW->LW_PDV
									SE5->E5_XESTAC	:=	SLW->LW_ESTACAO
									SE5->E5_XHORA	:=	SL1->L1_HORA
								endif
								SE5->(MsUnlock())        
							EndIf

							If !lOk .AND. !lAuto
								MsgAlert(cDescErro,"Atenção")
							EndIf

						else
							//incluir movimento
							RecLock("SE5",.T.)
							SE5->E5_FILIAL	:=	xFilial("SE5")
							SE5->E5_DATA	:=	SL1->L1_EMISNF
							SE5->E5_MOEDA	:=	"TC"
							SE5->E5_VALOR	:=	nDifTroco
							SE5->E5_NATUREZ	:=	StrTran(StrTran(GetMV("MV_NATTROC"),"'"),'"')
							SE5->E5_BANCO	:=	SLW->LW_OPERADO
							SE5->E5_AGENCIA	:=	SA6->A6_AGENCIA
							SE5->E5_CONTA	:=	SA6->A6_NUMCON
							SE5->E5_RECPAG	:=	"P"
							SE5->E5_HISTOR	:=	"Registro de Saida de Troco"
							if SuperGetMv("TP_MTPDOCT",,.T.) //muda troco de VL para TR?
								SE5->E5_TIPODOC	:=	"TR"
							else
								SE5->E5_TIPODOC	:=	"VL"
							endif
							SE5->E5_VLMOED2	:=	nDifTroco
							SE5->E5_PREFIXO	:=	IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)
							SE5->E5_NUMERO	:=	IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC)
							SE5->E5_CLIFOR	:=	SL1->L1_CLIENTE
							SE5->E5_LOJA	:=	SL1->L1_LOJA
							SE5->E5_DTDIGIT	:=	SL1->L1_EMISNF
							SE5->E5_MOTBX	:=	"NOR"
							SE5->E5_SEQ		:=	"01"
							SE5->E5_DTDISPO	:=	SL1->L1_EMISNF
							SE5->E5_ORIGEM	:=	"TRETA028"
							SE5->E5_NUMMOV	:=	SLW->LW_NUMMOV
							if SE5->(FieldPos("E5_XPDV")) > 0
								SE5->E5_XPDV	:=	SLW->LW_PDV
								SE5->E5_XESTAC	:=	SLW->LW_ESTACAO
								SE5->E5_XHORA	:=	SL1->L1_HORA
							endif
							SE5->(MsUnLock())
						endif
					endif

				endif
			elseif nTotTroco < (aValores[6]+ aValores[9] + aValores[10]) //se troco é menor do que ja tem

				nDifTroco := (aValores[6]+ aValores[9] + aValores[10]) - nTotTroco

				//Posiciono no SE5 do troco
				lAchouSE5 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'",.F.,.F.) > 0

				//Removo diferença somente caso tenha saldo em dinheiro
				if aValores[6] >= nDifTroco
					if lAchouSE5
						if Upper(SE5->E5_RECONC) == "X"
							if !lAuto
								MsgAlert("Ação não permitida. Movimento de troco já se encontra conciliado!","Atenção")
							endif
							lOk := .F.
						elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
							if !lAuto
								MsgAlert("Ação não permitida. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
							endif
							lOk := .F.
						else
							//se tenho que excluir
							if (SE5->E5_VALOR - nDifTroco) <= 0
								cIdFKAux := SE5->E5_IDORIG
								If ExistFunc("LjNewGrvTC") .And. LjNewGrvTC() //Verifica se o sistema est?atualizado para executar o novo procedimento para grava?o dos movimentos de troco.
									aDados := {}
									cDescErro:=""
									lMsErroAuto := .F.
									aAdd( aDados, {"E5_DATA"    , SE5->E5_DATA     	, NIL} )
									aAdd( aDados, {"E5_MOEDA" 	, SE5->E5_MOEDA    	, NIL} )
									aAdd( aDados, {"E5_VALOR"   , SE5->E5_VALOR    	, NIL} )
									aAdd( aDados, {"E5_NATUREZ" , SE5->E5_NATUREZ  	, NIL} )
									aAdd( aDados, {"E5_BANCO" 	, SE5->E5_BANCO  	, NIL} )
									aAdd( aDados, {"E5_AGENCIA" , SE5->E5_AGENCIA  	, NIL} )
									aAdd( aDados, {"E5_CONTA" 	, SE5->E5_CONTA  	, NIL} )
									aAdd( aDados, {"E5_HISTOR" 	, SE5->E5_HISTOR  	, NIL} )
									aAdd( aDados, {"E5_TIPOLAN" , SE5->E5_TIPOLAN  	, NIL} )

									MsExecAuto( {|w,x, y| FINA100(w, x, y)}, 0, aDados, 5 ) //5=Exclusão de Movimento

									If lMsErroAuto
										cDescErro:= MostraErro("\")
										cDescErro := "Erro de Exclusão do troco na Rotina Automatica FINA100:" + Chr(13) + cDescErro 
										lOk := .F.
									EndIf
									If !lOk .AND. !lAuto
										MsgAlert(cDescErro,"Atenção")
									EndIf
								else
									RecLock("SE5", .F.)
										SE5->(DbDelete())
									SE5->(MsUnlock())
								endif

								//Excluindo as FK5 que fica la (são duas, do mov e estorno)
								if lOk .AND. !empty(cIdFKAux)
									FKA->(DbSetOrder(3)) //FKA_FILIAL+FKA_TABORI+FKA_IDORIG
									FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
									if FKA->(DbSeek(xFilial("FKA") +"FK5"+ cIdFKAux ))
										cIdFKAux := FKA->FKA_IDPROC
										FKA->(DbSetOrder(2)) //FKA_FILIAL+FKA_IDPROC+FKA_IDORIG+FKA_TABORI
										if FKA->(DbSeek(xFilial("FKA") + cIdFKAux ))
											While FKA->(!Eof()) .AND. FKA->FKA_FILIAL+FKA->FKA_IDPROC == xFilial("FKA") + cIdFKAux
												if FKA->FKA_TABORI == "FK5" .AND. FK5->(DbSeek(xFilial("FK5") + FKA->FKA_IDORIG ))
													RecLock("FK5", .F.)
													FK5->(DbDelete())
													FK5->(MsUnlock())
												endif
												FKA->(DbSkip())
											enddo
										endif
									endif
								endif
							else //senao so altero valor
								RecLock("SE5", .F.)
								SE5->E5_VALOR -= nDifTroco
								SE5->(MsUnlock())

								FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
								if !empty(SE5->E5_IDORIG) .AND. FK5->(DbSeek(xFilial("FK5") + SE5->E5_IDORIG ))
									RecLock("FK5", .F.)
									FK5->FK5_VALOR -= nDifTroco
									FK5->(MsUnlock())
								endif
							endif
						endif
					else
						//Posiciono no SE5 do troco
						lAchouSE5 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'", .F., .T.) > 0
						if lAchouSE5
							if Upper(SE5->E5_RECONC) == "X"
								if !lAuto
									MsgAlert("Ação não permitida. Movimento de troco já se encontra conciliado!","Atenção")
								endif
								lOk := .F.
							elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
								if !lAuto
									MsgAlert("Ação não permitida. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
								endif
								lOk := .F.
							else
								//se tenho que excluir
								if (nTotTroco - aValores[9] - aValores[10]) <= 0
									cIdFKAux := SE5->E5_IDORIG
									If ExistFunc("LjNewGrvTC") .And. LjNewGrvTC() //Verifica se o sistema est?atualizado para executar o novo procedimento para grava?o dos movimentos de troco.
										aDados := {}
										cDescErro:=""
										lMsErroAuto := .F.
										aAdd( aDados, {"E5_DATA"    , SE5->E5_DATA     	, NIL} )
										aAdd( aDados, {"E5_MOEDA" 	, SE5->E5_MOEDA    	, NIL} )
										aAdd( aDados, {"E5_VALOR"   , SE5->E5_VALOR    	, NIL} )
										aAdd( aDados, {"E5_NATUREZ" , SE5->E5_NATUREZ  	, NIL} )
										aAdd( aDados, {"E5_BANCO" 	, SE5->E5_BANCO  	, NIL} )
										aAdd( aDados, {"E5_AGENCIA" , SE5->E5_AGENCIA  	, NIL} )
										aAdd( aDados, {"E5_CONTA" 	, SE5->E5_CONTA  	, NIL} )
										aAdd( aDados, {"E5_HISTOR" 	, SE5->E5_HISTOR  	, NIL} )
										aAdd( aDados, {"E5_TIPOLAN" , SE5->E5_TIPOLAN  	, NIL} )

										MsExecAuto( {|w,x, y| FINA100(w, x, y)}, 0, aDados, 5 ) //5=Exclusão de Movimento

										If lMsErroAuto
											cDescErro:= MostraErro("\")
											cDescErro := "Erro de Exclusão do troco na Rotina Automatica FINA100:" + Chr(13) + cDescErro 
											lOk := .F.
										EndIf
										If !lOk .AND. !lAuto
											MsgAlert(cDescErro,"Atenção")
										EndIf
									else
										RecLock("SE5", .F.)
											SE5->(DbDelete())
										SE5->(MsUnlock())
									endif

									//Excluindo as FK5 que fica la (são duas, do mov e estorno)
									if lOk .AND. !empty(cIdFKAux)
										FKA->(DbSetOrder(3)) //FKA_FILIAL+FKA_TABORI+FKA_IDORIG
										FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
										if FKA->(DbSeek(xFilial("FKA") +"FK5"+ cIdFKAux ))
											cIdFKAux := FKA->FKA_IDPROC
											FKA->(DbSetOrder(2)) //FKA_FILIAL+FKA_IDPROC+FKA_IDORIG+FKA_TABORI
											if FKA->(DbSeek(xFilial("FKA") + cIdFKAux ))
												While FKA->(!Eof()) .AND. FKA->FKA_FILIAL+FKA->FKA_IDPROC == xFilial("FKA") + cIdFKAux
													if FKA->FKA_TABORI == "FK5" .AND. FK5->(DbSeek(xFilial("FK5") + FKA->FKA_IDORIG ))
														RecLock("FK5", .F.)
														FK5->(DbDelete())
														FK5->(MsUnlock())
													endif
													FKA->(DbSkip())
												enddo
											endif
										endif
									endif
								else //senao so altero valor
									RecLock("SE5", .F.)
									SE5->E5_NUMMOV	:= SLW->LW_NUMMOV
									SE5->E5_VALOR	:= nTotTroco - aValores[9] - aValores[10]
									if SE5->(FieldPos("E5_XPDV")) > 0
										SE5->E5_XPDV	:=	SLW->LW_PDV
										SE5->E5_XESTAC	:=	SLW->LW_ESTACAO
										SE5->E5_XHORA	:=	SL1->L1_HORA
									endif
									SE5->(MsUnlock())

									FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
									if !empty(SE5->E5_IDORIG) .AND. FK5->(DbSeek(xFilial("FK5") + SE5->E5_IDORIG ))
										RecLock("FK5", .F.)
										FK5->FK5_VALOR := nTotTroco - aValores[9] - aValores[10]
										FK5->(MsUnlock())
									endif
								endif
							endif
						else
							if !lAuto
								MsgAlert("Falha ao encontrar movimento de troco para a manutenção!","Atenção")
							endif
							lOk := .F.
						endif
					endif
				else
					if !lAuto
						MsgAlert("Não há saldo de troco em dinheiro suficiente para remover a diferença encontrada!","Atenção")
					endif
					lOk := .F.
				endif

			elseif !lAuto
				MsgInfo("Não há divergências de troco nesta venda!","Atenção")
			endif
		else
			if !lAuto
				MsgAlert("Total recebido é menor que total dos produtos. Ação nao permitida!","Atenção")
			endif
			lOk := .F.
		endif

		if SL1->(!Eof()) .and. lMvPosto //se posto, atualizo os valores troco em cheque e vale na SL1, para contabilização
			RecLock("SL1",.F.)
				SL1->L1_XTROCCH := aValores[9]
				SL1->L1_XTROCVL := aValores[10]
			SL1->(MSUnlock())
		endif
	else
		if !lAuto
			MsgAlert("Falha ao buscar valores financeiros da venda!","Atenção")
		endif
		lOk := .F.
	endif

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return lOk

//------------------------------------------------------------
// faz a alteração do vendedor da venda
//------------------------------------------------------------
Static Function AltSL1Vend(bRefresh)
	
	Local lOk := .F.
	Local oPnlDet, oDsVend
	Local cDsVend := Posicione("SA3",1,xFilial("SA3")+SL1->L1_VEND,"A3_NOME")
	Local oGetVende
	Local cGetVende := SL1->L1_VEND
	Private oDlgAux

	DEFINE MSDIALOG oDlgAux TITLE "Alterar Vendedor da Venda" STYLE DS_MODALFRAME FROM 000, 000  TO 200, 400 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgAux,05,05,72,190,.F.,.T.,.T.)

	@ 027, 010 SAY "Vendedor:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 025, 050 MSGET oGetVende VAR cGetVende WHEN .T. SIZE 035, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL F3 "SA3" VALID empty(cGetVende) .OR. (!empty(cDsVend := Posicione("SA3",1,xFilial("SA3")+cGetVende,"A3_NOME")) .AND. oDlgAux:Refresh() )
	@ 025, 090 MSGET oDsVend VAR cDsVend WHEN .F. SIZE 90, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 082, 150 BUTTON oButton2 PROMPT "Confirmar" SIZE 040, 012 OF oDlgAux PIXEL Action iif( !empty(cDsVend), (lOk:= .T., oDlgAux:End()) , MsgInfo("Dados não informados corretamente.", "Atenção"))
	oButton2:SetCSS( CSS_BTNAZUL )
	@ 082, 105 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgAux PIXEL Action (lOk:= .F., oDlgAux:End())

	ACTIVATE MSDIALOG oDlgAux CENTERED

	if lOk
		RecLock("SL1",.F.)
			SL1->L1_VEND := cGetVende
		SL1->(MsUnlock())
	endif

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Funçao para ajuste de titulos R$ quando nao baixados/compensados
//--------------------------------------------------------------------------------------
Static Function AjuSL1Baixa()

	Local lRet := .F.
	Local aCampos := {"E1_TIPO","E1_BAIXA"}
	Local aDados
	Local nRecSE1Din := 0
	Local cTipo := ""
	Local nX

	//buscando total dos titulos
	aDados := BuscaSE1(aCampos, "E1_PREFIXO='"+SL1->L1_SERIE+"' AND E1_NUM='"+SL1->L1_DOC+"' AND E1_TIPO<>'NCC'",,.F.,.F.)
	For nX:=1 To Len(aDados)

		cTipo := Alltrim(aDados[nX][aScan(aCampos,"E1_TIPO")])

		//ajuste dinheiro nao baixado
		if Alltrim(cTipo) == SIMBDIN .AND. empty(aDados[nX][aScan(aCampos,"E1_BAIXA")])
			SA6->(DbSetOrder(1))
			If (SA6->(DbSeek( xFilial("SA6") + SL1->L1_OPERADO))) //posiciona no banco do caixa (operador) que finalizou a venda
				nRecSE1Din := aDados[nX][len(aDados[nX])-1]
				if BxDinheiro(nRecSE1Din,SA6->A6_COD,SA6->A6_AGENCIA,SA6->A6_NUMCON, SL1->L1_HORA,"BAIXA REF VENDA EM DINHEIRO")
					lRet := .T.
				endif
			endif
		endif

	Next nX

Return lRet

//--------------------------------------------------------------------------------------
// Função para tentar localizar abastecimento que nao ficou vinculado na SL2
//--------------------------------------------------------------------------------------
Static Function CorrCodAbast(cNumOrc)

	Local cChave := ""
	Local aArea := GetArea()
	Local aAreaSL2 := SL2->(GetArea())
	Local cQry := ""
	Local lRet := .F.

	// verifica se tem algum abastecimento "solto" sem baixar
	cQry := " SELECT SL2.L2_FILIAL, SL2.L2_NUM, SL2.L2_ITEM, SL2.L2_PRODUTO, SL1.L1_EMISNF, SL2.L2_DOC, SL2.L2_SERIE, "
	cQry += " SL2.L2_MIDCOD, MID.MID_CODABA, SL2.L2_QUANT, MID.MID_NUMORC, MID.MID_AFERIR , MID.R_E_C_N_O_ RECMID "
	cQry += " FROM " + RetSqlName("SL2") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2 "
	cQry += " INNER JOIN " + RetSqlName("SL1") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 "
	cQry += "	ON ( SL1.D_E_L_E_T_ <> '*' AND SL1.L1_FILIAL = SL2.L2_FILIAL AND SL1.L1_NUM = SL2.L2_NUM AND SL1.L1_DOC = SL2.L2_DOC AND SL1.L1_SERIE = SL2.L2_SERIE ) "
	cQry += " INNER JOIN " + RetSqlName("MID") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" MID "
	cQry += "	ON( MID.D_E_L_E_T_ <> '*' "
	cQry += "	AND MID.MID_FILIAL = SL2.L2_FILIAL "
	cQry += "	AND MID.MID_LITABA = SL2.L2_QUANT "
	cQry += "	AND MID.MID_DATACO = SL2.L2_EMISSAO "
	cQry += "	AND MID.MID_XPROD = SL2.L2_PRODUTO ) "
	cQry += " WHERE SL2.D_E_L_E_T_ <> '*' "
	cQry += "	AND SL2.L2_MIDCOD = '        ' "
	cQry += "	AND NOT EXISTS ( SELECT L2_MIDCOD FROM " + RetSqlName("SL2") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" L2 "
	cQry += "		WHERE L2.D_E_L_E_T_ <> '*' "
	cQry += "			AND L2.L2_FILIAL = MID.MID_FILIAL "
	cQry += "			AND L2.L2_MIDCOD = MID.MID_CODABA ) "
	cQry += " 	AND SL1.L1_SITUA = 'OK'" //L1_SITUA <> 'ER'
	cQry += " 	AND SL1.L1_FILIAL = '"+xFilial("SL1")+"' "
	cQry += " 	AND SL1.L1_NUM = '"+cNumOrc+"' "
	cQry += " ORDER BY L2_FILIAL, L1_EMISNF, L2_DOC, L2_SERIE, MID_NUMORC "

	If Select("QRYSL1") > 0
		QRYSL1->(DbCloseArea())
	EndIf

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYSL1" // Cria uma nova area com o resultado do query

	QRYSL1->(DbGoTop())

	cChave := ""
	SL2->(DbSetorder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO

	While QRYSL1->(!Eof())

		If cChave <> QRYSL1->L2_FILIAL+QRYSL1->L2_NUM+QRYSL1->L2_ITEM+QRYSL1->L2_PRODUTO
			cChave := QRYSL1->L2_FILIAL+QRYSL1->L2_NUM+QRYSL1->L2_ITEM+QRYSL1->L2_PRODUTO

			If SL2->(DbSeek(cChave)) .and. SL2->L2_MIDCOD == '        ' .and. !Empty(QRYSL1->MID_CODABA)
				if QRYSL1->MID_AFERIR<>'S' .OR. QRYSL1->L2_QUANT > 25 //nao é aferiçao
					RecLock("SL2",.F.)
					SL2->L2_MIDCOD := QRYSL1->MID_CODABA
					SL2->(MsUnlock())

					MID->(DbGoTo(QRYSL1->RECMID))
					RecLock("MID",.F.)
					MID->MID_NUMORC := cNumOrc //numero do orçamento
					MID->(MsUnlock())

					lRet := .T.
				else
					MsgAlert("Abastecimento encontrado, mas está como AFERIÇÃO. Abatecimento: " + QRYSL1->MID_CODABA + ".","Atenção")
				endif
			EndIf
		EndIf

		QRYSL1->(DbSkip())
	EndDo

	QRYSL1->(DbCloseArea())

	RestArea(aAreaSL2)
	RestArea(aArea)

Return lRet

//--------------------------------------------------------------------------------------
// Função para realizar troca de forma de pagamento de vendas.
// nTipo : 1=Venda;2=Compensaçao
// Ja deve estar posicionado na SL1 ou UC0
//--------------------------------------------------------------------------------------
User Function TR028TFO(nTipo, bRefresh)
Return TrocaForm(nTipo, bRefresh)
Static Function TrocaForm(nTipo, bRefresh)

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aCamposOld := {"MARK","E1_EMISSAO","E1_TIPO","E1_VLRREAL","E1_VENCREA","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_HIST","E1_FATURA"}
	Local bMarcaTodos := {|x| iif(x[1]=="LBNO", x[1]:="LBOK", x[1]:="LBNO")  }
	Local oGetDoc, oGetCli, oGetLoj, oGetNome
	//Local cCliPad := AllTrim(GetMv("MV_CLIPAD"))+AllTrim(GetMv("MV_LOJAPAD"))
	Local lAcessTF := SuperGetMv("TP_ACESSTF",,.F.) //Define se valida acesso na opção troca forma
	Local nPosFatura 	:= aScan(aCamposOld, "E1_FATURA")
	Local nPosPrefixo	:= aScan(aCamposOld, "E1_PREFIXO")
	Local nPosNumero	:= aScan(aCamposOld, "E1_NUM")
	Local nPosParcela	:= aScan(aCamposOld, "E1_PARCELA")
	Local nPosTipo	 	:= aScan(aCamposOld, "E1_TIPO")
	Local nPosCliente	:= aScan(aCamposOld, "E1_CLIENTE")
	Local nPosloja	 	:= aScan(aCamposOld, "E1_LOJA")
	Private lMvFpCli := SuperGetMv("MV_XTFPCLI",,.T.) //Define se permite alterar cliente das novas parcelas
	Private cMvFpCli := SuperGetMv("MV_XFPGCLI",,"NP,CR") //Define as formas de pagamento que pode ser trocado o cliente

	Private nPosValOld, nPosValNew
	Private bAtuSaldo := {|| nSaldoFPG:=0, aEval(oMsFPagOld:aCols, {|x| iif(x[1]=="LBOK",nSaldoFPG += x[nPosValOld],) }), aEval(oMsFPagNew:aCols, {|x| iif( !x[len(x)] ,nSaldoFPG -= x[nPosValNew],) }), oSaldoFPG:Refresh(), .T. }
	Private lMARKALL := .F.
	Private oMsFPagOld
	Private oMsFPagNew
	Private oDlgDet
	Private oSaldoFPG
	Private nSaldoFPG := 0
	Private aInfComplem := {} //grava informações complementares da forma de pagamento
	//Novos Campos
	Private cDocTroca
	Private cCliTroca
	Private cLojTroca
	Private cNomTroca

	//valida se a venda já houve devolução na venda
	SD1->(DbSetOrder(19)) //D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA
	If SD1->(DbSeek(xFilial("SD1") + SL1->L1_DOC + SL1->L1_SERIE ))
		If SD1->D1_TIPO == 'D' //nota de devolução
			MsgInfo("Existe devolução para a venda selecionada. Operação não permitida!","Atenção")
			Return
		EndIf
	EndIf

	if lAcessTF
		U_TRETA37B("TFORMA", "TROCAR FORMA - CONFERENCIA CAIXA")
		if !U_VLACESS2("TFORMA", RetCodUsr(), .T.)
			Return
		EndIf
	endif	

	if nTipo == 1 //se origem venda
		aColsEx := BuscaSE1(aCamposOld, "E1_PREFIXO='"+SL1->L1_SERIE+"' AND E1_NUM='"+SL1->L1_DOC+"' AND E1_TIPO<>'NCC'",,,.T.,.F.)
		cDocTroca := SL1->L1_DOC + "/" + SL1->L1_SERIE
		cCliTroca := SL1->L1_CLIENTE
		cLojTroca := SL1->L1_LOJA
		//para somente permitir troca quando consumidor padrao
		//if cCliPad <> cCliTroca+cLojTroca
		//	lMvFpCli := .F.
		//endif
	else
		lMvFpCli := .F. //nao habilito pra compensaçao
		aColsEx := BuscaSE1(aCamposOld, "E1_NUM='"+UC0->UC0_NUM+"' AND E1_TIPO<>'NCC'",,,.F.,.T.)
		cDocTroca := UC0->UC0_NUM
		cCliTroca := UC0->UC0_CLIENT
		cLojTroca := UC0->UC0_LOJA
	endif

	//ajusto campo E1_FATURA, para novo formato liquidação
	for nX := 1 to len(aColsEx)
		aColsEx[nX][nPosFatura] := Posicione("FI7",1,xFilial("FI7")+aColsEx[nX][nPosPrefixo]+aColsEx[nX][nPosNumero]+aColsEx[nX][nPosParcela]+aColsEx[nX][nPosTipo]+aColsEx[nX][nPosCliente]+aColsEx[nX][nPosLoja],"FI7_NUMDES")
	next nX

	cNomTroca := Posicione("SA1",1,xFilial("SA1")+cCliTroca+cLojTroca,"A1_NOME")

	if empty(aColsEx)
		aadd(aColsEx, MontaDados("SE1",aCamposOld, .T.)) //linha vazia
	endif

	DEFINE MSDIALOG oDlgDet TITLE "Trocar Forma - " + iif(nTipo==1,"Venda","Compensação") STYLE DS_MODALFRAME FROM 000, 000  TO 450, 800 COLORS 0, 16777215 PIXEL

	@ 005, 005 SAY iif(nTipo==1,"Nº Venda","Nº Compensação") SIZE 50, 007 OF oDlgDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 005 MSGET oGetDoc VAR cDocTroca SIZE 070, 010 OF oDlgDet HASBUTTON COLORS 0, 16777215 PIXEL WHEN .F.

	@ 005, 085 SAY "Cliente" SIZE 50, 007 OF oDlgDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 085 MSGET oGetCli VAR cCliTroca SIZE 060, 010 OF oDlgDet HASBUTTON COLORS 0, 16777215 PIXEL F3 "SA1" VALID oGetNome:Refresh() WHEN lMvFpCli

	@ 005, 150 SAY "Loja" SIZE 50, 007 OF oDlgDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 150 MSGET oGetLoj VAR cLojTroca SIZE 030, 010 OF oDlgDet HASBUTTON COLORS 0, 16777215 PIXEL VALID oGetNome:Refresh() WHEN lMvFpCli
     
	@ 005, 185 SAY "Nome" SIZE 50, 007 OF oDlgDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 185 MSGET oGetNome VAR (cNomTroca:=Posicione("SA1",1,xFilial("SA1")+cCliTroca+cLojTroca,"A1_NOME")) SIZE 150, 010 OF oDlgDet HASBUTTON COLORS 0, 16777215 PIXEL WHEN .F.

	oPnlDet := TScrollBox():New(oDlgDet,28,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Parcelas Atuais" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCamposOld)

	oMsFPagOld := MsNewGetDados():New( 015, 002, 85, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsEx)
	oMsFPagOld:oBrowse:bHeaderClick := {|oBrw,nCol,aDim| iif(oBrw:nColPos<>111 .and. nCol == 1 .and. lMARKALL, (aEval(oMsFPagOld:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL, Eval(bAtuSaldo)), lMARKALL:=!lMARKALL ) }
	oMsFPagOld:oBrowse:bLDblClick := {|| oMsFPagOld:aCols[oMsFPagOld:nAt][1] := iif(oMsFPagOld:aCols[oMsFPagOld:nAt][1]=="LBNO", "LBOK", "LBNO") , oMsFPagOld:oBrowse:Refresh(), Eval(bAtuSaldo) }

	@ 088, 005 SAY "Novas Parcelas" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 090, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	oMsFPagNew := MsFPagNew(nTipo, 098, 002, 165, 386, oPnlDet)

	@ 205, 006 SAY "SALDO:" SIZE 50, 9 OF oDlgDet COLOR CLR_BLACK PIXEL
	@ 205, 030 SAY oSaldoFPG VAR nSaldoFPG SIZE 50, 9 OF oDlgDet PICTURE PesqPict("SE1","E1_VALOR") COLOR CLR_BLUE PIXEL

	@ 205, 310 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	@ 205, 355 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oDlgDet PIXEL Action MsAguarde({|| iif(GrvTrocaForma(nTipo),oDlgDet:End(),) },"Aguarde...","Processando gravação...",.T.)
	oButton1:SetCSS( CSS_BTNAZUL )

	//alimento variaveis para uso no bloco que atualiza total
	nPosValOld := aScan(oMsFPagOld:aHeader,{|x| Alltrim(x[2])=='E1_VLRREAL'})
	nPosValNew := aScan(oMsFPagNew:aHeader,{|x| Alltrim(x[2])=='L4_VALOR'})

	ACTIVATE MSDIALOG oDlgDet CENTERED

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Monta o Grid de novas formas no troca forma
//--------------------------------------------------------------------------------------
Static Function MsFPagNew(nTipo, nTop, nLeft, nBottom, nRight, oPainel)

	Local oGridRet
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aAlterFields := {"NFORMA","L4_VALOR","E1_HIST"}
	Local cValid := ""
	Local nPosAux := 0

	if nTipo==1
		aadd(aAlterFields, "L1_CONDPG")
	endif

	// Define field properties

	If !empty(GetSx3Cache("E1_TIPO", "X3_CAMPO")) //"NFORMA"
		aadd(aHeaderEx, U_UAHEADER("E1_TIPO") )
		nPosAux := len(aHeaderEx) 
		aHeaderEx[nPosAux][1] := "Forma Pgt."
		aHeaderEx[nPosAux][2] := "NFORMA"
		aHeaderEx[nPosAux][6] := cValid
		aHeaderEx[nPosAux][9] := ""
	Endif

	If !empty(GetSx3Cache("X5_DESCRI", "X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER("X5_DESCRI") )
		nPosAux := len(aHeaderEx) 
		aHeaderEx[nPosAux][1] := "Descricao"
		aHeaderEx[nPosAux][6] := ""
	Endif

	If !empty(GetSx3Cache("L1_CONDPG", "X3_CAMPO"))
		if nTipo==1
			cValid := "U_TR028VCD(oMsFPagNew:aCols[oMsFPagNew:nAt][aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=='NFORMA'})], M->L1_CONDPG)"
		endif
		aadd(aHeaderEx, U_UAHEADER("L1_CONDPG") )
		nPosAux := len(aHeaderEx) 
		aHeaderEx[nPosAux][6] := cValid
		aHeaderEx[nPosAux][9] := "SE4"
	Endif

	If !empty(GetSx3Cache("L4_VALOR", "X3_CAMPO"))
		cValid := "POSITIVO(M->L4_VALOR) .AND. (oMsFPagNew:aCols[oMsFPagNew:nAt][aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=='L4_VALOR'})]:=M->L4_VALOR, Eval(bAtuSaldo))"
		aadd(aHeaderEx, U_UAHEADER("L4_VALOR") )
		nPosAux := len(aHeaderEx) 
		aHeaderEx[nPosAux][6] := cValid
	Endif

	If !empty(GetSx3Cache("E1_HIST", "X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER("E1_HIST") )
		nPosAux := len(aHeaderEx) 
		aHeaderEx[nPosAux][1] := "Observacoes"
	Endif

	Aadd(aColsEx, { space(3), space(50), space(3), 0, space(TamSX3("E1_HIST")[1]), .F.})

	oGridRet := MsNewGetDados():New(  nTop, nLeft, nBottom, nRight, GD_INSERT+GD_UPDATE+GD_DELETE, "Eval(bAtuSaldo)", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "Eval(bAtuSaldo)", oPainel, aHeaderEx, aColsEx)
	oGridRet:oBrowse:bHeaderClick := {|oBrw1,nCol|  } //desabilito opção de mudar para ediçao em tela
	oGridRet:lEditLine := .F.

	oGridRet:aInfo[1][4] := 'U_TR028FPG('+cValToChar(nTipo)+')'
	oGridRet:aInfo[1][8] := .T. //obrigatorio
	oGridRet:aInfo[3][4] := 'U_TR028VFP('+cValToChar(nTipo)+')'
	oGridRet:aInfo[3][8] := nTipo==1 //obrigatorio
	oGridRet:aInfo[4][4] := 'U_TR028VFP('+cValToChar(nTipo)+')'
	oGridRet:aInfo[4][8] := .T. //obrigatorio

Return oGridRet

//-----------------------------------------------------------------------------------------
// Tela de seleção de forma de pagamento para rotina troca forma
//-----------------------------------------------------------------------------------------
//Static Function F3FormaPg(nTipo)
User Function TR028FPG(nTipo)

	Local nX := 0
	Local cFiltroX5 := "PadR(aContent[nX][3],3)+'/' $ "
	Local nPosForma := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="NFORMA"})
	Local nPosDescr := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="X5_DESCRI"})
	Local nPosCond := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="L1_CONDPG"})
	Local nPosVal := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="L4_VALOR"})
	Local cDescri := oMsFPagNew:aCols[oMsFPagNew:nAt][nPosDescr]
	Local cCondPg := ""

	M->NFORMA := oMsFPagNew:aCols[oMsFPagNew:nAt][nPosForma] //pego forma atual
	if nTipo == 1
		cFiltroX5 += "'" + PadR(SIMBDIN,3) + "/" //dinheiro obrigatório
		for nX := 1 to len(aFormasHab)
			if aFormasHab[nX][8] //se habilitado
				cFiltroX5 += PadR(aFormasHab[nX][1], 3)+"/"
			endif
		next nX
		cFiltroX5 += "'"
	else
		cFiltroX5 += "'CH /CC /CD /CF /'"
	endif

	M->NFORMA := PadR(CONPADX5( "24", cFiltroX5, M->NFORMA, @cDescri), 3 )

	oMsFPagNew:lNewLine := .F. //flag para não apagar a linha que acabamos de modificar
	oMsFPagNew:aCols[oMsFPagNew:nAt][nPosForma] := M->NFORMA
	oMsFPagNew:aCols[oMsFPagNew:nAt][nPosDescr] := cDescri
	oMsFPagNew:aCols[oMsFPagNew:nAt][nPosCond] := Space(len(oMsFPagNew:aCols[oMsFPagNew:nAt][nPosCond]))
	oMsFPagNew:aCols[oMsFPagNew:nAt][nPosVal] := 0

	if alltrim(M->NFORMA) $ SIMBDIN+","+SuperGetMv("MV_XT028GC",,"NP") //gatilho para condição U44
		cCondPg := GatCondicao(alltrim(M->NFORMA), 1, nTipo)
		if !empty(cCondPg)
			oMsFPagNew:aCols[oMsFPagNew:nAt][nPosCond] := cCondPg
		endif
	endif

	oMsFPagNew:oBrowse:Refresh()

	//ajusta o array aInfComplem para tamanho do oMsFPagNew:aCols
	aSize(aInfComplem, len(oMsFPagNew:aCols))
	aInfComplem[oMsFPagNew:nAt] := Nil

Return .F. //retorna falso para nao habilitar ediçao do campo

//--------------------------------------------------------------------------------------
// Monta o Grid de novas formas no troca forma
//--------------------------------------------------------------------------------------
Static Function GatCondicao(cFormaPg, nTpRet, nTipo)

	Local _xClient, _xLoja, _xcProd, _cGrpCli, _cClasse, _cAtivid, _cGrpProd
	Local cQry := ""
	Local xRet := iif(nTpRet==1,"",{})

	if !lMvPosto
		if nTpRet==1
			xRet := Posicione("SE4",1,xFilial("SE4"),"E4_CODIGO")
		else
			Aadd(xRet,Posicione("SE4",1,xFilial("SE4"),"E4_CODIGO") + " - " + SE4->E4_DESCRI)
		endif
		REturn xRet
	endif

	_xClient 	:= cCliTroca
	_xLoja 		:= cLojTroca
	_cGrpCli 	:= Posicione("SA1",1,xFilial("SA1")+_xClient+_xLoja,"A1_GRPVEN")
	_cClasse    := Posicione("SA1",1,xFilial("SA1")+_xClient+_xLoja,"A1_XCLASSE")
	_cAtivid    := Posicione("SA1",1,xFilial("SA1")+_xClient+_xLoja,"A1_SATIV1")
	_cGrpProd 	:= ""

	if nTipo == 1
		DbSelectArea("SL2")
		SL2->(DbSetOrder(1))
		if !empty(SL1->L1_NUM) .AND. SL2->(DbSeek(xFilial("SL2")+SL1->L1_NUM ))
			_xcProd	:= SL2->L2_PRODUTO
			_cGrpProd := Posicione("SB1",1,xFilial("SB1")+_xcProd,"B1_GRUPO")
		endif
	endif

	cQry := "SELECT U44_CONDPG, U44_DESCRI "
	cQry += "FROM "+RetSqlName("U44")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U44 "
	cQry += "LEFT JOIN "+RetSqlName("U53")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U53 "
	cQry += "ON (U53.D_E_L_E_T_ = ' ' AND U53_FILIAL = '"+xFilial("U53")+"' AND U53_FORMPG = U44_FORMPG AND U53_CONDPG = U44_CONDPG AND U53_TPRGNG <> 'E' ) "
	cQry += "WHERE U44.D_E_L_E_T_ = ' ' "
	cQry += " AND U44_FILIAL = '" + xFilial("U44") + "'"
	cQry += " AND U44_FORMPG = '"+Alltrim(cFormaPg)+"' "
	cQry += " AND (U44_PADRAO = 'S' OR ("

	cQry += "  ((U53_CODCLI = '"+alltrim(_xClient)+"'"
	cQry += " 		   AND U53_LOJA = '"+alltrim(_xLoja)+"' )"
	if !empty(_cGrpCli)
		cQry += " 	OR U53_GRPVEN = '"+alltrim(_cGrpCli)+"'"
	endif
	if !empty(_cClasse)
		cQry += " 	OR U53_CLASSE = '"+alltrim(_cClasse)+"'"
	endif
	if !empty(_cAtivid)
		cQry += " 	OR U53_SATIV1 = '"+alltrim(_cAtivid)+"'"
	endif
	cQry += " 	) "
	cQry += "   AND "

	cQry += " (U53_CODPRO = '"+alltrim(_xcProd)+"' "
	if !empty(_cGrpProd)
		cQry += "   OR U53_GRUPO = '"+alltrim(_cGrpProd)+"'"
	endif
	cQry += "   OR (U53_GRUPO = '' AND U53_CODPRO = '' ))"

	cQry += " )) "

	cQry += "ORDER BY U44_CONDPG "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	While QRYT1->(!Eof())

		if nTpRet == 1 //retorna a primeira condiçao encontrada
			xRet := QRYT1->U44_CONDPG
			EXIT
		elseif aScan(xRet, QRYT1->U44_CONDPG + " - " + QRYT1->U44_DESCRI ) == 0
			Aadd(xRet,QRYT1->U44_CONDPG + " - " + QRYT1->U44_DESCRI)
		endif

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if nTpRet == 2 .AND. empty(xRet)
		aadd(xRet, "")
	endif

Return xRet

//-----------------------------------------------------------------------------------------
// Validação campo condição
//-----------------------------------------------------------------------------------------
//Static Function ValCondic(cForma, cCond)
User Function TR028VCD(cForma, cCond)

	Local lRet := .T.
	Local _cPadrao, _xClient, _xLoja
	Local _xcProd := ""

	if empty(cCond) .OR. !lMvPosto
		return lRet
	endif

	_xClient 	:= cCliTroca
	_xLoja 		:= cLojTroca

	//considera somente o primeiro produto
	SL2->(DbSetOrder(1))
	if !empty(SL1->L1_NUM) .AND. SL2->(DbSeek(xFilial("SL2")+SL1->L1_NUM ))
		_xcProd		:= SL2->L2_PRODUTO
	endif

	_cPadrao := Posicione("U44",1,xFilial("U44")+cForma+cCond,"U44_PADRAO")

	if empty(_cPadrao)
		MsgInfo("Forma de Pagamento + Condição de Pagamento não vinculadas. Acesse o menu 'Negociação de Pagamento' e faça a amarração entre forma e condição.", "Atenção")
		lRet := .F.
	elseif _cPadrao == 'N' .AND. !empty(_xClient+_xLoja)  //se não é padrão
		//verifica se bloqueia ou não
		lRet := U_TRET022D(cForma,cCond,_xClient,_xLoja,_xcProd)
	endif

Return lRet

//--------------------------------------------------------------------------------------
// Abre tela detalhada da forma de pagamento selecionada.
//--------------------------------------------------------------------------------------
//Static Function F3ValorFP(nTipo)
User Function TR028VFP(nTipo)

	Local lModEdic := .T.
	Local lOk := .F.
	Local nPosForma := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="NFORMA"})
	Local nPosDescri := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="X5_DESCRI"})
	Local nPosHist := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="E1_HIST"})
	Local nPosCond := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="L1_CONDPG"})
	Local nPosVal := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="L4_VALOR"})
	Local cFormaPg := oMsFPagNew:aCols[oMsFPagNew:nAt,nPosForma]
	Local bValTela
	Local oBtnCanc, oBtnOK, oVlrCred
	Local nList := 1
	Local lParcCCPg := SuperGetMV("MV_XPARCPG",,.T.) //Define se a quantidade de parcelas será definida pela condição de pagamento ou não
	Private oDlgForma, oListGdNeg
	Private nValForm := oMsFPagNew:aCols[oMsFPagNew:nAt,nPosVal]
	Private cCondPg := oMsFPagNew:aCols[oMsFPagNew:nAt,nPosCond]
	Private dDataTran 	:= CtoD("")
	Private nParcelas 	:= 1
	Private oPanelAux
	Private aNCCsCli := {}

	//ajusta o array aInfComplem para tamanho do oMsFPagNew:aCols
	aSize(aInfComplem, len(oMsFPagNew:aCols))

	if empty(cFormaPg) //se nao preencheu a forma, não faz nada
		lModEdic := .F.

	elseif Alltrim(cFormaPg) == "CH" //formas que exigem dados complementares

		lModEdic := .F.

		if aInfComplem[oMsFPagNew:nAt] == Nil
			aInfComplem[oMsFPagNew:nAt] := {;
				dDataTran,;
				0,;
				Space(TamSX3("EF_BANCO")[1]), ;
				Space(TamSX3("EF_AGENCIA")[1]), ;
				Space(TamSX3("EF_CONTA")[1]), ;
				Space(TamSX3("EF_NUM")[1]), ;
				Space(TamSX3("EF_EMITENT")[1]), ;
				Space(TamSX3("EF_CPFCNPJ")[1]), ;
				Space(TamSX3("EF_RG")[1]), ;
				Space(TamSX3("EF_TEL")[1]), ;
				iif(SEF->(FieldPos("EF_COMP")>0),Space(TamSX3("EF_COMP")[1]),Space(3)), ;
				iif(SEF->(FieldPos("EF_XCMC7")>0),Space(TamSX3("EF_XCMC7")[1]),Space(34)), ;
				nList ;
			}
		else
			nList := aInfComplem[oMsFPagNew:nAt][13]
		endif

		if nTipo==1 .AND. lMvPosto
			oDlgForma := TDialog():New(0,0,480,500,"Dados " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

			aNegs := GatCondicao(cFormaPg, 2, nTipo)
			if nList > len(aNegs)
				nList := 1
			endif
			LoadSelNeg(cFormaPg, aNegs[nList])
			aInfComplem[oMsFPagNew:nAt][1]:= dDataTran

			@ 010, 010 SAY oSay1 PROMPT "Negociações de Pagamento" SIZE 200, 008 OF oDlgForma COLORS 0, 16777215 PIXEL
			oListGdNeg := TListBox():Create(oDlgForma, 020, 010, {|u| if(Pcount()>0,nList:=u,nList) }, aNegs, 230, 040,{|| LoadSelNeg(cFormaPg, oListGdNeg:GetSelText()), aInfComplem[oMsFPagNew:nAt][1]:=dDataTran },,,,.T.,,{|| oDlgForma:aControls[5]:SetFocus() })

			// crio o panel para mudar a cor da tela
			@ 055, 0 MSPANEL oPanelAux SIZE 250, 190 OF oDlgForma COLORS 0, 16777215

		else
			//monta tela de informar cheques
			oDlgForma := TDialog():New(0,0,380,500,"Dados " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

			// crio o panel para mudar a cor da tela
			@ 0, 0 MSPANEL oPanelAux SIZE 100, 100 OF oDlgForma COLORS 0, 16777215
			oPanelAux:Align := CONTROL_ALIGN_ALLCLIENT

			cCondPg := Posicione("SE4",1,xFilial("SE4"),"E4_CODIGO") //colocado pra nao ficar vazio, mas nao vou usar
		endif

		MontaCpChq(oPanelAux, aInfComplem[oMsFPagNew:nAt])
		bValTela := {|| !empty(cCondPg) .AND. !empty(aInfComplem[oMsFPagNew:nAt][1]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][2]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][3]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][4]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][5])  .AND. !empty(aInfComplem[oMsFPagNew:nAt][6]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][7])  }

		@ iif(nTipo==1 .AND. lMvPosto,218,170), 200 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgForma ACTION iif(Eval(bValTela), iif(nParcelas>1, (MsgAlert("Utilize uma condição de pagamento de cheque que gera apenas uma parcela.","Atenção"),.F.), (lOk := .T.,oDlgForma:End()) ), MsgInfo("Campos obrigatórios não foram preenchidos!","Atenção")) PIXEL
		oBtnOK:SetCSS( CSS_BTNAZUL )
		@ iif(nTipo==1 .AND. lMvPosto,218,170), 155 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgForma ACTION oDlgForma:End() PIXEL

		oDlgForma:lCentered := .T.
		oDlgForma:Activate()

	elseif Alltrim(cFormaPg) == "CF" //Carta Frete

		lModEdic := .F.

		if aInfComplem[oMsFPagNew:nAt] == Nil
			aInfComplem[oMsFPagNew:nAt] := {;
				Space(TamSX3("A1_CGC")[1]),;
				"",;
				Space(TamSX3("E1_NUMCART")[1]),;
				0,;
				Space(TamSX3("E1_HIST")[1]),;
				stod("");
			}
		endif

		oDlgForma := TDialog():New(0,0,320,375,"Dados " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

		@ 0, 0 MSPANEL oPanelAux SIZE 100, 100 OF oDlgForma COLORS 0, 16777215
		oPanelAux:Align := CONTROL_ALIGN_ALLCLIENT

		MontaCpCFret(oPanelAux, aInfComplem[oMsFPagNew:nAt],nTipo)
		bValTela := {|| !empty(aInfComplem[oMsFPagNew:nAt][1]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][2]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][3]) .AND. aInfComplem[oMsFPagNew:nAt][4]>0  }

		@ 140, 135 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgForma ACTION iif(Eval(bValTela),(lOk := .T.,oDlgForma:End()),MsgInfo("Campos obrigatórios nao preenchidos corretamente!","Atenção")) PIXEL
		oBtnOK:SetCSS( CSS_BTNAZUL )
		@ 140, 090 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgForma ACTION oDlgForma:End() PIXEL

		oDlgForma:lCentered := .T.
		oDlgForma:Activate()

	elseif Alltrim(cFormaPg) $ "CC,CD" //formas que exigem dados complementares

		lModEdic := .F.

		if aInfComplem[oMsFPagNew:nAt] == Nil
			//{nValor, cRedeAut, cBandeira, cAdmFin, cNsuDoc, cAutoriz, dDataTran, nParcelas, lista}
			aInfComplem[oMsFPagNew:nAt] := {;
				0,;
				Space(TamSx3("MDE_CODIGO")[1]),;
				Space(TamSx3("MDE_CODIGO")[1]) ,;
				Space(TamSx3("AE_COD")[1]),;
				Space(TAMSx3("L4_NSUTEF")[1]),;
				Space(TAMSx3("L4_AUTORIZ")[1]), ;
				IIF(nTipo==1,SL1->L1_EMISNF,SLW->LW_DTABERT),; //TODO: ajustado, pois caso o caixa vire de uma data para a outra, ocorre erros ao trocar a forma
				1, ;
				nList ;
			}
		else
			nList := aInfComplem[oMsFPagNew:nAt][9]
		endif

		if nTipo==1 .AND. lMvPosto
			oDlgForma := TDialog():New(0,0,495,435,"Dados Complementares - " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

			aNegs := GatCondicao(cFormaPg, 2, nTipo)
			if nList > len(aNegs)
				nList := 1
			endif
			LoadSelNeg(cFormaPg, aNegs[nList], .T.)

			@ 010, 010 SAY oSay2 PROMPT "Negociações de Pagamento" SIZE 200, 008 OF oDlgForma COLORS 0, 16777215 PIXEL
			oListGdNeg := TListBox():Create(oDlgForma, 020, 010, {|u| if(Pcount()>0,nList:=u,nList) }, aNegs, 200, 040,{|| LoadSelNeg(cFormaPg, oListGdNeg:GetSelText(), .T.) },,,,.T.,,{|| oDlgForma:aControls[5]:SetFocus() })

			// crio o panel para mudar a cor da tela
			@ 065, 0 MSPANEL oPanelAux SIZE 250, 190 OF oDlgForma COLORS 0, 16777215

		else
			oDlgForma := TDialog():New(0,0,375,435,"Dados Complementares - " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

			// crio o panel para mudar a cor da tela
			@ 0, 0 MSPANEL oPanelAux SIZE 100, 100 OF oDlgForma COLORS 0, 16777215
			oPanelAux:Align := CONTROL_ALIGN_ALLCLIENT

			cCondPg := Posicione("SE4",1,xFilial("SE4"),"E4_CODIGO") //colocado pra nao ficar vazio, mas nao vou usar
		endif

		lAltParc := (!lMvPosto .OR. nTipo==2 .OR. !lParcCCPg) .AND. Alltrim(cFormaPg)=="CC" //parcela somente para cartao credito, e se não trata parcela pela condição
		MontaCpCart(Alltrim(cFormaPg), oPanelAux, aInfComplem[oMsFPagNew:nAt], lAltParc , iif((nTipo==1.AND.lMvPosto),0,Nil))
		bValTela := {|| aInfComplem[oMsFPagNew:nAt][1]>0 .AND. !empty(cCondPg) .AND. !empty(aInfComplem[oMsFPagNew:nAt][4]) .AND. !empty(aInfComplem[oMsFPagNew:nAt][5])  .AND. !empty(aInfComplem[oMsFPagNew:nAt][6]) .AND. aInfComplem[oMsFPagNew:nAt][8]>0  }

		@ iif(nTipo==1 .AND. lMvPosto,228,170), 165 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgForma ACTION iif(Eval(bValTela),(lOk := .T.,oDlgForma:End()), MsgInfo("Campos obrigatórios não foram preenchidos!","Atenção")) PIXEL
		oBtnOK:SetCSS( CSS_BTNAZUL )
		@ iif(nTipo==1 .AND. lMvPosto,228,170), 120 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgForma ACTION oDlgForma:End() PIXEL

		oDlgForma:lCentered := .T.
		oDlgForma:Activate()

	elseif Alltrim(cFormaPg) $ "PX" //formas que exigem dados complementares

		lModEdic := .F.

		if aInfComplem[oMsFPagNew:nAt] == Nil
			//{nValor, cAdmFin, dDataTran, nParcelas, lista}
			aInfComplem[oMsFPagNew:nAt] := {;
				0,;
				Space(TamSx3("AE_COD")[1]),;
				SLW->LW_DTABERT,;
				1, ;
				nList ;
			}
		else
			nList := aInfComplem[oMsFPagNew:nAt][5]
		endif

		oDlgForma := TDialog():New(0,0,400,435,"Dados Complementares - " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

		aNegs := GatCondicao(cFormaPg, 2, nTipo)
		if nList > len(aNegs)
			nList := 1
		endif
		LoadSelNeg(cFormaPg, aNegs[nList], .F.)

		@ 010, 010 SAY oSay2 PROMPT "Negociações de Pagamento" SIZE 200, 008 OF oDlgForma COLORS 0, 16777215 PIXEL
		oListGdNeg := TListBox():Create(oDlgForma, 020, 010, {|u| if(Pcount()>0,nList:=u,nList) }, aNegs, 200, 040,{|| LoadSelNeg(cFormaPg, oListGdNeg:GetSelText(), .F.) },,,,.T.,,{|| oDlgForma:aControls[5]:SetFocus() })

		// crio o panel para mudar a cor da tela
		@ 065, 0 MSPANEL oPanelAux SIZE 250, 190 OF oDlgForma COLORS 0, 16777215

		lAltParc := .F.
		MontaCpPx(Alltrim(cFormaPg), oPanelAux, aInfComplem[oMsFPagNew:nAt], lAltParc , 0)
		bValTela := {|| aInfComplem[oMsFPagNew:nAt][1]>0 .AND. !empty(cCondPg) .AND. !empty(aInfComplem[oMsFPagNew:nAt][2]) .AND. aInfComplem[oMsFPagNew:nAt][4]>0  }

		@ 182, 170 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgForma ACTION iif(Eval(bValTela),(lOk := .T.,oDlgForma:End()), MsgInfo("Campos obrigatórios não foram preenchidos!","Atenção")) PIXEL
		oBtnOK:SetCSS( CSS_BTNAZUL )
		@ 182, 125 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgForma ACTION oDlgForma:End() PIXEL

		oDlgForma:lCentered := .T.
		oDlgForma:Activate()

	elseif Alltrim(cFormaPg) == "CR" //Credito

		lModEdic := .F.
		cCondPg := Posicione("SE4",1,xFilial("SE4"),"E4_CODIGO") //colocado pra nao ficar vazio, mas nao vou usar

		if aInfComplem[oMsFPagNew:nAt] == Nil
			aInfComplem[oMsFPagNew:nAt] := {;
				space(40),;
				0,; //valor a compensar
				Nil,; //array da linha selecionada
				nList;
			}
		endif

		oDlgForma := TDialog():New(0,0,480,500,"Seleção do Credito Cliente",,,,,,,,,.T.)

		// crio o panel para mudar a cor da tela
		@ 0, 0 MSPANEL oPanelAux SIZE 100, 100 OF oDlgForma COLORS 0, 16777215
		oPanelAux:Align := CONTROL_ALIGN_ALLCLIENT

		@ 010, 010 SAY oSay2 PROMPT "Cód. Barras / Núm. Título" SIZE 220, 008 OF oPanelAux COLORS 0, 16777215 PIXEL
		TGet():New(020,010,{|u| iif( PCount()==0,aInfComplem[oMsFPagNew:nAt][1],aInfComplem[oMsFPagNew:nAt][1]:=u)},oPanelAux,200,013,"!@",{|| FindCredCl(cCliTroca,cLojTroca,aInfComplem[oMsFPagNew:nAt][1]) },,,,,,.T.,,,{|| .T.},,,,.F.,.F.,,"oGetCod",,,,.F.,.T.)

		oListGdNeg := TListBox():Create(oDlgForma, 040, 010, {|u| if(Pcount()>0,nList:=u,nList) }, {''}, 230, 125,,,,,.T.,,{|| oVlrCred:SetFocus() })

	    @ 175, 010 SAY "Valor a Compensar" SIZE 70, 008 OF oPanelAux COLORS 0, 16777215 PIXEL
		oVlrCred := TGet():New( 185, 010,{|u| iif(PCount()>0,aInfComplem[oMsFPagNew:nAt][2]:=u,aInfComplem[oMsFPagNew:nAt][2])},oPanelAux,85, 015,PesqPict("SL4","L4_VALOR"),{|| Positivo(aInfComplem[oMsFPagNew:nAt][2]) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oVlrCred",,,,.F.,.T.)

		bValTela := {|| aInfComplem[oMsFPagNew:nAt][2]>0 .AND. !empty(oListGdNeg:GetSelText())}

		@ 218, 200 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgForma ACTION iif(Eval(bValTela), iif(aNCCsCli[nList][2]>=aInfComplem[oMsFPagNew:nAt][2],(lOk := .T.,oDlgForma:End()), MsgInfo("Valor a compensar deve ser menor ou igual ao valor do titulo de credito.","Atenção")) , MsgInfo("Selecione um titulo na lista e informe o valor a compensar!","Atenção")) PIXEL
		oBtnOK:SetCSS( CSS_BTNAZUL )
		@ 218, 155 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgForma ACTION oDlgForma:End() PIXEL

		if aInfComplem[oMsFPagNew:nAt][3] <> Nil
			oDlgForma:bInit := {|| FindCredCl(cCliTroca,cLojTroca,aInfComplem[oMsFPagNew:nAt][1]), oListGdNeg:SetFocus(), oListGdNeg:Select(aInfComplem[oMsFPagNew:nAt][4]) }
		endif

		oDlgForma:lCentered := .T.
		oDlgForma:Activate()

	elseif Alltrim(cFormaPg) $ "CT" //CTF

		lModEdic := .F.

		if aInfComplem[oMsFPagNew:nAt] == Nil
			//{nValor, cAdmFin, dDataTran, nParcelas, lista, oAdmFin}
			aInfComplem[oMsFPagNew:nAt] := {;
				0,;
				Space(TamSx3("AE_COD")[1]),;
				SLW->LW_DTABERT,;
				1, ;
				nList, ;
				nil; //objeto campo oAdmFin
			}
		else
			nList := aInfComplem[oMsFPagNew:nAt][5]
		endif

		aNegs := GatCondicao(cFormaPg, 2, nTipo)
		if nList > len(aNegs)
			nList := 1
		endif
		
		if !empty(aNegs[1])
			oDlgForma := TDialog():New(0,0,400,435,"Dados Complementares - " + Alltrim(oMsFPagNew:aCols[oMsFPagNew:nAt,nPosDescri]),,,,,,,,,.T.)

			LoadSelNeg(cFormaPg, aNegs[nList], .F.)

			@ 010, 010 SAY oSay2 PROMPT "Negociações de Pagamento" SIZE 200, 008 OF oDlgForma COLORS 0, 16777215 PIXEL
			oListGdNeg := TListBox():Create(oDlgForma, 020, 010, {|u| if(Pcount()>0,nList:=u,nList) }, aNegs, 200, 040,{|| LoadSelNeg(cFormaPg, oListGdNeg:GetSelText(), .F.) },,,,.T.,,{|| oDlgForma:aControls[5]:SetFocus() })

			// crio o panel para mudar a cor da tela
			@ 065, 0 MSPANEL oPanelAux SIZE 250, 190 OF oDlgForma COLORS 0, 16777215

			lAltParc := .F.
			MontaCpCTF(Alltrim(cFormaPg), oPanelAux, aInfComplem[oMsFPagNew:nAt], lAltParc , 0)
			bValTela := {|| aInfComplem[oMsFPagNew:nAt][1]>0 .AND. !empty(cCondPg) .AND. !empty(aInfComplem[oMsFPagNew:nAt][2]) .AND. aInfComplem[oMsFPagNew:nAt][4]>0  }

			@ 182, 170 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgForma ACTION iif(Eval(bValTela),(lOk := .T.,oDlgForma:End()), MsgInfo("Campos obrigatórios não foram preenchidos!","Atenção")) PIXEL
			oBtnOK:SetCSS( CSS_BTNAZUL )
			@ 182, 125 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgForma ACTION oDlgForma:End() PIXEL

			oDlgForma:lCentered := .T.
			oDlgForma:bInit := {|| LoadSelNeg(cFormaPg, oListGdNeg:GetSelText(), .F.) }
			oDlgForma:Activate()
		else
			MsgInfo("Não há negociações de pagamento de CTF habilitadas para o cliente da venda.")
		endif

	endif

	if !lModEdic .AND. lOk
		if Alltrim(cFormaPg) $ "CC,CD"
			nValForm := aInfComplem[oMsFPagNew:nAt][1]
			aInfComplem[oMsFPagNew:nAt][9] := nList
		elseif Alltrim(cFormaPg) $ "PX"
			nValForm := aInfComplem[oMsFPagNew:nAt][1]
			aInfComplem[oMsFPagNew:nAt][5] := nList
		elseif Alltrim(cFormaPg) == "CH"
			nValForm := aInfComplem[oMsFPagNew:nAt][2]
			aInfComplem[oMsFPagNew:nAt][13] := nList
		elseif Alltrim(cFormaPg) == "CF"
			nValForm := aInfComplem[oMsFPagNew:nAt][4]
			oMsFPagNew:aCols[oMsFPagNew:nAt][nPosHist] := aInfComplem[oMsFPagNew:nAt][5] //hist
		elseif Alltrim(cFormaPg) == "CR"
			nValForm := aInfComplem[oMsFPagNew:nAt][2]
			aInfComplem[oMsFPagNew:nAt][3] := aClone(aNCCsCli[nList])
			aInfComplem[oMsFPagNew:nAt][3][1] := .T. //marcado
			aInfComplem[oMsFPagNew:nAt][4] := nList
		elseif Alltrim(cFormaPg) $ "CT" //CTF
			nValForm := aInfComplem[oMsFPagNew:nAt][1]
			aInfComplem[oMsFPagNew:nAt][5] := nList
		endif

		oMsFPagNew:lNewLine := .F. //flag para não apagar a linha que acabamos de modificar
		oMsFPagNew:aCols[oMsFPagNew:nAt][nPosCond] := cCondPg //condiçao
		oMsFPagNew:aCols[oMsFPagNew:nAt][nPosVal] := nValForm //valor
		oMsFPagNew:oBrowse:Refresh()
		Eval(bAtuSaldo)
	endif

Return lModEdic

//--------------------------------------------------------------
// Função para carregar dados da negociação de pagamento selecionada
//--------------------------------------------------------------
Static Function LoadSelNeg(cForma, cTxtList, lCard)

	Local aArea := GetArea()
	Local aAreaU44 := U44->(GetArea())
	Local lRet := .T.
	Local aParc
	Local cAdmFinU44
	Default lCard := .F.

	cCondPg := SubStr(cTxtList,1,3)

    aParc := condicao(100,cCondPg,0.00,SLW->LW_DTABERT,0.00,{},,0)

    If Len(aParc) > 0
	    dDataTran := aParc[01][01]
	    nParcelas := Len(aParc)
    Else
		dDataTran := ctod("")
		nParcelas := 0
    EndIf

	if lCard
		aInfComplem[oMsFPagNew:nAt][8] := nParcelas
	endif

	if Alltrim(cForma) == "CT" .AND. aInfComplem[oMsFPagNew:nAt][6] <> Nil //CTF
		if U44->(FieldPos("U44_ADMFIN"))
			cAdmFinU44 := Posicione("U44",1,xFilial("U44") + PadR(cForma,TamSx3("U44_FORMPG")[1]) + cCondPg, "U44_ADMFIN")
			aInfComplem[oMsFPagNew:nAt][6]:lReadOnly := .F.
			if !empty(cAdmFinU44)
				nX := aScan(aInfComplem[oMsFPagNew:nAt][6]:aItems, {|x| SubStr(x,1,TamSx3("AE_COD")[1]) == cAdmFinU44 })
				aInfComplem[oMsFPagNew:nAt][6]:Select(nX)
				aInfComplem[oMsFPagNew:nAt][6]:lReadOnly := .T.
			endif
		endif
	endif

	RestArea(aAreaU44)
	RestArea(aArea)

Return lRet

//-----------------------------------------------------------------------------------------
// Validação campo condição
//-----------------------------------------------------------------------------------------
Static Function GrvTrocaForma(nTipo)

	Local nQtdSel := 0
	Local lOk := .T.
	Local nX, nI
	Local cChavE1 := "" //Chave do titulo
	Local nPosForma := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="NFORMA"})
	Local nPosCond := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="L1_CONDPG"})
	Local nPosVal := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="L4_VALOR"})
	Local nPosHist := aScan(oMsFPagNew:aHeader,{|X| Alltrim(x[2])=="E1_HIST"})
	Local nIntervalo := SuperGetMV("MV_LJINTER") //Intervalo das parcelas loja
	Local cPfxCmp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local aParcCond := {} //parcelas da condiçao de pagamento
	Local nParcGrv
	Local cDoc, cSerie, cCliente, cLoja, dEmissao, cParcela, cFormaPg //variaveis para gravaçao
	Local cBanco, cAgencia, cNumConta, aRet
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa

	//verifico se há itens selecionados
	aEval(oMsFPagOld:aCols, {|x| iif(x[1] == "LBOK", nQtdSel++,) })
	if nQtdSel == 0
		MsgAlert("Selecione pelo menos uma parcela de origem para fazer a troca.","Atenção")
		Return .F.
	endif

	if !oMsFPagNew:ChkObrigat()
		Return .F.
	endif

	//atualizo o saldo antes das validações
	Eval(bAtuSaldo)
	if nSaldoFPG <> 0
		MsgAlert("Valor total das novas parcelas é diferente do valor total das parcelas atuais. Operação não permitida.","Atenção")
		Return .F.
	endif

	SA6->(DbSetOrder(1))
	If SA6->(DbSeek(xFilial("SA6")+SLW->LW_OPERADO)) //posiciona no banco do caixa (operador)
		cBanco    := SA6->A6_COD
		cAgencia  := SA6->A6_AGENCIA
		cNumConta := SA6->A6_NUMCON
	else
		MsgAlert("Não foi possível encontrar banco do operador para realizar movimento.","Atenção")
		Return .F.
	endif

	//verifico se está na filial correta
	if cFilAnt <> iif(nTipo==1,SL1->L1_FILIAL,UC0->UC0_FILIAL)
		MsgAlert("Falha na operação. Filial desposicionada. Saia do sistema e entre novamente.","Atenção")
		Return .F.
	endif

	if nTipo == 2 //compensacao
		cParcela := PADL("1",TAMSX3("E1_PARCELA")[1],"0") //Inicia parcela com 1
		UC1->(DBSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
		if UC1->(DbSeek(UC0->UC0_FILIAL+UC0->UC0_NUM))
			While UC1->(!Eof()) .AND. UC1->UC1_FILIAL+UC1->UC1_NUM == UC0->UC0_FILIAL+UC0->UC0_NUM
				if SubStr(UC1->UC1_SEQ,1,TAMSX3("E1_PARCELA")[1]) > cParcela
					cParcela := SubStr(UC1->UC1_SEQ,1,TAMSX3("E1_PARCELA")[1])
				endif
				UC1->(dbSkip())
			enddo
		endif
	endif

	BeginTran()

	cLogCaixa += "PARCELAS EXCLUIDAS:" + CRLF
	//DELETANDO PARCELAS MARCADAS
	for nX := 1 to len(oMsFPagOld:aCols)
		if oMsFPagOld:aCols[nX][1] == "LBOK"

			//posiciona no titulo marcado
			SE1->(DbGoTo(oMsFPagOld:aCols[nX][len(oMsFPagOld:aHeader)]))
			cLogCaixa += Space(4) + SE1->E1_PARCELA + " | " + SE1->E1_TIPO + " | " +;
						 iif(SE1->E1_VLRREAL > 0, Transform(SE1->E1_VLRREAL ,"@E 999,999,999.99"), Transform(SE1->E1_VALOR ,"@E 999,999,999.99")) + ;
						 " | " + DTOC(SE1->E1_VENCTO) + " | " + SE1->E1_CLIENTE +" | "+SE1->E1_LOJA+" | "+Alltrim(SE1->E1_NOMCLI) + CRLF

			if !Empty(SE1->E1_BAIXA)
				if alltrim(SE1->E1_TIPO) == "CR"
					if !CompensaCred(2) //chama estorno compensação do crédito
						DisarmTransaction()
						lOk := .F.
						EXIT
					endif
				elseif !CancBxSE1() //cancela baixa do titulo
					DisarmTransaction()
					lOk := .F.
					EXIT
				endif
			EndIf

			//Excluo registro da UC1 referente ao titulo
			if nTipo == 2
				UC1->(DBSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
				if UC1->(DbSeek(xFilial("UC1")+SE1->E1_NUM+SE1->E1_TIPO+SE1->E1_PARCELA))
					Reclock("UC1",.F.)
					UC1->(DbDelete())
					UC1->(MSUnlock())
				endif
			endif

			cChavE1 := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

			aFin040 := {}
			AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL	 	, Nil})
			AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO		, Nil})
			AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM			, Nil})
			AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA		, Nil})
			AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO			, Nil})

			//apaga a origem para ser possível alteração/exclusão do titulo
			RecLock("SE1",.F.)
				SE1->E1_ORIGEM := ""
			SE1->(MsUnlock())

			//execucao da rotina automática do título
			lMsErroAuto := .F.
			lMsHelpAuto := .T.
			MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)

			if lMsErroAuto
				MostraErro()
				DisarmTransaction()
				lOk := .F.
				EXIT
			else
				SE1->(DbSetOrder(1))
				if SE1->(DbSeek(cChavE1)) //se encontrar o titulo.. é pq nao conseguiu excluir
					MsgInfo("Não foi possível excluir o título. Entre em contato com o financeiro.","Atenção")
					DisarmTransaction()
					lOk := .F.
					EXIT
				else
					//Verifico se ainda ficou SEF vinculada e excluo caso encontre.
					SEF->(DbSetOrder(3)) //EF_FILIAL+EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO+EF_NUM+EF_SEQUENC
					if Alltrim(Right(cChavE1,3))=="CH" .AND. SEF->(DbSeek(cChavE1))
						While SEF->(!Eof()) .AND. SEF->EF_FILIAL+SEF->EF_PREFIXO+SEF->EF_TITULO+SEF->EF_PARCELA+SEF->EF_TIPO == cChavE1
							GravaSEF(5) //excluo cheque SEF
							SEF->(DBSkip())
						Enddo
					endif
				endif
			endif

		endif
	next nX

	//verifico se está na filial correta
	if lOk .AND. cFilAnt <> iif(nTipo==1,SL1->L1_FILIAL,UC0->UC0_FILIAL)
		MsgAlert("Falha na operação. Filial desposicionada. Saia do sistema e entre novamente.","Transaction")
		lOk := .F.
		DisarmTransaction()
	endif

	//CRIANDO NOVAS PARCELAS
	if lOk
		cLogCaixa += "NOVAS PARCELAS:" + CRLF
		for nX := 1 to len(oMsFPagNew:aCols)
			if oMsFPagNew:aCols[nX][len(oMsFPagNew:aCols[nX])] == .F.//se nao deletado
				cFormaPg := oMsFPagNew:aCols[nX][nPosForma]

				if nTipo == 1 //VENDA
					cDoc := SL1->L1_DOC
					cSerie := SL1->L1_SERIE
					cCliente := SL1->L1_CLIENTE
					cLoja := SL1->L1_LOJA
					dEmissao := SL1->L1_EMISNF

					//se habilitado troca cliente e forma permite troca, considero campos da tela
					if lMvFpCli .AND. Alltrim(cFormaPg) $ cMvFpCli
						cCliente := cCliTroca
						cLoja := cLojTroca
					endif

					if Alltrim(cFormaPg) == SIMBDIN //se venda em dinheiro
						lOk := AjuSL1Din(1, oMsFPagNew:aCols[nX][nPosVal], .F., .T.)
						cLogCaixa += Space(4) + space(3) + " | " + cFormaPg + " | " +;
									Transform(oMsFPagNew:aCols[nX][nPosVal] ,"@E 999,999,999.99") + ;
									" | " + DTOC(dEmissao) + " | " + cCliente +" | "+cLoja+" | "+Alltrim(Posicione("SA1",1,xFilial("SA1")+cCliente+cLoja, "A1_NREDUZ")) + CRLF
					else
						//verifico se credito de outra coligada para transferir
						if Alltrim(cFormaPg) == "CR"
							If AllTrim(aInfComplem[nX][3][14]) <> AllTrim(cFilAnt)
								aRet := U_TRETE031(aClone(aInfComplem[nX][3]))
								if aRet[2]
								 	aInfComplem[nX][3] := aClone(aRet[1])
								else
									MsgAlert("Falha ao tentar transferir credito entre coligadas.","Transaction")
									lOk := .F.
									DisarmTransaction()
									EXIT
								endif
							endif
						endif

						//quebra parcelas
						//aParcCond := condicao(oMsFPagNew:aCols[nX][nPosVal], oMsFPagNew:aCols[nX][nPosCond], 0.00, SLW->LW_DTABERT, 0.00,{},,0)
						aParcCond := condicao(oMsFPagNew:aCols[nX][nPosVal], oMsFPagNew:aCols[nX][nPosCond], 0.00, dEmissao, 0.00,{},,0) //TODO: ajustado, pois caso o caixa vire de uma data para a outra, ocorre erros ao trocar a forma
						if Alltrim(cFormaPg) $ "CC,CD" //se cartao
							DbSelectArea("SAE")
							SAE->(DbSetOrder(1))
							SAE->(DbSeek(xFilial("SAE")+aInfComplem[nX][4])) //adm fin

							cCliente := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] ) 
							cLoja	 := PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )

							if !lMvPosto .OR. !SuperGetMV("MV_XPARCPG",,.T.) //Define se a quantidade de parcelas será definida pela condição de pagamento ou não
								aParcCond := {} //ignoro a condição
								nParcGrv := aInfComplem[nX][8] //parcelas
								if nParcGrv > 1
									//Ajusto valor da parcela
									nDiferenca := Round( oMsFPagNew:aCols[nX][nPosVal] - (( Round( oMsFPagNew:aCols[nX][nPosVal] / nParcGrv,2) ) * nParcGrv), 2)
									For nI := 1 to nParcGrv
										//dData := SLW->LW_DTABERT + IIf(nI = 1, 0, nIntervalo*(nI-1))
										dData := dEmissao + IIf(nI = 1, 0, nIntervalo*(nI-1)) //TODO: ajustado, pois caso o caixa vire de uma data para a outra, ocorre erros ao trocar a forma
										nValor := Round( oMsFPagNew:aCols[nX][nPosVal] / nParcGrv, 2 )
										if nI == nParcGrv //ultima parcela soma diferença
											nValor := Round( nValor + nDiferenca, 2 )
										endif
										aadd(aParcCond, {dData, nValor})
									next nI
								else
									//aadd(aParcCond, {SLW->LW_DTABERT, oMsFPagNew:aCols[nX][nPosVal]})
									aadd(aParcCond, {dEmissao, oMsFPagNew:aCols[nX][nPosVal]}) //TODO: ajustado, pois caso o caixa vire de uma data para a outra, ocorre erros ao trocar a forma
								endif
							EndIf
						elseif Alltrim(cFormaPg) == "CF" //carta frete
							cCliente := Posicione("SA1",3,xFilial("SA1")+aInfComplem[nX][1], "A1_COD")
							cLoja	 := SA1->A1_LOJA
							if len(aParcCond) > 1
								aSize(aParcCond, 1) //considera só uma parcela
								aParcCond[1][2] := oMsFPagNew:aCols[nX][nPosVal] //forço valor
							endif
						elseif Alltrim(cFormaPg) == "PX" //PIX
							DbSelectArea("SAE")
							SAE->(DbSetOrder(1))
							SAE->(DbSeek(xFilial("SAE")+aInfComplem[nX][2])) //adm fin
							cCliente := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] ) 
							cLoja	 := PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
							if len(aParcCond) > 1
								aSize(aParcCond, 1) //considera só uma parcela
								aParcCond[1][2] := oMsFPagNew:aCols[nX][nPosVal] //forço valor
							endif
						elseif Alltrim(cFormaPg) == "CT" //CTF
							DbSelectArea("SAE")
							SAE->(DbSetOrder(1))
							SAE->(DbSeek(xFilial("SAE")+aInfComplem[nX][2])) //adm fin
							cCliente := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] ) 
							cLoja	 := PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
						endif

						cParcela := PADL("1",TAMSX3("E1_PARCELA")[1],"0") //Inicia parcela com 1
						//gerando titulos
						for nI:=1 to len(aParcCond)
							aFin040 := {}

							//verifica se numero de parcela ja foi utilizado e soma 1
							SE1->(DbSetOrder(1))
							While SE1->(DbSeek(xFilial("SE1") + PadR(cSerie,TamSX3("E1_PREFIXO")[1]) + PadR(cDoc, TamSX3("E1_NUM")[1]) + cParcela + PadR(cFormaPg,3) ))
								cParcela := Soma1(cParcela)
							enddo

							AADD(aFin040, {"E1_FILIAL"	, xFilial("SE1")				,Nil } )
							AADD(aFin040, {"E1_PREFIXO"	, cSerie        				,Nil } )
							AADD(aFin040, {"E1_NUM"		, cDoc   						,Nil } )
							AADD(aFin040, {"E1_PARCELA"	, cParcela		   				,Nil } )
							AADD(aFin040, {"E1_TIPO"	, cFormaPg						,Nil } )
							AADD(aFin040, {"E1_NATUREZ"	, BuscaNaturez(cFormaPg)		,Nil } )
							AADD(aFin040, {"E1_CLIENTE"	, cCliente						,Nil } )
							AADD(aFin040, {"E1_LOJA"	, cLoja							,Nil } )
							If SE1->(FieldPos("E1_DTLANC")) > 0
								AADD(aFin040, {"E1_DTLANC"	, dEmissao					,Nil } )
							EndIf
							AADD(aFin040, {"E1_EMISSAO"	, dEmissao						,Nil } )

							AADD(aFin040, {"E1_PORTADO"	, cBanco						,Nil } )
							AADD(aFin040, {"E1_AGEDEP"	, cAgencia						,Nil } )
							AADD(aFin040, {"E1_CONTA"	, cNumConta						,Nil } )

							if Alltrim(cFormaPg) == "CH"
								
								AADD(aFin040, {"E1_VALOR"   , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_BASCOM1" , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_VLRREAL" , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_VENCTO"	, aParcCond[nI][1]			,Nil})
								AADD(aFin040, {"E1_VENCREA"	, DataValida(aParcCond[nI][1])	,Nil})

								//dados complementares da forma
								//aInfComplem={"EF_VENCTO","EF_VALOR","EF_BANCO","EF_AGENCIA","EF_CONTA","EF_NUM","EF_EMITENT","EF_CPFCNPJ","EF_RG","EF_TEL","L4_COMP","EF_XCMC7"}
								AADD(aFin040, {"E1_BCOCHQ"	, aInfComplem[nX][3]	,Nil } )
								AADD(aFin040, {"E1_AGECHQ"	, aInfComplem[nX][4]	,Nil } )
								AADD(aFin040, {"E1_CTACHQ"	, aInfComplem[nX][5]	,Nil } )
								AADD(aFin040, {"E1_NUMCART"	, aInfComplem[nX][6]	,Nil } )
								AADD(aFin040, {"E1_EMITCHQ"	, aInfComplem[nX][7]	,Nil } )
							elseif Alltrim(cFormaPg) == "CF"
								AADD(aFin040, {"E1_VALOR"   , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_BASCOM1" , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_VLRREAL" , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_VENCTO"	, aParcCond[nI][1]			,Nil})
								AADD(aFin040, {"E1_VENCREA"	, DataValida(aParcCond[nI][1])	,Nil})
								AADD(aFin040, {"E1_NUMCART"	, aInfComplem[nX][3]	,Nil } )
							elseif Alltrim(cFormaPg) $ "CC,CD"
								DbSelectArea("SAE")
								SAE->(DbSetOrder(1))
								SAE->(DbSeek(xFilial("SAE")+aInfComplem[nX][4])) //adm fin

								//BUSCANDO TAXA ADM FINANCEIRA PARA CARTAO
								nValTaxAdm := 0
								If ExistFunc("LJ7_TXADM") .AND. MEN->(ColumnPos("MEN_TAXADM")) > 0
									//LJ7_TxAdm(cCodAdmin, nParc, nValCC)
									aAdmValTax := LJ7_TxAdm( SAE->AE_COD, aInfComplem[nX][8], aParcCond[nI][2] )
									If Len(aAdmValTax) > 0
										nValTaxAdm := aAdmValTax[3]
									EndIf
								EndIf
								If nValTaxAdm == 0
									nValTaxAdm := SAE->AE_TAXA
								EndIf

								AADD(aFin040, {"E1_VALOR"   , (aParcCond[nI][2] * (100 - nValTaxAdm) / 100)	,Nil})
								AADD(aFin040, {"E1_BASCOM1" , (aParcCond[nI][2] * (100 - nValTaxAdm) / 100)	,Nil})
								AADD(aFin040, {"E1_VLRREAL" , aParcCond[nI][2]  								,Nil})
								AADD(aFin040, {"E1_VENCTO"  , (aParcCond[nI][1] + SAE->AE_DIAS) 				,Nil})
								AADD(aFin040, {"E1_VENCREA" , DataValida((aParcCond[nI][1] + SAE->AE_DIAS))		,Nil})

								AADD(aFin040, {"E1_NSUTEF" , aInfComplem[nX][5]		,Nil})
								AADD(aFin040, {"E1_CARTAUT" , aInfComplem[nX][6]		,Nil})

							elseif Alltrim(cFormaPg) == "CT" //CTF
								DbSelectArea("SAE")
								SAE->(DbSetOrder(1))
								SAE->(DbSeek(xFilial("SAE")+aInfComplem[nX][2])) //adm fin

								//BUSCANDO TAXA ADM FINANCEIRA PARA CARTAO
								nValTaxAdm := 0
								If ExistFunc("LJ7_TXADM") .AND. MEN->(ColumnPos("MEN_TAXADM")) > 0
									//LJ7_TxAdm(cCodAdmin, nParc, nValCC)
									aAdmValTax := LJ7_TxAdm( SAE->AE_COD, aInfComplem[nX][4], aParcCond[nI][2] )
									If Len(aAdmValTax) > 0
										nValTaxAdm := aAdmValTax[3]
									EndIf
								EndIf
								If nValTaxAdm == 0
									nValTaxAdm := SAE->AE_TAXA
								EndIf

								AADD(aFin040, {"E1_VALOR"   , (aParcCond[nI][2] * (100 - nValTaxAdm) / 100)	,Nil})
								AADD(aFin040, {"E1_BASCOM1" , (aParcCond[nI][2] * (100 - nValTaxAdm) / 100)	,Nil})
								AADD(aFin040, {"E1_VLRREAL" , aParcCond[nI][2]  								,Nil})
								AADD(aFin040, {"E1_VENCTO"  , (aParcCond[nI][1] + SAE->AE_DIAS) 				,Nil})
								AADD(aFin040, {"E1_VENCREA" , DataValida((aParcCond[nI][1] + SAE->AE_DIAS))		,Nil})
							else //outras formas
								AADD(aFin040, {"E1_VALOR"   , aParcCond[nI][2]  		,Nil})
								AADD(aFin040, {"E1_BASCOM1" , aParcCond[nI][2]  		,Nil})
								if Alltrim(cFormaPg) <> SIMBDIN
									AADD(aFin040, {"E1_VLRREAL" , aParcCond[nI][2]  		,Nil})
								endif
								AADD(aFin040, {"E1_VENCTO"	, aParcCond[nI][1]			,Nil})
								AADD(aFin040, {"E1_VENCREA"	, DataValida(aParcCond[nI][1])	,Nil})
							endif

							AADD(aFin040, {"E1_VEND1" 	,SL1->L1_VEND			,Nil } )
							AADD(aFin040, {"E1_COMIS1" 	,SL1->L1_COMIS			,Nil } )
							If SE1->(FieldPos("E1_XPLACA")) > 0
								AADD(aFin040, {"E1_XPLACA" 	,SL1->L1_PLACA		,Nil } )
							endif

							AADD(aFin040, {"E1_NUMNOTA" ,cDoc						,Nil } )
							AADD(aFin040, {"E1_SERIE" 	,cSerie						,Nil } )
							AADD(aFin040, {"E1_SDOC" 	,cSerie						,Nil } )
							//AADD(aFin040, {"E1_ORIGEM" 	,"LOJA701"					,Nil } )
							AADD(aFin040, {"E1_HIST" 	,oMsFPagNew:aCols[nX][nPosHist]	,Nil } )
							If SE1->(FieldPos("E1_XCOND")) > 0
								if SE1->(FieldPos("E1_XDTFATU")) > 0 
									AADD( aFin040, {"E1_XDTFATU" , U_TRETE014(oMsFPagNew:aCols[nX][nPosCond], aParcCond[nI][1]) ,Nil } )
								endif
								AADD(aFin040, {"E1_XCOND" 	,oMsFPagNew:aCols[nX][nPosCond] ,Nil } )
							endif

							//execucao da rotina automática do título
							lMsErroAuto := .F.
							lMsHelpAuto := .F.
							SA3->(DbSetOrder(1)) //forço indice para nao dar erro no ExistCpo da validacao padrao.
							MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 3)
							if lMsErroAuto
								MostraErro()
								DisarmTransaction()
								lOk := .F.
								EXIT
							else
								If RecLock('SE1',.F.)
									SE1->E1_ORIGEM := "LOJA701"
									SE1->(MsUnlock())
								EndIf
								cLogCaixa += Space(4) + SE1->E1_PARCELA + " | " + SE1->E1_TIPO + " | " +;
											 iif(SE1->E1_VLRREAL > 0, Transform(SE1->E1_VLRREAL ,"@E 999,999,999.99"), Transform(SE1->E1_VALOR ,"@E 999,999,999.99")) +;
											 " | " + DTOC(SE1->E1_VENCTO) + " | " + SE1->E1_CLIENTE +" | "+SE1->E1_LOJA+" | "+Alltrim(SE1->E1_NOMCLI) + CRLF

								if Alltrim(cFormaPg) == "CH"
									GravaSEF(3, aInfComplem[nX], SE1->E1_VALOR, SE1->E1_VENCTO) //gravo cheque SEF
								elseif Alltrim(cFormaPg) == SIMBDIN //dinheiro (somente para venda)
									if !BxDinheiro(SE1->(RECNO()),cBanco,cAgencia,cNumConta, SL1->L1_HORA, "BAIXA REF VENDA EM DINHEIRO")
										DisarmTransaction()
										lOk := .F.
										EXIT
									endif
								elseif Alltrim(cFormaPg) == "CR"
									if !CompensaCred(1, SE1->(Recno()), aInfComplem[nX][3][5]) //Chama tela padrão de compensaçao financeira
										MsgAlert("Compensação de crédito não concluída! Operação Abortada.","Atenção")
										DisarmTransaction()
										lOk := .F.
										EXIT
									endif
								endif
							endif

							cParcela := Soma1(cParcela)
						next nI
					endif

				else //COMPENSACAO
					
					cDoc := UC0->UC0_NUM
					cSerie := cPfxCmp

					nParcGrv := 1
					aParcCond := {}
					if Alltrim(cFormaPg) $ "CC/CD"
						nParcGrv := aInfComplem[nX][8] //parcelas
						if nParcGrv > 1
							//Ajusto valor da parcela
							nDiferenca := Round( oMsFPagNew:aCols[nX][nPosVal] - (( Round( oMsFPagNew:aCols[nX][nPosVal] / nParcGrv,2) ) * nParcGrv), 2)
							For nI := 1 to nParcGrv
								dData := SLW->LW_DTABERT + IIf(nI = 1, 0, nIntervalo*(nI-1))
								nValor := Round( oMsFPagNew:aCols[nX][nPosVal] / nParcGrv, 2 )
								if nI == nParcGrv //ultima parcela soma diferença
									nValor := Round( nValor + nDiferenca, 2 )
								endif
								aadd(aParcCond, {nValor, dData})
							next nI
						else
							aadd(aParcCond, {oMsFPagNew:aCols[nX][nPosVal], SLW->LW_DTABERT})
						endif
					endif

					for nI := 1 to nParcGrv
						cParcela := Soma1(cParcela)

						Reclock("UC1", .T.) //inclui
						UC1->UC1_FILIAL := UC0->UC0_FILIAL
						UC1->UC1_NUM 	:= UC0->UC0_NUM
				 		UC1->UC1_FORMA	:= cFormaPg
				 		UC1->UC1_SEQ	:= cParcela

				 		if Alltrim(cFormaPg) == "CH"
						 	cCliente := UC0->UC0_CLIENT
							cLoja := UC0->UC0_LOJA
				 			//aInfComplem={"EF_VENCTO","EF_VALOR","EF_BANCO","EF_AGENCIA","EF_CONTA","EF_NUM","EF_EMITENT","EF_CPFCNPJ","EF_RG","EF_TEL","L4_COMP","EF_XCMC7"}
				 			UC1->UC1_VALOR	:= aInfComplem[nX][2]
				 			UC1->UC1_VENCTO := aInfComplem[nX][1]
				 			UC1->UC1_BANCO 	:= aInfComplem[nX][3]
				 			UC1->UC1_AGENCI := aInfComplem[nX][4]
				 			UC1->UC1_CONTA 	:= aInfComplem[nX][5]
				 			UC1->UC1_NUMCH 	:= aInfComplem[nX][6]
				 			UC1->UC1_CGC 	:= aInfComplem[nX][8]
				 			UC1->UC1_RG 	:= aInfComplem[nX][9]
				 			UC1->UC1_TEL1 	:= aInfComplem[nX][10]
				 			UC1->UC1_COMPEN := aInfComplem[nX][11]
				 			UC1->UC1_CMC7 	:= aInfComplem[nX][12]
				 		elseif Alltrim(cFormaPg) $ "CC/CD"
							if Posicione("SAE",1,xFilial("SAE")+aInfComplem[nX][4], "AE_FINPRO" )=="S"
								cCliente := UC0->UC0_CLIENT 
								cLoja := UC0->UC0_LOJA 
							else
								cCliente := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] )
								cLoja := PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
							endif
				 			//aInfComplem={nList, cRedeAut, cBandeira, cAdmFin, cNsuDoc, cAutoriz, dDataTran, nParcelas}
				 			UC1->UC1_VALOR	:= aParcCond[nI][1]
				 			UC1->UC1_VENCTO := aParcCond[nI][2]
				 			UC1->UC1_ADMFIN := aInfComplem[nX][4]
				 			UC1->UC1_NSUDOC := aInfComplem[nX][5]
				 			UC1->UC1_CODAUT := aInfComplem[nX][6]
				 			UC1->UC1_OBS 	:= "REDEAUT:"+Alltrim(aInfComplem[nX][2])+" / BANDEIRA:"+Alltrim(aInfComplem[nX][3])
				 			UC1->UC1_COMPEN := cValToChar(aInfComplem[nX][8]) //num de parcelas
				 		elseif Alltrim(cFormaPg) == "CF"
							cCliente := Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_COD")
							cLoja := SA1->A1_LOJA
				 			//aInfComplem={cCGCEmit, cNomEmit, cNumCF, nValor, cHist, dData}
				 			UC1->UC1_VALOR	:= aInfComplem[nX][4]
				 			UC1->UC1_VENCTO := aInfComplem[nX][6]
				 			UC1->UC1_CGC 	:= aInfComplem[nX][1]
				 			UC1->UC1_CFRETE := aInfComplem[nX][3]
				 			UC1->UC1_OBS 	:= aInfComplem[nX][5]
				 		endif

				 		UC1->(MsUnlock())

						cLogCaixa += Space(4) + UC1->UC1_SEQ + " | " + UC1->UC1_FORMA + " | " +;
									Transform(UC1->UC1_VALOR ,"@E 999,999,999.99") + " | " + DTOC(SE1->E1_VENCTO) + ;
									" | " + cCliente +" | "+cLoja+" | "+Alltrim(Posicione("SA1",1,xFilial("SA1")+cCliente+cLoja, "A1_NREDUZ")) + CRLF
					next nI

					//reprocesso job financeiro para gerar novas parcelas
					RecLock("UC0", .F.)
					UC0->UC0_GERFIN := "R"
					UC0->(MsUnlock())
					cMsgErro := ""
					lOk := U_TRETE024(UC0->UC0_NUM,@cMsgErro)
					if !lOk
						MsgAlert("Falha ao gerar financeiro da compensação! "+ CRLF +cMsgErro,"Atenção")
						DisarmTransaction()
					endif
				endif

				if !lOk
					EXIT
				endif
			endif
		next nX
	endif
	
	if lOk .AND. lLogCaixa
		GrvLogConf("2","A", cLogCaixa, cDoc, cSerie)
	endif

	EndTran()

Return lOk

//-----------------------------------------------------------------------------------------
// Retorna a Natureza de acordo com a forma e tipo
//-----------------------------------------------------------------------------------------
Static Function BuscaNaturez(nFormaPg)

	Local cNature := ""
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")

	Do Case //Busca Natureza
		Case Alltrim(nFormaPg) == "VA"
			cNature := &(SuperGetMV("MV_NATVALE"))
		Case Alltrim(nFormaPg) == "CC"
			cNature := &(SuperGetMV("MV_NATCART"))
		Case Alltrim(nFormaPg) $ "CH,CHP"
			cNature := SuperGetMV("MV_NATCHEQ")
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("MV_NATCHEQ"))
			endif
		Case Alltrim(nFormaPg) == "CD"
			cNature := SuperGetMV("MV_NATTEF")
			If SubStr(cNature,1,1) == "&"
				cNature := SubStr(cNature,2,Len(cNature))
				//------------------------------------------------------------------------------------------------------
				// Se MV_NATTEF Iniciar com & passo o conteudo apartir do segundo byte para ser expandido via macro,
				// senao passo o label para na expansao pegar o conteudo
				//------------------------------------------------------------------------------------------------------
				cNature := &(cNature)
			Elseif SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("MV_NATTEF"))
			EndIf
		Case Alltrim(nFormaPg) == "CO"
			cNature := &(SuperGetMV("MV_NATCONV"))
		Case Alltrim(nFormaPg) == "FI"
			cNature := &(SuperGetMV("MV_NATFIN"))
		Case Alltrim(nFormaPg) == SIMBDIN
			cNature := &(SuperGetMV("MV_NATDINH"))
		Case Alltrim(nFormaPg) == "CR"
			cNature := &(SuperGetMV("MV_NATCRED"))
		Case Alltrim(nFormaPg) == "NP"
			cNature := SuperGetMv( "TP_NATNP" , .F. , "OUTROS",)
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("TP_NATNP"))
			endif
		Case Alltrim(nFormaPg) == "CT"
			cNature := SuperGetMv( "TP_NATCT" , .F. , "OUTROS",)
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("TP_NATCT"))
			endif
		Case Alltrim(nFormaPg) == "CF"
			cNature := SuperGetMv("TP_NATCF",.F.,"OUTROS")
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("TP_NATCF"))
			endif
		Case Alltrim(nFormaPg) $ cFPConv .AND. !empty(SuperGetMV("TP_NAT"+Alltrim(nFormaPg),,""))
			cNature := SuperGetMV("TP_NAT"+Alltrim(nFormaPg),,"")
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("TP_NAT"+Alltrim(nFormaPg),,""))
			endif
		Case Alltrim(nFormaPg) == "PD"
			cNature := SuperGetMv( "MV_NATPGDG" , .F. , "PAGDIGITAL",)
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("MV_NATPGDG"))
			endif
		Case Alltrim(nFormaPg) == "PX"
			cNature := SuperGetMv( "MV_NATPGPX" , .F. , "PAGTOPIX",)
			if SubStr(cNature, 1, 1) == '"' .OR. SubStr(cNature, 1, 1) == "'"
				cNature := &(SuperGetMV("MV_NATPGPX"))
			endif
		Otherwise
			cNature := &(SuperGetMV("MV_NATOUTR"))
	EndCase

Return cNature

//-----------------------------------------------------------------------------------------
// Faz gravaçao da SEF
// Deve estar posicionado na SE1 que será relacionada
// aDadosCheque={"SEQ","EF_VENCTO","EF_VALOR","EF_BANCO","EF_AGENCIA","EF_CONTA","EF_NUM","EF_XCODEMI","EF_XLOJEMI","EF_EMITENT","EF_CPFCNPJ","EF_RG","EF_TEL","EF_TEL2","L4_COMP","EF_XCMC7"}
//-----------------------------------------------------------------------------------------
Static Function GravaSEF(nOpc, aDadosCheque, nValor, dVencto)

	Local lInclui := .T.
	Default aDadosCheque := {}
	Default nValor := 0
	Default dVencto := STOD("")

	if nOpc <> 3
		lInclui := .F.
	endif

	DbSelectArea("SEF")

	RecLock("SEF", lInclui) //inclui

	if nOpc == 5
		SEF->(DbDelete())
	else
		SEF->EF_FILIAL 	:= xFilial("SEF")
		SEF->EF_FILORIG	:= cFilAnt
		SEF->EF_BANCO 	:= aDadosCheque[3]
		SEF->EF_AGENCIA	:= aDadosCheque[4]
		SEF->EF_CONTA	:= aDadosCheque[5]
		SEF->EF_NUM		:= aDadosCheque[6]
		SEF->EF_VALOR	:= nValor
		SEF->EF_VALORBX	:= nValor
		SEF->EF_DATA	:= dDataBase
		SEF->EF_VENCTO	:= dVencto
		SEF->EF_PREFIXO	:= SE1->E1_PREFIXO
		SEF->EF_TITULO	:= SE1->E1_NUM
		SEF->EF_PARCELA	:= SE1->E1_PARCELA
		SEF->EF_TIPO	:= SE1->E1_TIPO
		SEF->EF_BENEF	:= SM0->M0_NOMECOM
		SEF->EF_CLIENTE := SE1->E1_CLIENTE
		SEF->EF_LOJACLI := SE1->E1_LOJA
		SEF->EF_CPFCNPJ := aDadosCheque[8]
		SEF->EF_EMITENT := aDadosCheque[7]
		SEF->EF_CART	:= "R"
		SEF->EF_ORIGEM  := "FINA040" //alterado para funcionar corretamente a rotina de baixa de cheques
		SEF->EF_RG		:= aDadosCheque[9]
		SEF->EF_TERCEIR := .T.
		SEF->EF_TEL		:= aDadosCheque[10]
		if SEF->(FieldPos("EF_COMP")) > 0
			SEF->EF_COMP	:= aDadosCheque[11]
		endif
		if SEF->(FieldPos("EF_XCMC7")) > 0
			SEF->EF_XCMC7	:= aDadosCheque[12]
		endif
		SEF->EF_NUMNOTA	:= SE1->E1_NUM
		SEF->EF_SERIE	:= SE1->E1_PREFIXO
	endif

	SEF->(MsUnlock())

	//ponto de entrada para manipular campos da SEF ou SE1 referente a cheques
	//Já posicionado em ambas tabelas SE1 e SEF
	If ExistBlock("TPINCSEF")
		ExecBlock("TPINCSEF",.F.,.F.,{"3"}) //Parametros; 1=Venda (gravabatch); 2=Compensação; 3=Conferencia Caixa
	EndIf

Return .T.

//-------------------------------------------------------
// Busca créditos de cliente
//-------------------------------------------------------
Static Function FindCredCl(cCliente,cLojaCli,cBusca)

	Local nX := 0
	Local aListGdNeg := {}

	aNCCsCli := U_TPDVE006(cCliente,cLojaCli,cBusca)

	//atualiza todos
	For nX:=1 to Len(aNCCsCli)
		//R$ SALDO / TIPO / PREFIXO / NUM / PARCELA / EMISSAO / CODBAR / FILIAL
		aadd(aListGdNeg,;
			'R$ '+Alltrim(Transform(aNCCsCli[nX][2],PesqPict("SL1","L1_VLRLIQ")))+' / '+;
			AllTrim(aNCCsCli[nX][11])+' / '+;
			AllTrim(aNCCsCli[nX][9])+' / '+;
			AllTrim(aNCCsCli[nX][3])+' / '+;
			AllTrim(aNCCsCli[nX][10])+' / '+;
			DtoC(aNCCsCli[nX][4])+' / '+;
			AllTrim(aNCCsCli[nX][15])+' / '+;
			AllTrim(aNCCsCli[nX][14]);
		)
	Next nX

	oListGdNeg:SetItems(aListGdNeg)

Return .T.

//----------------------------------------------------------------------------
// Faz compensaçao do titulo SE1 posicionado.
// nOpcxCp: 1=Compensar ; 2=Estornar
//----------------------------------------------------------------------------
Static Function CompensaCred(nOpcxCp, nRecnoE1, nRecnoRA)

	Local lRetOK := .T.
	Local aArea  := SE1->(GetArea())
	Local _SE1Rec:= SE1->(Recno())
	Local lContabiliza, lAglutina, lDigita
	Local aRecRA, aRecSE1

	if nOpcxCp == 1
		PERGUNTE("AFI340",.F.)
		lContabiliza  := MV_PAR11 == 1
		lAglutina   := MV_PAR08 == 1
		lDigita   := MV_PAR09 == 1

		SE1->(dbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_FORNECE+E1_LOJA

		aRecRA := { nRecnoRA }
		aRecSE1 := { nRecnoE1 }

		If !MaIntBxCR(3,aRecSE1,,aRecRA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,SLW->LW_DTABERT )
			lRetOK := .F.
		else
			//Tratamento para alterar status da requisição pré U57, usada na venda
			U_TRA028CR() 
		EndIf
	elseif nOpcxCp == 2
		//Tratamento para alterar status da requisição pré U57, usada na venda
		U_TRA028CR(.T.) //estorna

		//Fa330Desc("SE1", SE1->(Recno()), 4)
		FINA330(4 /*nOpc exclusao*/, .T./*lAuto*/)
		SE1->(DbGoto(_SE1Rec))
		If !Empty(SE1->E1_BAIXA)
			MsgInfo("Confirme o estorno da compensação para continuar. Processo Abortado!", "Atenção")
			lRetOK := .F.
			//Desfaço alterar status da requisição pré U57, usada na venda
			U_TRA028CR()
		EndIf
	else
		lRetOK := .T.
	endif

	RestArea(aArea)

Return lRetOK

//--------------------------------------------------------------------------------------
// Tela Genérica de manutenção de formas de pagamento (recebidas SE1)
//--------------------------------------------------------------------------------------
Static Function ManutForma(cForma, nRecSE1, lAltVal, lAltSacado, lAltVencto, bRefresh)

	Local lAdmFin := .F.
	Local nPosFunc := aScan(aFormasHab, {|x| x[1] == cForma })
	Local cDescForma := aFormasHab[nPosFunc][2]
	Local oPrefixo,oTitulo,oParcela,oTipo,oCodCli,oLoja,oNomeCli,oVencto,oVencRea,oValor
	Local cCodCli, cLojCli, cNomCli, dVencto, dVencRea, nValor, cNSUDOC, cCodAuto
	Local oFntVlr := TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local nOpcx := 0

	Private oDlgAux

	if empty(nRecSE1)
		Return
	endif

	SE1->(DbGoTo(nRecSE1))

	if !Empty(SE1->E1_BAIXA)
		MsgInfo("O título se encontra baixado. Operação nao permitida.","Atenção")
		Return
	EndIf

	cCodCli := SE1->E1_CLIENTE
	cLojCli := SE1->E1_LOJA
	dVencto := SE1->E1_VENCTO
	dVencRea := SE1->E1_VENCREA //DataValida(aParcCond[nI][1])
	nValor := iif(SE1->E1_VLRREAL > 0, SE1->E1_VLRREAL, SE1->E1_VALOR)
	cNSUDOC := SE1->E1_NSUTEF
	cCodAuto := SE1->E1_CARTAUT

	//nao permito alterar TEF
	if lAltVal .AND. !empty(SE1->E1_DOCTEF)
		lAltVal := .F.
	endif

	//verifico se é cliente ou ADM Financeira
	//TODO Alterar busca para campo E1_ADM
	if Len(Alltrim(SE1->E1_CLIENTE)) == 3
		SAE->(DbSetOrder(1))
		SAE->(DbSeek(xFilial("SAE")+ Alltrim(SE1->E1_CLIENTE) ))
		lAdmFin := .T.
	endif

	DEFINE MSDIALOG oDlgAux TITLE ("Manutenção - "+Capital(cDescForma)) STYLE DS_MODALFRAME FROM 000, 000  TO 400, 400 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgAux,05,05,172,190,.F.,.T.,.T.)

	@ 005, 010 SAY "Prefixo" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 013, 010 MSGET oPrefixo VAR SE1->E1_PREFIXO SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL When .F.

	@ 005, 045 SAY "Numero" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 013, 045 MSGET oTitulo VAR SE1->E1_NUM SIZE 065, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL When .F.

	@ 005, 115 SAY "Parcela" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 013, 115 MSGET oParcela VAR SE1->E1_PARCELA SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL When .F.

	@ 005, 150 SAY "Tipo" SIZE 030, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 013, 150 MSGET oTipo VAR SE1->E1_TIPO SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL When .F.

	@ 026, 002 SAY Replicate("_",184) SIZE 184, 007 OF oPnlDet COLORS CLR_HGRAY, 16777215 PIXEL

	@ 037, 010 SAY "Cliente" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 045, 010 MSGET oCodCli VAR cCodCli SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL WHEN lAltSacado F3 "SA1" VALID (!lAdmFin .OR. len(Alltrim(cCodCli))==3) .AND. oDlgAux:Refresh()

	@ 037, 075 SAY "Loja" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 045, 075 MSGET oLoja VAR cLojCli SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL WHEN lAltSacado VALID oDlgAux:Refresh()

	@ 059, 010 SAY "Nome Cliente" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 067, 010 MSGET oNomeCli VAR (cNomCli:=Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")) When .F. SIZE 150, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 081, 010 SAY "Vencimento" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 089, 010 MSGET oVencto VAR dVencto SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL WHEN lAltVencto VALID (dVencRea:=DataValida(dVencto), oDlgAux:Refresh() )

	@ 081, 075 SAY "Vencto.Real" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 089, 075 MSGET oVencRea VAR dVencRea When .F. SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 111, 010 SAY "Valor" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 108, 045 MSGET oValor VAR nValor SIZE 105, 013 OF oPnlDet HASBUTTON COLORS 0, 16777215 FONT oFntVlr PIXEL WHEN lAltVal Picture PesqPict("SE1","E1_VALOR") VALID nValor>=0

	@ 182, 155 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oDlgAux PIXEL Action (nOpcx := 1, oDlgAux:End())
	oButton1:SetCSS( CSS_BTNAZUL )
	@ 182, 110 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgAux PIXEL Action oDlgAux:End()

	ACTIVATE MSDIALOG oDlgAux CENTERED

	LjMsgRun("Processando alteração dos dados...","Aguarde...",{|| ProcMntForm(cForma, cCodCli, cLojCli, cNomCli, dVencto, nValor, lAltVal, lAltSacado, lAltVencto, lAdmFin) })

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Valida e Processa gravaçao da tela de manutnçao titulos generica
//--------------------------------------------------------------------------------------
Static Function ProcMntForm(cForma, cCodCli, cLojCli, cNomCli, dVencto, nValor, lAltVal, lAltSacado, lAltVencto, lAdmFin, aCpExtraSE1, lCtrTran, aInfComp)

	Local lOk := .T.
	Local nX := 0
	Local aFin040 := {}
	Local nDifValor := nValor - iif(SE1->E1_VLRREAL > 0, SE1->E1_VLRREAL, SE1->E1_VALOR)
	Local lAddDinhe := .F.
	Local nTotTroDin := 0
	Local lCMP := .F. //Define se é compensação de valores ou nao
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local cBkpOrigem := ""
	Default aCpExtraSE1 := {}
	Default lCtrTran := .T.
	Default aInfComp := {}

	if empty(cCodCli) .OR. empty(cLojCli) .OR. empty(cNomCli) .OR. empty(dVencto) .OR. empty(nValor)
		MsgInfo("Campos obrigatórios nao foram preenchidos!","Atenção")
		Return .F.
	endif

	if lMvPosto .AND. Alltrim(SE1->E1_PREFIXO) == Alltrim(cPfxComp)
		lCMP := .T.
	endif

	if lAltSacado .AND. lAdmFin //se altera sacado de adm financeira, sempre deve ajustar valor por causa da taxa
		lAltVal := .T.
	endif

	if lAltVal .AND. !lCMP .AND. nDifValor < 0 //se diminuiu o valor, verifico o troco do cupom
		nTotTroDin := U_T028TTV(4,,,"E5_PREFIXO = '"+SE1->E1_PREFIXO+"' AND E5_NUMERO = '"+SE1->E1_NUM+"'",.F.,.F.)
		if Abs(nDifValor) > nTotTroDin
			lAddDinhe := .T.
		endif
	endif

	AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL		, Nil})
	AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO		, Nil})
	AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM			, Nil})
	AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA		, Nil})
	AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO			, Nil})

	if lAltVencto
		AADD( aFin040, {"E1_VENCTO"   , dVencto , Nil})
	endif

	if lAltVal
		if lAdmFin .AND. !(Alltrim(cForma) $ SIMBDIN+",CH") //tira cheque e dinheiro
			SAE->(DbSetOrder(1))
			//TODO trocar para E1_ADM
			SAE->(DbSeek(xFilial("SAE")+ Alltrim(cCodCli) ))
			AADD( aFin040, {"E1_VALOR"   , (nValor * (100 - SAE->AE_TAXA) / 100)  ,Nil})
			AADD( aFin040, {"E1_BASCOM1" , (nValor * (100 - SAE->AE_TAXA) / 100)  , Nil})
			AADD( aFin040, {"E1_VLRREAL" , nValor  ,Nil})
		else
			AADD( aFin040, {"E1_VALOR"    , nValor			   		, Nil})
			AADD( aFin040, {"E1_BASCOM1"  , nValor			  		, Nil})
			if !(Alltrim(cForma) $ SIMBDIN)
				AADD( aFin040, {"E1_VLRREAL"  , nValor			  		, Nil})
			endif
		endif
	endif

	if lCtrTran
		BeginTran()
	endif

	if lAltVencto .OR. lAltVal
		lMsErroAuto := .F.
		lMsHelpAuto := .T.

		//apaga a origem para ser possível alteração/exclusão do titulo
		cBkpOrigem := SE1->E1_ORIGEM
		RecLock("SE1",.F.)
			SE1->E1_ORIGEM := ""
		SE1->(MsUnlock())

		MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 4)

		if lMsErroAuto
			MostraErro()
			lOk := .F.
		endif

		//volta a origem 
		RecLock("SE1",.F.)
			SE1->E1_ORIGEM := cBkpOrigem
		SE1->(MsUnlock())
	endif

	if lOk
		RecLock("SE1",.F.)
		if lAltSacado
			SE1->E1_CLIENTE := cCodCli
			SE1->E1_LOJA	:= cLojCli
			SE1->E1_NOMCLI	:= cNomCli
		endif

		//campos extras
		for nX := 1 to len(aCpExtraSE1)
			SE1->&(aCpExtraSE1[nX][1]) := aCpExtraSE1[nX][2]
		next nX

		SE1->(MsUnLock())
	endif

	if lOk
		if lCMP //se compensação, atualizos os dados na UC1
			UC1->(DbSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
			if UC1->(DbSeek(xFilial("UC1")+SE1->E1_NUM+SE1->E1_TIPO+SE1->E1_PARCELA))
				RecLock("UC1", .F.)
				if lAltVal
					UC1->UC1_VALOR  := SE1->E1_VLRREAL
				endif
				if lAltVencto
					UC1->UC1_VENCTO := SE1->E1_VENCTO
				endif
				if Alltrim(SE1->E1_TIPO) == "CH"
					UC1->UC1_BANCO 	:= aInfComp[3]
		 			UC1->UC1_AGENCI := aInfComp[4]
		 			UC1->UC1_CONTA 	:= aInfComp[5]
		 			UC1->UC1_NUMCH 	:= aInfComp[6]
		 			UC1->UC1_CGC 	:= aInfComp[8]
		 			UC1->UC1_RG 	:= aInfComp[9]
		 			UC1->UC1_TEL1 	:= aInfComp[10]
		 			UC1->UC1_COMPEN := aInfComp[11]
		 			UC1->UC1_CMC7 	:= aInfComp[12]
				elseif Alltrim(SE1->E1_TIPO) $ "CC/CD"
		 			UC1->UC1_ADMFIN := aInfComp[4]
		 			UC1->UC1_NSUDOC := aInfComp[5]
		 			UC1->UC1_CODAUT := aInfComp[6]
		 			UC1->UC1_OBS 	:= "REDEAUT:"+Alltrim(aInfComp[2])+" / BANDEIRA:"+Alltrim(aInfComp[3])
		 			if Val(UC1->UC1_COMPEN) > 1
		 				MsgInfo("Cartão parcelado! Caso necessário, ajuste também as demais parcelas.","Aviso")
		 			endif
				elseif Alltrim(SE1->E1_TIPO) == "CF"
					UC1->UC1_CGC 	:= aInfComp[1]
		 			UC1->UC1_CFRETE := aInfComp[3]
		 			UC1->UC1_OBS 	:= aInfComp[5]
				endif
				UC1->(MsUnlock())

				if lAltVal .AND. nDifValor <> 0 .AND. !U_TRETE29J(iif(nDifValor>0,5,6), Abs(nDifValor), UC1->UC1_NUM )
					MsgAlert("Falha na alteração do valor em dinheiro da saida da compensação! Operação abortada!","Atenção")
					lOk := .F.
				endif
			else
				MsgAlert("Parcela da compensação não encontrada para a manutenção! Operação abortada.","Atenção")
				lOk := .F.
			endif
		else //é venda (cupom/NFCE)
			if lAltVal .AND. nDifValor <> 0
				SL1->(DbSetOrder(2)) //L1_FILIAL + L1_SERIE + L1_DOC + L1_PDV
				If SL1->(DbSeek(xFilial("SL1")+SE1->E1_PREFIXO+SE1->E1_NUM))

					if lAddDinhe
						if !AjuSL1Din(1, Abs(nDifValor), .F., .T.) //tento adicionar a diferença em dinheiro
							MsgInfo("Não foi possível jogar a diferença como dinheiro. Operação abortada! Caso necessário, adicione manualmente o valor da diferença em dinheiro (opção Ajuste Dinheiro) para gerar troco na venda.","Atenção")
							lOk := .F.
						endif
					endif

					if lOk .AND. !AjuSL1Troco(.T.)
						MsgAlert("Falha na alteração do valor em dinheiro do troco da venda! Operação abortada!","Atenção")
						lOk := .F.
					endif
				else
					MsgAlert("Falha ao localizar venda para ajuste da diferença do valor. Operação abortada.","Atenção")
					lOk := .F.
				endif
			endif
		endif
	endif

	if lCtrTran
		if !lOk
			DisarmTransaction()
		endif
		EndTran()
	endif

Return lOk

//--------------------------------------------------------------------------------------
// Tela de manutenção de cartão de crédito e débito
//--------------------------------------------------------------------------------------
Static Function ManCartao(cForma, nRecSE1, bRefresh)

	Local lOk := .T.
	Local bValTela
	Local aDadosAux := {}
	Local aDadosBkp := {}
	Local oPanelCC
	Local nOpcRet := 0
	Local nVlrAnt := 0
	Local aCpExtraSE1 := {}
	Local nDifMant := SuperGetMv("MV_XDIFMAN", .F., 0.10) //Valor máximo para acrescentar ou diminuir no valor da manutenção de cartão
	Local cLogCaixa := "AJUSTE MANUTENÇÃO DE CARTÃO:" + CRLF + CRLF
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local nX := 0
	Private oDlgCC

	If Empty(nRecSE1)
		Return
	EndIf

	SE1->(DbGoTo(nRecSE1))

	If !Empty(SE1->E1_BAIXA)
		MsgInfo("O título se encontra baixado. Operação não permitida.","Atenção")
		Return
	EndIf

	nVlrAnt := iif(SE1->E1_VLRREAL > 0, SE1->E1_VLRREAL, SE1->E1_VALOR)

	SAE->(DbSetOrder(1)) //AE_FILIAL+AE_COD
	If !SAE->(DbSeek(xFilial("SAE")+SubStr(SE1->E1_CLIENTE, 1, TamSx3("AE_COD")[1])))
		SAE->(DbSetOrder(2)) //AE_FILIAL+AE_CODCLI
		SAE->(DbSeek(xFilial("SAE")+SE1->E1_CLIENTE))
		While SAE->(!Eof()) .and. (SE1->E1_CLIENTE == SAE->AE_CODCLI .and. SE1->E1_LOJA <> SAE->AE_LOJCLI)
			SAE->(DbSkip())
		EndDo
		If SAE->(Eof()) .or. .not.(SE1->E1_CLIENTE == SAE->AE_CODCLI .and. SE1->E1_LOJA == SAE->AE_LOJCLI)
			MsgInfo("Cadastro de administradora financeira não encontrada. Operação não permitida.","Atenção")
			Return
		EndIf
	EndIf

	If SAE->(Eof())
		MsgInfo("Cadastro de administradora financeira não encontrada. Operação não permitida.","Atenção")
		Return
	EndIf

	//{nValor, cRedeAut, cBandeira, cAdmFin, cNsuDoc, cAutoriz, dDataTran, nParcelas}
	aDadosAux := {;
		nVlrAnt,;
		SAE->AE_REDEAUT,;
		SAE->AE_ADMCART ,;
		SAE->AE_COD,;
		SE1->E1_NSUTEF,;
		SE1->E1_CARTAUT, ;
		SE1->E1_EMISSAO,;
		1;
	}

	oDlgCC := TDialog():New(0,0,400,375,"Manutenção de Cartão",,,,,,,,,.T.)

	cLogCaixa += "VALOR ANTERIOR: [VALOR] " +Transform(aDadosAux[1],"@E 999,999,999.99")+ " | [OPERADORA] " +aDadosAux[2]+ " | [BANDEIRA] " +aDadosAux[3]+ " | [NSU] " +aDadosAux[5]+ " | [AUTORIZACAO] " +aDadosAux[6]+ CRLF + CRLF

	// crio o panel para mudar a cor da tela
	@ 0, 0 MSPANEL oPanelCC SIZE 100, 100 OF oDlgCC COLORS 0, 16777215
	oPanelCC:Align := CONTROL_ALIGN_ALLCLIENT

	MontaCpCart(cForma, oPanelCC, aDadosAux, .F.)
	bValTela := {|| aDadosAux[1]>0 .AND. !empty(aDadosAux[4]) .AND. !empty(aDadosAux[5]) .AND. !empty(aDadosAux[6]) .AND. aDadosAux[8]>0 .AND. ( aDadosAux[1]>=(nVlrAnt-nDifMant) .AND. aDadosAux[1]<=(nVlrAnt+nDifMant) )  }

	aDadosBkp := aClone(aDadosAux)

	@ 180, 145 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgCC ACTION iif(Eval(bValTela),(nOpcRet := 1,oDlgCC:End()),MsgInfo("Campos obrigatórios nao preenchidos corretamente! (Valor máximo a ser corrigido no parâmetro [MV_XDIFMAN]: "+cValToChar(nDifMant)+")","Atenção")) PIXEL
	oBtnOK:SetCss(CSS_BTNAZUL)
	@ 180, 100 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgCC ACTION oDlgCC:End() PIXEL

	oDlgCC:lCentered := .T.
	oDlgCC:Activate()

	If nOpcRet == 1 //opção "Confirmar"
		nOpcRet := 0
		For nX := 1 to Len(aDadosAux) //verifica se houve alteração dos dados
			If .not.(aDadosAux[nX] == aDadosBkp[nX])
				nOpcRet := 1
				Exit //sai do For
			EndIf
		Next nX
	EndIf

	If nOpcRet <> 1
		Return
	EndIf

	BeginTran()

	SAE->(DbSetOrder(1)) //AE_FILIAL+AE_COD
	SAE->(DbSeek(xFilial("SAE")+SubStr(aDadosAux[4], 1, TamSx3("AE_COD")[1])))

	cCodCli := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] ) //adm fin
	cLojCli	:= PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
	cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")

	aadd(aCpExtraSE1, {"E1_NSUTEF", aDadosAux[5]})
	aadd(aCpExtraSE1, {"E1_CARTAUT", aDadosAux[6]})

	//processo alteraçao financeira
	LjMsgRun("Processando alteração dos dados...","Aguarde...",{|| lOk := ProcMntForm(cForma, cCodCli, cLojCli, cNomCli, aDadosAux[7], aDadosAux[1], .T., .T., .F., .T., aCpExtraSE1, .F., aDadosAux) })

	If !lOk
		DisarmTransaction()
	EndIf
	EndTran()

	If lOk .and. lLogCaixa
		cLogCaixa += "NOVO VALOR: [VALOR] " +Transform(aDadosAux[1],"@E 999,999,999.99")+ " | [OPERADORA] " +aDadosAux[2]+ " | [BANDEIRA] " +aDadosAux[3]+ " | [NSU] " +aDadosAux[5]+ " | [AUTORIZACAO] " +aDadosAux[6]+ CRLF
		GrvLogConf("2","A", cLogCaixa, IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC), IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE))
	EndIf

	If bRefresh <> Nil
		EVal(bRefresh)
	EndIf

Return

//----------------------------------------------------------
// Monta campos da cartão - manutencao
//----------------------------------------------------------
Static Function MontaCpCart(cForma, oPnlCC, aDadosAux, lAltParc, nLinCp)

	Local oVlrRec, oRedeAut, oBandeira, oAdmFin, oNsuDoc, oAutoriz, oDataTran, oParcelas
	Local nPosAux
	Local aMyAdmFin, aMyRede, aMyBandei, aTmpAdm
	Local lSelAdm := SuperGetMV("MV_XSELADM",,.F.) //Define se ao inves de selecionar OPERADORA + BANDEIRA (.F.), será selecionado ADM. FINANCEIRA (.T.)
	Default nLinCp := 10

	//buscando adm financeiras
	aMyAdmFin := GetAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	//TODO Retirar isso futuramente (controle do CCP e CDP)
	aTmpAdm := GetAdmFinan(Alltrim(cForma)+"P") //forma CCP e CDP
	if !empty(aTmpAdm)
		aEval(aTmpAdm, {|x| aadd(aMyAdmFin, x)})
	endif
	//adicionando opção em branco no combobox da Adm Fin
	if empty(aMyAdmFin)
		aadd(aMyAdmFin, Space(TamSx3("AE_COD")[1]))
	else
		aSize(aMyAdmFin, Len(aMyAdmFin)+1)
		aIns(aMyAdmFin,1)
		aMyAdmFin[1] := Space(TamSx3("AE_COD")[1])
	endif
	nPosAux := aScan(aMyAdmFin, {|x| x = aDadosAux[4]  } )
	if nPosAux > 0
		aDadosAux[4] := aMyAdmFin[nPosAux]
	endif

	if lMvPosto
		//Buscando redes autorizadoras
		aMyRede := GetMDEAdm(1, aMyAdmFin) //busca redes relacionadas as adm encontradas
		nPosAux := aScan(aMyRede, {|x| x = aDadosAux[2] } )
		if nPosAux > 0
			aDadosAux[2] := aMyRede[nPosAux]
		endif

		//Buscando Bandeiras
		aMyBandei:= GetMDEAdm(2, aMyAdmFin, aDadosAux[2])
		nPosAux := aScan(aMyBandei, {|x| x = aDadosAux[3] } )
		if nPosAux > 0
			aDadosAux[3] := aMyBandei[nPosAux]
		endif
	endif

	@ nLinCp, 010 SAY "Valor do Cartão" SIZE 100, 007 OF oPnlCC  PIXEL
	oVlrRec := TGet():New( nLinCp+10, 010,{|u| iif( PCount()==0,aDadosAux[1],aDadosAux[1]:= u)},oPnlCC,090, 013,"@E 999,999,999.99",{|| .T.},,,,,,.T.,,,{|| .T./*lModEdic*/},,,,.F.,.F.,,"L4_VALOR",,,,.T.,.F.)
	nLinCp += 30

	if lMvPosto
		@ nLinCp, 010 SAY "Operadora" SIZE 106, 010 OF oPnlCC COLORS 0, 16777215 PIXEL
		oRedeAut := TComboBox():New(nLinCp+10, 010, {|u| If(PCount()>0,aDadosAux[2]:=u,aDadosAux[2])}, aMyRede , 080, 016, oPnlCC, Nil,{|| aMyBandei:=GetMDEAdm(2, aMyAdmFin, aDadosAux[2]), oBandeira:SetItems(aMyBandei), oBandeira:Refresh()  },/*bValid*/,,,.T.,,Nil,Nil,{|| !lSelAdm } )

		@ nLinCp, 100 SAY "Bandeira" SIZE 106, 010 OF oPnlCC COLORS 0, 16777215 PIXEL
	  	oBandeira := TComboBox():New(nLinCp+10, 100, {|u| If(PCount()>0,aDadosAux[3]:=u,aDadosAux[3])}, aMyBandei , 080, 016, oPnlCC, Nil,{|| nX := GetMDEAdm(3, aMyAdmFin, aDadosAux[2], aDadosAux[3]), oAdmFin:Select(nX) },/*bValid*/,,,.T.,,Nil,Nil,{|| !lSelAdm } )
	  	nLinCp += 30
  	endif

  	@ nLinCp, 010 SAY "Adm. Financeira" SIZE 120, 010 OF oPnlCC COLORS 0, 16777215 PIXEL
	oAdmFin := TComboBox():New(nLinCp+10, 010, {|u| If(PCount()>0,aDadosAux[4]:=u,aDadosAux[4])}, aMyAdmFin , 170, 016, oPnlCC, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| !lMvPosto .or. lSelAdm } )
	nLinCp += 30

	@ nLinCp, 010 SAY "NSU" SIZE 070, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 010 MSGET oNsuDoc VAR aDadosAux[5] SIZE 080, 013 OF oPnlCC COLORS 0, 16777215 PIXEL PICTURE Replicate("N",len(aDadosAux[5]))

    @ nLinCp, 100 SAY "Autorização" SIZE 060, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 100 MSGET oAutoriz VAR aDadosAux[6] SIZE 080, 013 OF oPnlCC COLORS 0, 16777215 PIXEL PICTURE Replicate("N",len(aDadosAux[6]))
    nLinCp += 30

    @ nLinCp, 010 SAY "Data" SIZE 070, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 010 MSGET oDataTran VAR aDadosAux[7] SIZE 090, 013 OF oPnlCC COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL

    @ nLinCp, 100 SAY "Parcelas" SIZE 057, 007 OF oPnlCC COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 100 MSGET oParcelas VAR aDadosAux[8] SIZE 040, 013 OF oPnlCC COLORS 0, 16777215 WHEN lAltParc HASBUTTON PIXEL PICTURE "99"

Return

//--------------------------------------------------------------------------------------
// Tela de manutenção de Cheques
//--------------------------------------------------------------------------------------
Static Function ManCheque(nRecSE1, bRefresh)

	Local lOk := .T.
	Local nOpcRet := 0
	Local oPanelChq
	Local aDadosAux := {}
	Local bValTela
	Local nRecSEF := 0
	Local dVencto, nValor
	Local aCpExtraSE1 := {}
	Private oDlgCH

	if empty(nRecSE1)
		Return
	endif

	SE1->(DbGoTo(nRecSE1))

	if !Empty(SE1->E1_BAIXA)
		MsgInfo("O título se encontra baixado. Operação nao permitida.","Atenção")
		Return
	EndIf

	if !Empty(SE1->E1_NUMBOR)
		MsgInfo("O título se encontra em um borderô. Operação nao permitida.","Atenção")
		Return
	EndIf

	SEF->(DbSetOrder(3))
	If SEF->(Dbseek(xFilial("SEF")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
		nRecSEF := SEF->(Recno())
		aDadosAux := {;
			SEF->EF_VENCTO ,; //EF_VENCTO
			SEF->EF_VALOR ,; //EF_VALOR
			SEF->EF_BANCO ,; //EF_BANCO
			SEF->EF_AGENCIA ,; //EF_AGENCIA
			SEF->EF_CONTA ,; //EF_CONTA
			SEF->EF_NUM ,; //EF_NUM
			SEF->EF_EMITENT ,; //EF_EMITENT
			SEF->EF_CPFCNPJ ,; //EF_CPFCNPJ
			SEF->EF_RG ,; //EF_RG
			SEF->EF_TEL ,; //EF_TEL
			iif(SEF->(FieldPos("EF_COMP")) > 0 ,SEF->EF_COMP ,"   ") ,; //L4_COMP
			iif(SEF->(FieldPos("EF_XCMC7")) > 0,SEF->EF_XCMC7,Space(34)) ; //EF_XCMC7
		}
	else
		MsgAlert("Não foi possível localizar registro de cheque na tabela SEF. Operação abortada.","Atenção")
		Return
	endif

	//monta tela de informar cheques
	oDlgCH := TDialog():New(0,0,380,500,"Manutenção de Cheque",,,,,,,,,.T.)

	// crio o panel para mudar a cor da tela
	@ 0, 0 MSPANEL oPanelChq SIZE 100, 100 OF oDlgCH COLORS 0, 16777215
	oPanelChq:Align := CONTROL_ALIGN_ALLCLIENT

	MontaCpChq(oPanelChq, aDadosAux)
	bValTela := {|| !empty(aDadosAux[1]) .AND. !empty(aDadosAux[2]) .AND. !empty(aDadosAux[3]) .AND. !empty(aDadosAux[4]) .AND. !empty(aDadosAux[5]) .AND. !empty(aDadosAux[6]) .AND. !empty(aDadosAux[7])  }

	@ 170, 200 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgCH ACTION iif(Eval(bValTela),(nOpcRet := 1,oDlgCH:End()),MsgInfo("Campos obrigatórios nao preenchidos corretamente!","Atenção")) PIXEL
	oBtnOK:SetCss(CSS_BTNAZUL)
	@ 170, 155 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgCH ACTION oDlgCH:End() PIXEL

	oDlgCH:lCentered := .T.
	oDlgCH:Activate()

	if nOpcRet <> 1
		Return
	endif

	BeginTran()

	//processo alteraçao financeira
	dVencto := aDadosAux[1]
	nValor := aDadosAux[2]

	aadd(aCpExtraSE1, {"E1_BCOCHQ", aDadosAux[3]})
	aadd(aCpExtraSE1, {"E1_AGECHQ", aDadosAux[4]})
	aadd(aCpExtraSE1, {"E1_CTACHQ", aDadosAux[5]})
	aadd(aCpExtraSE1, {"E1_NUMCART", aDadosAux[6]})
	aadd(aCpExtraSE1, {"E1_EMITCHQ", aDadosAux[7]})
	if SE1->(FieldPos("E1_XCODEMI")) > 0
		aadd( aCpExtraSE1, {"E1_XCGCEMI", aDadosAux[8]})
		if !empty(Posicione("SA1",3,xFilial("SA1")+aDadosAux[8],"A1_COD"))
			AADD( aCpExtraSE1, {"E1_XCODEMI" , SA1->A1_COD  })
			AADD( aCpExtraSE1, {"E1_XLOJEMI" , SA1->A1_LOJA })
		endif
	endif

	LjMsgRun("Processando alteração dos dados...","Aguarde...",{|| lOk := ProcMntForm("CH", SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_NOMCLI, dVencto, nValor, .T., .F., .T., .F., aCpExtraSE1, .F., aDadosAux) })

	if lOK
		SEF->(DbGoTo(nRecSEF))
		RecLock("SEF",.F.)
		SEF->EF_VENCTO	:=  aDadosAux[1]
		SEF->EF_VALOR 	:=  aDadosAux[2]
		SEF->EF_VALORBX :=  aDadosAux[2]
		SEF->EF_BANCO 	:=  aDadosAux[3]
		SEF->EF_AGENCIA :=  aDadosAux[4]
		SEF->EF_CONTA 	:=  aDadosAux[5]
		SEF->EF_NUM 	:=  aDadosAux[6]
		SEF->EF_EMITENT :=  aDadosAux[7]
		SEF->EF_CPFCNPJ :=  aDadosAux[8]
		SEF->EF_RG 		:=  aDadosAux[9]
		SEF->EF_TEL 	:=  aDadosAux[10]
		SEF->EF_COMP :=  aDadosAux[11]
		if SEF->(FieldPos("EF_XCMC7"))>0
			SEF->EF_XCMC7 :=  aDadosAux[12]
		endif
		if SEF->(FieldPos("EF_XCODEMI")) > 0
			if !empty(Posicione("SA1",3,xFilial("SA1")+aDadosAux[8],"A1_COD"))
				SEF->EF_XCODEMI := SA1->A1_COD
				SEF->EF_XLOJEMI := SA1->A1_LOJA
			endif
		endif
		SEF->(MsUnLock())

		//ponto de entrada para manipular campos da SEF ou SE1 referente a cheques
		//Já posicionado em ambas tabelas SE1 e SEF
		If ExistBlock("TPINCSEF")
			ExecBlock("TPINCSEF",.F.,.F.,{"3"}) //Parametros; 1=Venda (gravabatch); 2=Compensação; 3=Conferencia Caixa
		EndIf
	endif

	if !lOk
		DisarmTransaction()
	endif
	EndTran()

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// monta campos da tela de cheques para quando não é do template posto
//--------------------------------------------------------------------------------------
Static Function MontaCpChq(oPanelAux, aDadosCH, lVencto, lValor)

	Local oGetBanco, oGetAgencia, oGetConta, oGetNumCH, oGetNome, oGetCGC
	Local oGetRG, oGetTel, oValor, oVencto, oCmc7, oComp
	Local bWhen
	Default lVencto := .T.
	Default lValor := .T.

	bWhen := &("{|| "+iif(lValor,".T.",".F.")+" }")

	@ 010, 010 SAY oSay1 PROMPT "Valor do Cheque" SIZE 70, 008 OF oPanelAux COLORS 0, 16777215 PIXEL
	oValor := TGet():New( 020, 010,{|u| iif( PCount()==0,aDadosCH[2],aDadosCH[2]:=u)},oPanelAux,80, 013,PesqPict("SE1","E1_VALOR"),{|| .T. },,,,,,.T.,,,bWhen,,,,.F.,.F.,,"nValorCh",,,,.F.,.T.)

	bWhen := &("{|| "+iif(lVencto,".T.",".F.")+" }")

	@ 010, 095 SAY oSay1 PROMPT "Data Venc." SIZE 070, 007 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oVencto := TGet():New( 020, 095,{|u| iif( PCount()==0,aDadosCH[1],aDadosCH[1]:=u)},oPanelAux,70, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,bWhen,,,,.F.,.F.,,"dDataCh",,,,.T.,.F.)

  	@ 040, 010 SAY oSay1 PROMPT "CPF/CNPJ do Emitente" SIZE 100, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetCGC := TGet():New( 050, 010,{|u| iif( PCount()==0,aDadosCH[8],aDadosCH[8]:=u)},oPanelAux,80, 013,,{|| !lMvPosto .OR. VldEmitChq(aDadosCH[8], @aDadosCH[7], @aDadosCH[10], @aDadosCH[9]) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,iif(lMvPosto,"SA1CGC",""),"cCgcEmit",,,,.T.,.F.)

  	@ 040, 95 SAY oSay1 PROMPT "Nome do Emitente" SIZE 070, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetNome := TGet():New( 050, 95,{|u| iif( PCount()==0,aDadosCH[7],aDadosCH[7]:=u)},oPanelAux,145, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,lMvPosto,.F.,,"cNomeEmit",,,,.T.,.F.)

  	@ 070, 010 SAY oSay1 PROMPT "Codigo de Barras CMC7" SIZE 100, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oCmc7 := TGet():New( 080, 010,{|u| iif( PCount()==0,aDadosCH[12],aDadosCH[12]:=u)},oPanelAux,230, 013,,{|| VldCMC7Chq(aDadosCH[12], @aDadosCH[3], @aDadosCH[4], @aDadosCH[5], @aDadosCH[6], @aDadosCH[11]) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cCmc7",,,,.T.,.F.)

  	@ 100, 010 SAY oSay1 PROMPT "Banco" SIZE 50, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetBanco := TGet():New( 110, 010,{|u| iif( PCount()==0,aDadosCH[3],aDadosCH[3]:=u)},oPanelAux,35, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cBanco",,,,.T.,.F.)

  	@ 100, 050 SAY oSay1 PROMPT "Agência" SIZE 50, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetAgencia := TGet():New( 110, 050,{|u| iif( PCount()==0,aDadosCH[4],aDadosCH[4]:=u)},oPanelAux,40, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cAgencia",,,,.T.,.F.)

  	@ 100, 095 SAY oSay1 PROMPT "Conta" SIZE 070, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetConta := TGet():New( 110, 095,{|u| iif( PCount()==0,aDadosCH[5],aDadosCH[5]:=u)},oPanelAux,070, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cConta",,,,.T.,.F.)

  	@ 100, 170 SAY oSay1 PROMPT "Num. Cheque" SIZE 070, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetNumCH := TGet():New( 110, 170,{|u| iif( PCount()==0,aDadosCH[6],aDadosCH[6]:=u)},oPanelAux,070, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cNumCh",,,,.T.,.F.)

  	@ 130, 010 SAY oSay1 PROMPT "R.G." SIZE 50, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetRG := TGet():New( 140, 010,{|u| iif( PCount()==0,aDadosCH[9],aDadosCH[9]:=u)},oPanelAux,80, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cRG",,,,.T.,.F.)

  	@ 130, 095 SAY oSay1 PROMPT "Telefone" SIZE 50, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oGetTel := TGet():New( 140, 095,{|u| iif( PCount()==0,aDadosCH[10],aDadosCH[10]:=u)},oPanelAux,70, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cTel",,,,.T.,.F.)

  	@ 130, 170 SAY oSay1 PROMPT "Compensação" SIZE 50, 010 OF oPanelAux COLORS 0, 16777215 PIXEL
  	oComp := TGet():New( 140, 170,{|u| iif( PCount()==0,aDadosCH[11],aDadosCH[11]:=u)},oPanelAux,70, 013,,{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"cComp",,,,.T.,.F.)

Return

//-------------------------------------------------------
// Valida e gatilha emitente de cheque
//-------------------------------------------------------
Static Function VldEmitChq(cCgcEmit, cNomeEmit, cTel, cRG)

	Local cHelpCh := ""
	Local lRet := .T.

	if empty(cCgcEmit)
		cNomeEmit := ""
	else
		cNomeEmit := Posicione("SA1",3,xFilial("SA1")+cCgcEmit,"A1_NOME")
		if empty(cNomeEmit)
			cHelpCh := "Emitente não cadastrado!"
			lRet := .F.
		endif
		if SA1->(FieldPos("A1_XEMCHQ")) > 0
			if SA1->A1_XEMCHQ <> "S"
				cHelpCh := "O cliente não está habilitado como Emitente de Cheques!"
				lRet := .F.
			endif
		endif
		if lRet //gatilha demais campos
			cTel := PadR(alltrim(SA1->A1_DDD + SA1->A1_TEL),TamSx3("EF_TEL")[1])
			cRG := iif(SA1->A1_PESSOA=='F',SA1->A1_PFISICA,SA1->A1_INSCR)
		endif
	endif

	if !lRet
		MsgInfo(cHelpCh,"Atenção")
	endif

Return lRet

//-------------------------------------------------------
// Valida e gatilha dados do cheque pelo CMC7
//-------------------------------------------------------
Static Function VldCMC7Chq(cCmc7, cBanco, cAgencia, cConta, cNumCh, cComp)

	Local cHelpCh
	Local lRet := .T.
	Local cMyCmc7 := ""
    Local c1 := c2 := c3 := ""

	if !empty(cCmc7)
		cMyCmc7 := alltrim(cCmc7)
		If Len(cMyCmc7)>=30 .and. Right(cMyCmc7,1)<>":"
			c1 := SubStr(cMyCmc7,1,8)
			c2 := SubStr(cMyCmc7,9,10)
			c3 := SubStr(cMyCmc7,19,12)
			cMyCmc7 := "<"+c1+"<"+c2+">"+c3+":"
			cCmc7 := cMyCmc7
		EndIf

		if ("?" $ cMyCmc7) .OR. Len(AllTrim(cMyCmc7)) <> 34
			cHelpCh := "Erro na leitura. Passe o cheque novamente no leitor."
			lRet := .F.
		else
			if Modulo10(SubStr(cMyCmc7,2,7)) <> SubStr(cMyCmc7,22,1)
			     lRet := .F.
			Elseif Modulo10(SubStr(cMyCmc7,11,10)) <> SubStr(cMyCmc7,9,1)
			     lRet := .F.
			Elseif Modulo10(SubStr(cMyCmc7,23,10)) <> SubStr(cMyCmc7,33,1)
			     lRet := .F.
			endif
			if !lRet
				cHelpCh := "O Código CMC7 informado é iválido!"
			endif
		endif

		//setando campos
		if lRet
			cBanco := PadR(SubStr(cMyCmc7, 2, 3), TamSx3("EF_BANCO")[1]) //Banco
			cAgencia := PadR(SubStr(cMyCmc7, 5, 4), TamSx3("EF_AGENCIA")[1]) //Agencia
			cNumCh := PadR(SubStr(cMyCmc7, 14, 6),TamSx3("EF_NUM")[1]) //Nro Cheque
			cComp := PadR(SubStr(cMyCmc7, 11, 3),TamSx3("L4_COMP")[1]) //Comp.

			//buscando a cona para cada banco
			If cBanco  $  "314/001" //itau, brasil
			 	cConta := SubStr(cMyCmc7, 27, 6)  //Conta
			ElseIf cBanco = "756" //sicoob
			 	cConta := SubStr(cMyCmc7, 23, 10)  //Conta
			ElseIf cBanco = "237" //bradesco
			 	cConta := SubStr(cMyCmc7, 26, 7)  //Conta
			ElseIf cBanco = "104" //caixa
			 	cConta := SubStr(cMyCmc7, 24, 9)  //Conta
			ElseIf cBanco = "356" //real
			 	cConta := SubStr(cMyCmc7, 26, 7)  //Conta
			ElseIf cBanco = "399" //hsbc
			 	cConta := SubStr(cMyCmc7, 23, 9)  //Conta
			ElseIf cBanco = "745" //citibank
				cConta := SubStr(cMyCmc7, 25, 8)  //Conta
			Else
				cConta := SubStr(cMyCmc7, 25, 8)  //Conta
			EndIf
		endif
	endif

	if !lRet
		MsgInfo(cHelpCh,"Atenção")
	endif

Return lRet

//-------------------------------------------------------
// Valida código CMC7 informado
//-------------------------------------------------------
Static Function Modulo10(cLinha)

	Local nSoma:= 0
	Local nResto
	Local nCont
	Local cDigRet
	Local nResult
	Local lDobra:= .f.
	Local cValor
	Local nAux

	For nCont:= Len(cLinha) To 1 Step -1
		lDobra:= !lDobra

		If lDobra
			cValor:= AllTrim(Str(Val(Substr(cLinha, nCont, 1)) * 2))
		Else
			cValor:= AllTrim(Str(Val(Substr(cLinha, nCont, 1))))
		EndIf

		For nAux:= 1 To Len(cValor)
			nSoma += Val(Substr(cValor, nAux, 1))
		Next n
	Next nCont

	nResto:= MOD(nSoma, 10)
	nResult:= 10 - nResto

	If nResult == 10
		cDigRet:= "0"
	Else
		cDigRet:= StrZero(10 - nResto, 1)
	EndIf

Return cDigRet

//--------------------------------------------------------------------------------------
// Tela de manutenção de carta frete
//--------------------------------------------------------------------------------------
Static Function ManCartaFrete(nRecSE1, bRefresh)

	Local lOk := .T.
	Local bValTela
	Local aDadosAux := {}
	Local oPanelCF
	Local nOpcRet := 0
	Local nVlrAnt := 0
	Local aCpExtraSE1 := {}
	Local dVencto
	Private oDlgCF

	if empty(nRecSE1)
		Return
	endif

	SE1->(DbGoTo(nRecSE1))

	if !Empty(SE1->E1_BAIXA)
		MsgInfo("O título se encontra baixado. Operação nao permitida.","Atenção")
		Return
	EndIf

	nVlrAnt := iif(SE1->E1_VLRREAL > 0, SE1->E1_VLRREAL, SE1->E1_VALOR)

	aDadosAux := {;
		Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_CGC"),;
		SA1->A1_NOME,;
		SE1->E1_NUMCART ,;
		nVlrAnt,;
		SE1->E1_HIST,;
		SE1->E1_VENCTO ;
	}

	//monta tela de informar cheques
	oDlgCF := TDialog():New(0,0,320,375,"Manutenção de Carta Frete",,,,,,,,,.T.)

	// crio o panel para mudar a cor da tela
	@ 0, 0 MSPANEL oPanelCF SIZE 100, 100 OF oDlgCF COLORS 0, 16777215
	oPanelCF:Align := CONTROL_ALIGN_ALLCLIENT

	MontaCpCFret(oPanelCF, aDadosAux)
	bValTela := {|| !empty(aDadosAux[1]) .AND. !empty(aDadosAux[2]) .AND. !empty(aDadosAux[3]) .AND. aDadosAux[4]>0  }

	@ 140, 135 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgCF ACTION iif(Eval(bValTela),(nOpcRet := 1,oDlgCF:End()),MsgInfo("Campos obrigatórios nao preenchidos corretamente!","Atenção")) PIXEL
	oBtnOK:SetCss(CSS_BTNAZUL)
	@ 140, 090 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgCF ACTION oDlgCF:End() PIXEL

	oDlgCF:lCentered := .T.
	oDlgCF:Activate()

	if nOpcRet <> 1
		Return
	endif

	BeginTran()

	cCodCli := Posicione("SA1",3,xFilial("SA1")+aDadosAux[1],"A1_COD")
	cLojCli := SA1->A1_LOJA
	cNomCli := SA1->A1_NOME

	aadd(aCpExtraSE1, {"E1_NUMCART", aDadosAux[3]})
	aadd(aCpExtraSE1, {"E1_HIST", aDadosAux[5]})
	dVencto := aDadosAux[6]

	//processo alteraçao financeira
	LjMsgRun("Processando alteração dos dados...","Aguarde...",{|| lOk := ProcMntForm("CF", cCodCli, cLojCli, cNomCli, dVencto, aDadosAux[4], .T., .T., .T., .F., aCpExtraSE1, .F., aDadosAux) })

	if !lOk
		DisarmTransaction()
	endif
	EndTran()

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//----------------------------------------------------------
// Monta campos da carta frete - manutencao
//----------------------------------------------------------
Static Function MontaCpCFret(oPnlCF, aDadosAux, nTipo)

	Local oEmitCF, oNomeEmiCF, oCFrete, oValorCF, oObserv

	@ 010, 010 SAY oSay1 PROMPT "CNPJ do Emitente" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oEmitCF := TGet():New( 020, 010,{|u| iif(PCount()>0,aDadosAux[1]:=u,aDadosAux[1])},oPnlCF,80, 013,,{|| VldEmitCF(aDadosAux[1], @aDadosAux[2], @aDadosAux[6], nTipo) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,"SA1CGC","oEmitCF",,,,.T.,.F.)

	@ 040, 010 SAY oSay1 PROMPT "Nome do Emitente" SIZE 080, 010 OF oPnlCF COLORS 0, 16777215 PIXEL
	oNomeEmiCF := TGet():New( 050, 010,{|u| iif(PCount()>0,aDadosAux[2]:=u,aDadosAux[2])},oPnlCF,165, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,"oNomeEmiCF",,,,.T.,.F.)
	oNomeEmiCF:lCanGotFocus := .F.

	@ 070, 010 SAY oSay1 PROMPT "Numero Carta Frete" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oCFrete := TGet():New( 080, 010,{|u| iif(PCount()>0,aDadosAux[3]:=u,aDadosAux[3])},oPnlCF,080, 013,,{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oCFrete",,,,.T.,.F.)

	@ 070, 095 SAY oSay1 PROMPT "Valor da Carta Frete" SIZE 70, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oValorCF := TGet():New( 080, 095,{|u| iif( PCount()==0,aDadosAux[4],aDadosAux[4]:=u)},oPnlCF,80, 013,PesqPict("SE1","E1_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"nValorCF",,,,.F.,.T.)

	@ 100, 010 SAY oSay1 PROMPT "Observações" SIZE 100, 008 OF oPnlCF COLORS 0, 16777215 PIXEL
	oObserv := TGet():New( 110, 010,{|u| iif(PCount()>0,aDadosAux[5]:=u,aDadosAux[5])},oPnlCF,165, 013,"",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oObserv",,,,.T.,.F.)

Return

//-------------------------------------------------------
// Valida e gatilha emitente de carta frete
//-------------------------------------------------------
Static Function VldEmitCF(cEmitCF, cNomeEmiCF, dDataVen, nTipo)

	Local lRet := .T.
	Local aParc
	Default nTipo := 0

	if empty(cEmitCF)
		cNomeEmiCF := ""
	else
		if empty(Posicione("SA1",3,xFilial("SA1")+cEmitCF,"A1_NOME"))
			cHelpCF := "Emitente não cadastrado!"
			lRet := .F.
		endif

		if SA1->(FieldPos("A1_XEMICF")) > 0
			if SA1->A1_XEMICF <> "S"
				cHelpCF := "O cliente não está habilitado como Emitente de Carta Frete!"
				lRet := .F.
			endif
		endif

		if lRet
			cNomeEmiCF := SA1->A1_NOME

			cCondPg := space(tamsx3("E4_CODIGO")[1])
			
			if SA1->(FieldPos("A1_XCONDCF")) > 0
				cCondPg := SA1->A1_XCONDCF
			endif

			if empty(cCondPg)
				if nTipo==1 //venda
					cCondPg := GatCondicao("CF", 1, nTipo)
				else //compensacao
					cCondPg := SuperGetMv("MV_XCONDCF", .F., "")
				endif
			endif

			if empty(cCondPg)
				cHelpCF := "Condição de pagamento do Emitente não configurada! Verifique campo A1_XCONDCF ou parametro MV_XCONDCF ou negociação de pagamento."
			else
				aParc := condicao(100,cCondPg,0.00,SLW->LW_DTABERT,0.00,{},,0)
				if Len(aParc) > 1
					cHelpCF := "Condição de pagamento do Emitente não pode gerar mais de 1 parcela!"
					lRet := .F.
				elseif !empty(aParc)
					dDataVen := aParc[1][1]
				endif
			endif
		endif
	endif

	if !lRet
		MsgInfo(cHelpCF,"Atenção")
	endif

Return lRet

//--------------------------------------------------------------------------------------------
// Função de inclusao de cheque troco
// nTipoDoc: 1=Venda;2=Compensaçao;3=Saque/VLM
//--------------------------------------------------------------------------------------------
Static Function IncChqTroco(nTipoDoc, lAuto, bRefresh, cSerie, cDoc, cCodBar, cBanco, cAgencia, cConta, cNumCheq, nValor)

	Local lWhenDoc := .T.
	Local lOk := .F.
	Local nOpcX := 0
	Local oFntVlr := TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local dBkpDbase := dDataBase
	Local oSerie, oDoc, oCodBar, oBanco, oAgencia, oConta, oNumCheq, oValor
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local aParBox := {}, aRetPar := {}, aOptCombo := {}
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa

	Default nTipoDoc := 0
	Default lAuto := .F.
	Default cSerie := Space(TamSX3("UF2_SERIE")[1])
	Default cDoc := Space(TamSX3("UF2_DOC")[1])
	Default cCodBar := Space(TamSX3("UF2_CODBAR")[1])
	Default cBanco := Space(TamSX3("UF2_BANCO")[1])
	Default cAgencia := Space(TamSX3("UF2_AGENCI")[1])
	Default cConta := Space(TamSX3("UF2_CONTA")[1])
	Default cNumCheq := Space(TamSX3("UF2_NUM")[1])
	Default nValor := 0

	Private oDlgCHT

	if nTipoDoc > 0
		lWhenDoc := .F.
		if nTipoDoc == 1 //venda
			cDoc := SL1->L1_DOC
			cSerie := SL1->L1_SERIE
		elseif nTipoDoc == 2 //compensacao
			cDoc := UC0->UC0_NUM
			cSerie := PadR(cPfxComp,TamSX3("UF2_SERIE")[1])
		elseif nTipoDoc == 3 //saque
			cCodBar := U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL
		endif
	elseif !lAuto //escolher o tipo
		aadd(aOptCombo, "Venda")
		aadd(aOptCombo, "Compensação" + iif(SuperGetMV("TP_ACTCMP",,.F.),"","(desabilitado)") )
		aadd(aOptCombo, "Saque/Vale Mot." + iif(SuperGetMV("TP_ACTSQ",,.F.),"","(desabilitado)"))
		aAdd(aParBox, {3, 'Tipo Documento:', 1, aOptCombo, 100, '', .T., '.T.'})
		If ParamBox(aParBox, 'Inclusão Cheque Troco', @aRetPar)
			nTipoDoc := aRetPar[1]
			if nTipoDoc==2 .AND. !SuperGetMV("TP_ACTCMP",,.F.)
				MsgInfo("Rotina de compensação Desabilitada!","Atenção")
				Return .F.
			endif
			if nTipoDoc==3 .AND. !SuperGetMV("TP_ACTSQ",,.F.)
				MsgInfo("Rotina de saque Desabilitada!","Atenção")
				Return .F.
			endif
		else
			Return .F.
		EndIf
	else
		Return .F.
	endif

	if nTipoDoc == 2 .AND. empty(cSerie)
		cSerie := PadR(cPfxComp,TamSX3("UF2_SERIE")[1])
	endif

	if lAuto
		if ValidIncCHQ(nTipoDoc, .T., cSerie, cDoc, cCodBar, cBanco, cAgencia, cConta, cNumCheq, nValor)
			nOpcX := 1
		endif
	else
		DEFINE MSDIALOG oDlgCHT TITLE "Inclusao de Cheque Troco" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 400 COLORS 0, 16777215 PIXEL

		oPnlDet := TScrollBox():New(oDlgCHT,05,05,172,190,.F.,.T.,.T.)

		if nTipoDoc == 3 //se cheque do saque
			@ 005, 010 SAY "Codigo de Barra" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
			@ 013, 010 MSGET oCodBar VAR cCodBar WHEN lWhenDoc SIZE 080, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL
		else
			@ 005, 010 SAY "Documento" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
			@ 013, 010 MSGET oDoc VAR cDoc WHEN lWhenDoc SIZE 080, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

			@ 005, 095 SAY "Série" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
			@ 013, 095 MSGET oSerie VAR cSerie WHEN lWhenDoc .AND. nTipoDoc==1 SIZE 040, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL
		endif

		@ 026, 002 SAY Replicate("_",184) SIZE 184, 007 OF oPnlDet COLORS CLR_HGRAY, 16777215 PIXEL

		@ 037, 010 SAY "Banco" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 045, 010 MSGET oBanco VAR cBanco SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL  Valid((nValor := Posicione("UF2",2,xFilial("UF2")+cBanco+cAgencia+cConta+cNumCheq,"UF2_VALOR"), oValor:Refresh()))

		@ 037, 076 SAY "Agencia" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 045, 076 MSGET oAgencia VAR cAgencia SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL  Valid((nValor := Posicione("UF2",2,xFilial("UF2")+cBanco+cAgencia+cConta+cNumCheq,"UF2_VALOR"), oValor:Refresh()))

		@ 059, 010 SAY "Conta" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 067, 010 MSGET oConta VAR cConta SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL Valid((nValor := Posicione("UF2",2,xFilial("UF2")+cBanco+cAgencia+cConta+cNumCheq,"UF2_VALOR"), oValor:Refresh()))

		@ 059, 076 SAY "Numero Cheque" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 067, 076 MSGET oNumCheq VAR cNumCheq SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL Valid((nValor := Posicione("UF2",2,xFilial("UF2")+cBanco+cAgencia+cConta+cNumCheq,"UF2_VALOR"), oValor:Refresh()))

		@ 092, 010 SAY "Valor" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 089, 045 MSGET oValor VAR nValor SIZE 105, 013 OF oPnlDet HASBUTTON COLORS 0, 16777215 FONT oFntVlr PIXEL Picture PesqPict("UF2","UF2_VALOR") VALID nValor>=0

		@ 182, 155 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oDlgCHT PIXEL Action iif(ValidIncCHQ(nTipoDoc, !lWhenDoc, cSerie, cDoc, cCodBar, cBanco, cAgencia, cConta, cNumCheq, nValor),(nOpcX:=1,oDlgCHT:End()),)
		oButton1:SetCSS( CSS_BTNAZUL )
		@ 182, 110 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgCHT PIXEL Action oDlgCHT:End()

		ACTIVATE MSDIALOG oDlgCHT CENTERED

	endif

	if nOpcX == 1

		if !lAuto
			BeginTran()
		endif

		lOk := .T.

		dDataBase := SLW->LW_DTABERT //altero database

		RecLock("UF2",.F.)
		//forço ficar no operador da conferencia do caixa
		UF2->UF2_PDV	:= SLW->LW_PDV
		UF2->UF2_CODCX	:= SLW->LW_OPERADO
		UF2->UF2_VALOR 	:= nValor
		UF2->UF2_DOC   	:= cDoc
		UF2->UF2_SERIE 	:= cSerie
		UF2->UF2_CODBAR	:= cCodBar
		UF2->UF2_DATAMO	:= dDataBase
		UF2->UF2_STATUS := "2" //cheque gerado na SEF e liberado (SE5)
		UF2->UF2_XOPERA	:= SLW->LW_OPERADO
		UF2->UF2_XPDV	:= SLW->LW_PDV
		UF2->UF2_XESTAC	:= SLW->LW_ESTACAO
		UF2->UF2_XNUMMO	:= SLW->LW_NUMMOV
		if nTipoDoc == 1 //venda
			UF2->UF2_NATURE	:= SuperGetMV("MV_XNATCHA", .T., "CHEQUE")
			UF2->UF2_CLIENT := SL1->L1_CLIENTE
			UF2->UF2_LOJACL := SL1->L1_LOJA
			UF2->UF2_XHORA	:= SL1->L1_HORA
		elseif nTipoDoc == 2 //compensacao
			UF2->UF2_NATURE	:= SuperGetMv( "MV_XCNATCT", .T., "CHEQUE")
			UF2->UF2_CLIENT := UC0->UC0_CLIENT
			UF2->UF2_LOJACL := UC0->UC0_LOJA
			UF2->UF2_XHORA	:= UC0->UC0_HORA
		elseif nTipoDoc == 3 //requisição
			U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
			U56->(DbSeek(U57->U57_FILIAL+U57->U57_PREFIX+U57->U57_CODIGO))

			UF2->UF2_NATURE	:= SuperGetMV("MV_XNATCHA", .T., "CHEQUE")
			UF2->UF2_DOC   	:= Substr(U57->U57_PREFIX,1,1)+U57->U57_CODIGO
			UF2->UF2_SERIE 	:= iif(U56->U56_TIPO="1","RPR",AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")))
			UF2->UF2_CLIENT := U56->U56_CODCLI
			UF2->UF2_LOJACL := U56->U56_LOJA
			UF2->UF2_XHORA	:= U57->U57_XHORA

			RecLock("U57",.F.)
			U57->U57_CHTROC += nValor
			U57->(MsUnlock())
		endif
		UF2->(MsUnLock())
		
		cLogCaixa += Space(4) + UF2->UF2_BANCO+" | "+UF2->UF2_AGENCI+" | "+UF2->UF2_CONTA+" | "+UF2->UF2_NUM+" | "+Transform(UF2->UF2_VALOR ,"@E 999,999,999.99") + CRLF

		LjMsgRun("Processando financeiro do cheque troco...","Aguarde...",{|| lOk := U_TRETE029(UF2->(Recno())) })
		if lOk

			RecLock("UF2",.F.)
			UF2->UF2_XGERAF := 'G'
			UF2->(MsUnlock())

			//Removendo o valor em dinheiro no documento
			if nTipoDoc == 1 //venda
				LjMsgRun("Ajustando troco da venda...","Aguarde...",{|| lOk := AjuSL1Troco() })
				if !lOk
					MsgAlert("Falha na alteração do valor em dinheiro do troco da venda! Operação abortada!","Atenção")
					if !lAuto
						DisarmTransaction()
					endif
				endif
			elseif nTipoDoc == 2 //compensacao
			 	LjMsgRun("Ajustando saida da compensação...","Aguarde...",{|| lOk := U_TRETE29J(1, nValor, cDoc)  })
				if !lOk
					MsgAlert("Falha na alteração do valor em dinheiro da saida da compensação! Operação abortada!","Atenção")
					if !lAuto
						DisarmTransaction()
					endif
				endif
			endif

		else
			MsgAlert("Falha ao processar financeiro do cheque troco! Operação abortada!","Atenção")
			if !lAuto
				DisarmTransaction()
			endif
		endif

		if lOk
			U_UREPLICA("UF2", 1, UF2->UF2_FILIAL+UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_SEQUEN+UF2->UF2_NUM, "A")
		endif
		if !lAuto
			EndTran()

			if lOk .AND. lLogCaixa
				GrvLogConf("3","I", cLogCaixa, UF2->UF2_DOC,UF2->UF2_SERIE,UF2->UF2_CODBAR,UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM)
			endif
		endif

		dDataBase := dBkpDbase

		if bRefresh <> Nil
			EVal(bRefresh)
		endif
	endif

Return lOk

//--------------------------------------------------------------------------------------------
// Valida Inclusao Cheque Troco
// nTipoDoc: 1=Venda;2=Compensaçao;3=Saque/VLM
//--------------------------------------------------------------------------------------------
Static Function ValidIncCHQ(nTipoDoc, lJaPosi, cSerie, cDoc, cCodBar, cBanco, cAgencia, cConta, cNumCheq, nValor, nValSubst)

	Local nTrocoSL1 := 0
	Local nTamHora := TamSX3("LW_HRABERT")[1]
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo
	Default nValSubst := 0 //valor a ser substituido (para uso da rotina de substituição)

	if (nTipoDoc<3 .AND. (empty(cSerie) .OR. empty(cDoc))) .OR. (nTipoDoc==3 .AND. empty(cCodBar)) .OR. empty(cBanco) .OR. empty(cAgencia) .OR. empty(cConta) .OR. empty(cNumCheq) .OR. empty(nValor)
		MsgInfo("Campos obrigatórios nao foram preenchidos!","Atenção")
		Return .F.
	endif

	//Verifica se existe cheque troco com os dados digitados
	UF2->(DbSetOrder(2)) //UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_NUM
	If !UF2->(DbSeek(xFilial("UF2")+cBanco+cAgencia+cConta+cNumCheq))
		MsgInfo("Não foi encontrado cheque troco com os dados informados. Verifique Informações digitadas.","Atenção")
		Return .F.
	endif

	//verifico uso do cheque troco
	if !empty(UF2->UF2_DOC+UF2->UF2_SERIE+UF2->UF2_CODBAR)
		if !empty(UF2->UF2_CODBAR)
			MsgAlert("Cheque Troco ja utilizado para Requisição Saque/Vale Motorista: " + UF2->UF2_CODBAR +". Não será permitida utilização deste cheque.","Atenção")
		else
			MsgAlert("Cheque Troco ja utilizado para Documento/Serie: " + UF2->UF2_DOC + "/" + UF2->UF2_SERIE +". Não será permitida utilização deste cheque.","Atenção")
		endif
		Return .F.
	endif

	SEF->(DbSetOrder(1))
	if SEF->(DbSeek(xFilial("SEF")+cBanco+cAgencia+cConta+cNumCheq)) .AND. SEF->EF_HIST $ "CHEQUE TROCO NO PDV"
		MsgAlert("Cheque Troco já utilizado para Documento/Serie: " + SEF->EF_NUMNOTA + "/" + SEF->EF_SERIE +". Não será permitida utilização deste cheque.","Atenção")
		Return .F.
	endif

	if UF2->UF2_STATUS == '2' .OR. UF2->UF2_STATUS == '3'
		MsgAlert("O cheque troco já foi utilizado ou foi inutilizado. Ação não permitida!","Atenção")
		Return .F.
	endif

	if UF2->UF2_VALOR > 0 .AND. UF2->UF2_VALOR <> nValor
		if !MsgYesNo("O cheque troco já possui um valor pré preenchido de "+Alltrim(Transform(UF2->UF2_VALOR ,"@E 999,999,999.99"))+". Deseja alterar o valor do cheque para "+Alltrim(Transform(nValor,"@E 999,999,999.99"))+"?","Atenção")
			Return .F.
		endif
	endif

	if !lJaPosi //se nao está poisicionado no documento, verifica
		if nTipoDoc == 1 //venda
			SL1->(DbSetOrder(2)) //filial + serie + doc + pdv
			If !SL1->(DbSeek(xFilial("SL1")+cSerie+cDoc))
				MsgInfo("Não foi encontrada a venda. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif

			//verifico se a venda realmente é deste caixa
			if !(Alltrim(SL1->L1_OPERADO) = Alltrim(SLW->LW_OPERADO) .AND. ;
			Alltrim(SL1->L1_ESTACAO) = Alltrim(SLW->LW_ESTACAO) .AND. ;
			Alltrim(SL1->L1_NUMMOV) = Alltrim(SLW->LW_NUMMOV) .AND. ;
			Alltrim(SL1->L1_PDV) = Alltrim(SLW->LW_PDV) .AND. ;
			DTOS(SL1->L1_EMISNF)+SUBSTR(SL1->L1_HORA,1,nTamHora) >= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT .AND. ;
			DTOS(SL1->L1_EMISNF)+SUBSTR(SL1->L1_HORA,1,nTamHora) <= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA .AND. ;
			!empty(SL1->L1_DOC) .AND. SL1->L1_SITUA == 'OK' )
				MsgInfo("Venda informada não pertence a este caixa. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif
		elseif nTipoDoc == 2 //compensação
			UC0->(DbSetOrder(1))
			if !UC0->(DbSeek(xFilial("UC0")+cDoc))
				MsgInfo("Não foi encontrada a Compensação. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif

			//verifico se a compensação realmente é deste caixa
			if !(Alltrim(UC0->UC0_OPERAD) = Alltrim(SLW->LW_OPERADO) .AND. ;
			Alltrim(UC0->UC0_ESTACA) = Alltrim(SLW->LW_ESTACAO) .AND. ;
			Alltrim(UC0->UC0_NUMMOV) = Alltrim(SLW->LW_NUMMOV) .AND. ;
			Alltrim(UC0->UC0_PDV) = Alltrim(SLW->LW_PDV) .AND. ;
			DTOS(UC0->UC0_DATA)+SUBSTR(UC0->UC0_HORA,1,nTamHora) >= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT .AND. ;
			DTOS(UC0->UC0_DATA)+SUBSTR(UC0->UC0_HORA,1,nTamHora) <= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA .AND. ;
			UC0->UC0_ESTORN == 'N')
				MsgInfo("Compensação informada não pertence a este caixa. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif
		else //requisição
			U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
			if !U57->(DbSeek(xFilial("U57")+cCodBar))
				MsgInfo("Não foi encontrada a Requisição. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif

			//verifico se realmente é do caixa
			if !(U57->U57_XPDV = SLW->LW_PDV .AND. ;
			U57->U57_XESTAC = SLW->LW_ESTACAO .AND. ;
			U57->U57_XNUMMO = SLW->LW_NUMMOV .AND. ;
			U57->U57_XOPERA = SLW->LW_OPERADO .AND. ;
			(DTOS(U57->U57_DATAMO)+SUBSTR(U57->U57_XHORA,1,nTamHora)) >= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT .AND. ;
			(DTOS(U57->U57_DATAMO)+SUBSTR(U57->U57_XHORA,1,nTamHora)) <= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA )
				MsgInfo("Requisição informada não pertence a este caixa. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif

			//verifico tipo da requisição
			if U57->U57_TUSO != "S" //somente se for saque
				MsgAlert("A Requisição informada não é de SAQUE. Ação não permitida!","Atenção")
				Return .F.
			endif
		endif
	endif

	//validando valor
	if nTipoDoc == 1 //se venda
		//Troco em Dinheiro
		nTrocoSL1 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'",.f.,.f.)
		if nTrocoSL1 > 0 //se encontrou a SE5
			if Upper(SE5->E5_RECONC) == "X"
				MsgAlert("Ação não permitida. Movimento de troco já se encontra conciliado!","Atenção")
				Return .F.
			elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
				MsgAlert("Ação não permitida. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
				Return .F.
			endif
		endif
		if nTrocoSL1+nValSubst < nValor
			MsgAlert("O valor do cheque troco ultrapassa o valor de troco em dinheiro da venda.","Atenção")
			Return .F.
		endif
	elseif nTipoDoc == 2 .AND. UC0->UC0_VLDINH+nValSubst < nValor //valida valor
		MsgAlert("O valor do cheque troco ultrapassa o valor de saída em dinheiro da compensação.","Atenção")
		Return .F.
	elseif nTipoDoc == 3 .AND. U57->U57_VALSAQ-U57->U57_CHTROC+nValSubst < nValor //valida valor
		MsgAlert("O valor do cheque troco ultrapassa o valor da saída em dinheiro da requisição de saque.","Atenção")
		Return .F.
	endif

Return .T.

//--------------------------------------------------------------------------------------
// Faz exclusao do cheque troco
// nTipoDoc: 1=Venda;2=Compensaçao;3=Saque/VLM
//--------------------------------------------------------------------------------------
Static Function DelChqTroco(nRecUF2, nTipoDoc, lAuto, lInutiliza, bRefresh)

	Local lOk := .T.
	Local cMsgErro := ""
	Local cSerie, cDoc, cCodBar, nValor, cChavCheq
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local cLogCaixa := ""
	Local nTrocoSL1 := 0
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lVldLA := SuperGetMV("MV_XFTVLLA",,.T.) //parametro para verificar se valida ou não a contabilização do titulo
	Default nTipoDoc := 0
	Default lAuto := .F.
	Default lInutiliza := .T.

	if empty(nRecUF2)
		Return .F.
	endif

	UF2->(DbGoTo(nRecUF2))

	cSerie := UF2->UF2_SERIE
	cDoc := UF2->UF2_DOC
	cCodBar := UF2->UF2_CODBAR
	nValor := UF2->UF2_VALOR
	cChavCheq := UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM

	cLogCaixa += Space(4) + UF2->UF2_BANCO+" | "+UF2->UF2_AGENCI+" | "+UF2->UF2_CONTA+" | "+UF2->UF2_NUM+" | "+Transform(UF2->UF2_VALOR ,"@E 999,999,999.99") + CRLF

	if nTipoDoc == 0
		if !empty(cCodBar) //saque
			nTipoDoc := 3
		elseif cSerie = cPfxComp //compensacao
			nTipoDoc := 2
		else //venda
			nTipoDoc := 1
		endif
	endif

	//validando valor
	if nTipoDoc == 1 //se venda
		//posiciono na SL1
		SL1->(DbSetOrder(2)) //filial + serie + doc + pdv
		If !SL1->(DbSeek(xFilial("SL1")+cSerie+cDoc))
			MsgInfo("Não foi encontrada a venda. Verifique Informações digitadas.","Atenção")
			Return .F.
		endif

		//Troco em Dinheiro
		nTrocoSL1 := U_T028TTV(4,,,"E5_PREFIXO = '"+cSerie+"' AND E5_NUMERO = '"+cDoc+"'",.f.,.f.)
		if nTrocoSL1 > 0 //se encontrou a SE5
			if Upper(SE5->E5_RECONC) == "X"
				MsgAlert("Ação não permitida. Movimento de troco da venda já se encontra conciliado!","Atenção")
				Return .F.
			elseif lVldLA .AND. Upper(Alltrim(SE5->E5_LA)) == "S"
				MsgAlert("Ação não permitida. Movimento de troco da venda já se encontra contabilizado! Estorne a contabilização e tente novamente.","Atenção")
				Return .F.
			endif
		endif
	Endif

	if !lAuto
		BeginTran()
	endif

	//TRETE29G(lAjuTroco, lTransaction, lAuto, lInutiliza, cMsgErro)
	LjMsgRun("Processando financeiro cheque troco...","Aguarde...",{|| lOK := U_TRETE29G(.F., .F., lAuto, lInutiliza, @cMsgErro) })
	if lOK

		//AvalUF2(cDoc, cSerie, cPdv, lOK, cObs, aIdCorrige, cChvCheq)
		AvalUF2(,,,@lOK, @cMsgErro,,cChavCheq) //avaliso pela chave do cheque
		if !lOK
			MsgAlert("Falha! Verificação pós exclusao: Não foi excluido totalmente o financeiro do cheque troco.","Atenção")
			if !lAuto
				DisarmTransaction()
			endif
			lOk := .F.
		endif

		//Adicionando o valor em dinheiro no documento
		if lOk
			if nTipoDoc == 1 //venda
				LjMsgRun("Ajustando troco da venda...","Aguarde...",{|| lOk := AjuSL1Troco() })
				if !lOk
					MsgAlert("Falha na alteração do valor em dinheiro do troco da venda! Operação abortada!","Atenção")
					if !lAuto
						DisarmTransaction()
					endif
				endif
			elseif nTipoDoc == 2 //compensacao
				LjMsgRun("Ajustando saida da compensação...","Aguarde...",{|| lOk := U_TRETE29J(2, nValor, cDoc) })
				if !lOk
					MsgAlert("Falha na alteração do valor em dinheiro da saida da compensação! Operação abortada!","Atenção")
					if !lAuto
						DisarmTransaction()
					endif
				endif
			endif
		endif
	else
		if !empty(cMsgErro)
			MsgAlert(cMsgErro,"Atenção")
		endif
		if !lAuto
			DisarmTransaction()
		endif
	endif

	if !lAuto
		EndTran()

		if lOk .AND. lLogCaixa
			GrvLogConf("3","E", cLogCaixa, cDoc,cSerie,cCodBar,cChavCheq)
		endif
	endif

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return lOk

//--------------------------------------------------------------------------------------
// Faz substituição do cheque troco (excluir e inclui)
//--------------------------------------------------------------------------------------
Static Function SubChqTroco(nRecUF2, lJaPosi, bRefresh)

	Local lOk := .T.
	Local cChavCheq := ""
	Local cMsgErro := ""
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local cSerieInc := Space(TamSX3("UF2_SERIE")[1])
	Local cDocInc   := Space(TamSX3("UF2_DOC")[1])
	Local cCodBarInc := Space(TamSX3("UF2_CODBAR")[1])
	Local cBancoInc := Space(TamSX3("UF2_BANCO")[1])
	Local cAgencInc := Space(TamSX3("UF2_AGENCI")[1])
	Local cContaInc := Space(TamSX3("UF2_CONTA")[1])
	Local cNumChInc := Space(TamSX3("UF2_NUM")[1])
	Local nValorInc := nValorEx := 0
	Local nTipoDoc := 0
	Local oInutiliza, lInutiliza := .F.
	Local oFntVlr := TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local nOpcX := 0
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local lInutChqCx := SuperGetMv("ES_FLAGINU",,.T.) //Ativa Flag de inutilização de cheque na conferença de caixa //Felipe Sousa - 07/03/2024 || Chamado: POSTO-384

	Private oDlgCHT

	if empty(nRecUF2)
		Return
	endif

	UF2->(DbGoTo(nRecUF2))

	nValorEx := UF2->UF2_VALOR
	nValorInc := UF2->UF2_VALOR
	cChavCheq := UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM
	if !empty(UF2->UF2_CODBAR) //saque
		nTipoDoc := 3
		cCodBarInc := UF2->UF2_CODBAR
	elseif UF2->UF2_SERIE = cPfxComp //compensacao
		nTipoDoc := 2
		cDocInc := UF2->UF2_DOC
		cSerieInc := UF2->UF2_SERIE
	else //venda
		nTipoDoc := 1
		cDocInc := UF2->UF2_DOC
		cSerieInc := UF2->UF2_SERIE
	endif

	cLogCaixa += Space(4) + UF2->UF2_BANCO+" | "+UF2->UF2_AGENCI+" | "+UF2->UF2_CONTA+" | "+UF2->UF2_NUM+" | "+Transform(UF2->UF2_VALOR ,"@E 999,999,999.99") +" | EXCLUIDO"+ CRLF

	If !U_TRETE29K(.F.,@cMsgErro) //validação se tem SE5 e se está conciliado
		Return .F.
	EndIf

	DEFINE MSDIALOG oDlgCHT TITLE "Substituição de Cheque Troco" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 400 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgCHT,05,05,172,190,.F.,.T.,.T.)

	@ 005, 010 SAY "Dados Cheque Atual" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",184) SIZE 184, 007 OF oPnlDet COLORS CLR_HGRAY, 16777215 PIXEL

	@ 016, 010 SAY "Banco" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 024, 010 MSGET oBanco VAR UF2->UF2_BANCO WHEN .F. SIZE 050, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 016, 065 SAY "Agencia" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 024, 065 MSGET oAgencia VAR UF2->UF2_AGENCI WHEN .F. SIZE 050, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 016, 120 SAY "Conta" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 024, 120 MSGET oConta VAR UF2->UF2_CONTA WHEN .F. SIZE 050, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 038, 010 SAY "Numero Cheque" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 046, 010 MSGET oNumCheq VAR UF2->UF2_NUM WHEN .F. SIZE 050, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 038, 065 SAY "Valor" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	oNumCheq := TGet():New( 046, 065,{|u| UF2->UF2_VALOR },oPnlDet,050, 010,PesqPict("UF2","UF2_VALOR"),,,,,,,.T.,,,{|| .F.},,,,.F.,.F.,,,,,,.F.,.T.)
	//Felipe Sousa - 07/03/2024 || Chamado: POSTO-384
	If lInutChqCx
		@ 048, 120 CHECKBOX oInutiliza VAR lInutiliza PROMPT "Inutilizar Cheque?" SIZE 060, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	EndIf

	if nTipoDoc == 3 //se cheque do saque
		@ 060, 010 SAY "Codigo de Barra" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 068, 010 MSGET oCodBar VAR cCodBarInc WHEN .F. SIZE 080, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL
	else
		@ 060, 010 SAY "Documento" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 068, 010 MSGET oDoc VAR cDocInc WHEN .F. SIZE 080, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

		@ 060, 095 SAY "Série" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
		@ 068, 095 MSGET oSerie VAR cSerieInc WHEN .F. .AND. nTipoDoc==1 SIZE 040, 010 OF oPnlDet COLORS 0, 16777215 PIXEL
	endif

	@ 086, 010 SAY "Dados Novo Cheque" SIZE 50, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 088, 002 SAY Replicate("_",184) SIZE 184, 007 OF oPnlDet COLORS CLR_HGRAY, 16777215 PIXEL

	@ 097, 010 SAY "Banco" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 105, 010 MSGET oBanco VAR cBancoInc SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 097, 076 SAY "Agencia" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 105, 076 MSGET oAgencia VAR cAgencInc SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 119, 010 SAY "Conta" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 127, 010 MSGET oConta VAR cContaInc SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 119, 076 SAY "Numero Cheque" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 127, 076 MSGET oNumCheq VAR cNumChInc SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 149, 010 SAY "Valor" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 146, 045 MSGET oValor VAR nValorInc SIZE 105, 013 OF oPnlDet HASBUTTON COLORS 0, 16777215 FONT oFntVlr PIXEL Picture PesqPict("UF2","UF2_VALOR") VALID nValorInc>=0

	@ 182, 155 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oDlgCHT PIXEL Action iif((cBancoInc+cAgencInc+cContaInc+cNumChInc == cChavCheq .AND. nValorInc<>nValorEx .AND. MsgYesNo("Alteração apenas do Valor! Confirma?","Atenção")) .OR. ValidIncCHQ(nTipoDoc, lJaPosi, cSerieInc, cDocInc, cCodBarInc, cBancoInc, cAgencInc, cContaInc, cNumChInc, nValorInc, nValorEx),(nOpcX:=1,oDlgCHT:End()),)
	oButton1:SetCSS( CSS_BTNAZUL )
	@ 182, 110 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgCHT PIXEL Action oDlgCHT:End()

	ACTIVATE MSDIALOG oDlgCHT CENTERED

	if nOpcX == 1

		BeginTran()

		//excluindo cheque atual
		if DelChqTroco(nRecUF2, nTipoDoc, .T., lInutiliza)
			//incluindo novo cheque
			if !IncChqTroco(nTipoDoc, .T.,, cSerieInc, cDocInc, cCodBarInc, cBancoInc, cAgencInc, cContaInc, cNumChInc, nValorInc)
				lOk := .F.
				DisarmTransaction()
			else
				cLogCaixa += Space(4) + UF2->UF2_BANCO+" | "+UF2->UF2_AGENCI+" | "+UF2->UF2_CONTA+" | "+UF2->UF2_NUM+" | "+Transform(UF2->UF2_VALOR ,"@E 999,999,999.99") +" | INCLUIDO"+ CRLF
			endif
		else
			lOk := .F.
			DisarmTransaction()
		endif

		EndTran()

		if lOk .AND. lLogCaixa
			GrvLogConf("3","A", cLogCaixa, cDocInc,cSerieInc,cCodBarInc, (cBancoInc+cAgencInc+cContaInc+cNumChInc) )
		endif

		if bRefresh <> Nil
			EVal(bRefresh)
		endif
	endif

Return lOk

//--------------------------------------------------------------------------------------
// Faz correção do cheque troco
//--------------------------------------------------------------------------------------
Static Function CorrigeCHT(nRecUF2, bRefresh)

	Local oBanco, oAgencia, oConta, oNum, oValor, oDocum, oSerie, oCodBar, oCliente
	Local aCpoSEF := {"LEG","EF_BANCO","EF_AGENCIA","EF_CONTA","EF_NUM","EF_VALOR","EF_DATA","EF_NUMNOTA","EF_SERIE","EF_XCODBAR","EF_CLIENTE","EF_LOJACLI","A1_NREDUZ"}
	Local aCpoSE5 := {"LEG","E5_RECPAG","E5_BANCO","E5_AGENCIA","E5_CONTA","E5_NUMCHEQ","E5_VALOR","E5_DATA","E5_NUMERO","E5_PREFIXO","E5_CLIFOR","E5_LOJA","A1_NREDUZ"}
	Local aHeaderEx := {}
	Local aColsEx := {}
	Private oDlgDetCHT
	Private oGridSEF, oGridSE5CHT

	if empty(nRecUF2)
		Return
	endif

	UF2->(DbGoTo(nRecUF2))

	if LegendUF2() == "BR_VERDE" //se tudo OK com financeiro, aborta
		MsgInfo("Este cheque troco não tem pendências financeiras.","Atenção")
		Return .F.
	endif

	DEFINE MSDIALOG oDlgDetCHT TITLE "Corrige Cheque Troco - Detalhe" STYLE DS_MODALFRAME FROM 000, 000  TO 500, 800 COLORS 0, 16777215 PIXEL

	//---- Dados Cabeçalho
	@ 05, 05 GROUP oGroup1 TO 060, 395 PROMPT "Dados Atuais do Cheque Troco" OF oDlgDetCHT COLOR 0, 16777215 PIXEL

	@ 015, 010 SAY "Banco" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
	@ 023, 010 MSGET oBanco VAR UF2->UF2_BANCO When .F. SIZE 030, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 045 SAY "Agencia" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
	@ 023, 045 MSGET oAgencia VAR UF2->UF2_AGENCI When .F. SIZE 050, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 100 SAY "Conta" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
	@ 023, 100 MSGET oConta VAR UF2->UF2_CONTA When .F. SIZE 050, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 155 SAY "Numero CH" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
	@ 023, 155 MSGET oNum VAR UF2->UF2_NUM When .F. SIZE 050, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

	@ 015, 210 SAY "Valor" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
	@ 023, 210 MSGET oValor VAR UF2->UF2_VALOR When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

	if !empty(UF2->UF2_CODBAR)
		@ 037, 010 SAY "Doc/NF" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
		@ 045, 010 MSGET oCodBar VAR UF2->UF2_CODBAR When .F. SIZE 090, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL
	else
		@ 037, 010 SAY "Doc/NF" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
		@ 045, 010 MSGET oDocum VAR UF2->UF2_DOC When .F. SIZE 055, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

		@ 037, 070 SAY "Série" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
		@ 045, 070 MSGET oSerie VAR UF2->UF2_SERIE When .F. SIZE 030, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL
	endif

	@ 037, 105 SAY "Cliente" SIZE 50, 007 OF oDlgDetCHT COLORS 0, 16777215 PIXEL
	@ 045, 105 MSGET oCliente VAR (UF2->UF2_CLIENT+"/"+UF2->UF2_LOJACL+" - "+Posicione("SA1",1,xFilial("SA1")+UF2->UF2_CLIENT+UF2->UF2_LOJACL,"A1_NOME")) When .F. SIZE 200, 010 OF oDlgDetCHT HASBUTTON COLORS 0, 16777215 PIXEL

	//---- SEF
	@ 065, 005 GROUP oGroup1 TO 145, 395 PROMPT "Registros da SEF" OF oDlgDetCHT COLOR 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCpoSEF)
	aColsEx := {}
	aadd(aColsEx, MontaDados("SEF",aCpoSEF, .T.))
	oGridSEF := MsNewGetDados():New( 075, 010, 140, 390,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgDetCHT, aHeaderEx, aColsEx)
	oGridSEF:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridSEF, @nCol), )}

	//---- SE5
	@ 150, 005 GROUP oGroup1 TO 230, 395 PROMPT "Registros da SE5" OF oDlgDetCHT COLOR 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCpoSE5)
	aColsEx := {}
	aadd(aColsEx, MontaDados("SE5",aCpoSE5, .T.))
	oGridSE5CHT := MsNewGetDados():New( 160, 010, 225, 390,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgDetCHT, aHeaderEx, aColsEx)
	oGridSE5CHT:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oGridSE5CHT, @nCol), )}

	@ 235, 355 BUTTON oButton1 PROMPT "Corrigir" SIZE 040, 012 OF oDlgDetCHT PIXEL Action LjMsgRun("Corrigindo cheque troco...","Corrigindo...",{|| ProcCorrCHT(aCpoSEF,aCpoSE5) })
	@ 235, 310 BUTTON oButton1 PROMPT "Fechar" SIZE 040, 012 OF oDlgDetCHT PIXEL Action oDlgDetCHT:End()

	AtuDetCHT(aCpoSEF,aCpoSE5, .F.)

	ACTIVATE MSDIALOG oDlgDetCHT CENTERED

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Carrega dados na tela de Corrigir Cheque troco
//--------------------------------------------------------------------------------------
Static Function AtuDetCHT(aCpoSEF,aCpoSE5, lRefresh)

	Local cQry := ""
	Local lOK := .T.
	Default lRefresh := .T.

	//SEF
	oGridSEF:aCols := {}
	cQry := "SELECT SEF.R_E_C_N_O_ RECNO "
	cQry += "FROM "+RetSqlName("SEF")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SEF "
	cQry += "WHERE SEF.D_E_L_E_T_ = ' ' "
	cQry += "  AND EF_FILIAL = '"+xFilial("SEF")+"' "
	cQry += "  AND EF_HIST LIKE 'CHEQUE TROCO NO PDV' "
	cQry += "  AND EF_BANCO = '"+UF2->UF2_BANCO+"'"
	cQry += "  AND EF_AGENCIA = '"+UF2->UF2_AGENCI+"'"
	cQry += "  AND EF_CONTA = '"+UF2->UF2_CONTA+"'"
	cQry += "  AND EF_NUM = '"+UF2->UF2_NUM+"'"
	If Select("QRYSEF") > 0
		QRYSEF->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYSEF" // Cria uma nova area com o resultado do query
	While QRYSEF->(!Eof())
		SEF->(DbGoTo(QRYSEF->RECNO))
		Posicione("SA1",1,xFilial("SA1")+SEF->EF_CLIENTE+SEF->EF_LOJACLI,"A1_NREDUZ")
		aadd(oGridSEF:aCols, MontaDados("SEF",aCpoSEF, .F.))
		if !empty(UF2->UF2_CODBAR)
			if SEF->EF_XCODBAR==UF2->UF2_CODBAR
				oGridSEF:aCols[len(oGridSEF:aCols)][aScan(aCpoSEF,"LEG")] := "BR_VERDE"
			else
				oGridSEF:aCols[len(oGridSEF:aCols)][aScan(aCpoSEF,"LEG")] := "BR_VERMELHO"
				lOK := .F.
			endif
		else
			if SEF->EF_NUMNOTA==UF2->UF2_DOC .AND. SEF->EF_SERIE==UF2->UF2_SERIE
				oGridSEF:aCols[len(oGridSEF:aCols)][aScan(aCpoSEF,"LEG")] := "BR_VERDE"
			else
				oGridSEF:aCols[len(oGridSEF:aCols)][aScan(aCpoSEF,"LEG")] := "BR_VERMELHO"
				lOK := .F.
			endif
		endif
		QRYSEF->(DbSkip())
	EndDo
	QRYSEF->(DbCloseArea())
	if empty(oGridSEF:aCols)
		aadd(oGridSEF:aCols, MontaDados("SEF",aCpoSEF, .T.))
		lOK := .F.
	endif

	//SE5
	oGridSE5CHT:aCols := {}
	cQry := "SELECT 'SE5' TIPO, SE5.R_E_C_N_O_ RECNO "
	cQry += "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
	cQry += "WHERE SE5.D_E_L_E_T_ = ' ' "
	cQry += "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
	cQry += "  AND E5_TIPODOC IN ('CA','CH') "
	cQry += "  AND E5_NUMCHEQ <> ' ' " //cheque preenchido
	cQry += "  AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C'"
	cQry += "  AND E5_BANCO = '"+UF2->UF2_BANCO+"'"
	cQry += "  AND E5_AGENCIA = '"+UF2->UF2_AGENCI+"'"
	cQry += "  AND E5_CONTA = '"+UF2->UF2_CONTA+"'"
	cQry += "  AND E5_NUMCHEQ = '"+UF2->UF2_NUM+"'"
	cQry += "  UNION "
	cQry += "SELECT 'E5-' TIPO, SE5.R_E_C_N_O_ RECNO "
	cQry += "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
	cQry += "WHERE SE5.D_E_L_E_T_ = ' ' "
	cQry += "  AND E5_FILIAL = '"+xFilial("SE5")+"' "
	cQry += "  AND E5_TIPODOC = 'EC' "
	cQry += "  AND E5_NUMCHEQ <> ' ' " //cheque preenchido
	cQry += "  AND E5_RECPAG = 'R' "
	cQry += "  AND E5_BANCO = '"+UF2->UF2_BANCO+"'"
	cQry += "  AND E5_AGENCIA = '"+UF2->UF2_AGENCI+"'"
	cQry += "  AND E5_CONTA = '"+UF2->UF2_CONTA+"'"
	cQry += "  AND E5_NUMCHEQ = '"+UF2->UF2_NUM+"'"
	If Select("QRYSE5") > 0
		QRYSE5->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYSE5" // Cria uma nova area com o resultado do query
	While QRYSE5->(!Eof())
		SE5->(DbGoTo(QRYSE5->RECNO))
		Posicione("SA1",1,xFilial("SA1")+SE5->E5_CLIFOR+SE5->E5_LOJA,"A1_NREDUZ")
		aadd(oGridSE5CHT:aCols, MontaDados("SE5",aCpoSE5, .F.))
		if !empty(UF2->UF2_CODBAR)
			oGridSE5CHT:aCols[len(oGridSE5CHT:aCols)][aScan(aCpoSE5,"LEG")] := "BR_VERDE"
		else
			if SE5->E5_NUMERO==UF2->UF2_DOC .AND. SE5->E5_PREFIXO==UF2->UF2_SERIE
				oGridSE5CHT:aCols[len(oGridSE5CHT:aCols)][aScan(aCpoSE5,"LEG")] := "BR_VERDE"
			else
				oGridSE5CHT:aCols[len(oGridSE5CHT:aCols)][aScan(aCpoSE5,"LEG")] := "BR_VERMELHO"
				lOK := .F.
			endif
		endif
		QRYSE5->(DbSkip())
	EndDo
	QRYSE5->(DbCloseArea())
	if empty(oGridSE5CHT:aCols) .AND. cLIBCHEQ == "S"
		aadd(oGridSE5CHT:aCols, MontaDados("SE5",aCpoSE5, .T.))
		lOK := .F.
	endif

	if lRefresh
		oGridSEF:oBrowse:Refresh()
		oGridSE5CHT:oBrowse:Refresh()
		oDlgDetCHT:Refresh()
	endif

Return lOK

//--------------------------------------------------------------------------------------
// Processa correção do cheque troco
//--------------------------------------------------------------------------------------
Static Function ProcCorrCHT(aCpoSEF,aCpoSE5)

	Local lOK := .T.
	Local lAux := .F.
	Local nX := 0
	Local dBkpDbase := dDataBase

	BeginTran()

	dDataBase := SLW->LW_DTABERT //altero database

	//excluo as SEF e SE5 para refazer financeiro depois
	if !empty(oGridSEF:aCols[1][2]) // se tem SEF
		//tenta estornar as baixas da SEF
		lOK := U_TR029CAN(UF2->UF2_BANCO, UF2->UF2_AGENCI, UF2->UF2_CONTA, UF2->UF2_NUM)
		if lOK //se processou corretamente estorno, excluo as SEF
			For nX := 1 to len(oGridSEF:aCols)
				SEF->(DbGoTo(oGridSEF:aCols[nX][len(oGridSEF:aHeader)]))
				RecLock("SEF",.F.)
				SEF->(DbDelete())
				SEF->(MsUnlock())
			next nX
		endif
		AtuDetCHT(aCpoSEF,aCpoSE5, .F.) //atualizo grid
	endif

	if lOK .AND. !empty(oGridSE5CHT:aCols[1][2])
		//Exclui as SE5 se ainda existir
		For nX := 1 to len(oGridSE5CHT:aCols)
			SE5->(DbGoTo(oGridSE5CHT:aCols[nX][len(oGridSE5CHT:aHeader)]))
			RecLock("SE5",.F.)
			SE5->(DbDelete())
			SE5->(MsUnlock())
		next nX
		AtuDetCHT(aCpoSEF,aCpoSE5, .F.) //atualizo grid
	endif

	//se grid de SEF e SE5 vazia, nao gerou financeiro.
	if empty(oGridSEF:aCols[1][2]) .AND. empty(oGridSE5CHT:aCols[1][2])
		//Chamo rotina que gera financeiro do cheque troco
		lOk := U_TRETE029(UF2->(Recno())) 
		if lOk
			RecLock("UF2",.F.)
			UF2->UF2_XGERAF := 'G'
			UF2->(MsUnlock())
		endif
	else
		lOK := .F. //falha nas exclusoes
	endif

	//verifico se corrigiu
	lAux := AtuDetCHT(aCpoSEF,aCpoSE5, .F.)
	if lOK .AND. !lAux
		lOK := .F.
	endif

	dDataBase := dBkpDbase //volto data

	if lOK
		oDlgDetCHT:End()
	else
		MsgAlert("Não foi possível corrigir financeiro automaticamente. Acione equipe de TI.","Atenção")
		DisarmTransaction()
	endif

	EndTran()

Return

//--------------------------------------------------------------------------------------------
// Função de inclusao de vale haver
// nTipoDoc: 1=Venda;2=Compensaçao
//--------------------------------------------------------------------------------------------
Static Function IncValeHav(nTipoDoc, bRefresh)
	LjMsgRun("Processando financeiro do vale Haver...","Aguarde...",{|| ProcIncVLH(nTipoDoc, bRefresh) })
Return
Static Function ProcIncVLH(nTipoDoc, bRefresh)

	Local lWhenDoc := .T.
	Local lOk := .T.
	Local nOpcX := 0
	Local oFntVlr := TFont():New("Verdana",,020,,.T.,,,,,.F.,.F.)
	Local dBkpDbase := dDataBase
	Local oSerie, oDoc, oValor, oCodCli,oLojCli,oNomCli
	Local aParBox := {}, aRetPar := {}
	Local cSerie := Space(TamSX3("L1_SERIE")[1])
	Local cDoc := Space(TamSX3("L1_DOC")[1])
	Local nValor := 0
	Local cCodCli := Space(TamSX3("A1_COD")[1])
	Local cLojCli := Space(TamSX3("A1_LOJA")[1])
	Local cNomCli := Space(TamSX3("A1_NOME")[1])
	Local bGatilSL1
	Local bGatilUC0
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Local dDataEmiss := STOD("")
	cPfxComp := PadR(cPfxComp,TamSX3("E1_PREFIXO")[1])

	Default nTipoDoc := 0

	Private oDlgIncVlh

	bGatilSL1 := {|| cCodCli:=Posicione("SL1",2,xFilial("SL1")+cSerie+cDoc,"L1_CLIENTE"),cLojCli:=SL1->L1_LOJA,cNomCli:=Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_NOME"),oDlgIncVlh:Refresh() }
	if SuperGetMV("TP_ACTCMP",,.F.)
		bGatilUC0 := {|| cCodCli:=Posicione("UC0",1,xFilial("UC0")+cDoc,"UC0_CLIENT"),cLojCli:=UC0->UC0_LOJA,cNomCli:=Posicione("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_NOME"),oDlgIncVlh:Refresh() }
	endif

	if nTipoDoc > 0
		lWhenDoc := .F.
		if nTipoDoc == 1 //venda
			cDoc := SL1->L1_DOC
			cSerie := SL1->L1_SERIE
			cCodCli := SL1->L1_CLIENTE
			cLojCli := SL1->L1_LOJA
			cNomCli := Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_NOME")
		elseif nTipoDoc == 2 //compensacao
			cDoc := UC0->UC0_NUM
			cSerie := UC0->UC0_ESTACA
			cCodCli := UC0->UC0_CLIENT
			cLojCli := UC0->UC0_LOJA
			cNomCli := Posicione("SA1",1,xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA,"A1_NOME")
		else
			Return
		endif
		
		if U_T028TVLH(4,,,cDoc,iif(nTipoDoc==2,cPfxComp,cSerie)) > 0 //se tem vale haver
			MsgInfo("Este documento ja possui um titulo de vale haver. Ação nao permitida!","Atenção")
			Return
		endif

		if nTipoDoc == 2
			if UC0->UC0_CLIENT + UC0->UC0_LOJA == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
				MsgInfo("Esta compensação está com cliente consumidor padrão. Ação nao permitida!","Atenção")
				Return
			endif
		endif
	else
		if SuperGetMV("TP_ACTCMP",,.F.) 
			aAdd(aParBox, {3, 'Tipo Documento:', 1, {"Venda","Compensação"}, 100, '', .T., '.T.'})
			If ParamBox(aParBox, 'Inclusão Vale Haver', @aRetPar)
				nTipoDoc := aRetPar[1]
			else
				Return
			EndIf
		else
			nTipoDoc := 1 
		endif
	endif

	if empty(cSerie)
		if nTipoDoc == 2 //compensacao
			cSerie := PadR(SLW->LW_ESTACAO,TamSX3("E1_PREFIXO")[1])
		else
			cSerie := PadR(SLW->LW_SERIE,TamSX3("E1_PREFIXO")[1])
		endif
	endif

	DEFINE MSDIALOG oDlgIncVlh TITLE "Inclusao de Vale Haver" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 400 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgIncVlh,05,05,172,190,.F.,.T.,.T.)

	@ 005, 010 SAY "Documento" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 010 MSGET oDoc VAR cDoc WHEN lWhenDoc SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL VALID iif(nTipoDoc==1, Eval(bGatilSL1), Eval(bGatilUC0))

	@ 005, 075 SAY "Série" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 013, 075 MSGET oSerie VAR cSerie WHEN lWhenDoc .AND. nTipoDoc==1 SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL VALID iif(nTipoDoc==1, Eval(bGatilSL1), Eval(bGatilUC0))

	@ 027, 010 SAY "Cliente" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 035, 010 MSGET oCodCli VAR cCodCli When .F. SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 027, 075 SAY "Loja" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 035, 075 MSGET oLojCli VAR cLojCli When .F. SIZE 030, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 049, 010 SAY "Nome Cliente" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 057, 010 MSGET oNomCli VAR cNomCli When .F. SIZE 150, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	@ 070, 002 SAY Replicate("_",184) SIZE 184, 007 OF oPnlDet COLORS CLR_HGRAY, 16777215 PIXEL

	@ 095, 010 SAY "Valor" SIZE 50, 007 OF oPnlDet COLORS CLR_BLUE, 16777215 PIXEL
	@ 092, 045 MSGET oValor VAR nValor SIZE 105, 013 OF oPnlDet HASBUTTON COLORS 0, 16777215 FONT oFntVlr PIXEL Picture PesqPict("SE1","E1_VALOR") VALID nValor>=0

	@ 182, 155 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 012 OF oDlgIncVlh PIXEL Action iif(ValidIncVLH(nTipoDoc, !lWhenDoc, cSerie, cDoc, cCodCli, cLojCli, nValor, cPfxComp),(nOpcX:=1,oDlgIncVlh:End()),)
	oButton1:SetCSS( CSS_BTNAZUL )
	@ 182, 110 BUTTON oButton1 PROMPT "Cancelar" SIZE 040, 012 OF oDlgIncVlh PIXEL Action oDlgIncVlh:End()

	ACTIVATE MSDIALOG oDlgIncVlh CENTERED

	if nOpcX == 1

		if nTipoDoc == 1 //venda
			dDataEmiss := SL1->L1_EMISNF
		elseif nTipoDoc == 2 
			dDataEmiss := UC0->UC0_DATA
		endif

		BeginTran()

		dDataBase := SLW->LW_DTABERT //altero database
		if !empty(dDataEmiss)
			dDataBase := dDataEmiss
		endif

		//chamo a função que inclui o vale haver
		if U_IncVlHav(nValor, cDoc, cCodCli, cLojCli, dDataBase, cSerie, SLW->LW_PDV, iif(nTipoDoc==2, SuperGetMV( "MV_XCNATVL" , .F. , "VALE",) ,Nil) )

			cLogCaixa += "VALOR VALE HAVER: " + Transform(nValor ,"@E 999,999,999.99") + CRLF

			//Removendo o valor em dinheiro no documento
			if nTipoDoc == 1 //venda
				if !AjuSL1Troco()
					MsgAlert("Falha na alteração do valor em dinheiro do troco da venda! Operação abortada!","Atenção")
					DisarmTransaction()
					lOk := .F.
				endif
			elseif nTipoDoc == 2 .AND. !U_TRETE29J(3, nValor, cDoc) //compensacao
				MsgAlert("Falha na alteração do valor em dinheiro da saida da compensação! Operação abortada!","Atenção")
				DisarmTransaction()
				lOk := .F.
			endif

			if lOk .AND. lLogCaixa
				GrvLogConf("A","I", cLogCaixa, cDoc, iif(nTipoDoc==2,cPfxComp,cSerie))
			endif

		else
			MsgAlert("Falha ao processar financeiro do vale haver! Operação abortada!","Atenção")
			DisarmTransaction()
			lOk := .F.
		endif

		EndTran()

		dDataBase := dBkpDbase

		if bRefresh <> Nil
			EVal(bRefresh)
		endif
	endif

Return

//--------------------------------------------------------------------------------------------
// Valida Inclusao Vale Haver
// nTipoDoc: 1=Venda;2=Compensaçao;3=Saque/VLM
//--------------------------------------------------------------------------------------------
Static Function ValidIncVLH(nTipoDoc, lJaPosi, cSerie, cDoc, cCodCli, cLojCli, nValor, cPfxComp)

	Local nTrocoSL1 := 0
	Local nTamHora := TamSX3("LW_HRABERT")[1]

	if empty(cSerie) .OR. empty(cDoc) .OR. empty(cCodCli) .OR. empty(cLojCli) .OR. empty(nValor)
		MsgInfo("Campo obrigatórios nao foram preenchidos!","Atenção")
		Return .F.
	endif
	
	if U_T028TVLH(4,,,cDoc,iif(nTipoDoc==2,cPfxComp,cSerie)) > 0 //se tem vale haver
		MsgInfo("Este documento ja possui um titulo de vale haver. Ação nao permitida!","Atenção")
		Return .F.
	endif

	if !lJaPosi //se nao está poisicionado no documento, verifica
		if nTipoDoc == 1 //venda
			SL1->(DbSetOrder(2)) //filial + serie + doc + pdv
			If !SL1->(DbSeek(xFilial("SL1")+cSerie+cDoc))
				MsgInfo("Não foi encontrada a venda. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif

			//verifico se a venda realmente é deste caixa
			if !(Alltrim(SL1->L1_OPERADO) = Alltrim(SLW->LW_OPERADO) .AND. ;
				Alltrim(SL1->L1_ESTACAO) = Alltrim(SLW->LW_ESTACAO) .AND. ;
				Alltrim(SL1->L1_NUMMOV) = Alltrim(SLW->LW_NUMMOV) .AND. ;
				Alltrim(SL1->L1_PDV) = Alltrim(SLW->LW_PDV) .AND. ;
				DTOS(SL1->L1_EMISNF)+SUBSTR(SL1->L1_HORA,1,nTamHora) >= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT .AND. ;
				DTOS(SL1->L1_EMISNF)+SUBSTR(SL1->L1_HORA,1,nTamHora) <= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA .AND. ;
				!empty(SL1->L1_DOC) .AND. SL1->L1_SITUA == 'OK' )
				MsgInfo("Venda informada não pertence a este caixa. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif
		elseif nTipoDoc == 2 //compensação
			UC0->(DbSetOrder(1))
			if !UC0->(DbSeek(xFilial("UC0")+cDoc))
				MsgInfo("Não foi encontrada a Compensação. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif

			//verifico se a compensação realmente é deste caixa
			if !(Alltrim(UC0->UC0_OPERAD) = Alltrim(SLW->LW_OPERADO) .AND. ;
				Alltrim(UC0->UC0_ESTACA) = Alltrim(SLW->LW_ESTACAO) .AND. ;
				Alltrim(UC0->UC0_NUMMOV) = Alltrim(SLW->LW_NUMMOV) .AND. ;
				Alltrim(UC0->UC0_PDV) = Alltrim(SLW->LW_PDV) .AND. ;
				DTOS(UC0->UC0_DATA)+SUBSTR(UC0->UC0_HORA,1,nTamHora) >= DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT .AND. ;
				DTOS(UC0->UC0_DATA)+SUBSTR(UC0->UC0_HORA,1,nTamHora) <= DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA .AND. ;
				UC0->UC0_ESTORN == 'N')
				MsgInfo("Compensação informada não pertence a este caixa. Verifique Informações digitadas.","Atenção")
				Return .F.
			endif
						
			if UC0->UC0_CLIENT + UC0->UC0_LOJA == GETMV("MV_CLIPAD")+GETMV("MV_LOJAPAD")
				MsgInfo("Esta compensação está com cliente consumidor padrão. Ação nao permitida!","Atenção")
				Return .F.
			endif
		endif
	endif

	//validando valor
	if nTipoDoc == 1 //se venda
		//Troco em Dinheiro
		nTrocoSL1 := U_T028TTV(4,,,"E5_PREFIXO = '"+SL1->L1_SERIE+"' AND E5_NUMERO = '"+SL1->L1_DOC+"'",.F.,.F.)
		if nTrocoSL1 < nValor
			MsgAlert("O valor do vale haver ultrapassa o valor de troco em dinheiro da venda.","Atenção")
			Return .F.
		endif
	elseif nTipoDoc == 2 .AND. UC0->UC0_VLDINH < nValor //valida valor
		MsgAlert("O valor do vale haver ultrapassa o valor de saída em dinheiro da compensação.","Atenção")
		Return .F.
	endif

Return .T.

//--------------------------------------------------------------------------------------
// Faz exclusao do vale haver
// nTipoDoc: 1=Venda;2=Compensaçao
//--------------------------------------------------------------------------------------
Static Function DelValeHav(nRecSE1, nTipoDoc, bRefresh)
	LjMsgRun("Processando financeiro do vale Haver...","Aguarde...",{|| ProcDelVLH(nRecSE1, nTipoDoc, bRefresh) })
Return 
Static Function ProcDelVLH(nRecSE1, nTipoDoc, bRefresh)
	Local lOk := .T.
	Local cSerie, cDoc, nValor, aFin040
	Local cPrefix := PadR(SLW->LW_ESTACAO,TamSX3("E1_PREFIXO")[1])
	Local cLogCaixa := ""
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local cPfxComp := SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)
	Default nTipoDoc := 0

	if empty(nRecSE1)
		Return .F.
	endif

	SE1->(DbGoTo(nRecSE1))

	cSerie := SE1->E1_PREFIXO
	cDoc := SE1->E1_NUM
	nValor := SE1->E1_VALOR

	if nTipoDoc == 0
		UC0->(DbSetOrder(1))
		SL1->(DbSetOrder(2)) //filial + serie + doc + pdv
		if cSerie == cPrefix .AND. UC0->(DbSeek(xFilial("UC0")+cDoc)) //se tem compensação
			nTipoDoc := 2
		elseIf SL1->(DbSeek(xFilial("SL1")+cSerie+cDoc))
			nTipoDoc := 1
		else
			MsgInfo("Não foi encontrado o documento do vale haver. Operaçao abortada.","Atenção")
			Return .F.
		endif
	endif

	if SE1->E1_SALDO <> SE1->E1_VALOR
		MsgInfo("Vale haver ja utilizado (baixado ou compensado). Operaçao abortada.","Atenção")
		Return .F.
	endif

	if !MsgYesNo("Confirma exclusão do vale haver selecionado?","Excluir")
		Return .F.
	endif

	cLogCaixa += "VALOR VALE HAVER: " + Transform(nValor ,"@E 999,999,999.99") + CRLF
	
	BeginTran()

	aFin040 := {}
	AADD( aFin040, {"E1_FILIAL"  , xFilial("SE1")																	 	, Nil})
	AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
	AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM		, Nil})
	AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA	, Nil})
	AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

	//Assinatura de variáveis que controlarão a exclusão automática do título;
	lMsErroAuto := .F.
	lMsHelpAuto := .T.

	//apaga a origem para ser possível alteração/exclusão do titulo
	RecLock("SE1",.F.)
		SE1->E1_ORIGEM := ""
	SE1->(MsUnlock())

	MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)

	if lMsErroAuto
		MostraErro()
		lOk := .F.
	else
		//Adicionando o valor em dinheiro no documento
		if nTipoDoc == 1 //venda
			if !AjuSL1Troco()
				MsgAlert("Falha na alteração do valor em dinheiro do troco da venda! Operação abortada!","Atenção")
				lOk := .F.
			endif
		elseif nTipoDoc == 2 .AND. !U_TRETE29J(4, nValor, cDoc) //compensacao
			MsgAlert("Falha na alteração do valor em dinheiro da saida da compensação! Operação abortada!","Atenção")
			lOk := .F.
		endif
	endif

	if lOk
		if lLogCaixa
			GrvLogConf("A","E", cLogCaixa, cDoc, iif(nTipoDoc==2,cPfxComp,cSerie))
		endif
	else
		DisarmTransaction()
	endif
	EndTran()

	if bRefresh <> Nil
		EVal(bRefresh)
	endif

Return

//--------------------------------------------------------------------------------------
// Função que faz conexão RPC na retaguarda, para buscar registros
//--------------------------------------------------------------------------------------
Static Function DoRPC_Pdv(cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)

	Local xRet      := {}
	Local cAmbLocal := AllTrim(SuperGetMv( "MRPC_CAIXA" , .F. , "002",)) //Determina o codigo de cada ambiente no PDV, preencher parametro por filial
	Local cRpcEnv   := ""
	Local cRpcSrv   := ""
	Local nRpcPort  := 0
	Local cRpcEmp   := ""
	Local cRpcFil   := ""
	Local aAliasRpc := {"SLW","SL1","SL2","SL4","SE5","SA1","U56","U57","UC0","UC1","UIC"}
	Local lAmbByPdv := .F.
	Local cMsgError := ""

	if type("oRpcSrv")=="O"
		if oRpcSrv:CallProc( 'FindFunction', cFunction )
			// Executa função através do CallProc
			xRet:= oRpcSrv:CallProc( cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)
			cMsgError := ""
		else
			cMsgError := "RPC: Função "+cFunction+" nao compilada no ambiente destino."
		endif
	else
		DbSelectArea("MD4")
		MD4->( DbSetOrder(1) ) //MD4_FILIAL+MD4_CODIGO
		DbSelectArea("MD3")
		MD3->( DbSetOrder(1) ) //MD3_FILIAL+MD3_CODAMB+MD3_TIPO

		//se existe o campo PDV para encontrar ambiente
		if MD4->(FieldPos("MD4_XPDV")) > 0
			MD4->(DbSeek( xFilial("MD4") ))
			While MD4->(!Eof()) .AND. MD4->MD4_FILIAL == xFilial("MD4")
				if !empty(MD4->MD4_XPDV) .AND. MD4->MD4_XPDV == SLW->LW_PDV
					If MD3->(DbSeek( xFilial("MD3") + MD4->MD4_CODIGO + "R")) //"R" -> Tipo de Comunicacao RPC
						if MD3->MD3_EMP == cEmpAnt .AND. MD3->MD3_FIL == cFilAnt
							lAmbByPdv := .T.
							EXIT
						endif
					endif
				endif
				MD4->(DbSkip())
			enddo
		endif

		//tenta a conexao direto no PDV
		if lAmbByPdv
			// Prepara ambiente para conexão em outro Servidor
			cRpcEnv := AllTrim( MD3->MD3_NOMAMB )
			cRpcEmp := AllTrim( MD3->MD3_EMP )
			cRpcFil := cFilAnt //AllTrim( MD3->MD3_FIL )
			oRpcSrv := TRpc():New( cRpcEnv ) //TRpc():New(GetEnvServer())

			// Conecta no ambiente
			cRpcSrv  := AllTrim( MD3->MD3_IP )
			nRpcPort := Val( MD3->MD3_PORTA )

			If ( oRpcSrv:Connect( cRpcSrv, nRpcPort ) )
				oRpcSrv:CallProc( 'RPCSetType', 3 )
				oRpcSrv:CallProc( 'RPCSetEnv', cRpcEmp, cRpcFil,,,"FRT",, aAliasRpc )

				if oRpcSrv:CallProc( 'FindFunction', cFunction )
					// Executa função através do CallProc
					xRet:= oRpcSrv:CallProc( cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)
					cMsgError := ""
				else
					cMsgError := "RPC: Função "+cFunction+" nao compilada no ambiente destino."
					lAmbByPdv := .F.
				endif

			Else
				cMsgError := 'RPC: Conexão com o Servidor PDV Falhou!'
				lAmbByPdv := .F.
				FreeObj(oRpcSrv)
			Endif
		endif

		//senao conseguir no PDV direto, tenta na central pdv
		If !lAmbByPdv .AND. !Empty( cAmbLocal )
			If MD4->(DbSeek( xFilial("MD4") + cAmbLocal ))
				DbSelectArea("MD3")
				MD3->( DbSetOrder(1) ) //MD3_FILIAL+MD3_CODAMB+MD3_TIPO
				If MD3->(DbSeek( xFilial("MD3") + cAmbLocal + "R")) //"R" -> Tipo de Comunicacao RPC
					// Prepara ambiente para conexão em outro Servidor
					cRpcEnv := AllTrim( MD3->MD3_NOMAMB )
					cRpcEmp := AllTrim( MD3->MD3_EMP )
					cRpcFil := cFilAnt //AllTrim( MD3->MD3_FIL )
					oRpcSrv := TRpc():New( cRpcEnv ) //TRpc():New(GetEnvServer())

					// Conecta no ambiente
					cRpcSrv  := AllTrim( MD3->MD3_IP )
					nRpcPort := Val( MD3->MD3_PORTA )

					If ( oRpcSrv:Connect( cRpcSrv, nRpcPort ) )
						oRpcSrv:CallProc( 'RPCSetType', 3 )
						oRpcSrv:CallProc( 'RPCSetEnv', cRpcEmp, cRpcFil,,,,, aAliasRpc )

						if oRpcSrv:CallProc( 'FindFunction', cFunction )
							// Executa função através do CallProc
							xRet:= oRpcSrv:CallProc( cFunction, xParam1, xParam2, xParam3, xParam4, xParam5, xParam6, xParam7, xParam8, xParam9, xParam10, xParam11, xParam12, xParam13, xParam14, xParam15)
							cMsgError := ""
						else
							cMsgError := "RPC: Função "+cFunction+" nao compilada no ambiente destino."
						endif

					Else
						cMsgError := 'RPC: Conexão com o Servidor PDV Falhou!'
						FreeObj(oRpcSrv)
					Endif
				EndIf
			EndIf
		EndIf
	Endif

	if !empty(cMsgError)
		MsgAlert(cMsgError, "Aviso!")
	endif

	If ValType(xRet) <> "A" .AND. Upper(cFunction)<>"POSICIONE"
		xRet := {}
	EndIf

Return xRet

//--------------------------------------------------------------------------------------
// Função que fecha conexão RPC
//--------------------------------------------------------------------------------------
Static Function DoRpcClose()
	if oRpcSrv != Nil
		oRpcSrv:CallProc( 'RpcClearEnv' )
		oRpcSrv:CallProc( 'DbCloseAll' )
		oRpcSrv:Disconnect()
		FreeObj(oRpcSrv)
	endif
Return

//--------------------------------------------------------------------------------------
// Função para ordenaçao de grid MsNewGetDados
//--------------------------------------------------------------------------------------
Static Function OrdGrid(oObj,nColum)

	if __XVEZ == "0"
		__XVEZ := "1"
	else
		if __XVEZ == "1"
			__XVEZ := "2"
		endif
	endif

	if __XVEZ == "2"

		// reordeno o array do grid
		if __ASC
			if valtype(oObj) == "A"
				ASORT(oObj,,,{|x, y| x[nColum] < y[nColum] }) //ordena?o crescente
			else
				ASORT(oObj:aCols,,,{|x, y| x[nColum] < y[nColum] }) //ordena?o crescente
			endif
			__ASC := .F.
		else
			if valtype(oObj) == "A"
				ASORT(oObj,,,{|x, y| x[nColum] > y[nColum] }) //ordena?o decrescente
			else
				ASORT(oObj:aCols,,,{|x, y| x[nColum] > y[nColum] }) //ordena?o decrescente
			endif
			__ASC := .T.
		endif

		// fa? um refresh no grid
		if valtype(oObj) == "O"
			oObj:oBrowse:Refresh()
		endif
		__XVEZ := "0"

	endif

Return()

//--------------------------------------------------------------------------------------
// Classe que monta barra de totais da vendas
//--------------------------------------------------------------------------------------
CLASS BTotaisVenda

	DATA oTotPrd
	DATA nTotPrd
	DATA oTitRec
	DATA nTitRec
	DATA oTrocoDin
	DATA nTrocoDin
	DATA oTrocoCht
	DATA nTrocoCht
	DATA oTrocoVlh
	DATA nTrocoVlh
	DATA lSubTroco

	DATA oSldVenda
	DATA nSldVenda

	METHOD New(oDlg, nTop, nLeft, lLables, lSubTroco) CONSTRUCTOR
	METHOD Limpa()
	METHOD Refresh()

ENDCLASS
//--------------------------------------------------------------------------------------
// metodo construtor
//--------------------------------------------------------------------------------------
METHOD New(oDlg, nTop, nLeft, lLables, lSubTroco) CLASS BTotaisVenda

	Default lSubTroco := .T.

	//inicializo as variaveis
	::Limpa()
	::lSubTroco := lSubTroco

	if lLables
		@ nTop, nLeft SAY "Total Produtos (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ nTop, nLeft+70 SAY "Total Recebido (+)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ nTop, nLeft+140 SAY "Troco ("+SIMBDIN+") (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		if lMvPosto
			@ nTop, nLeft+210 SAY "Troco Cheque (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
			@ nTop, nLeft+280 SAY "Troco Vale Haver (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
			@ nTop, nLeft+350 SAY "Saldo Venda (=)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		else
			@ nTop, nLeft+210 SAY "Saldo Venda (=)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		endif
	endif

	@ nTop+8, nLeft MSGET ::oTotPrd VAR ::nTotPrd When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+70 MSGET ::oTitRec VAR ::nTitRec When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+140 MSGET ::oTrocoDin VAR ::nTrocoDin When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	if lMvPosto
		@ nTop+8, nLeft+210 MSGET ::oTrocoCht VAR ::nTrocoCht When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
		@ nTop+8, nLeft+280 MSGET ::oTrocoVlh VAR ::nTrocoVlh When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
		@ nTop+8, nLeft+350 MSGET ::oSldVenda VAR ::nSldVenda When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	else
		@ nTop+8, nLeft+210 MSGET ::oSldVenda VAR ::nSldVenda When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	endif
Return
//--------------------------------------------------------------------------------------
// Metodo para destrutor da classe
//--------------------------------------------------------------------------------------
METHOD Limpa() CLASS BTotaisVenda
	::nTotPrd := 0
	::nTitRec := 0
	::nTrocoDin := 0
	::nTrocoCht := 0
	::nTrocoVlh := 0
	::nSldVenda := 0
Return
//--------------------------------------------------------------------------------------
// Metodo para dar refresh nos campos
//--------------------------------------------------------------------------------------
METHOD Refresh() CLASS BTotaisVenda
	if ::lSubTroco
		::nTrocoDin -= ::nTrocoCht
		::nTrocoDin -= ::nTrocoVlh
	endif
	::nSldVenda := ::nTitRec - ::nTotPrd - ::nTrocoDin - ::nTrocoCht - ::nTrocoVlh
	::oTotPrd:Refresh()
	::oTitRec:Refresh()
	::oTrocoDin:Refresh()
	if lMvPosto
		::oTrocoCht:Refresh()
		::oTrocoVlh:Refresh()
	endif
	::oSldVenda:Refresh()
Return

//--------------------------------------------------------------------------------------
// Classe que monta barra de totais da compensaçao
//--------------------------------------------------------------------------------------
CLASS BTotaisComp

	DATA oValEntrada
	DATA nValEntrada
	DATA oValDin
	DATA nValDin
	DATA oValVlh
	DATA nValVlh
	DATA oValCht
	DATA nValCht

	DATA nSaldo
	DATA oSaldo

	METHOD New(oDlg, nTop, nLeft, lLables) CONSTRUCTOR
	METHOD Limpa()
	METHOD Refresh()

ENDCLASS
//--------------------------------------------------------------------------------------
// metodo construtor
//--------------------------------------------------------------------------------------
METHOD New(oDlg, nTop, nLeft, lLables) CLASS BTotaisComp

	//inicializo as variaveis
	::Limpa()

	if lLables
		@ nTop, nLeft SAY "Total Entrada (+)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ nTop, nLeft+70 SAY "Saida ("+SIMBDIN+") (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ nTop, nLeft+140 SAY "Saida Cheque (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ nTop, nLeft+210 SAY "Saida Vale Haver (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ nTop, nLeft+280 SAY "Saldo (=)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	endif

	@ nTop+8, nLeft MSGET ::oValEntrada VAR ::nValEntrada When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+70 MSGET ::oValDin VAR ::nValDin When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+140 MSGET ::oValCht VAR ::nValCht When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+210 MSGET ::oValVlh VAR ::nValVlh When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+280 MSGET ::oSaldo VAR ::nSaldo When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL

Return
//--------------------------------------------------------------------------------------
// Metodo para destrutor da classe
//--------------------------------------------------------------------------------------
METHOD Limpa() CLASS BTotaisComp
	::nValEntrada := 0
	::nValDin := 0
	::nValVlh := 0
	::nValCht := 0
	::nSaldo := 0
Return
//--------------------------------------------------------------------------------------
// Metodo para dar refresh nos campos
//--------------------------------------------------------------------------------------
METHOD Refresh() CLASS BTotaisComp
	::nSaldo := ::nValEntrada - ::nValDin - ::nValVlh - ::nValCht

	::oValEntrada:Refresh()
	::oValDin:Refresh()
	::oValVlh:Refresh()
	::oValCht:Refresh()
	::oSaldo:Refresh()
Return

//--------------------------------------------------------------------------------------
// Classe que monta barra de totais do Vale Serviço
//--------------------------------------------------------------------------------------
CLASS BTotaisVLS

	DATA nVlrServico
	DATA oVlrServico
	DATA nVlrReceb
	DATA oVlrReceb
	DATA nVlrPagar
	DATA oVlrPagar
	DATA cLblReceb
	DATA oLblReceb

	METHOD New(oDlg, nTop, nLeft) CONSTRUCTOR
	METHOD Limpa()
	METHOD Refresh()

ENDCLASS
//--------------------------------------------------------------------------------------
// metodo construtor
//--------------------------------------------------------------------------------------
METHOD New(oDlg, nTop, nLeft) CLASS BTotaisVLS

	//inicializo as variaveis
	::Limpa()

	@ nTop, nLeft SAY "Valor Serviço" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+70 SAY ::oLblReceb PROMPT ::cLblReceb SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+140 SAY "Titulo a Pagar" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ nTop+8, nLeft MSGET ::oVlrServico VAR ::nVlrServico When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+70 MSGET ::oVlrReceb VAR ::nVlrReceb When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+140 MSGET ::oVlrPagar VAR ::nVlrPagar When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL

Return
//--------------------------------------------------------------------------------------
// Metodo para destrutor da classe
//--------------------------------------------------------------------------------------
METHOD Limpa() CLASS BTotaisVLS
	::nVlrServico := 0
	::nVlrReceb := 0
	::nVlrPagar := 0
	::cLblReceb := "Titulo Receber"
Return
//--------------------------------------------------------------------------------------
// Metodo para dar refresh nos campos
//--------------------------------------------------------------------------------------
METHOD Refresh() CLASS BTotaisVLS
	::oVlrServico:Refresh()
	::oVlrReceb:Refresh()
	::oVlrPagar:Refresh()
	::oLblReceb:Refresh()
Return

//--------------------------------------------------------------------------------------
// Classe que monta barra de totais de Requisições
//--------------------------------------------------------------------------------------
CLASS BTotaisU57

	DATA nVlrU57
	DATA oVlrU57
	DATA nVlrReceb
	DATA oVlrReceb
	DATA nVlrCredi
	DATA oVlrCredi
	DATA nVlrDin
	DATA oVlrDin
	DATA nVlrCHT
	DATA oVlrCHT
	DATA nSaldo
	DATA oSaldo

	METHOD New(oDlg, nTop, nLeft) CONSTRUCTOR
	METHOD Limpa()
	METHOD Refresh()

ENDCLASS
//--------------------------------------------------------------------------------------
// metodo construtor
//--------------------------------------------------------------------------------------
METHOD New(oDlg, nTop, nLeft) CLASS BTotaisU57

	//inicializo as variaveis
	::Limpa()

	@ nTop, nLeft SAY "Vlr.Requisiçao (+)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+70 SAY "Tit. a Receber (+)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+140 SAY "Credito Gerado (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+210 SAY "Saida "+SIMBDIN+" (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+280 SAY "Cheque Troco (-)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ nTop, nLeft+350 SAY "Saldo Requis. (=)" SIZE 50, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ nTop+8, nLeft MSGET ::oVlrU57 VAR ::nVlrU57 When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+70 MSGET ::oVlrReceb VAR ::nVlrReceb When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+140 MSGET ::oVlrCredi VAR ::nVlrCredi When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+210 MSGET ::oVlrDin VAR ::nVlrDin When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+280 MSGET ::oVlrCHT VAR ::nVlrCHT When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL
	@ nTop+8, nLeft+350 MSGET ::oSaldo VAR ::nSaldo When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oDlg HASBUTTON COLORS 0, 16777215 PIXEL

Return
//--------------------------------------------------------------------------------------
// Metodo para destrutor da classe
//--------------------------------------------------------------------------------------
METHOD Limpa() CLASS BTotaisU57
	::nVlrU57 := 0
	::nVlrReceb := 0
	::nVlrCredi := 0
	::nVlrDin := 0
	::nVlrCHT := 0
	::nSaldo := 0
Return
//--------------------------------------------------------------------------------------
// Metodo para dar refresh nos campos
//--------------------------------------------------------------------------------------
METHOD Refresh() CLASS BTotaisU57
	::nSaldo := ::nVlrU57 + ::nVlrReceb - ::nVlrCredi - ::nVlrDin - ::nVlrCHT

	::oVlrU57:Refresh()
	::oVlrReceb:Refresh()
	::oVlrCredi:Refresh()
	::oVlrDin:Refresh()
	::oVlrCHT:Refresh()
	::oSaldo:Refresh()
Return

/*/{Protheus.doc} CONPADX5
Tela de busca das formas de pagamento

@author thebr
@since 02/01/2019
@version 1.0
@return Nil
@type function
/*/
Static cX5RETCP		:= ""
Static Function CONPADX5(_cTabela, _cCond, _cContent, _cDescric)

	Local _cTitulo, oGet1, oGet2, oSay1, oSay2, oButton1, oButton2, oButton3
	Local nX
	Local aHeaderEx := {}
	Local aFields := {"X5_CHAVE", "X5_DESCRI"}
	Local aAlterFields := {}
	Local aDados := {}
	Local aContent

	Default _cCond := ".T."
	Default _cContent := space(TamSX3("X5_CHAVE")[1])
	Default _cDescric := space(TamSX3("X5_DESCRI")[1])

	Private oNewGetX5
	Private nOpcx := 0
	Private cGet1 := space(TamSX3("X5_CHAVE")[1])
	Private cGet2 := space(TamSX3("X5_DESCRI")[1])
	Private oDlgX5

	_cTitulo := "Consultar - " + Capital(alltrim( Posicione("SX5",1,xFilial("SX5") + "00" + _cTabela, "X5_DESCRI") ))

	aContent := FWGetSX5( _cTabela )
	if !empty(aContent)
		for nX := 1 to len(aContent)
			if empty(_cCond) .OR. &(_cCond)
				if aContent[nX][2] == "24" .AND. Alltrim(aContent[nX][3])=="CR" //feito isso poir sigaloja usa a descriçao deste registro como natureza financeira
					aAdd(aDados,{aContent[nX][3], "CREDITO", .F.})
				else
					aAdd(aDados,{aContent[nX][3], aContent[nX][4], .F.})
				endif
			endif
		next nX
	endif

	DEFINE MSDIALOG oDlgX5 TITLE _cTitulo FROM 000, 000  TO 400, 500 COLORS 0, 16777215 PIXEL

    @ 007, 042 SAY oSay1 PROMPT "Descricao" SIZE 025, 007 OF oDlgX5 COLORS 0, 16777215 PIXEL
    @ 007, 006 SAY oSay2 PROMPT "Codigo" SIZE 025, 007 OF oDlgX5 COLORS 0, 16777215 PIXEL
    @ 016, 006 MSGET oGet1 VAR cGet1 SIZE 030, 010 OF oDlgX5 COLORS 0, 16777215 PIXEL
    @ 016, 042 MSGET oGet2 VAR cGet2 SIZE 157, 010 OF oDlgX5 COLORS 0, 16777215 PIXEL
    @ 016, 207 BUTTON oButton1 PROMPT "Buscar" SIZE 037, 012 OF oDlgX5 ACTION (X5Filtrar()) PIXEL

	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX], "X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Next nX

    oNewGetX5 := MsNewGetDados():New(033, 006, 174, 246,, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgX5, aHeaderEx, aDados)
    oNewGetX5:oBrowse:bLDblClick := {|| (nOpcx := 1,oDlgX5:End()) }

    @ 180, 207 BUTTON oButton2 PROMPT "Confirmar" SIZE 037, 012 OF oDlgX5 ACTION (nOpcx := 1,oDlgX5:End()) PIXEL
    oButton2:SetCss(CSS_BTNAZUL)
    @ 180, 165 BUTTON oButton3 PROMPT "Cancelar" SIZE 037, 012 OF oDlgX5 ACTION (nOpcx := 0,oDlgX5:End()) PIXEL

	ACTIVATE MSDIALOG oDlgX5 CENTERED ON INIT oNewGetX5:oBrowse:SetFocus()

	if nOpcx == 1
		cX5RETCP := oNewGetX5:aCols[oNewGetX5:nAt][1]
		_cDescric := oNewGetX5:aCols[oNewGetX5:nAt][2]
	else
		cX5RETCP := _cContent
	endif

Return cX5RETCP
//--------------------------------------------------------------------------------------
// filtro da consulta de formas de pagto
//--------------------------------------------------------------------------------------
Static Function X5Filtrar()

	Local nX := 1

	for nX := 1 to len(oNewGetX5:aCols)
		if (!empty(oNewGetX5:aCols[nX][1]) .AND. UPPER(alltrim(cGet1)) $ UPPER(oNewGetX5:aCols[nX][1])) .OR. ;
			(!empty(oNewGetX5:aCols[nX][2]) .AND. UPPER(alltrim(cGet2)) $ UPPER(oNewGetX5:aCols[nX][2]) )
			EXIT
		endif
	next nX

	if nX > len(oNewGetX5:aCols)
		oNewGetX5:GoTop()
	else
		oNewGetX5:GoTo(nX)
	endif

Return

//--------------------------------------------------------------
// busca as MDE relacionadas com a adm financeira.
// nTipo: 1=Retorna as Redes;2=Retorna as Bandeiras;3=Adm Encontrada
//--------------------------------------------------------------
Static Function GetMDEAdm(nTipo, aAdm, cRede, cBand)

	Local aArea := GetArea()
	Local xRet  := {}
	Local nX
	Local nTamCdAE := TamSX3("AE_COD")[1]
	Local nTamCdMDE := TamSX3("MDE_CODIGO")[1]
	Local cCodMDE
	Default cRede := ""
	Default cBand := ""

	if nTipo <> 3
		aadd(xRet, Space(nTamCdMDE))
	else
		xRet := 1
	endif
	cRede := SubStr(cRede,1,nTamCdMDE)
	cBand := SubStr(cBand,1,nTamCdMDE)

	DbSelectArea("SAE")
	SAE->(DbSetOrder(1))
	For nX := 1 to len(aAdm)
		SAE->(DbSeek(xFilial("SAE")+ SubStr(aAdm[nX],1,nTamCdAE) ))
		if nTipo==1 .AND. !empty(SAE->AE_REDEAUT)
			cCodMDE := Posicione("MDE",1,xFilial("MDE")+SAE->AE_REDEAUT,"MDE_CODIGO")
			if !empty(cCodMDE) .AND. aScan(xRet, {|x| SubStr(x,1,nTamCdMDE)==cCodMDE }) == 0
				aadd(xRet, MDE->MDE_CODIGO + "- " + MDE->MDE_DESC)
			endif
		endif
		if nTipo==2 .AND. !empty(cRede) .AND. SAE->AE_REDEAUT==cRede .AND. !empty(SAE->AE_ADMCART)
			cCodMDE := Posicione("MDE",1,xFilial("MDE")+SAE->AE_ADMCART,"MDE_CODIGO")
			if !empty(cCodMDE) .AND. aScan(xRet, {|x| SubStr(x,1,nTamCdMDE)==cCodMDE }) == 0
				aadd(xRet, MDE->MDE_CODIGO + "- " + MDE->MDE_DESC)
			endif
		endif
		if nTipo==3 .AND. !empty(cRede) .AND. !empty(cBand) .AND. SAE->AE_REDEAUT==cRede .AND. SAE->AE_ADMCART==cBand
			xRet := nX
			EXIT
		endif
	next nX

	RestArea(aArea)

Return xRet

//--------------------------------------------------------------
// busca as administradoras financeiras da forma
//--------------------------------------------------------------
Static Function GetAdmFinan(cType)

	Local aRet  := {}
	Local cQry := ""

	cQry := "SELECT AE_COD, AE_DESC "
	cQry += "FROM "+RetSqlName("SAE")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SAE "
	cQry += "WHERE SAE.D_E_L_E_T_ = ' ' "
	cQry += " AND AE_FILIAL = '" + xFilial("SAE") + "'"
	cQry += " AND AE_TIPO = '"+cType+"' "
	cQry += "ORDER BY AE_COD "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	While QRYT1->(!Eof())
		Aadd(aRet,QRYT1->AE_COD + "- " + QRYT1->AE_DESC)
		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

Return aRet

/***************************************************************************************************
************************************** FUNÇÕES PARA RELATORIO **************************************
***************************************************************************************************/

//--------------------------------------------------------------------------------------
// Valida e Chama impressão do relatório
//--------------------------------------------------------------------------------------
User Function TRA028RL

	//Local cMsgAviso := ""
	Local nTipoRel := 1 //Tipo de Impressão? - 1=Sintético/2=Analítico
	Local cMsgAguarde := "Consulta do fluxo de caixa do operador (Movimento Processos de Venda)..."
	Local nI := 0
	//Local _nOpc := 2
	//Local cPerg := "TRA028RL"
	Private nQuebra := 1 //Imprime uma seção por página? - 1=Sim/2=Não

	//Verifica se o caixa foi conferido
	If !(SLW->LW_CONFERE == '1' .Or. SLW->LW_CONFERE == '2' )
		MsgAlert("Primeiramente realize o fechamento e a conferência do caixa.","Atenção")
		Return
	EndIf

	//cMsgAviso := "Este programa irá imprimir o relatório de conferência de caixa." + CRLF + CRLF
	//cMsgAviso += "Defina a seguir os parâmetros de impressão." + CRLF
	//_nOpc := Aviso("Relatório Conferencia", cMsgAviso, {"Imprimir","Fechar" },2)

	//If _nOpc == 1
		//AjustaSx1(cPerg)
		//If Pergunte(cPerg,.T.) //Chama a tela de parametros
		If UPergunte(.F.)
			nTipoRel := MV_PAR01 //1=Sintetico;2=Analitico
			nQuebra  := MV_PAR02 //Imprime uma seção por página? - 1=Sim/2=Não
		Else
			Return
		EndIf
	//Else
	//	Return
	//EndIf

	//Variaveis de Tipos de fontes que podem ser utilizadas no relatório
	//Private oFont6		:= TFONT():New("ARIAL",06,06,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	//Private oFont6N 	:= TFONT():New("ARIAL",06,06,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",08,08,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",08,08,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	//Private oFont10S	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",10,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	//Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	//Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	//Private oFont14		:= TFONT():New("ARIAL",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
	//Private oFont14NS	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
	//Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	//Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	//Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	//Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	//Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	//Variveis para impressão
	Private cStartPath
	Private nLin 		:= 50
	Private oPrint		:= TMSPRINTER():New("")
	Private oBrush1		:= TBrush():New( , CLR_HGRAY )
	Private nPag		:= 1

	Private aFormasHab	:= FormasHab()

	//adiciona uma posição de controle da impressão da sessão: size=9
	For nI:=1 to Len(aFormasHab)
		aAdd(aFormasHab[nI],.F.) //size=9
	Next nI

	//se relatório analítico, mostra tela para marcar/desmarcar sessão
	If nTipoRel == 2 //1=Sintetico;2=Analitico
		If !UPergFormas()
			Return
		EndIf
	EndIf

	//Define Tamanho do Papel
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//Orientacao do papel (Retrato ou Paisagem)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	Cabecalho()

	oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin,1200, "Resumo Movimentação de Caixa", oFont12N,,,,2)
	nLin+= 55

	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin+5,55, "Movimentação", oFont10N)
	oPrint:Say(nLin+5,2350, "Vlr. Apurado (+/-)", oFont10N,,,,1)
	nLin+= 70

	LjMsgRun(cMsgAguarde,"Relatório Conferencia de Caixa",{|| ImpRelSint() })

	if SLW->(FieldPos("LW_XOBS"))>0
		U_T028IOBS()
	endif

	if nTipoRel == 2
		LjMsgRun(cMsgAguarde,"Relatório Conferencia de Caixa",{|| ImpRelAnalit() })
	endif

	//Finaliza Relatório
	Rod()

	//Visualiza a impressao
	oPrint:Preview()

Return

//----------------------------------------------------------------------
// Atualiza as peguntas na tabela SX1 para o relatorio
//----------------------------------------------------------------------
Static Function AjustaSX1(cPerg)

	Local aHelpPor	:= {}
	Local aHelpEng	:= {}
	Local aHelpSpa	:= {}
	Local oObj := FWSX1Util():New()
	Local aPergunte
	
	//verifico se ja existe a pergunta, senao nem chamo o ajusteSX1.. que ta com pau
	oObj:AddGroup(cPerg)
	oObj:SearchGroup()
	aPergunte := oObj:GetGroup(cPerg)

	if len(aPergunte) >= 2 .and. empty(aPergunte[2])

		if cPerg == "TRA028RL" //relatório de conferencia de caixa

			U_uAjusSx1( cPerg, "01","Tipo de Impressão?","Tipo de Impressão?","Tipo de Impressão?","mv_ch1","N",1,0,0,"C","","","","",;
						"mv_par01","Sintético","","","","Analítico","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

			U_uAjusSx1( cPerg, "02","Imprime uma seção por página?","Imprime uma seção por página?","Imprime uma seção por página?","mv_ch2","N",1,0,0,"C","","","","",;
						"mv_par02","Não","","","","Sim","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

		elseif cPerg == "TRA028RI" //relatório caixa x vendedor

			U_uAjusSx1( cPerg, "01","Tipo de Impressão?","Tipo de Impressão?","Tipo de Impressão?","mv_ch1","N",1,0,0,"C","","","","",;
						"mv_par01","Por Forma","","","","Por Documento","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

			U_uAjusSx1( cPerg, "02","Salta pagina p/ Vendedor?","Salta pagina p/ Vendedor?","Salta pagina p/ Vendedor?","mv_ch2","N",1,0,0,"C","","","","",;
						"mv_par02","Não","","","","Sim","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

		endif
		
	endif

Return

//----------------------------------------------------------------------
//Perguntas do relatório
//----------------------------------------------------------------------
Static Function UPergunte(lVend)

Local aRet := {}
Local aParamBox := {}
Local lRet := .T.
Local cParRel := AllTrim(SM0->M0_CODIGO)+AllTrim(SM0->M0_CODFIL)+"TRETA028"
Local aParam := {2,1,Space(TamSx3("A3_COD")[1]),Replicate("Z",TamSx3("A3_COD")[1])}
Local cModelRelIden := SuperGetMV("TP_RIDENTF",,"O") //Modelo de relatório por identifid (vendedor): O-Old/N-New
Local nA := 0
Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
Local cCodVend := ""
Private cCadastro := "TRETA028"
Default lVend := .F. //Rel.Caixa x Vendedor

aAdd(aParamBox,{2,"Tipo de Impressão",aParam[01],{"1=Sintético","2=Analítico"},80,"",.F.})
aAdd(aParamBox,{2,"Imprime uma seção por página",aParam[02],{"1=Não","2=Sim"},40,"",.F.})

If lVend //Rel.Caixa x Vendedor
	aAdd(aParamBox,{1,"Vendedor De",aParam[03],"","","SA3","",0,.F.})
	aAdd(aParamBox,{1,"Vendedor Até",aParam[04],"","","SA3","",0,.F.})
EndIf

//restauro os parametros usados anteriomente
For nA := 1 To Len(aParamBox)
	aParamBox[nA][3] := &("MV_PAR"+STRZERO(nA,2)) := aParam[nA] := ParamLoad(cParRel,aParamBox,nA,aParamBox[nA][3])	
Next nA

If lVend .and. lSrvPDV .and. lMvPswVend .and. !Empty(cCodVend := U_TPGetVend()) .and. cCodVend <> GetMV("MV_VENDPAD")
	aParamBox[03][3] := &("MV_PAR"+STRZERO(03,2)) := aParam[03] := cCodVend
	aParamBox[04][3] := &("MV_PAR"+STRZERO(04,2)) := aParam[04] := cCodVend
EndIf

If lRet := ParamBox(aParamBox,"Parâmetros Rel. Conf. Caixa",@aRet)
   
    //MsgInfo(aRet[ni],"Opção escolhida")
	MV_PAR01 := Val(cValToChar(aRet[01])) //Tipo de Impressão? - 1=Sintético/2=Analítico
	MV_PAR02 := Val(cValToChar(aRet[02])) //Imprime uma seção por página? - 1=Sim/2=Não

	If lVend .and. !(cModelRelIden == "O") //Rel.Caixa x Vendedor
		MV_PAR03 := aRet[03]
		MV_PAR04 := aRet[04]
	Else
		MV_PAR03 := aParam[03]
		MV_PAR04 := aParam[04]
	EndIf

	//salvo os novos parametros escolhidos
	ParamSave(cParRel,aParamBox,"1") 
   
Endif

Return lRet

//----------------------------------------------------------------------
//Marca quais seções serão impressas
//----------------------------------------------------------------------
Static Function UPergFormas()
Local nI := 0
Local aRet := {}
Local aParamBox := {}
Local lRet := .T.
Local aItem := {}
Local aMvPar := {}
Private cCadastro := "TRETA028"

For nI:=1 to Len(aFormasHab)
	If !Empty(aFormasHab[nI][6])
		aAdd(aParamBox,{5,aFormasHab[nI][1]+" - "+aFormasHab[nI][2],.T.,180,"",.F.})
		aAdd(aItem,nI)
	EndIf
	aFormasHab[nI][len(aFormasHab[nI])] := .F. //size=9
Next nI

For nI := 1 To Len( aItem )
   aAdd( aMvPar, &( "MV_PAR" + StrZero( nI, 2, 0 ) ) )
Next nI

If lRet := ParamBox(aParamBox,"Marque as Sessões Rel. Analítico",@aRet)
    For nI:=1 to Len(aRet)
		aFormasHab[aItem[nI]][len(aFormasHab[aItem[nI]])] := aRet[nI]
	Next nI
Endif

For nI := 1 To Len( aItem )
   &( "MV_PAR" + StrZero( nI, 2, 0 ) ) := aMvPar[ nI ]
Next nI

Return lRet

//--------------------------------------------------------------------------------------
// Monta cabeçalho do relatório
//--------------------------------------------------------------------------------------
User Function TR028CAB(cTitle)
Return Cabecalho(cTitle)
Static Function Cabecalho(cTitle)

	Default cTitle := "Relatório Demonstrativo do Fechamento de Caixa"

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin:=80
	oPrint:SayBitmap(nLin, 60, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 400, 128)///Impressao da Logo
	oPrint:Say(nLin, 2350, "Pagina: " + strzero(nPag,3), oFont8N,,,,1)
	oPrint:Say(nLin+50, 1200, cTitle, oFont16N,,,,2)
	nLin+=30
	oPrint:Say(nLin+30, 2350, DTOC(dDataBase), oFont8N,,,,1)
	nLin+=70
	oPrint:Say(nLin, 2350, TIME(), oFont8N,,,,1)
	nLin:=250

	oPrint:FillRect( {nLin,45, nLin+50, 2400}, oBrush1 )
	oPrint:Box( 50,45,300,2400 )
	oPrint:Line (nLin, 45, nLin, 2400)
	oPrint:Say(nLin+5, 80, "Data Caixa: "+DTOC(SLW->LW_DTABERT), oFont8N)
	oPrint:Say(nLin+5, 550, "Turno: "+SLW->LW_NUMMOV	, oFont8N)
	oPrint:Say(nLin+5, 770, "Operador: "+Posicione("SA6",1,xFilial("SA6")+SLW->LW_OPERADO,"A6_NOME")	, oFont8N)
	oPrint:Say(nLin+5, 1400, "PDV: "+Alltrim(SLW->LW_PDV)+" - "+Alltrim(SM0->M0_FILIAL)+" - "+Posicione("SLG",1,xFilial("SLG")+SLW->LW_ESTACAO,"LG_SERPDV"), oFont8N)

	nLin+=100

Return

//--------------------------------------------------------------------------------------
// Monta rodapé do relatório
//--------------------------------------------------------------------------------------
User Function TR028ROD()
Return Rod()
Static Function Rod()

	nLin := 3350
	oPrint:Line (nLin, 45, nLin, 2400)
	nPag++
	oPrint:EndPage()

Return

//--------------------------------------------------------------------------------------
// Faz impressão das formas, sinteticamente
//--------------------------------------------------------------------------------------
Static Function ImpRelSint()

	Local nValForm := 0
	Local nTotSaida := 0
	Local nTotEntra := 0
	Local nSaldoDin := 0
	Local nX := 0

	//forma com sinal de +
	For nX := 1 to len(aFormasHab)
		if aFormasHab[nX][3] == "+"
			oPrint:Say(nLin,55, Capital(aFormasHab[nX][2]) , oFont10)
			nValForm := DoTotForma(aFormasHab[nX][1], 2)
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
			nLin+= 60

			nTotSaida += nValForm
		endif
	Next nX

	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+= 10
	oPrint:Say(nLin,55, "Total Saídas:", oFont10N)
	oPrint:Say(nLin,2350, Transform(nTotSaida,"@E 999,999,999.99")+" (+)", oFont10N,,,,1)
	nLin+= 100

	//forma com sinal de -
	For nX := 1 to len(aFormasHab)
		if aFormasHab[nX][3] == "-"
			oPrint:Say(nLin,55, Capital(aFormasHab[nX][2]) , oFont10)
			nValForm := DoTotForma(aFormasHab[nX][1], 2)
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
			nLin+= 60

			nTotEntra += nValForm
		endif
	Next nX

	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+= 10
	oPrint:Say(nLin,55, "Total Entradas:", oFont10N)
	oPrint:Say(nLin,2350, Transform(nTotEntra,"@E 999,999,999.99")+" (-)", oFont10N,,,,1)
	nLin+= 100

	oPrint:Box( nLin,45,nLin+55,2400 )
	if nTotEntra - nTotSaida   > 0
		oPrint:Say(nLin,55, "SOBRA DE CAIXA", oFont10N)
	else
		oPrint:Say(nLin,55, "FALTA DE CAIXA", oFont10N)
	endif
	oPrint:Say(nLin,2350, Transform(nTotEntra - nTotSaida,"@E 999,999,999.99")+" (=)", oFont10N,,,,1)
	nLin+= 80

	//--------------------------------------------------------------------------
	//Resumo Dinheiro
	//--------------------------------------------------------------------------
	oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin,1200, "Resumo Movimentação de Dinheiro em Espécie", oFont10N,,,,2)
	nLin+= 55

	oPrint:Box( nLin,45,nLin+55,2400 )
	oPrint:Say(nLin+5,55, "Movimentação", oFont10N)
	oPrint:Say(nLin+5,2350, "Vlr. Apurado (+/-)", oFont10N,,,,1)
	nLin+= 70

	//(+) Suprimentos
	oPrint:Say(nLin,55, "Suprimentos no Caixa", oFont10)
	nValForm := DoTotForma("SU", 2)
	nSaldoDin += nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
	nLin+= 60

	//(+) Vendas Recebidas em Dinheiro
	oPrint:Say(nLin,55, "Vendas Recebidas em Dinheiro", oFont10)
	if lSrvPDV
		aDados := BuscaSL4("PDV", 2, {"L4_VALOR"},,"Alltrim(SL4->L4_FORMA) == '"+SIMBDIN+"'")
	else
		aDados := BuscaSE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = '"+SIMBDIN+"'",,,.T.,.F.)
	endif
	nValForm := 0
	For nX:=1 To Len(aDados)
		nValForm += aDados[nX][1]
	Next
	nSaldoDin += nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
	nLin+= 60

	//(-) Troco em Dinheiro de Vendas
	oPrint:Say(nLin,55, "Troco em Dinheiro (Vendas)", oFont10)
	nValForm := U_T028TTV(4)
	nSaldoDin -= nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
	nLin+= 60

	if lMvPosto

		//(-) Saída Dinheiro Compensação Valores
		if SuperGetMV("TP_ACTCMP",,.F.)
			nValForm := 0
			if lSrvPDV
				cCondicao := GetFilUC0("PDV", .T.)
				bCondicao 	:= "{|| " + cCondicao + " }"
				UC0->(DbClearFilter())
				UC0->(DbSetFilter(&bCondicao,cCondicao))
				UC0->(DbGoTop())
				While UC0->(!Eof())
					nValForm += UC0->UC0_VLDINH
					UC0->(DbSkip())
				enddo
				UC0->(DbClearFilter())
			else
				aDados := BuscaSE1({"E1_VALOR"}, "RTRIM(E1_TIPO) = 'NCC'",,,.F.,.T.)
				For nX:=1 To Len(aDados)
					nValForm += aDados[nX][1]
				Next
			endif

			oPrint:Say(nLin,55, "Saída Dinheiro Compensação Valores", oFont10)
			nSaldoDin -= nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
			nLin+= 60

		endif

		//+ Vale Serviço Pré-Pago Recebidos
		if SuperGetMV("TP_ACTDP",,.F.)
			oPrint:Say(nLin,55, "Vale Serviço Pré-Pago Recebidos", oFont10)
			nValForm := U_T028TVLS(4,,,,.T.)
			nSaldoDin += nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
			nLin+= 60
		endif

		//+ Depositos no PDV
		if SuperGetMV("TP_ACTDP",,.F.)
			oPrint:Say(nLin,55, "Depositos no PDV", oFont10)
			nValForm := DoTotForma("DP", 2)
			nSaldoDin += nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (+)", oFont10,,,,1)
			nLin+= 60
		endif

		if SuperGetMV("TP_ACTSQ",,.F.)
			nValForm := 0
			//- Saques Pré
			nValForm += DoTotForma("SQ", 2)
			//- Vale Motorista (pós)
			nValForm += DoTotForma("VLM", 2)
			//retiro os cheque troco desses valores
			if SuperGetMV("TP_ACTCHT",,.F.)
				nValForm -= U_T028TCHT(4,,,.F.,.F.,.T.)
			endif

			oPrint:Say(nLin,55, "Saída de Saque/Vale Motorista em Dinheiro", oFont10)
			nSaldoDin -= nValForm
			oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
			nLin+= 60
		endif

	endif

	//(-) Sangria
	oPrint:Say(nLin,55, "Sangrias de Caixa", oFont10)
	nValForm := DoTotForma("SG", 2)
	nSaldoDin -= nValForm
	oPrint:Say(nLin,2350, Transform(nValForm ,"@E 999,999,999.99")+" (-)", oFont10,,,,1)
	nLin+= 60

	//(=) Total 
	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+= 10
	oPrint:Say(nLin,55, "TOTAL DINHEIRO:", oFont10N)
	oPrint:Say(nLin,2350, Transform(nSaldoDin,"@E 999,999,999.99")+" (=)", oFont10N,,,,1)
	nLin+= 100


Return

//--------------------------------------------------------------------------------------
// Faz impressão das formas, analiticamente
//--------------------------------------------------------------------------------------
Static Function ImpRelAnalit()

	Local cFuncton := ""
	Local bExFunc := {|cFunc| ExistBlock(cFunc) }
	Local nX

	For nX := 1 to len(aFormasHab)
		cFuncton := aFormasHab[nX][6]
		if !Empty(cFuncton) .and. aFormasHab[nX][9]
			if Eval(bExFunc, cFuncton) //ExistBlock(cFuncton)
				ExecBlock(cFuncton,.F.,.F., {2, aFormasHab[nX][2], aFormasHab[nX][1]})
			endif
		endif
	Next nX

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de venda combustiveis
//--------------------------------------------------------------------------------------
User Function T028RVC

	Local nX, nPosAux
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	//Local cFormPg := ParamIxb[3]
	Local aCampos := {"MID_CODBIC","L2_PRODUTO","B1_DESC","MID_ENCFIN","L2_QUANT","L2_VALDESC","L2_VLRITEM"}
	Local lAbastOk := .T.
	Local aDados := {}
	Local aDadosBico := {}
	Local aDadosProd := {}
	Local bAtuBico := {|x| x[3]:=x[4]-x[5], x[7]:=x[8]/x[5] }
	Local bAtuProd := {|x| x[4]:=((x[3]*100)/nTotQtd), x[5]:=x[6]/x[3] }
	Local nTotQtd := 0
	Local nTotVal := 0
	Local nTotDesc := 0
	Local nTotalPro := 0

	nTotalPro := U_T028TVC(nOpcX, @aDados, aCampos, @lAbastOk)

	if nTotalPro > 0
		//montando aglutinado
		For nX := 1 to len(aDados)
			//bicos
			if (nPosAux := aScan(aDadosBico, {|x| x[1] == aDados[nX][1] })) > 0
				aDadosBico[nPosAux][5] += aDados[nX][5] //quantidade
				aDadosBico[nPosAux][6] += aDados[nX][6] //desconto
				aDadosBico[nPosAux][8] += aDados[nX][7] //valor total
				//deixar com o maior encerrante
				If aDadosBico[nPosAux][4] < aDados[nX][4]
					aDadosBico[nPosAux][4] := aDados[nX][4]
				EndIf
			else
				aadd(aDadosBico, {aDados[nX][1],aDados[nX][3], 0,aDados[nX][4], aDados[nX][5], aDados[nX][6], 0,aDados[nX][7]} )
			endif

			//produto
			if (nPosAux := aScan(aDadosProd, {|x| x[1] == Alltrim(aDados[nX][2]) })) > 0
				aDadosProd[nPosAux][3] += aDados[nX][5] //quantidade
				aDadosProd[nPosAux][6] += aDados[nX][7] //valor total
			else
				aadd(aDadosProd, {Alltrim(aDados[nX][2]),aDados[nX][3],aDados[nX][5],0, 0, aDados[nX][7]} )
			endif

			nTotQtd += aDados[nX][5]
			nTotDesc += aDados[nX][6]
			nTotVal += aDados[nX][7]
		next nX

		aSort(aDadosBico,,,{|x,y| x[1] < y[1] }) //ordena aglutinado por bico
		aEval(aDadosBico, bAtuBico) //gravo posições 3(encerrante ini.) e 7(val litro)

		aSort(aDadosProd,,,{|x,y| x[1] < y[1] }) //ordena aglutinado por produto
		aEval(aDadosProd, bAtuProd) //gravo posições 4(percentual) e 5(val litro)

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100

		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Bico", oFont10N)
		oPrint:Say(nLin+5,150, "Produto", oFont10N)
		oPrint:Say(nLin+5,1140, "Encerr.Inicial", oFont10N,,,,1)
		oPrint:Say(nLin+5,1450, "Encerr.Final", oFont10N,,,,1)
		oPrint:Say(nLin+5,1680, "Qtd.Litros", oFont10N,,,,1)
		oPrint:Say(nLin+5,1950, "Desconto", oFont10N,,,,1)
		oPrint:Say(nLin+5,2150, "Val. Litro", oFont10N,,,,1)
		oPrint:Say(nLin+5,2380, "Val. Total", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDadosBico)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDadosBico[nX][1], oFont10)
			oPrint:Say(nLin,130, aDadosBico[nX][2], oFont10)
			oPrint:Say(nLin,1140, Transform(aDadosBico[nX][3],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,1450, Transform(aDadosBico[nX][4],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,1680, Transform(aDadosBico[nX][5],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,1950, Transform(aDadosBico[nX][6],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,2150, Transform(aDadosBico[nX][7],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,2380, Transform(aDadosBico[nX][8],"@E 999,999,999.999"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1100, "Total:", oFont10N)
		oPrint:Say(nLin,1680, Transform(nTotQtd,"@E 999,999,999.999"), oFont10N,,,,1)
		oPrint:Say(nLin,1950, Transform(nTotDesc,"@E 999,999,999.999"), oFont10N,,,,1)
		oPrint:Say(nLin,2380, Transform(nTotVal,"@E 999,999,999.999"), oFont10N,,,,1)
		nLin+=100

		if nLin+150 > 3300
			Rod()
			Cabecalho()
		EndIf

		oPrint:Say(nLin,55, "Resumo Combustíveis", oFont12N)
		nLin+=50
		oPrint:Line (nLin, 45, nLin, 2400)
		nLin+=10
		oPrint:Say(nLin+5,55, "Produto", oFont10N)
		oPrint:Say(nLin+5,1200, "Litros", oFont10N,,,,1)
		oPrint:Say(nLin+5,1500, "Percent.", oFont10N,,,,1)
		oPrint:Say(nLin+5,1900, "Val. Litro", oFont10N,,,,1)
		oPrint:Say(nLin+5,2380, "Val. Total", oFont10N,,,,1)
		nLin+=50

		For nX := 1 to len(aDadosProd)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDadosProd[nX][1]+" - "+aDadosProd[nX][2], oFont10)
			oPrint:Say(nLin,1200, Transform(aDadosProd[nX][3],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,1500, Transform(aDadosProd[nX][4],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,1900, Transform(aDadosProd[nX][5],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,2380, Transform(aDadosProd[nX][6],"@E 999,999,999.999"), oFont10,,,,1)

			nLin+=50
		Next nX

		oPrint:Say(nLin,700, "Total:", oFont10N)
		oPrint:Say(nLin,1200, Transform(nTotQtd,"@E 999,999,999.999"), oFont10N,,,,1)
		oPrint:Say(nLin,1500, Transform(100,"@E 999.99"), oFont10N,,,,1)
		oPrint:Say(nLin,2380, Transform(nTotVal,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de venda produtos
//--------------------------------------------------------------------------------------
User Function T028RVP

	Local nX, nPosAux
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos := {"L2_PRODUTO","B1_DESC","L2_LOCAL","L2_QUANT","L2_UM","L2_VALDESC","L2_VLRITEM","B1_GRUPO"}
	Local aDados := {}
	Local aDadosProd := {}
	Local aDadosGrup := {}
	Local bAtuProd := {|x| x[6]:=x[8]/x[4] }
	Local nTotQtd := 0
	Local nTotVal := 0
	Local nTotDesc := 0
	Local nTotalPro := 0

	if Alltrim(cFormPg) == "VP"
		nTotalPro := U_T028TVP(nOpcX, @aDados, aCampos)
	endif

	if nTotalPro > 0
		//montando aglutinado
		For nX := 1 to len(aDados)

			if (nPosAux := aScan(aDadosProd, {|x| x[1] == Alltrim(aDados[nX][1]) })) > 0
				aDadosProd[nPosAux][4] += aDados[nX][4] //quantidade
				aDadosProd[nPosAux][7] += aDados[nX][6] //desconto
				aDadosProd[nPosAux][8] += aDados[nX][7] //valor total
			else
				aadd(aDadosProd, {Alltrim(aDados[nX][1]),aDados[nX][2],aDados[nX][3],aDados[nX][4], aDados[nX][5], 0, aDados[nX][6], aDados[nX][7]} )
			endif

			if (nPosAux := aScan(aDadosGrup, {|x| x[1] == Alltrim(aDados[nX][8]) })) > 0
				aDadosGrup[nPosAux][3] += aDados[nX][7] //valor total
			else
				aadd(aDadosGrup, {Alltrim(aDados[nX][8]), Posicione("SBM",1,xFilial("SBM")+aDados[nX][8],"BM_DESC"), aDados[nX][7]} )
			endif

			nTotQtd += aDados[nX][4]
			nTotDesc += aDados[nX][6]
			nTotVal += aDados[nX][7]
		next nX

		aSort(aDadosProd,,,{|x,y| x[1] < y[1] }) //ordena aglutinado por produto
		aEval(aDadosProd, bAtuProd) //gravo posições 6(Val Unit)

		aSort(aDadosGrup,,,{|x,y| x[1] < y[1] }) //ordena aglutinado por bico

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Produto", oFont10N)
		oPrint:Say(nLin+5,1180, "Armazém", oFont10N,,,,1)
		oPrint:Say(nLin+5,1450, "Quantidade", oFont10N,,,,1)
		oPrint:Say(nLin+5,1500, "UM", oFont10N)
		oPrint:Say(nLin+5,1800, "Val. Unitario", oFont10N,,,,1)
		oPrint:Say(nLin+5,2100, "Val. Desconto", oFont10N,,,,1)
		oPrint:Say(nLin+5,2380, "Val. Líquido", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDadosProd)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDadosProd[nX][1]+" - "+aDadosProd[nX][2], oFont10)
			oPrint:Say(nLin,1180, aDadosProd[nX][3], oFont10,,,,1)
			oPrint:Say(nLin,1450, Transform(aDadosProd[nX][4],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,1500, aDadosProd[nX][5], oFont10)
			oPrint:Say(nLin,1800, Transform(aDadosProd[nX][6],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,2100, Transform(aDadosProd[nX][7],"@E 999,999,999.999"), oFont10,,,,1)
			oPrint:Say(nLin,2380, Transform(aDadosProd[nX][8],"@E 999,999,999.999"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1100, "Total:", oFont10N)
		oPrint:Say(nLin,1450, Transform(nTotQtd,"@E 999,999,999.999"), oFont10N,,,,1)
		oPrint:Say(nLin,2100, Transform(nTotDesc,"@E 999,999,999.999"), oFont10N,,,,1)
		oPrint:Say(nLin,2380, Transform(nTotVal,"@E 999,999,999.999"), oFont10N,,,,1)
		nLin+=100

		if nLin+150 > 3300
			Rod()
			Cabecalho()
		EndIf

		oPrint:Say(nLin,55, "Resumo Produtos", oFont12N)
		nLin+=50
		oPrint:Line (nLin, 45, nLin, 2400)
		nLin+=10
		oPrint:Say(nLin+5,55, "Grupo", oFont10N)
		oPrint:Say(nLin+5,2380, "Val. Total", oFont10N,,,,1)
		nLin+=50

		For nX := 1 to len(aDadosGrup)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDadosGrup[nX][1]+" - "+aDadosGrup[nX][2], oFont10)
			oPrint:Say(nLin,2380, Transform(aDadosGrup[nX][3],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		oPrint:Say(nLin,1100, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotVal,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de cheques troco
//--------------------------------------------------------------------------------------
User Function T028RCHT

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos := {"UF2_BANCO","UF2_AGENCI","UF2_CONTA","UF2_NUM","UF2_VALOR","UF2_DOC","UF2_SERIE","UF2_CODBAR"}
	Local aDados := {}
	Local nTotalCHT := 0

	nTotalCHT := U_T028TCHT(nOpcX, @aDados, aCampos)

	if nTotalCHT > 0
		
		//ordenando por banco+agencia+conta+numcheque
		ASORT(aDados,,, { |x, y| x[1]+x[2]+x[3]+x[4] < y[1]+y[2]+y[3]+y[4] } )  

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Banco", oFont10N)
		oPrint:Say(nLin+5,850, "Agencia", oFont10N)
		oPrint:Say(nLin+5,1100, "Conta", oFont10N)
		oPrint:Say(nLin+5,1350, "Num.Cheque", oFont10N)
		oPrint:Say(nLin+5,1800, "Documento", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+" - "+SubStr(Posicione("SA6",1,xFilial("SA6")+aDados[nX][1]+aDados[nX][2]+aDados[nX][3],"A6_NOME"),1,25), oFont10)
			oPrint:Say(nLin,850, aDados[nX][2], oFont10)
			oPrint:Say(nLin,1100, aDados[nX][3], oFont10)
			oPrint:Say(nLin,1350, aDados[nX][4], oFont10)
			oPrint:Say(nLin,1800, iif(empty(aDados[nX][8]),aDados[nX][6]+"/"+aDados[nX][7],aDados[nX][8]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][5],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalCHT,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de Vale haver
//--------------------------------------------------------------------------------------
User Function T028RVLH

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos
	Local aDados := {}
	Local nTotalVLH := 0

	if lSrvPDV
		aCampos := {"L1_CLIENTE","L1_LOJA","A1_NOME","L1_DOC","L1_SERIE","L1_EMISNF","L1_XTROCVL"}
	else
		aCampos := {"E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_NUM","E1_PREFIXO","E1_EMISSAO","E1_VALOR"}
	endif

	nTotalVLH := U_T028TVLH(nOpcX, @aDados, aCampos)

	if nTotalVLH > 0

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Cliente", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Emissão", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+"/"+aDados[nX][2]+" "+Alltrim(aDados[nX][3]), oFont10)
			oPrint:Say(nLin,1600, aDados[nX][4]+"/"+aDados[nX][5], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][6]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][7],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalVLH,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica genérica de formas  (BOL,NP,FID,RP)
//--------------------------------------------------------------------------------------
User Function T028RGEN

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos := {}
	Local aCamposCmp := {}
	Local aDados := {}
	Local nTotalFor := 0
	Local nPosFunc := aScan(aFormasHab, {|x| x[1] == cFormPg })
	Private __CFORMAATU := cFormPg

	if lSrvPDV
		aCampos := {"A1_COD","A1_LOJA","A1_NOME","L1_DOC","L1_SERIE","L4_DATA","L4_VALOR","L4_VALOR"}
		if Alltrim(cFormPg) $ "CC,CD"
			aCamposCmp := {"A1_COD","A1_LOJA","A1_NOME","UC1_NUM"," ","UC1_VENCTO","UC1_VALOR","UC1_VALOR"}
		endif
	else
		aCampos := {"E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_NUM","E1_PREFIXO","E1_VENCREA","E1_VALOR","E1_VLRREAL"}
	endif

	if nPosFunc > 0
		if lSrvPDV
			if Alltrim(cFormPg) == "CC"
				nTotalFor := U_T028TCC(nOpcX, @aDados, aCampos,.T.,.F.) + U_T028TCC(nOpcX, @aDados, aCamposCmp,.F.,.T.)
			elseif Alltrim(cFormPg) == "CD"
				nTotalFor := U_T028TCD(nOpcX, @aDados, aCampos,.T.,.F.) + U_T028TCD(nOpcX, @aDados, aCamposCmp,.F.,.T.)
			else
				nTotalFor := &("U_"+aFormasHab[nPosFunc][4]+"(nOpcX, @aDados, aCampos)")
			endif
		else
			nTotalFor := &("U_"+aFormasHab[nPosFunc][4]+"(nOpcX, @aDados, aCampos)")
		endif
	endif

	if nTotalFor > 0

		//iniciando impressões
		if nLin+230 > 3300  .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Cliente", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Vencimento", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+"/"+aDados[nX][2]+" "+Alltrim(aDados[nX][3]), oFont10)
			oPrint:Say(nLin,1600, aDados[nX][4]+"/"+aDados[nX][5], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][6]), oFont10)
			oPrint:Say(nLin,2380, Transform(iif(empty(aDados[nX][8]),aDados[nX][7],aDados[nX][8]),"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalFor,"@E 999,999,999.99"), oFont10N,,,,1)

		//imprime o aglutinado de cartão por cliente
		if SuperGetMV("TP_IMPAGLC",,.T.) .and. Alltrim(cFormPg) $ "CC,CD"
			ImpCartAglut(aDados)
		endif
	endif

Return

//imprime os cartoes aglutinado por bandeira
Static Function ImpCartAglut(_aDados)

	Local aDadosAglut := {}
	Local nX, nPosAux

	//montando aglutinado
	For nX := 1 to len(_aDados)
		if (nPosAux := aScan(aDadosAglut, {|x| x[1] == _aDados[nX][1] .AND. x[2] == _aDados[nX][2] })) > 0
			aDadosAglut[nPosAux][8] += _aDados[nX][8] //valor real
		else
			aadd(aDadosAglut, aClone(_aDados[nX]) )
		endif
	next nX

	//iniciando impressões
	if nLin+230 > 3300  .Or. nQuebra == 2
		Rod()
		Cabecalho()
	EndIf

	nLin+=100
	oPrint:Say(nLin,55, "TOTAIS POR ADM FINANCEIRA", oFont12N)
	nLin+=50
	oPrint:Line (nLin, 45, nLin, 2400)
	nLin+=10
	oPrint:Say(nLin+5,55, "Cliente", oFont10N)
	oPrint:Say(nLin+5,1900, "Valor", oFont10N,,,,1)
	nLin+=50

	For nX := 1 to len(aDadosAglut)
		if nLin>3300
			Rod()
			Cabecalho()
		EndIf

		oPrint:Say(nLin,55, aDadosAglut[nX][1]+"/"+aDadosAglut[nX][2]+" "+Alltrim(aDadosAglut[nX][3]), oFont10)
		oPrint:Say(nLin,1900, Transform(aDadosAglut[nX][8],"@E 999,999,999.99"), oFont10,,,,1)

		nLin+=50
	Next nX

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de Dinheiro Recebido vendas e recebimento
//--------------------------------------------------------------------------------------
User Function T028RDIN

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCamposE1 := {}
	Local aDados := {}
	Local nTotalDin := 0

	if lSrvPDV
		aCampos := {"A1_COD","A1_LOJA","L1_DOC","L1_SERIE","L4_DATA","L4_VALOR"}
		aDados := BuscaSL4("PDV", 2, aCampos,, "Alltrim(SL4->L4_FORMA) == '"+SIMBDIN+"'")
	else
		aCamposE1 := {"E1_CLIENTE","E1_LOJA","E1_NUM","E1_PREFIXO","E1_EMISSAO","E1_VALOR"}
		aDados := BuscaSE1(aCamposE1, "RTRIM(E1_TIPO) = '"+SIMBDIN+"'")
	endif

	//+ Apurando vendas dinheiro
	For nX:=1 To Len(aDados)
		nTotalDin += aDados[nX][6]
	Next

	if nTotalDin > 0

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Cliente", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Emissão", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+"/"+aDados[nX][2]+" "+Alltrim(Posicione("SA1",1,xFilial("SA1")+aDados[nX][1]+aDados[nX][2],"A1_NOME")), oFont10)
			oPrint:Say(nLin,1600, aDados[nX][3]+"/"+aDados[nX][4], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][5]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][6],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalDin,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de Saques
//--------------------------------------------------------------------------------------
User Function T028RSQ

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos := {"U57_PREFIX","U57_CODIGO","U57_PARCEL","U56_CODCLI","U56_LOJA","U56_NOME","U57_VALSAQ","U57_CHTROC","U57_PLACA","U56_REQUIS","U57_TUSO","U57_VALOR"}
	Local aDados := {}
	Local nTotalSQ := 0

	if Alltrim(cFormPg) == "DP" //deposito
		nTotalSQ := U_T028TDP(nOpcX, @aDados, aCampos)
	elseif Alltrim(cFormPg) == "SQ" //saque pré
		nTotalSQ := U_T028TSQ(nOpcX, @aDados, aCampos)
	else //saque pós
		nTotalSQ := U_T028TVLM(nOpcX, @aDados, aCampos)
	endif

	if nTotalSQ > 0

		//iniciando impressões
		if nLin+230 > 3300  .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Cod.Barra Requis.", oFont10N)
		oPrint:Say(nLin+5,500, "Placa", oFont10N)
		oPrint:Say(nLin+5,800, "Cliente", oFont10N)
		if Alltrim(cFormPg) == "DP" //deposito
			oPrint:Say(nLin+5,1800, "Tipo Uso", oFont10N)
		else
			oPrint:Say(nLin+5,2000, "Chq.Troco", oFont10N,,,,1)
		endif
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+aDados[nX][2]+aDados[nX][3], oFont10)
			oPrint:Say(nLin,500, aDados[nX][9], oFont10)
			oPrint:Say(nLin,800, aDados[nX][4]+"/"+aDados[nX][5]+" "+Alltrim(aDados[nX][6]), oFont10)
			if Alltrim(cFormPg) == "DP" //deposito
				oPrint:Say(nLin,1800, iif(aDados[nX][10]=="S","Saque","Consumo") , oFont10)
				oPrint:Say(nLin,2380, Transform(aDados[nX][11],"@E 999,999,999.99"), oFont10,,,,1)
			else
				oPrint:Say(nLin,2000, Transform(aDados[nX][8],"@E 999,999,999.99"), oFont10,,,,1)
				oPrint:Say(nLin,2380, Transform(aDados[nX][7],"@E 999,999,999.99"), oFont10,,,,1)
			endif

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalSQ,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de SANGRIA E SUPRIMENTO
//--------------------------------------------------------------------------------------
User Function T028RSS

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCamposE5 := {"E5_HISTOR","E5_PREFIXO","E5_NUMERO","E5_DATA","E5_VALOR"}
	Local aDados := {}
	Local nTotalDin := 0

	//+ Apurando vendas dinheiro
	if cFormPg == "SU"
		nTotalDin := U_T028TSU(nOpcX, @aDados, aCamposE5)
	elseif cFormPg == "SG"
		nTotalDin := U_T028TSG(nOpcX, @aDados, aCamposE5)
	endif

	if nTotalDin > 0

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Histórico", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Emissão", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1], oFont10)
			oPrint:Say(nLin,1600, aDados[nX][2]+"/"+aDados[nX][3], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][4]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][5],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalDin,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de TROCOS DE VENDAS
//--------------------------------------------------------------------------------------
User Function T028RTV

	Local nX
	Local nOpcX := 4 //ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	//Local cFormPg := ParamIxb[3]
	Local aCamposE5 := {"E5_HISTOR","E5_PREFIXO","E5_NUMERO","E5_DATA","E5_VALOR"}
	Local aDados := {}
	Local nTotalDin := 0

	//+ Apurando troco em dinheiro
	nTotalDin := U_T028TTV(nOpcX,@aDados,aCamposE5) //nOpcX, aDados, aCampos, cFiltro, lChvCx, lSoData

	if nTotalDin > 0

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Histórico", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Emissão", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1], oFont10)
			oPrint:Say(nLin,1600, aDados[nX][2]+"/"+aDados[nX][3], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][4]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][5],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalDin,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão das observações da conferência de caixa
//--------------------------------------------------------------------------------------
User Function T028IOBS
	
	Local lImpObs := SuperGetMV("TP_IMPOBSC",,.T.) //Imprime o observações da conferência de caixa (default .T.)
	Local nX := 1
	Local cObsCx := StrTran(AllTrim(SLW->LW_XOBS),CRLF,' ') //remove os pula linha (CRLF)

	if !lImpObs
		Return
	endif
	
	if !empty(cObsCx)
		aTemp := QuebraTexto(cObsCx,130)
		if Len(aTemp)>0

			//iniciando impressões
			if nLin+230 > 3300 .Or. nQuebra == 2
				Rod()
				Cabecalho()
			EndIf

			nLin+=100
			oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
			oPrint:Box( nLin,45,nLin+55,2400 )
			oPrint:Say(nLin,1200, "Observações da Conferência de Caixa", oFont10N,,,,2)
			nLin+= 55

			//fazer laço para quebra de linha
			for nX := 1 to len(aTemp)
				if nLin>3300
					Rod()
					Cabecalho()
				EndIf
				oPrint:Say(nLin,55,aTemp[nX],oFont10)
				nLin+=50
			next nX

		endif
	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de notas fiscais
//--------------------------------------------------------------------------------------
User Function T028RSL1

	Local nX
	//Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	//Local cFormPg := ParamIxb[3]
	Local aCampos := {"L1_CLIENTE","L1_LOJA","L1_DOC","L1_SERIE","L1_EMISNF","L1_VLRTOT","L1_SITUA","L1_STORC"}
	Local aDadosRet := {}
	Local aDados := {}
	Local nTotalVen := 0
	Local aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, SLW->LW_DTFECHA, SLW->LW_HRFECHA}
	Local lTemVenda := .F.

	aDadosRet := U_T028DOCS(aSLW,lSrvPDV,aCampos,{},{})
	aDados := aDadosRet[1]

	lTemVenda := aScan(aDados, {|x| x[7]<>"X2" }) > 0

	if lTemVenda

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Cliente", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Emissão", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			//se está cancelada, nao levo pro relatorio
			if aDados[nX][7] == "X2" .OR. aDados[nX][7] == "07" .OR. aDados[nX][8] == "C" .OR. aDados[nX][8] == "A"
				LOOP
			endif

			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+"/"+aDados[nX][2]+" "+Alltrim(Posicione("SA1",1,xFilial("SA1")+aDados[nX][1]+aDados[nX][2],"A1_NOME")), oFont10)
			oPrint:Say(nLin,1600, aDados[nX][3]+"/"+aDados[nX][4], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][5]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][6],"@E 999,999,999.99"), oFont10,,,,1)

			nTotalVen += aDados[nX][6]

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalVen,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de cheques recebidos
//--------------------------------------------------------------------------------------
User Function T028RCHR

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos
	Local aCamposCmp
	Local aDados := {}
	Local nTotalCH := 0

	if lSrvPDV
		aCampos := {"L4_CGC","L4_NOMECLI","L4_ADMINIS","L4_AGENCIA","L4_CONTA","L4_NUMCART","L4_DATA","L4_VALOR","L1_DOC","L1_SERIE"}
		aCamposCmp := {"UC1_CGC","A1_NOME","UC1_BANCO","UC1_AGENCI","UC1_CONTA","UC1_NUMCH","UC1_VENCTO","UC1_VALOR","UC1_NUM"," "}
	else
		aCampos := {"A1_CGC","A1_NOME","E1_BCOCHQ","E1_AGECHQ","E1_CTACHQ","E1_NUMCART","E1_VENCREA","E1_VALOR","E1_NUM","E1_PREFIXO","E1_CLIENTE","E1_LOJA","A1_COD","A1_LOJA"}
	endif

	if Alltrim(cFormPg) == "CH"
		nTotalCH := U_T028TCH(nOpcX, @aDados, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCH(nOpcX, @aDados, aCamposCmp,.F.,.T.),0)
	elseif Alltrim(cFormPg) == "CHP"
		nTotalCH := U_T028TCHP(nOpcX, @aDados, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCHP(nOpcX, @aDados, aCamposCmp,.F.,.T.),0)
	endif

	if nTotalCH > 0

		//iniciando impressões
		if nLin+230 > 3300  .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Emitente", oFont10N)
		oPrint:Say(nLin+5,1000, "Documento", oFont10N)
		oPrint:Say(nLin+5,1460, "Bco", oFont10N)
		oPrint:Say(nLin+5,1540, "Agen.", oFont10N)
		oPrint:Say(nLin+5,1660, "Cont.", oFont10N)
		oPrint:Say(nLin+5,1860, "Cheque", oFont10N)
		oPrint:Say(nLin+5,2000, "Vencto", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDados[nX][1]+" - "+Alltrim(SubStr(aDados[nX][2],1,25)), oFont10)
			oPrint:Say(nLin,1000, aDados[nX][9]+"/"+aDados[nX][10], oFont10)
			oPrint:Say(nLin,1460, aDados[nX][3], oFont10)
			oPrint:Say(nLin,1540, aDados[nX][4], oFont10)
			oPrint:Say(nLin,1660, aDados[nX][5], oFont10)
			oPrint:Say(nLin,1860, aDados[nX][6], oFont10)
			oPrint:Say(nLin,2000, DTOC(aDados[nX][7]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][8],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50

			//se o emitente é diferente do cliente do documento, mostro
			if !lSrvPDV	.AND. aDados[nX][11]+aDados[nX][12] <> aDados[nX][13]+aDados[nX][14]
				Posicione("SA1",1,xFilial("SA1")+aDados[nX][11]+aDados[nX][12] ,"A1_CGC")
				oPrint:Say(nLin,155,"Cliente Venda/Cmp.: " + SA1->A1_CGC + " - " + Alltrim(SA1->A1_NOME) + " ("+aDados[nX][11]+"/"+aDados[nX][12]+")", oFont8)
				nLin+=40
			endif
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalCH,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de carta frete
//--------------------------------------------------------------------------------------
User Function T028RCF

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos
	Local aCamposCmp
	Local aDados := {}
	Local nTotalCF := 0

	if lSrvPDV
		aCampos := {"L4_CGC","A1_NOME","L1_DOC","L1_SERIE","L4_DATA","L4_VALOR","L4_NUMCART"}
		aCamposCmp := {"UC1_CGC","A1_NOME","UC1_NUM"," ","UC1_VENCTO","UC1_VALOR","UC1_CFRETE"}
	else
		aCampos := {"A1_CGC","A1_NOME","E1_NUM","E1_PREFIXO","E1_VENCREA","E1_VLRREAL","E1_NUMCART"}
	endif

	nTotalCF := U_T028TCF(nOpcX, @aDados, aCampos,.T.,.F.) + iif(lSrvPDV,U_T028TCF(nOpcX, @aDados, aCamposCmp,.F.,.T.),0)

	if nTotalCF > 0

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Emitente", oFont10N)
		oPrint:Say(nLin+5,1250, "N.Carta Frete", oFont10N)
		oPrint:Say(nLin+5,1600, "Documento", oFont10N)
		oPrint:Say(nLin+5,1950, "Vencimento", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, Alltrim(aDados[nX][1])+" - "+Alltrim(aDados[nX][2]), oFont10)
			oPrint:Say(nLin,1250, aDados[nX][7], oFont10)
			oPrint:Say(nLin,1600, aDados[nX][3]+"/"+aDados[nX][4], oFont10)
			oPrint:Say(nLin,1950, DTOC(aDados[nX][5]), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][6],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalCF,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de Compensaçao de valores
//--------------------------------------------------------------------------------------
User Function T028RCMP

	Local nX, nY
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aDadosRet := {}
	Local aDadosCmp := {}
	Local nTotDin := nTotVlh := nTotCht := nTotCMP := 0
	Local aSLW := {SLW->LW_OPERADO, SLW->LW_NUMMOV, SLW->LW_PDV, SLW->LW_ESTACAO, SLW->LW_DTABERT, SLW->LW_HRABERT, SLW->LW_DTFECHA, SLW->LW_HRFECHA}
	Local aCpoUC0	:= {"UC0_NUM","UC0_CLIENT","UC0_LOJA","UC0_VLDINH","UC0_VLVALE","UC0_VLCHTR","UC0_VLTOT","UC0_ESTORN"}
	Local aCpoUC1	:= {"UC1_FORMA","UC1_VENCTO","UC1_VALOR","UC1_CGC","UC1_CFRETE","UC1_ADMFIN","UC1_NSUDOC","UC1_CODAUT","UC1_BANCO","UC1_AGENCI","UC1_CONTA","UC1_NUMCH"}
	Local nPosUC1 := len(aCpoUC0)+1
	Local cCodCliAdm
	Local lTemCMP := .F.

	aDadosRet := U_T028DOCS(aSLW,lSrvPDV,,,,,,,aCpoUC0,aCpoUC1)
	aDadosCmp := aDadosRet[3]

	lTemCMP := aScan(aDadosCmp, {|x| x[8]=="N" }) > 0

	if lTemCMP

		//iniciando impressões
		if nLin+230 > 3300 .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Num Cmp.", oFont10N)
		oPrint:Say(nLin+5,280, "Cliente", oFont10N)
		oPrint:Say(nLin+5,1640, "Dinheiro", oFont10N,,,,1)
		oPrint:Say(nLin+5,1890, "Vale Haver", oFont10N,,,,1)
		oPrint:Say(nLin+5,2140, "Chq. Troco", oFont10N,,,,1)
		oPrint:Say(nLin+5,2390, "Valor Total", oFont10N,,,,1)
		nLin += 55
		oPrint:Box( nLin, 145, nLin+55, 2400 )
		oPrint:Say(nLin+5,155, "Forma", oFont10)
		oPrint:Say(nLin+5,280, "Emitente", oFont10)
		oPrint:Say(nLin+5,1100, "Documento", oFont10)
		oPrint:Say(nLin+5,1950, "Vencimento", oFont10)
		oPrint:Say(nLin+5,2380, "Valor", oFont10,,,,1)
		nLin+=80

		For nX := 1 to len(aDadosCmp)

			if aDadosCmp[nX][8] <> "N" //se está estornado, nao levo pro relatorio
				LOOP
			endif

			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, aDadosCmp[nX][1], oFont10N)
			oPrint:Say(nLin,280, aDadosCmp[nX][2]+"/"+aDadosCmp[nX][3]+" "+Alltrim(Posicione("SA1",1,xFilial("SA1")+aDadosCmp[nX][2]+aDadosCmp[nX][3],"A1_NOME")), oFont10N)
			oPrint:Say(nLin,1640, Transform(aDadosCmp[nX][4],"@E 999,999,999.99"), oFont10N,,,,1)
			oPrint:Say(nLin,1890, Transform(aDadosCmp[nX][5],"@E 999,999,999.99"), oFont10N,,,,1)
			oPrint:Say(nLin,2140, Transform(aDadosCmp[nX][6],"@E 999,999,999.99"), oFont10N,,,,1)
			oPrint:Say(nLin,2390, Transform(aDadosCmp[nX][7],"@E 999,999,999.99"), oFont10N,,,,1)

			nTotDin += aDadosCmp[nX][4]
			nTotVlh += aDadosCmp[nX][5]
			nTotCht += aDadosCmp[nX][6]
			nTotCMP += aDadosCmp[nX][7]

			nLin+=50

			//imprime parcelas
			For nY := 1 to len(aDadosCmp[nX][nPosUC1])
				if nLin>3300
					Rod()
					Cabecalho()
				EndIf

				oPrint:Say(nLin,155, aDadosCmp[nX][nPosUC1][nY][1], oFont10) //forma

				if Alltrim(aDadosCmp[nX][nPosUC1][nY][1]) == "CH"

					oPrint:Say(nLin,280, SubStr(Posicione("SA1",3,xFilial("SA1")+aDadosCmp[nX][nPosUC1][nY][4],"A1_NOME"),1,25), oFont10) //emitente
					oPrint:Say(nLin,1100, "Bco: "+ alltrim(aDadosCmp[nX][nPosUC1][nY][9]) + " Ag: " + Alltrim(aDadosCmp[nX][nPosUC1][nY][10]) + " Cta: " + Alltrim(aDadosCmp[nX][nPosUC1][nY][11]) + " Num: " + Alltrim(aDadosCmp[nX][nPosUC1][nY][12]), oFont10)

				elseif Alltrim(aDadosCmp[nX][nPosUC1][nY][1]) == "CF"

					oPrint:Say(nLin,280, SubStr(Posicione("SA1",3,xFilial("SA1")+aDadosCmp[nX][nPosUC1][nY][4],"A1_NOME"),1,25), oFont10) //emitente
					oPrint:Say(nLin,1100, "Num.: "+aDadosCmp[nX][nPosUC1][nY][5] , oFont10)

				else //cartões
					cCodCliAdm := PadR(aDadosCmp[nX][nPosUC1][nY][6],TamSX3("A1_COD")[1])+"01"
					oPrint:Say(nLin,280, Posicione("SA1",1,xFilial("SA1")+cCodCliAdm,"A1_NREDUZ"), oFont10)
					oPrint:Say(nLin,1100, "NSU: " + Alltrim(aDadosCmp[nX][nPosUC1][nY][7]) + " Aut.: " + Alltrim(aDadosCmp[nX][nPosUC1][nY][8]), oFont10)

				endif
				oPrint:Say(nLin,1950, DTOC(aDadosCmp[nX][nPosUC1][nY][2]), oFont10) //vencto
				oPrint:Say(nLin,2380, Transform(aDadosCmp[nX][nPosUC1][nY][3],"@E 999,999,999.99"), oFont10,,,,1) //valor

				nLin+=50
			Next nY

		Next nX

		//totais
		oPrint:Say(nLin,1000, "Totais:", oFont10N)
		oPrint:Say(nLin,1640, Transform(nTotDin,"@E 999,999,999.99"), oFont10N,,,,1)
		oPrint:Say(nLin,1890, Transform(nTotVlh,"@E 999,999,999.99"), oFont10N,,,,1)
		oPrint:Say(nLin,2140, Transform(nTotCht,"@E 999,999,999.99"), oFont10N,,,,1)
		oPrint:Say(nLin,2390, Transform(nTotCMP,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//--------------------------------------------------------------------------------------
// Faz impressão analitica de vale serviços pré
//--------------------------------------------------------------------------------------
User Function T028RVLS

	Local nX
	Local nOpcX := ParamIxb[1]
	Local cDescForm := ParamIxb[2]
	Local cFormPg := ParamIxb[3]
	Local aCampos := {"UIC_TIPO","UIC_AMB","UIC_CODIGO","UIC_CLIENT","UIC_LOJAC","UIC_NOMEC","UIC_PRODUT","UIC_DESCRI","UIC_PRCPRO"}
	Local aDados := {}
	Local nTotalVLS := 0

	nTotalVLS := U_T028TVLS(nOpcX, @aDados, aCampos)

	if nTotalVLS > 0

		//iniciando impressões
		if nLin+230 > 3300  .Or. nQuebra == 2
			Rod()
			Cabecalho()
		EndIf

		nLin+=100
		oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, Capital(cDescForm), oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Tipo", oFont10N)
		oPrint:Say(nLin+5,155, "Codigo Vale", oFont10N)
		oPrint:Say(nLin+5,400, "Cliente", oFont10N)
		oPrint:Say(nLin+5,1370, "Serviço", oFont10N)
		oPrint:Say(nLin+5,2380, "Valor", oFont10N,,,,1)
		nLin+=80

		For nX := 1 to len(aDados)
			if nLin>3300
				Rod()
				Cabecalho()
			EndIf

			oPrint:Say(nLin,55, iif(aDados[nX][1]=="R","Pré","Pós"), oFont10)
			oPrint:Say(nLin,155, aDados[nX][2]+aDados[nX][3], oFont10)
			oPrint:Say(nLin,400, aDados[nX][4]+"/"+aDados[nX][5]+" "+SubStr(aDados[nX][6],1,25), oFont10)
			oPrint:Say(nLin,1370, Alltrim(aDados[nX][7])+"-"+SubStr(aDados[nX][8],1,25), oFont10)
			oPrint:Say(nLin,2380, Transform(aDados[nX][9],"@E 999,999,999.99"), oFont10,,,,1)

			nLin+=50
		Next nX

		//totais
		oPrint:Say(nLin,1900, "Total:", oFont10N)
		oPrint:Say(nLin,2380, Transform(nTotalVLS,"@E 999,999,999.99"), oFont10N,,,,1)

	endif

Return

//----------------------------------------------------------------------
// Relatorio por Identfid
//----------------------------------------------------------------------
User Function TRA028RI

	Local cPerg := "TRA028RL"
	Local cMsgAguarde := "Consulta do fluxo de caixa do operador (Movimento Processos de Venda)..."
	Local cModelRelIden := SuperGetMV("TP_RIDENTF",,"O") //Modelo de relatório por identifid (vendedor): O-Old/N-New

	Private nTipoRel := 1 //sintetico ou analitico
	Private nQuebra := 1 //1=Nao;2=Sim
	Private cVendDe := Space(TamSx3("A3_COD")[1])
	Private cVendAte := Replicate("Z",TamSx3("A3_COD")[1])

	//Verifica se o caixa foi conferido
	If !(SLW->LW_CONFERE == '1' .Or. SLW->LW_CONFERE == '2' )
		MsgAlert("Primeiramente realize o fechamento e a conferência do caixa.","Atenção")
		Return
	EndIf

	//atualizo, pois se o parametro estiver criado por filial, poderá montar a tela errada.
	lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.)

	if cModelRelIden == "O"
		cPerg := "TRA028RI"
	endif

	//AjustaSx1(cPerg)
	//If pergunte(cPerg,.T.) //Chama a tela de parametros
	If UPergunte(.T.)
		nTipoRel := MV_PAR01
		nQuebra  := MV_PAR02
		If !(cModelRelIden == "O")
			cVendDe  := MV_PAR03
			cVendAte := MV_PAR04
		EndIf
	Else
		Return
	EndIf
	
	If cModelRelIden == "O"
		LjMsgRun(cMsgAguarde,"Relatório Caixa Identfid",{|| OLDImpRelIdent(nTipoRel, nQuebra) })
	Else
		LjMsgRun(cMsgAguarde,"Relatório Caixa x Vendedor",{|| ImpRelIdent() })
	EndIf

Return

//----------------------------------------------------------------------
// Faz a impressao do Relatorio por Identfid
//----------------------------------------------------------------------
Static Function ImpRelIdent()

	Local aVendedor, nX, nI
	Private __CFILVEND := ""

	//Variaveis de Tipos de fontes que podem ser utilizadas no relatório
	//Private oFont6		:= TFONT():New("ARIAL",06,06,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	//Private oFont6N 	:= TFONT():New("ARIAL",06,06,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",08,08,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",08,08,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	//Private oFont10S	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",10,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	//Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	//Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	//Private oFont14		:= TFONT():New("ARIAL",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
	//Private oFont14NS	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
	//Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	//Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	//Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	//Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	//Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	//Variveis para impressão
	Private cStartPath
	Private nLin 		:= 50
	Private oPrint		:= TMSPRINTER():New("")
	Private oBrush1		:= TBrush():New( , CLR_HGRAY )
	Private nPag		:= 1

	Private aFormasHab	:= FormasHab()

	//adiciona uma posição de controle da impressão da sessão: size=9
	For nI:=1 to Len(aFormasHab)
		aAdd(aFormasHab[nI],.F.) //size=9
	Next nI

	//se relatório analítico, mostra tela para marcar/desmarcar sessão
	If nTipoRel == 2 //1=Sintetico;2=Analitico
		If !UPergFormas()
			Return
		EndIf
	EndIf

	//Define Tamanho do Papel
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//Orientacao do papel (Retrato ou Paisagem)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	aVendedor := GetVendCaixa()
	ASort(aVendedor) //ordena por codigo vendedor

	For nX := 1 to len(aVendedor)

		Cabecalho()

		if empty(aVendedor[nX])
			__CFILVEND := aVendedor[nX]

			oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
			oPrint:Box( nLin,45,nLin+55,2400 )
			oPrint:Say(nLin,55, "OPERAÇÕES DE CAIXA SEM VINCULO COM VENDEDOR", oFont12N)
			nLin+= 55
		else
			SA3->(DbSetOrder(1))
			SA3->(DbSeek(xFilial("SA3")+aVendedor[nX] ))
			__CFILVEND := SA3->A3_COD

			oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
			oPrint:Box( nLin,45,nLin+55,2400 )
			oPrint:Say(nLin,55, "VENDEDOR: " + SA3->A3_COD+"-"+Alltrim(SA3->A3_NOME)+" ("+Alltrim(SA3->A3_RFID)+")", oFont12N)
			nLin+= 55
		endif

		//oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin,1200, "Resumo Caixa do Vendedor", oFont12N,,,,2)
		nLin+= 55

		oPrint:Box( nLin,45,nLin+55,2400 )
		oPrint:Say(nLin+5,55, "Movimentação", oFont10N)
		oPrint:Say(nLin+5,2350, "Vlr. Apurado (+/-)", oFont10N,,,,1)
		nLin+= 70

		ImpRelSint()

		if SLW->(FieldPos("LW_XOBS"))>0
			U_T028IOBS()
		endif

		if nTipoRel == 2
			ImpRelAnalit()
		endif

		//Finaliza Relatório
		Rod()
	next nX

	//Visualiza a impressao
	oPrint:Preview()

Return

//----------------------------------------------
// Obtem vendedores distintos do caixa
//----------------------------------------------
Static Function GetVendCaixa()

	Local cCondicao, bCondicao, cQry
	Local aVend := {}
	Local lFilVend := type("__CFILVEND")=="C"
	Local aVendTmp := {}
	Local nX := 0

	if lSrvPDV

		//VENDAS
		cCondicao := GetFilSL1("PDV")
		bCondicao 	:= "{|| " + cCondicao + " }"
		SL1->(DbClearFilter())
		SL1->(DbSetFilter(&bCondicao,cCondicao))
		SL1->(DbSetOrder(1))
		SL1->(DbGoTop())
		While SL1->(!Eof())

			if aScan(aVend, SL1->L1_VEND) == 0
				aadd(aVend, SL1->L1_VEND )
			endif

			SL1->(DbSkip())
		EndDo
		SL1->(DbClearFilter())

		//SANGRIAS E SURPIMENTOS
		cCondicao := GetFilSE5("PDV")
		cCondicao += " .AND. ("
		cCondicao += " ((E5_TIPODOC == 'TR' .OR. E5_TIPODOC == 'TE') .AND. E5_MOEDA == 'TC' .AND. E5_RECPAG == 'R') "
		cCondicao += " .OR. "
		cCondicao += " ((E5_TIPODOC == 'SG' .OR. E5_TIPODOC == 'TR' .OR. E5_TIPODOC == 'TE') .AND. E5_MOEDA == '"+SIMBDIN+"' .AND. E5_RECPAG == 'P' .AND. E5_SITUACA <> 'C') "
		cCondicao += " ) "
		bCondicao 	:= "{|| " + cCondicao + " }"
		SE5->(DbClearFilter())
		SE5->(DbSetFilter(&bCondicao,cCondicao))
		SE5->(DbSetOrder(1))
		SE5->(DbGoTop())
		While SE5->(!Eof())

			if aScan(aVend, SE5->E5_OPERAD) == 0
				aadd(aVend, SE5->E5_OPERAD )
			endif

			SE5->(DbSkip())
		EndDo
		SE5->(DbClearFilter())

		if lMvPosto

			//COMPENSACAO
			if SuperGetMV("TP_ACTCMP",,.F.)
				cCondicao := GetFilUC0("PDV")
				bCondicao 	:= "{|| " + cCondicao + " }"
				UC0->(DbClearFilter())
				UC0->(DbSetFilter(&bCondicao,cCondicao))
				UC0->(DbSetOrder(1))
				UC0->(DbGoTop())
				While UC0->(!Eof())

					if aScan(aVend, UC0->UC0_VEND) == 0
						aadd(aVend, UC0->UC0_VEND )
					endif

					UC0->(DbSkip())
				EndDo
				UC0->(DbClearFilter())
			endif

			//SAQUES 
			if SuperGetMV("TP_ACTSQ",,.F.)
				cCondicao := GetFilU57("PDV")
				cCondicao += "  .AND. U57_TUSO = 'S' " //Saque pre e pos
				cCondicao += "  .AND. U57_FILSAQ = '"+cFilAnt+"' "
				bCondicao 	:= "{|| " + cCondicao + " }"
				U57->(DbClearFilter())
				U57->(DbSetFilter(&bCondicao,cCondicao))
				U57->(DbSetOrder(1))
				U57->(DbGoTop())
				While U57->(!Eof())

					if aScan(aVend, U57->U57_VEND) == 0
						aadd(aVend, U57->U57_VEND )
					endif

					U57->(DbSkip())
				EndDo
				U57->(DbClearFilter())
			endif

			//DEPOSITOS
			if SuperGetMV("TP_ACTDP",,.F.)
				cCondicao := GetFilU57("PDV",,,.T.)
				cCondicao += " .AND. U57_PREFIX == 'P"+cFilAnt+"' " 
				cCondicao += " .AND. U57_FILDEP == '"+cFilAnt+"' "
				bCondicao 	:= "{|| " + cCondicao + " }"
				U57->(DbClearFilter())
				U57->(DbSetFilter(&bCondicao,cCondicao))
				U57->(DbSetOrder(1))
				U57->(DbGoTop())
				While U57->(!Eof())

					if aScan(aVend, U57->U57_VEND) == 0
						aadd(aVend, U57->U57_VEND )
					endif

					U57->(DbSkip())
				EndDo
				U57->(DbClearFilter())
			endif

			//VALE SERVIÇO
			if SuperGetMV("TP_ACTVLS",,.F.)
				cCondicao := GetFilUIC("PDV") 
				bCondicao 	:= "{|| " + cCondicao + " }"
				UIC->(DbClearFilter())
				UIC->(DbSetFilter(&bCondicao,cCondicao))
				UIC->(DbSetOrder(1))
				UIC->(DbGoTop())
				While UIC->(!Eof())

					if aScan(aVend, UIC->UIC_VEND) == 0
						aadd(aVend, UIC->UIC_VEND )
					endif

					UIC->(DbSkip())
				EndDo
				UIC->(DbClearFilter())
			endif

		endif

	else

		//vendas
		cCondicao := GetFilSL1("TOP")
		cQry := " SELECT DISTINCT L1_VEND AS CODVEND "
		cQry += " FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 "
		cQry += " WHERE SL1.D_E_L_E_T_= ' ' AND "+cCondicao

		cQry += " UNION "

		//Sangrias e Suprimentos
		cCondicao := GetFilSE5("TOP")
		cQry += " SELECT DISTINCT E5_OPERAD AS CODVEND "
		cQry += " FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "
		cQry += " WHERE SE5.D_E_L_E_T_= ' ' "+cCondicao
		cQry += "  AND ( "
		cQry += "  ((E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') AND E5_MOEDA = 'TC' AND E5_RECPAG = 'R')"
		cQry += " OR "
		cQry += "  ((E5_TIPODOC = 'SG' OR E5_TIPODOC = 'TR' OR E5_TIPODOC = 'TE') AND E5_MOEDA = '"+SIMBDIN+"' AND E5_RECPAG = 'P' AND E5_SITUACA <> 'C') "
		cQry += " ) "

		if lMvPosto

			//compensacao
			if SuperGetMV("TP_ACTCMP",,.F.)
				cQry += " UNION "

				cCondicao := GetFilUC0("TOP")
				cQry += " SELECT DISTINCT UC0_VEND AS CODVEND "
				cQry += " FROM "+RetSqlName("UC0")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UC0 "
				cQry += " WHERE UC0.D_E_L_E_T_= ' ' AND "+cCondicao
			endif

			//SAQUE PRE e POS
			if SuperGetMV("TP_ACTSQ",,.F.)
				cQry += " UNION "

				cCondicao := GetFilU57("TOP")
				cQry += " SELECT DISTINCT U57_VEND AS CODVEND "
				cQry += " FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
				cQry += " WHERE U57.D_E_L_E_T_= ' ' AND "+cCondicao
				cQry += " AND U57_TUSO = 'S' " //Saque
				cQry += " AND U57_FILSAQ = '"+cFilAnt+"' "
			endif

			//DEPOSITO 
			if SuperGetMV("TP_ACTDP",,.F.)
				cQry += " UNION "

				cCondicao := GetFilU57("TOP",,,.T.)
				cQry += " SELECT DISTINCT U57_VEND AS CODVEND "
				cQry += " FROM "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
				cQry += " WHERE U57.D_E_L_E_T_= ' ' AND "+cCondicao
				cQry += " AND U57_FILDEP = '"+cFilAnt+"' "
			endif

			//vale serviço
			if SuperGetMV("TP_ACTVLS",,.F.)
				cQry += " UNION "

				cCondicao := GetFilUIC("TOP")
				cQry += " SELECT DISTINCT UIC_VEND AS CODVEND "
				cQry += " FROM "+RetSqlName("UIC")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" UIC "
				cQry += " WHERE UIC.D_E_L_E_T_= ' ' AND "+cCondicao
			endif
		endif
		
		If Select("TVEND") > 0
			TVEND->(DbCloseArea())
		EndIf
		
		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "TVEND" // Cria uma nova area com o resultado do query

		TVEND->(DbGoTop())
		While TVEND->(!Eof())

			if aScan(aVend, TVEND->CODVEND) == 0
				aadd(aVend, TVEND->CODVEND )
			endif

			TVEND->(DbSkip())
		EndDo

		TVEND->(DbCloseArea())

	endif

	//filtro por vendedor, quando for relatório por vendedor
	If lFilVend
		aVendTmp := aClone(aVend)
		aVend := {}
		For nX:=1 to Len(aVendTmp)
			If (aVendTmp[nX] >= cVendDe .and. aVendTmp[nX] <= cVendAte)
				aadd(aVend, aVendTmp[nX])
			EndIf
		Next nX
	EndIf

Return aVend

//----------------------------------------------------------------------
// Faz a impressao do Relatorio por Identfid
//----------------------------------------------------------------------
Static Function OLDImpRelIdent(nTipoRel, nQuebra, nOpcX)

	Local aDadosSL2 := {}
	Local aDadosAux := {}
	Local aCamposSL2 := {"L2_PRODUTO","L2_DESCRI","L2_VLRITEM","L2_DOC","L2_SERIE","L2_VEND"}
	Local aCamposSE1 := {"E1_TIPO", "E1_VALOR", "E1_VLRREAL","E1_NOMCLI"}
	Local aCamposSL4 := {"L4_FORMA","L4_VALOR","L4_VALOR","A1_NOME","A1_COD"}
	Local aVendedor := {} //{cCodVend, cNomVend, cIdentfid, {cCodProd, cDescri, cValor, cSerie, cDoc}}
	Local aFormasPg := {} //{cSerie, cDoc, {cForma, cValor}, cFormaL1}
	Local cVendAtu := ""
	Local cDoc := ""
	Local cSerie := ""
	Local cFormas := ""
	Local nPosVend := 0
	Local nPosDoc  := 0
	Local nPosForma := 0
	Local nPosAux  := 0
	Local nPosAux2 := 0
	Local nX, nY, nZ
	Local nTotVend := 0
	Local nTotForm := 0
	Local nVlrForma := 0
	Local nTrocoDin := 0

	//Variaveis de Tipos de fontes que podem ser utilizadas no relatório
	//Private oFont6		:= TFONT():New("ARIAL",06,06,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	//Private oFont6N 	:= TFONT():New("ARIAL",06,06,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",08,08,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",08,08,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	//Private oFont10S	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",10,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	//Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	//Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	//Private oFont14		:= TFONT():New("ARIAL",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
	//Private oFont14NS	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
	//Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	//Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	//Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	//Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	//Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	//Variveis para impressão
	Private cStartPath
	Private nLin 		:= 50
	Private oPrint		:= TMSPRINTER():New("")
	Private oBrush1		:= TBrush():New( , CLR_HGRAY )
	Private nPag		:= 1

	Private aFormasHab	:= FormasHab()

	//Define Tamanho do Papel
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//Orientacao do papel (Retrato ou Paisagem)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	if lSrvPDV
		aDadosSL2 := BuscaSL2("PDV", 2, aCamposSL2)
	else
		aDadosSL2 := BuscaSL2("TOP", 2, aCamposSL2)
	endif

	//buscando vendedores distintos
	for nX:=1 to len(aDadosSL2)

		cVendAtu := aDadosSL2[nX][aScan(aCamposSL2,"L2_VEND")]
		if empty(cVendAtu)
			cVendAtu := "SEM VENDEDOR"
		endif

		cSerie := aDadosSL2[nX][aScan(aCamposSL2,"L2_SERIE")]
		cDoc := aDadosSL2[nX][aScan(aCamposSL2,"L2_DOC")]

		nTrocoDin := U_T028TTV(2,,,iif(lSrvPDV,"L1_SERIE = '"+cSerie+"' .AND. L1_DOC = '"+cDoc+"'","E5_PREFIXO = '"+cSerie+"' AND E5_NUMERO = '"+cDoc+"'"),.F.,.F.)

		//montando vetor dos vendedores
		if (nPosVend:=ascan(aVendedor, {|x| x[1] == cVendAtu })) == 0
			if cVendAtu == "SEM VENDEDOR"
				aadd(aVendedor, {cVendAtu, ; //codigo
								"VENDA/ITEM SEM VENDEDOR",; //nome
								"",; //id identfid
								{} }) //array de itens
			else
				SA3->(DbSetOrder(1))
				SA3->(DbSeek(xFilial("SA3")+cVendAtu))
				aadd(aVendedor, {cVendAtu, ; //codigo
								SA3->A3_NOME,; //nome
								iif(SA3->(FieldPos("A3_RFID"))>0,SA3->A3_RFID,""),; //id identfid
								{} }) //array de itens
			endif
			nPosVend := len(aVendedor)
		endif

		//adiciono item ao vetor de vendedor
		aadd(aVendedor[nPosVend][4], { ;
			aDadosSL2[nX][aScan(aCamposSL2,"L2_PRODUTO")] ,;
			aDadosSL2[nX][aScan(aCamposSL2,"L2_DESCRI")] ,;
			aDadosSL2[nX][aScan(aCamposSL2,"L2_SERIE")] ,;
			aDadosSL2[nX][aScan(aCamposSL2,"L2_DOC")] ,;
			aDadosSL2[nX][aScan(aCamposSL2,"L2_VLRITEM")] ,;
			Posicione("SL1",2,xFilial("SL1")+cSerie+cDoc+Alltrim(SLW->LW_PDV),"L1_VLRLIQ") ;
		})

		//montando vetor de formas de pagamento
		if (nPosDoc:=ascan(aFormasPg, {|x| x[1]+x[2] == cSerie+cDoc} )) == 0
			aadd(aFormasPg, {aDadosSL2[nX][aScan(aCamposSL2,"L2_SERIE")],;
							aDadosSL2[nX][aScan(aCamposSL2,"L2_DOC")],;
			 				{},; //arrya de formas
			 				Posicione("SL1",2,xFilial("SL1")+cSerie+cDoc+Alltrim(SLW->LW_PDV),"L1_FORMPG"),;
			 				nTrocoDin })
			nPosDoc := len(aFormasPg)

			//Buscando formas do cupom
			//aCamposSE1 := {"E1_TIPO", "E1_VALOR", "E1_VLRREAL","E1_NOMCLI"}
			if lSrvPDV
				aDadosAux := BuscaSL4("PDV", 2, aCamposSL4,,,"SL1->L1_SERIE+SL1->L1_DOC+Alltrim(SL1->L1_PDV) == '"+cSerie+cDoc+Alltrim(SLW->LW_PDV)+"'")
			else
				aDadosAux := BuscaSE1(aCamposSE1, "E1_PREFIXO = '"+cSerie+"' AND E1_NUM = '"+cDoc+"' AND E1_TIPO <> 'NCC'")
			endif

			For nY:=1 To Len(aDadosAux)
				aadd(aFormasPg[nPosDoc][3], {;
					Alltrim(aDadosAux[nY][1]),;
					iif(aDadosAux[nY][3] == 0, aDadosAux[nY][2], aDadosAux[nY][3]) ,;
					Alltrim(aDadosAux[nY][4]) ;
				})
			next nY
		endif

	next nX

	if !empty(aVendedor)

		//ordeno por vendedor por nome
		ASort(aVendedor,,,{|x,y| x[2] < y[2] })

		Cabecalho()

		for nX := 1 to len(aVendedor)

			nTotVend := 0
			aDadosAux :={}

			if nLin>3300 .OR. (nQuebra==2 .AND. nX > 1)
				Rod()
				Cabecalho()
			EndIf

			oPrint:FillRect( {nLin,45, nLin+55, 2400}, oBrush1 )
			oPrint:Box( nLin,45,nLin+55,2400 )
			oPrint:Say(nLin,55, "Vendedor: " + aVendedor[nX][1]+"-"+Alltrim(aVendedor[nX][2])+" ("+aVendedor[nX][3]+")", oFont12N)
			nLin+= 55

			//ordeno por itens por doc/serie e produto
			ASort(aVendedor[nX][4],,,{|x,y| x[3]+x[4]+x[1] < y[3]+y[4]+y[1] })

			if nTipoRel == 1 //por forma

				oPrint:Box( nLin,45,nLin+55,2400 )
				oPrint:Say(nLin+5,55, "Produto", oFont8N)
				oPrint:Say(nLin+5,280, "Descriçao", oFont8N)
				oPrint:Say(nLin+5,950, "Doc/Serie", oFont8N)
				oPrint:Say(nLin+5,1200, "Cliente/Sacado", oFont8N)
				oPrint:Say(nLin+5,2050, "Vlr.Original", oFont8N,,,,1)
				oPrint:Say(nLin+5,2380, "Vlr.Vendedor", oFont8N,,,,1)
				nLin+=80

				//montando array por forma
				//aDadosAux := {cForma, {cProduto, cDescricao, cDocSer, nValorBruto, nVlrRateio, cCliente} }
				For nY := 1 to len(aVendedor[nX][4])

					cSerie := aVendedor[nX][4][nY][3]
					cDoc := aVendedor[nX][4][nY][4]
					
					nPosDoc := ascan(aFormasPg, {|x| x[1]+x[2] == cSerie+cDoc} ) //posiçao do doc

					for nZ:=1 to len(aFormasPg[nPosDoc][3])

						//retiro troco em dinheiro do recebimento em dinheiro
						nVlrForma := aFormasPg[nPosDoc][3][nZ][2]

						nVlrRateio := nVlrForma * (aVendedor[nX][4][nY][5] / aVendedor[nX][4][nY][6])
						nVlrRateio := Round(nVlrRateio , 2)
						if nVlrRateio == 0
							nVlrRateio := 0.01
						endif

						nPosAux := aScan(aDadosAux, {|x| x[1] == aFormasPg[nPosDoc][3][nZ][1] })
						if nPosAux == 0
							aadd(aDadosAux, { aFormasPg[nPosDoc][3][nZ][1],{} })
							nPosAux := len(aDadosAux)
						endif
						aadd(aDadosAux[nPosAux][2], { ;
								aVendedor[nX][4][nY][1],; //cod prod
								aVendedor[nX][4][nY][2],; //descricao
								cSerie+cDoc ,; //doc
								nVlrForma ,; //vlr bruto
								nVlrRateio ,;
								aFormasPg[nPosDoc][3][nZ][3] ; //CLIENTE
							} )

					next nZ

					//TROCO
					if aFormasPg[nPosDoc][5] > 0

						nPosAux := aScan(aDadosAux, {|x| x[1] == "TROCOS DE VENDA" })
						if nPosAux == 0
							aadd(aDadosAux, { "TROCO DE VENDA",{} })
							nPosAux := len(aDadosAux)
						endif

					 	nPosForma := 5
						cTpTroco := "R$"
						cDescTroc := "Dinheiro"

						if aFormasPg[nPosDoc][5] > 0
							nVlrForma := aFormasPg[nPosDoc][nPosForma] * (-1)

							nVlrRateio := nVlrForma * (aVendedor[nX][4][nY][5] / aVendedor[nX][4][nY][6])
							nVlrRateio := Round(nVlrRateio , 2)
							if nVlrRateio == 0
								nVlrRateio := 0.01
							endif

							nPosAux2 := aScan(aDadosAux[nPosAux][2], {|x| x[1]+x[3] == cTpTroco+cSerie+cDoc })
							if nPosAux2 == 0
								aadd(aDadosAux[nPosAux][2], { ;
										cTpTroco,; //cod prod
										cDescTroc,; //descricao
										cSerie+cDoc ,; //doc
										nVlrForma ,; //vlr bruto
										nVlrRateio ,;
										aFormasPg[nPosDoc][3][1][3] ; //CLIENTE
									} )
							else
								aDadosAux[nPosAux][2][nPosAux2][5] += nVlrRateio
							endif
						endif

					endif

					nTotVend += aVendedor[nX][4][nY][5] //totalizo aqui o vendedor, para evitar divergencia valor de rateio

				next nY

				//ordeno por forma
				ASort(aDadosAux,,,{|x,y| x[1] < y[1] })

				For nY := 1 to len(aDadosAux)
					nTotForm := 0

					if nLin>3300
						nLin := 3360
						oPrint:Say(nLin,55, "* Valor proporcional da forma de pagamento para o item", oFont10)
						Rod()
						Cabecalho()
					EndIf

					oPrint:Say(nLin,55, aDadosAux[nY][1] + " - " + Alltrim(Posicione("SX5",1,xFilial("SX5")+'05'+Alltrim(aDadosAux[nY][1]),"X5_DESCRI")), oFont10N)
					nLin+=50
					oPrint:Line (nLin, 45, nLin, 2400)
					nLin+=10

					for nZ := 1 to len(aDadosAux[nY][2])

						if nLin>3300
							nLin := 3360
							oPrint:Say(nLin,55, "* Valor proporcional da forma de pagamento para o item", oFont10)
							Rod()
							Cabecalho()
						EndIf

						oPrint:Say(nLin,55, 	aDadosAux[nY][2][nZ][1], oFont10) //cod prod
						oPrint:Say(nLin,280, 	aDadosAux[nY][2][nZ][2], oFont10) //descriçao
						oPrint:Say(nLin,950, 	aDadosAux[nY][2][nZ][3], oFont10) //doc serie
						oPrint:Say(nLin,1200, 	aDadosAux[nY][2][nZ][6], oFont10) //clente
						oPrint:Say(nLin,2050,	Transform(aDadosAux[nY][2][nZ][4],"@E 999,999,999.99"), oFont10,,,,1)
						oPrint:Say(nLin,2380, 	Transform(aDadosAux[nY][2][nZ][5],"@E 999,999,999.99"), oFont10,,,,1)

						if aDadosAux[nY][2][nZ][5] <> aDadosAux[nY][2][nZ][4]
							oPrint:Say(nLin,2390, 	"*", oFont10)
						endif

						nTotForm += aDadosAux[nY][2][nZ][5]

						nLin+=50

					next nZ

					if nLin>3300
						nLin := 3360
						oPrint:Say(nLin,55, "* Valor proporcional da forma de pagamento para o item", oFont10)
						Rod()
						Cabecalho()
					EndIf

					//totais forma
					oPrint:Line (nLin, 45, nLin, 2400)
					nLin+=10

					oPrint:Say(nLin,1100, "Total da forma:", oFont10N)
					oPrint:Say(nLin,2380, Transform(nTotForm,"@E 999,999,999.99"), oFont10N,,,,1)
					nLin+=100

				Next nY

				if nLin>3300
					nLin := 3360
					oPrint:Say(nLin,55, "* Valor proporcional da forma de pagamento para o item", oFont10)
					Rod()
					Cabecalho()
				EndIf

				//totais
				oPrint:Line (nLin, 45, nLin, 2400)
				nLin+=10
				oPrint:Say(nLin,1100, "Total Vendedor:", oFont10N)
				oPrint:Say(nLin,2380, Transform(nTotVend,"@E 999,999,999.99"), oFont10N,,,,1)
				nLin+=100

			else //por item

				oPrint:Box( nLin,45,nLin+55,2400 )
				oPrint:Say(nLin+5,55, "Produto", oFont8N)
				oPrint:Say(nLin+5,280, "Descriçao", oFont8N)
				oPrint:Say(nLin+5,1250, "Doc/Serie", oFont8N)
				oPrint:Say(nLin+5,1750, "Formas", oFont8N)
				oPrint:Say(nLin+5,2380, "Vlr.Total", oFont8N,,,,1)
				nLin+=80

				For nY := 1 to len(aVendedor[nX][4])
					if nLin>3300
						Rod()
						Cabecalho()
					EndIf

					cFormas := ""
					cSerie := aVendedor[nX][4][nY][3]
					cDoc := aVendedor[nX][4][nY][4]
					nPosDoc := ascan(aFormasPg, {|x| x[1]+x[2] == cSerie+cDoc} ) //posiçao do doc
					if len(aFormasPg[nPosDoc][3]) > 0
						aEval(aFormasPg[nPosDoc][3], {|x| iif(Alltrim(x[1]) $ cFormas,, cFormas += iif(empty(cFormas),"","/")+x[1] ) })
					else
						cFormas := aFormasPg[nPosDoc][4]
					endif

					oPrint:Say(nLin,55, 	aVendedor[nX][4][nY][1], oFont10) //cod prod
					oPrint:Say(nLin,280, 	aVendedor[nX][4][nY][2], oFont10) //descriçao
					oPrint:Say(nLin,1250, 	aVendedor[nX][4][nY][4]+"/"+aVendedor[nX][4][nY][3], oFont10)
					oPrint:Say(nLin,1750,	cFormas, oFont10)
					oPrint:Say(nLin,2380, 	Transform(aVendedor[nX][4][nY][5],"@E 999,999,999.99"), oFont10,,,,1)

					nTotVend += aVendedor[nX][4][nY][5]

					nLin+=50
				Next nY

				if nLin>3300
					Rod()
					Cabecalho()
				EndIf

				//totais
				oPrint:Line (nLin, 45, nLin, 2400)
				nLin+=10
				oPrint:Say(nLin,1100, "Total Vendedor:", oFont10N)
				oPrint:Say(nLin,2380, Transform(nTotVend,"@E 999,999,999.99"), oFont10N,,,,1)
				nLin+=100

			endif

		next nX

		//Finaliza Relatório
		if nTipoRel == 1 //por forma
			nLin := 3360
			oPrint:Say(nLin,55, "* Valor proporcional da forma de pagamento para o item", oFont10)
		endif
		Rod()

		//Visualiza a impressao
		oPrint:Preview()

	endif

Return

//----------------------------------------------------------------------
//Programa para Impressao do vale para caixa
//----------------------------------------------------------------------
User Function TRA028VL

	Local aTemp
	Local nX
	Local nFaltaCx := 0
	Local aFormasHab
	Local bExFunc := {|cFunc| ExistBlock(cFunc) }

	Private oFont8N 	:= TFONT():New("ARIAL",08,08,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",10,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	Private oFont10N 	:= TFONT():New("ARIAL",10,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito

	Private cStartPath
	Private nLin 		:= 50
	Private oPrint		:= TMSPRINTER():New("")
	Private oBrush1		:= TBrush():New( , CLR_HGRAY )
	Private nPag		:= 1

	//Define Tamanho do Papel
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//Orientacao do papel (Retrato ou Paisagem)
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	if SLW->(FieldPos("LW_XFLTCX")) > 0 .AND. SLW->LW_XFALTCX > 0
		nFaltaCx := SLW->LW_XFALTCX
	else
		aFormasHab := FormasHab()

		//buscando totais das formas habilitadas
		For nX := 1 to len(aFormasHab)
			if !empty(aFormasHab[nX][4]) //se tem função de total mostra
				if Eval(bExFunc, aFormasHab[nX][4]) //ExistBlock(aFormasHab[nX][4])
					nTotForm := ExecBlock(aFormasHab[nX][4],.F.,.F., {2})
					if "+" $ aFormasHab[nX][3]
						nFaltaCx += nTotForm
					elseif "-" $ aFormasHab[nX][3]
						nFaltaCx -= nTotForm
					endif
				endif
			endif
		Next nX
	endif

	if nFaltaCx > 0

		oPrint:StartPage() // Inicia uma nova pagina
		cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
		cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

		//CABECALHO
		nLin+=30
		oPrint:SayBitmap(nLin, 50, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 400, 128)///Impressao da Logo
		//oPrint:Say(nLin, 2350, "Pagina: " + strzero(nPag,3), oFont8N,,,,1)
		oPrint:Say(nLin+50, 1200, "Vale", oFont16N,,,,2)
		nLin+=30
		oPrint:Say(nLin+30, 2350, DTOC(dDataBase), oFont8N,,,,1)
		nLin+=70
		oPrint:Say(nLin, 2350, TIME(), oFont8N,,,,1)
		oPrint:Say(nLin, 850, "", oFont14N)
		nLin:=250
		oPrint:Line (nLin, 45, nLin, 2400)
		nLin+=100

		//Informacoes do caixa
		oPrint:Say(nLin, 100, "Data do Vale: "+DTOC(SLW->LW_DTABERT), oFont12N)
		oPrint:Say(nLin, 800, "Turno: "+SLW->LW_NUMMOV	, oFont12N)
		nLin+=100

		oPrint:Say(nLin, 100, "PDV: "+Alltrim(SLW->LW_PDV), oFont12N)
		nLin+=050
		oPrint:Say(nLin, 100, "Emp./Fil: "+Alltrim(SM0->M0_FILIAL), oFont12N)
		If !Empty(Posicione("SLG",1,xFilial("SLG")+SLW->LW_ESTACAO,"LG_SERPDV"))
			nLin+=050
			oPrint:Say(nLin, 100, "Serie PDV: "+Posicione("SLG",1,xFilial("SLG")+SLW->LW_ESTACAO,"LG_SERPDV"), oFont12N)
		EndIf
		nLin+=100

		oPrint:Say(nLin, 100, "Nome do Operador: "+SLW->LW_OPERADO+" - "+Posicione("SA6",1,xFilial("SA6")+SLW->LW_OPERADO,"A6_NOME")	, oFont12N)
		nLin+=100

		aTemp := QuebraTexto("O funcionário mencionado acima teve um vale no valor de:  R$ "+Alltrim(Transform(nFaltaCx,"@E 999,999,999.99"))+" ("+AllTrim(Extenso(nFaltaCx))+").",105)

		//fazer laço para quebra de linha
		for nX := 1 to len(aTemp)
			oPrint:Say(nLin,100,aTemp[nX],oFont12N,,0)
			nLin := nLin+0050
		next nX

		oPrint:Say(nLin, 100, "Estando ciente, firmamos o presente.", oFont12N)
		nLin+=150

		oPrint:Say(nLin, 2400, "__________________________________,_________ de _______________________ de _________.", oFont10N,,,,1)
		nLin+=200

		oPrint:Say(nLin, 2400, "__________________________________________________________________________________", oFont10N,,,,1)
		nLin+=50
		oPrint:Say(nLin, 2400, "      NOME/ASSINATURA                                                             ", oFont12N,,,,1)

		oPrint:EndPage()

		//Visualiza a impressao
		oPrint:Preview()

	Else

		MsgAlert("O caixa selecionado não possui falta de caixa.","Atenção")

	Endif

Return

//----------------------------------------------------------------------
// Quebra texto para relatorio
//----------------------------------------------------------------------
Static Function QuebraTexto(_cString,_nCaracteres)

	Local aTexto      := {}
	Local cAux        := ""
	Local cString     := AllTrim(_cString)
	Local nX          := 1
	Local nY          := 1

	if _nCaracteres > Len(cString)
		aadd(aTexto,cString)
	else

		While nX <= Len(cString)
	        cAux := SubStr(cString,nX,_nCaracteres)
			if Empty(cAux)
				nX += _nCaracteres
			else
				if SubStr(cAux,Len(cAux),1) == " " .OR. nX + _nCaracteres > Len(cString)
					aadd(aTexto,cAux)
					nX += _nCaracteres
				else
					For nY := Len(cAux) To 1 Step -1
						if SubStr(cAux,nY,1) == " "
							aadd(aTexto,SubStr(cAux,1,nY))
	                        nX += nY
	                        Exit
						endif
					Next nY
				endif
			endif
		EndDo
	endif

Return(aTexto)

//----------------------------------------------------------------------
//Programa para gerar arquivo CSV dos caixas
//----------------------------------------------------------------------
User Function TRA028EX

	//atualizo, pois se o parametro estiver criado por filial, poderá montar a tela errada.
	lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.)

	If MsgYesNO("Será gerado um aquivo .CSV com os totalizadores dos caixa baseados nos filtros do browser. Este processo pode demorar vários minutos, Deseja continuar?","Atenção")
		Processa({|lEnd| ArqCSV(@lEnd) },"Aguarde... este processo pode demorar...","Gerando arquivos CSV...", .T.)
	EndIf

Return
//----------------------------------------------------------------------
//Programa para gerar arquivo CSV dos caixas - Processamento
//----------------------------------------------------------------------
Static Function ArqCSV(lEnd)

	Local nX
	Local cFile
	Local nH
	Local aFormasHab := FormasHab()
	Local nTotForm, aQuantVC
	Local bExFunc := {|cFunc| ExistBlock(cFunc) }
	Private __cFORMAATU := ""

	cFile := cGetFile( '*.CSV' , "Selecione o diretório", 16, , .F.,GETF_LOCALHARD,.F., .T. ) //Selecao do arquivo que sera utilizado
	nH	  := MsfCreate(cFile+".CSV",0)

	If nH == -1
		MsgStop("Falha ao criar arquivo - erro "+str(ferror()))
		Return
	Endif

	ProcRegua(0)
	IncProc("Montando cabeçalho do arquivo...")

	// Cabecalho do Arquivo
	cHeader := 	"FILIAL"		+";"
	cHeader += 	"DATA ABERTURA"	+";"
	cHeader += 	"HORA ABERTURA"	+";"
	cHeader += 	"CAIXA"			+";"
	cHeader += 	"PDV"			+";"
	cHeader += 	"NUM.MOVIMENTO"	+";"
	cHeader += 	"ESTACAO"		+";"

	//montado cabeçalho de acordo com formas habilitadas
	For nX := 1 to len(aFormasHab)
		if !empty(aFormasHab[nX][4]) //se tem função de total mostra
			cHeader += 	Alltrim(aFormasHab[nX][2]) + ";"
			if aFormasHab[nX][1] == "VC" //se venda combustivel
				cHeader += 	"LITRAGEM COMBUSTIVEL"	+";"
			endif
		endif
	Next nX

	fWrite(nH,cHeader )
	fWrite(nH,CRLF)

	While SLW->(!Eof())

		if lEnd
			MsgAlert("Abortado pelo Usuário","Abortado")
			fClose(nH)
			Return
		endif

		IncProc("Buscando totais caixa: " + DTOC(SLW->LW_DTABERT) + " " + Alltrim(SLW->LW_OPERADO) + " " + Alltrim(SLW->LW_PDV) )

		cItem := 	SLW->LW_FILIAL	+";"
		cItem += 	DTOC(SLW->LW_DTABERT)	+";"
		cItem += 	SLW->LW_HRABERT	+";"
		cItem += 	SLW->LW_OPERADO	+";"
		cItem += 	SLW->LW_PDV	+";"
		cItem += 	SLW->LW_NUMMOV	+";"
		cItem += 	SLW->LW_ESTACAO	+";"

		//buscando totais das formas habilitadas
		For nX := 1 to len(aFormasHab)
			if !empty(aFormasHab[nX][4]) //se tem função de total mostra

				if Eval(bExFunc, aFormasHab[nX][4]) //ExistBlock(aFormasHab[nX][4])
					__cFORMAATU := aFormasHab[nX][1]
					nTotForm := ExecBlock(aFormasHab[nX][4],.F.,.F., {2})
					cItem += Alltrim(Transform(nTotForm, "@E 999,999,999.99")) + ";"
				else
					cItem += Alltrim(Transform(0, "@E 999,999,999.99")) + ";"
				endif

				if aFormasHab[nX][1] == "VC" //se venda combustivel
					aQuantVC := {}
					nTotForm := 0
					U_T028TVC(2, @aQuantVC, {"L2_QUANT","L2_VLRITEM"})
					aEval(aQuantVC, {|x| nTotForm += x[1] })
					cItem += Alltrim(Transform(nTotForm, "@E 999,999,999.99")) + ";"
				endif

			endif
		Next nX

		if fWrite(nH,cItem,len(cItem)) != len(cItem)
			MsgAlert("Erro na geração do arquivo CSV. Favor reprocessar.","Erro Gravação")
			fClose(nH)
			Return
		Endif

		fWrite(nH,CRLF)

		SLW->(DbSkip())
	EndDo

	fClose(nH)
	MsgInfo("Arquivo gerado com sucesso!","Atenção")

Return

/*/{Protheus.doc} DevVenda
Otimização do processo de devolução de combustiveis no caixa.

@author thebr
@since 14/01/2019
@version 1.0
@return Nil

@type function
/*/
Static Function DevVenda()

	Local lCompCR 		:= SuperGetMV( "MV_LJCMPCR", NIL, .T. ) 	// Indica se ira compensar o valor da NCC gerada com o titulo da nota fiscal original
	Local cMV_DEVNCC    := AllTrim(SuperGetMV("MV_DEVNCC"))			// Define a forma de devolucao default: "1"-Dinheiro;"2"-NCC
	Local cMV_LJCHGDV   := AllTrim(SuperGetMV("MV_LJCHGDV",,"1"))	// Define se permite ou nao modificar a forma de devolucao ao cliente ("0"-nao permite;"1"-permite)
	Local cMV_LJCMPNC   := AllTrim(SuperGetMV("MV_LJCMPNC",,"1"))	// Define se permite ou nao modificar a opcao para compensar a NCC com o titulo da NF original ("0"-nao permite;"1"-permite)
	Local cMV_XBCOCDV	:= AllTrim(SuperGetMV("MV_XBCOCDV",,""))	// Banco de Devoluções: banco + agencia + conta (A6_COD+A6_AGENCIA+A6_NUMCON)

	Static oDlgListDev

	// atualiza a data do sistema para a data atual
	dDataBase := date()

	//Validação (pré-requisitos)
	if lCompCR
		PutMvPar("MV_LJCMPCR",.F.)
		lCompCR := .F.
	endif

	if cMV_DEVNCC = "1" //"1"-Dinheiro;"2"-NCC
		PutMvPar("MV_DEVNCC","2")
	endif

	if cMV_LJCHGDV = "1" //"0"-nao permite;"1"-permite
		PutMvPar("MV_LJCHGDV","0")
	endif

	if cMV_LJCMPNC = "1" //"0"-nao permite;"1"-permite
		PutMvPar("MV_LJCMPNC","0")
	endif

	if Empty(cMV_XBCOCDV)
		MsgAlert("O parâmetro de banco de devolução não foi preenchido. Entre em contato com administrador do sistema.","Msg: MV_XBCOCDV")
		Return
	else
		SA6->(DbSetOrder(1)) //A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
		if SA6->(DbSeek(xFilial("SA6")+cMV_XBCOCDV)) .and. AllTrim(cMV_XBCOCDV) = AllTrim(SA6->A6_COD) .and. SA6->A6_XGERENT == "1"
		else
			MsgAlert("O parâmetro de banco de devolução não foi preenchido corretamente. Banco '"+cMV_XBCOCDV+"' inexistente. Entre em contato com administrador do sistema.","Msg: MV_XBCOCDV")
			Return
		endif
	endif

	//Tela "possíveis devoluções"
	if lMvPosto
		ListDev()
	endif

	//Fecho tabela TRB caso exista, pois estava dando erro ao acessar devolucao
	If Select("TRB") > 0
		TRB->(DbCloseArea())
	EndIf

	//Rotina de Troca (LOJA720)
	LOJA720()

	// volta a data do sistema para a data do caixa e parametros
	dDataBase := SLW->LW_DTABERT
	PutMvPar("MV_LJCMPCR",lCompCR)
	PutMvPar("MV_DEVNCC",cMV_DEVNCC)
	PutMvPar("MV_LJCHGDV",cMV_LJCHGDV)
	PutMvPar("MV_LJCMPNC",cMV_LJCMPNC)

Return

//------------------------------------------------
// mostra "possíveis devoluções"
//------------------------------------------------
Static Function ListDev()

	Local oButton1
	Local oSay1
	Local oSay2

	Private OMSGet1
	Private OMSGet2
	Private _aBkpAcols1 := {}
	Private _aBkpAcols2 := {}

	DEFINE MSDIALOG oDlgListDev TITLE "Sugestão de Vendas para Devoluções" FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

  	@ 005, 005 SAY oSay1 PROMPT "BAIXA DUPLICADA DE ABASTECIMENTOS" SIZE 200, 007 OF oDlgListDev COLORS 0, 16777215 PIXEL
	OMSGet1 := fMSNewGe1()

	@ 090, 005 SAY oSay2 PROMPT "VENDAS DE COMBUSTIVEIS SEM N. ABASTECIMENTOS (L2_MIDCOD)" SIZE 200, 007 OF oDlgListDev COLORS 0, 16777215 PIXEL
	OMSGet2 := fMSNewGe2()

	@ 180, 355 BUTTON oButton1 PROMPT "Fechar" SIZE 035, 012 OF oDlgListDev PIXEL Action oDlgListDev:End()

	//BAIXA DUPLICADA DE ABASTECIMENTO
	MsgRun("Aguarde, selecionando baixa duplicada de abastecimento...",,{|| AtuGrid(1)})

	//VENDAS DE COMBUSTIVEIS SEM N. ABASTECIMENTO (L2_MIDCOD)
	MsgRun("Aguarde, selecionando vendas de combustíveis sem número de abastecimento...",,{|| AtuGrid(2)})

	ACTIVATE MSDIALOG oDlgListDev CENTERED

Return

//------------------------------------------------
//Monta o Objeto Acols
//------------------------------------------------
Static Function fMSNewGe1()

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFields := {"L2_FILIAL", "L2_MIDCOD", "L2_QUANT", "L2_VLRITEM", "L1_VLRLIQ", "L1_FORMPG", "L1_TROCO1", "L2_EMISSAO", "L1_HORA", "L2_NUM", "L2_DOC", "L2_SERIE", "L1_OPERADO", "L1_PDV", "L1_ESTACAO", "L1_NUMMOV", "L1_KEYNFCE"}
	Local aAlterFields := {}

	// Define field properties
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX], "X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )

			// Define field values
			IF aHeaderEx[len(aHeaderEx)][8] == "N"
				Aadd(aFieldFill, 0)
			ElseIf aHeaderEx[len(aHeaderEx)][8] == "D"
				Aadd(aFieldFill, CtoD(""))
			ElseIf aHeaderEx[len(aHeaderEx)][8] == "L"
				Aadd(aFieldFill, ".F.")
			ElseIf aHeaderEx[len(aHeaderEx)][8] == "M" .or. aHeaderEx[len(aHeaderEx)][8] == "C"
				Aadd(aFieldFill, Space(aHeaderEx[len(aHeaderEx)][4]))
			EndIf

		EndIf
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

	_aBkpAcols1 := aClone(aColsEx)

Return MsNewGetDados():New( 015, 005, 085, 400, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgListDev, aHeaderEx, aColsEx)

//------------------------------------------------
//Monta o Objeto Acols
//------------------------------------------------
Static Function fMSNewGe2()

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFields := {"L2_FILIAL", "L2_MIDCOD", "L2_QUANT", "L2_VLRITEM", "L1_VLRLIQ", "L1_FORMPG", "L1_TROCO1", "L2_EMISSAO", "L1_HORA", "L2_NUM", "L2_DOC", "L2_SERIE", "L1_OPERADO", "L1_PDV", "L1_ESTACAO", "L1_NUMMOV", "L1_KEYNFCE"}
	Local aAlterFields := {}

	// Define field properties
	For nX := 1 to Len(aFields)
		If !empty(GetSx3Cache(aFields[nX], "X3_CAMPO"))
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )

			// Define field values
			IF aHeaderEx[len(aHeaderEx)][8] == "N"
				Aadd(aFieldFill, 0)
			ElseIf aHeaderEx[len(aHeaderEx)][8] == "D"
				Aadd(aFieldFill, CtoD(""))
			ElseIf aHeaderEx[len(aHeaderEx)][8] == "L"
				Aadd(aFieldFill, ".F.")
			ElseIf aHeaderEx[len(aHeaderEx)][8] == "M" .or. aHeaderEx[len(aHeaderEx)][8] == "C"
				Aadd(aFieldFill, Space(aHeaderEx[len(aHeaderEx)][4]))
			EndIf

		EndIf
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

	_aBkpAcols2 := aClone(aColsEx)

Return MsNewGetDados():New( 100, 005, 175, 400, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgListDev, aHeaderEx, aColsEx)

//--------------------------------------------------
// Atualiza o Grid da tela
//--------------------------------------------------
Static Function AtuGrid(nOpc)

	Local cQry 		 := ""
	Local lDuplic := .F.
	Local cAbastX := ""
	Local aTemp := {}

	If nOpc == 1 .OR. nOpc == 3 //BAIXA DUPLICADA DE ABASTECIMENTO

		cQry := " SELECT"
		cQry += " SL2.L2_FILIAL,"
		cQry += " SL2.L2_MIDCOD,"
		cQry += " SL2.L2_QUANT,"
		cQry += " SL2.L2_VLRITEM,"
		cQry += " SL1.L1_VLRLIQ,"
		cQry += " SL1.L1_FORMPG,"
		cQry += " SL1.L1_TROCO1,"
		cQry += " SL2.L2_EMISSAO,"
		cQry += " SL1.L1_HORA,"
		cQry += " SL2.L2_NUM,"
		cQry += " SL2.L2_DOC,"
		cQry += " SL2.L2_SERIE,"
		cQry += " SL1.L1_OPERADO,"
		cQry += " SL1.L1_PDV,"
		cQry += " SL1.L1_ESTACAO,"
		cQry += " SL1.L1_NUMMOV,"
		cQry += " SL1.L1_KEYNFCE " + CRLF
		cQry += " FROM " + RetSqlName("SL2") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2 " + CRLF
		cQry += " INNER JOIN " + RetSqlName("SL1") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 ON ( " + CRLF
		cQry += " 	SL1.D_E_L_E_T_ = ' '  " + CRLF
		cQry += " 	AND SL2.L2_FILIAL = SL1.L1_FILIAL  " + CRLF
		cQry += " 	AND SL2.L2_NUM = SL1.L1_NUM  " + CRLF
		cQry += " 	AND SL2.L2_DOC = SL1.L1_DOC  " + CRLF
		cQry += " 	AND SL2.L2_SERIE = SL1.L1_SERIE " + CRLF
		cQry += " 	AND SL1.L1_SITUA = 'OK' " + CRLF
		cQry += " 	AND SL1.L1_EMISNF||SL1.L1_HORA >= '"+DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT+"' " + CRLF
		cQry += " 	AND SL1.L1_EMISNF||SL1.L1_HORA <= '"+DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA+"' " + CRLF
		cQry += " )  " + CRLF
		
		//-- CONDICAO DA VENDA: COM ABASTECIMENTO 
		cQry += " WHERE SL2.D_E_L_E_T_ = ' ' " + CRLF
		cQry += " AND SL2.L2_MIDCOD <> '        ' " + CRLF
		cQry += " AND SL2.L2_DOC <> '         ' " + CRLF
		cQry += " AND SL2.L2_FILIAL = '" + xFilial("SL2") + "' " + CRLF
		
		//-- ABASTECIMENTO DUPLICADO
		cQry += " AND EXISTS ( " + CRLF
		cQry += "   SELECT SL2_2.L2_MIDCOD " + CRLF
		cQry += "   FROM " + RetSqlName("SL2") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2_2 " + CRLF
		cQry += "   WHERE SL2_2.D_E_L_E_T_ = ' ' " + CRLF
		cQry += "    AND SL2_2.L2_MIDCOD <> '        ' " + CRLF
		cQry += "    AND SL2_2.L2_DOC <> '         ' " + CRLF
		cQry += "    AND SL2_2.L2_MIDCOD = SL2.L2_MIDCOD " + CRLF
		cQry += "    AND SL2_2.L2_FILIAL = SL2.L2_FILIAL " + CRLF
		cQry += "   GROUP BY SL2_2.L2_MIDCOD " + CRLF
		cQry += "   HAVING (COUNT(*) > 1) " + CRLF
		cQry += " ) " + CRLF
		
		//-- QUE NAO FOI DEVOLVIDO AINDA
		cQry += " AND NOT EXISTS ( " + CRLF
		cQry += "   SELECT 1  " + CRLF
		cQry += "   FROM " + RetSqlName("SD1") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SD1 " + CRLF
		cQry += "   WHERE SD1.D_E_L_E_T_ = ' '  " + CRLF
		cQry += "   AND SD1.D1_FILORI = SL2.L2_FILIAL " + CRLF
		cQry += "   AND SD1.D1_NFORI = SL2.L2_DOC  " + CRLF
		cQry += "   AND SD1.D1_SERIORI = SL2.L2_SERIE " + CRLF
		cQry += "   AND SD1.D1_ITEMORI = SL2.L2_ITEM  " + CRLF
		cQry += "   AND SD1.D1_TIPO = 'D' " + CRLF
		cQry += " ) " + CRLF

		cQry += " ORDER BY SL2.L2_FILIAL, SL2.L2_MIDCOD, SL2.L2_EMISSAO, SL1.L1_HORA, SL1.L1_OPERADO, SL1.L1_PDV, SL1.L1_ESTACAO, SL1.L1_NUMMOV" + CRLF

		cQry := ChangeQuery(cQry) 

	Else //VENDAS DE COMBUSTIVEIS SEM N. ABASTECIMENTO (L2_MIDCOD)

		cQry := "SELECT SL2.L2_FILIAL, SL2.L2_MIDCOD, SL2.L2_QUANT, SL2.L2_VLRITEM, SL1.L1_VLRLIQ," + CRLF
		cQry += " SL1.L1_FORMPG, SL1.L1_TROCO1, SL2.L2_EMISSAO, SL1.L1_HORA, SL2.L2_NUM, SL2.L2_DOC," + CRLF
		cQry += " SL2.L2_SERIE, SL1.L1_OPERADO, SL1.L1_PDV, SL1.L1_ESTACAO, SL1.L1_NUMMOV, SL1.L1_KEYNFCE" + CRLF
		cQry += " FROM " + RetSqlName("SL2") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2" + CRLF
		
		cQry += " INNER JOIN " + RetSqlName("SL1") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 ON ( " + CRLF
		cQry += " 	SL1.D_E_L_E_T_ = ' '  " + CRLF
		cQry += " 	AND SL2.L2_FILIAL = SL1.L1_FILIAL  " + CRLF
		cQry += " 	AND SL2.L2_NUM = SL1.L1_NUM  " + CRLF
		cQry += " 	AND SL2.L2_DOC = SL1.L1_DOC  " + CRLF
		cQry += " 	AND SL2.L2_SERIE = SL1.L1_SERIE " + CRLF
		cQry += " 	AND SL1.L1_SITUA = 'OK' " + CRLF
		cQry += " 	AND SL1.L1_EMISNF||SL1.L1_HORA >= '"+DTOS(SLW->LW_DTABERT)+SLW->LW_HRABERT+"' " + CRLF
		cQry += " 	AND SL1.L1_EMISNF||SL1.L1_HORA <= '"+DTOS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA+"' " + CRLF
		cQry += " )  " + CRLF

		cQry += " WHERE SL2.D_E_L_E_T_ = ' '" + CRLF
		cQry += " 	AND SL2.L2_MIDCOD = '        '" + CRLF
		cQry += " 	AND SL2.L2_DOC <> '         '" + CRLF
		cQry += " 	AND SL2.L2_FILIAL = '"+xFilial("SL2")+"'" + CRLF

		//-- QUE NAO FOI DEVOLVIDO AINDA
		cQry += " AND NOT EXISTS ( " + CRLF
		cQry += "   SELECT 1  " + CRLF
		cQry += "   FROM " + RetSqlName("SD1") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SD1 " + CRLF
		cQry += "   WHERE SD1.D_E_L_E_T_ = ' '  " + CRLF
		cQry += "   AND SD1.D1_FILORI = SL2.L2_FILIAL " + CRLF
		cQry += "   AND SD1.D1_NFORI = SL2.L2_DOC  " + CRLF
		cQry += "   AND SD1.D1_SERIORI = SL2.L2_SERIE " + CRLF
		cQry += "   AND SD1.D1_ITEMORI = SL2.L2_ITEM  " + CRLF
		cQry += "   AND SD1.D1_TIPO = 'D' " + CRLF
		cQry += " ) " + CRLF
		
		cQry += " 	AND SL2.L2_PRODUTO IN (SELECT DISTINCT(MID_XPROD) AS MID_XPROD" + CRLF
		cQry += " 							FROM " + RetSqlName("MID") + " "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" MID " + CRLF
		cQry += " 							WHERE MID.D_E_L_E_T_ = ' '" + CRLF
		cQry += " 							AND MID.MID_FILIAL = '"+xFilial("MID")+"'" + CRLF
		cQry += " 							AND MID.MID_DATACO >= '"+DTOS(SLW->LW_DTABERT)+"' AND MID.MID_DATACO <= '"+DTOS(SLW->LW_DTFECHA)+"')" + CRLF

		cQry += " ORDER BY SL2.L2_FILIAL, SL2.L2_MIDCOD, SL2.L2_EMISSAO, SL1.L1_HORA, SL1.L1_OPERADO, SL1.L1_PDV, SL1.L1_ESTACAO, SL1.L1_NUMMOV" + CRLF
		cQry := ChangeQuery(cQry)
	EndIf

	If Select("QRYSL1") > 0
		QRYSL1->(DbCloseArea())
	EndIf

	TcQuery cQry New Alias "QRYSL1" // Cria uma nova area com o resultado do query

	QRYSL1->(DbGoTop())

	If nOpc == 1
		OMSGet1:aCols := {}
	Elseif nOpc == 2
		OMSGet2:aCols := {}
	EndIf

	If QRYSL1->(!EoF())

		While QRYSL1->(!EoF())
			
			if QRYSL1->L1_OPERADO = SLW->LW_OPERADO ;
				.AND. QRYSL1->L1_NUMMOV = SLW->LW_NUMMOV ;
				.AND. Alltrim(QRYSL1->L1_PDV) = AllTrim(SLW->LW_PDV) ;
				.AND. QRYSL1->L1_ESTACAO = SLW->LW_ESTACAO

		 		If nOpc == 1 .OR. nOpc == 3

				

					if QRYSL1->L2_MIDCOD <> cAbastX
						if len(aTemp)>1 .AND. aScan(aTemp, {|x| Alltrim(x[14])==AllTrim(SLW->LW_PDV) .AND. x[13]==SLW->LW_OPERADO .AND. x[15]==SLW->LW_ESTACAO .AND. x[16]==SLW->LW_NUMMOV .AND. x[8]==SLW->LW_DTABERT })>0
							If nOpc == 1
								aEval(aTemp, {|x| aadd(oMSGet1:aCols, aClone(x)) })
							else
								lDuplic := .T.
							endif
						endif
						aTemp := {}
					endif

					cAbastX := QRYSL1->L2_MIDCOD

					Aadd(aTemp, {QRYSL1->L2_FILIAL,;
										QRYSL1->L2_MIDCOD,;
										QRYSL1->L2_QUANT,;
										QRYSL1->L2_VLRITEM,;
										QRYSL1->L1_VLRLIQ,;
										QRYSL1->L1_FORMPG,;
										QRYSL1->L1_TROCO1,;
										StoD(QRYSL1->L2_EMISSAO),;
										QRYSL1->L1_HORA,;
										QRYSL1->L2_NUM,;
										QRYSL1->L2_DOC,;
										QRYSL1->L2_SERIE,;
										QRYSL1->L1_OPERADO,;
										QRYSL1->L1_PDV,;
										QRYSL1->L1_ESTACAO,;
										QRYSL1->L1_NUMMOV,;
										QRYSL1->L1_KEYNFCE,;
										.F.})

				Elseif nOpc == 2
					Aadd(OMSGet2:aCols, {QRYSL1->L2_FILIAL,;
										QRYSL1->L2_MIDCOD,;
										QRYSL1->L2_QUANT,;
										QRYSL1->L2_VLRITEM,;
										QRYSL1->L1_VLRLIQ,;
										QRYSL1->L1_FORMPG,;
										QRYSL1->L1_TROCO1,;
										StoD(QRYSL1->L2_EMISSAO),;
										QRYSL1->L1_HORA,;
										QRYSL1->L2_NUM,;
										QRYSL1->L2_DOC,;
										QRYSL1->L2_SERIE,;
										QRYSL1->L1_OPERADO,;
										QRYSL1->L1_PDV,;
										QRYSL1->L1_ESTACAO,;
										QRYSL1->L1_NUMMOV,;
										QRYSL1->L1_KEYNFCE,;
										.F.})
				EndIf
			endif

			QRYSL1->(DbSkip())
		EndDo

	EndIf

	QRYSL1->(DbCloseArea())

	If nOpc == 1
		If Len(oMSGet1:aCols) == 0  .Or. oMSGet1:aCols == Nil .Or. Empty(oMSGet1:aCols[1][1])
			oMSGet1:aCols := aClone(_aBkpAcols1)
		EndIf
		oMSGet1:Refresh()
	Elseif nOpc == 2
		If Len(oMSGet2:aCols) == 0  .Or. oMSGet2:aCols == Nil .Or. Empty(oMSGet2:aCols[1][1])
			oMSGet2:aCols := aClone(_aBkpAcols2)
		EndIf
		oMSGet2:Refresh()
	EndIf

Return lDuplic

/*/{Protheus.doc} zPrettyXML
Função que serve para quebrar um XML e deixá-lo indentado para o usuário
@author Atilio
@since 13/05/2018
@version 1.0
@param cTextoOrig, characters, descricao
@type function
@example Exemplo Abaixo
    //..............
    cTextoOrig := MemoRead("C:\TOTVS\notas\original.xml")
    cTextoNovo := ""

    cTextoNovo := u_zPrettyXML(cTextoOrig)

    Aviso('Atenção', cTextoNovo, {'OK'}, 03)
    //..............
/*/
Static Function zPrettyXML(cTextoOrig)

    Local aArea      := GetArea()
    Local cTextoNovo := ""
    Local aLinhas    := {}
    Local cEspaco    := ""
    Local nAbriu     := 0
    Local nAtual     := 0
    Local aLinNov    := {}

    //Se tiver conteúdo texto, e tiver o trecho de XML
    If ! Empty(cTextoOrig) .And. '<?xml version=' $ cTextoOrig

        //Substitui a fecha chaves para um enter
        /*cTextoNovo := StrTran(cTextoOrig, "</",                "zPrettyXML_QUEBR")
        cTextoNovo := StrTran(cTextoNovo, "<",                 CRLF + "<")
        cTextoNovo := StrTran(cTextoNovo, ">",                 ">" + CRLF)
        cTextoNovo := StrTran(cTextoNovo, "zPrettyXML_QUEBR",  CRLF + "</")*/
        cTextoNovo := StrTran(cTextoOrig, "><",                 ">" + CRLF + "<")

        //Pega todas as linhas
        aLinhas := StrTokArr(cTextoNovo, CRLF)

        //Percorre as linhas adicionando espaços em branco
        For nAtual := 1 To Len(aLinhas)
            //Somente se tiver conteúdo
            If ! Empty(aLinhas[nAtual])

                //Se for abertura de tag, e não for fechamento na mesma linha, aumenta a tabulação
                If "<" $ aLinhas[nAtual] .And. ! "<?" $ aLinhas[nAtual] .And. ! "</" $ aLinhas[nAtual] .And. ! "/>" $ aLinhas[nAtual]
                    nAbriu += 1
                EndIf

                //Definindo a quantidade de espaços em branco, conforme número de tags abertas
                cEspaco := ""
                If nAbriu > 0
                    cEspaco := Replicate(' ', 2 * (nAbriu + Iif(! "<" $ aLinhas[nAtual], 1, 0)) )
                EndIf

                //Monta agora o texto com a tabulação
                aAdd(aLinNov, cEspaco + aLinhas[nAtual])

                //Se for fechamento de tag, diminui a tabulação
                If "</" $ aLinhas[nAtual] .And. At('<', SubStr(aLinhas[nAtual], 2, Len(aLinhas[nAtual]))) == 0
                    nAbriu -= 1
                EndIf
            EndIf
        Next

        //Monta agora o texto novo
        cTextoNovo := ""
        For nAtual := 1 TO Len(aLinNov)
            cTextoNovo += aLinNov[nAtual] + CRLF
        Next
    EndIf

    RestArea(aArea)
Return cTextoNovo

//Pega XML da nota
Static Function SpedPExp(cSerie,cNotaIni,cNotaFim,lEnd,dDataDe,dDataAte)

	Local cChvNFe  	:= ""
	Local cIdflush  := cSerie+cNotaIni
	Local cModelo  	:= ""
	Local cURL     	:= PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local cXML		:= ""
	Local lOk      	:= .F.
	Local nX        := 0
	Local oRetorno
	Local oWS
	Local oXml
	Local oAux
	Local cIdEnt   := ""
	Local cCNPJCli := Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_CGC")

	Default cNotaIni:=""
	Default cNotaFim:=""
	Default dDataDe:=CtoD("  /  /  ")
	Default dDataAte:=CtoD("  /  /  ")

	cIdEnt := RetIdEnti()
	IF Empty( cIdEnt )
		MsgAlert("Nao foi Possivel Obter o Codigo da Entidade. Verifique a sua Configuracao do SPED","Atenção")
		Return cXML
	EndIF

	ProcRegua(1)

	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        := "TOTVS"
	oWS:cID_ENT           := cIdEnt
	oWS:_URL              := AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:cIdInicial        := cIdflush
	oWS:cIdFinal          := cIdflush
	oWS:dDataDe           := dDataDe
	oWS:dDataAte          := dDataAte
	oWS:cCNPJDESTInicial  := cCNPJCli
	oWS:cCNPJDESTFinal    := cCNPJCli
	oWS:nDiasparaExclusao := 0
	lOk:= oWS:RETORNAFX()
	oRetorno := oWS:oWsRetornaFxResult
	lOk := iif( valtype(lOk) == "U", .F., lOk )

	If lOk
		ProcRegua(Len(oRetorno:OWSNOTAS:OWSNFES3))

		//Exporta as notas
	    For nX := 1 To Len(oRetorno:OWSNOTAS:OWSNFES3)

	 		oXml    := oRetorno:OWSNOTAS:OWSNFES3[nX]
			oXmlExp := XmlParser(oRetorno:OWSNOTAS:OWSNFES3[nX]:OWSNFE:CXML,"","","")
			cXML	:= ""

			//cVerNfe := IIf(Type("oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT") <> "U", oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT, '')
			cVerNfe	:= ""
			if (oAux := XmlChildEx(oXmlExp,"_NFE"))!=Nil .AND. ;
				(oAux := XmlChildEx(oAux,"_INFNFE"))!=Nil .AND. ;
				(oAux := XmlChildEx(oAux,"_VERSAO"))!=Nil 

				cVerNfe := oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT
			endif

			 If !Empty(oXml:oWSNFe:cProtocolo)
		 		cChvNFe  := NfeIdSPED(oXml:oWSNFe:cXML,"Id")
				cModelo := cChvNFe
				cModelo := StrTran(cModelo,"NFe","")
				cModelo := StrTran(cModelo,"CTe","")
				cModelo := StrTran(cModelo,"MDFe","")
				cModelo := SubStr(cModelo,21,02)

				cCab1 := '<?xml version="1.0" encoding="UTF-8"?>'
				Do Case
					Case cVerNfe <= "1.07"
						cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.portalfiscal.inf.br/nfe procNFe_v1.00.xsd" versao="1.00">'
					Case cVerNfe >= "2.00" .And. "cancNFe" $ oXml:oWSNFe:cXML
						cCab1 += '<procCancNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
					OtherWise
						cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
				EndCase
				cRodap := '</nfeProc>'

	 			cXML := AllTrim(cCab1)
				cXML += AllTrim(oXml:oWSNFe:cXML)
				cXML += AllTrim(oXml:oWSNFe:cXMLPROT)
				cXML += AllTrim(cRodap)

			endif

			IncProc()
		Next nX

	endif

Return cXML

//*********************************************************************
// Tratamento para alterar status da requisição pré U57, usada na venda
// Deve estar posicionado na SL1
//*********************************************************************
User Function TRA028CR(lEstorna)

	Local cQry, _nPosIni
	Default lEstorna := .F.

	cQry := "SELECT U57.R_E_C_N_O_ RECNO "
	cQry += "FROM "+RetSqlName("SE5")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE5 "

	cQry += "INNER JOIN "+RetSqlName("SE1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SE1 "
	cQry += "ON SE1.D_E_L_E_T_ = ' ' "
	cQry += "AND E1_FILIAL = E5_FILIAL "
	_nPosIni := 1
	cQry += "AND E1_PREFIXO = SUBSTRING(E5_DOCUMEN,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("E1_PREFIXO")[1])+") "
	_nPosIni += TamSX3("E1_PREFIXO")[1]
	cQry += "AND E1_NUM = SUBSTRING(E5_DOCUMEN,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("E1_NUM")[1])+") "
	_nPosIni += TamSX3("E1_NUM")[1]
	cQry += "AND E1_PARCELA = SUBSTRING(E5_DOCUMEN,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("E1_PARCELA")[1])+") "
	_nPosIni += TamSX3("E1_PARCELA")[1]
	cQry += "AND E1_TIPO = SUBSTRING(E5_DOCUMEN,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("E1_TIPO")[1])+") "
	_nPosIni += TamSX3("E1_TIPO")[1]
	cQry += "AND E1_LOJA = SUBSTRING(E5_DOCUMEN,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("E1_LOJA")[1])+") "

	cQry += "INNER JOIN "+RetSqlName("U57")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U57 "
	cQry += "ON U57.D_E_L_E_T_ <> '*' "
	_nPosIni := 1
	cQry += "AND U57_PREFIX = SUBSTRING(E1_XCODBAR,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("U57_PREFIX")[1])+") "
	_nPosIni += TamSX3("U57_PREFIX")[1]
	cQry += "AND U57_CODIGO = SUBSTRING(E1_XCODBAR,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("U57_CODIGO")[1])+") "
	_nPosIni += TamSX3("U57_CODIGO")[1]
	cQry += "AND U57_PARCEL = SUBSTRING(E1_XCODBAR,"+cValTOChar(_nPosIni)+","+cValTOChar(TamSX3("U57_PARCEL")[1])+") "

	cQry += "WHERE SE5.D_E_L_E_T_ = ' ' "
	cQry += "AND E5_FILIAL = '"+xFilial("SE5")+"' "
	cQry += "AND E5_PREFIXO = '"+SL1->L1_SERIE+"' "
	cQry += "AND E5_NUMERO = '"+SL1->L1_DOC+"' "
	cQry += "AND E5_TIPO = 'CR ' "
	cQry += "AND E5_CLIFOR = '"+SL1->L1_CLIENTE+"' "
	cQry += "AND E5_LOJA = '"+SL1->L1_LOJA+"' "
	
	if Select("QRYU57") > 0
		QRYU57->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYU57" // Cria uma nova area com o resultado do query
	While QRYU57->(!Eof())
		U57->(DbGoTo(QRYU57->RECNO))

		Reclock("U57",.F.)
			if lEstorna
				U57->U57_XOPERA := ''
				U57->U57_XPDV   := ''
				U57->U57_XESTAC := ''
				U57->U57_XNUMMO	:= ''
				U57->U57_DATAMO	:= STOD('')
				U57->U57_XHORA	:= ''
			else
				U57->U57_XOPERA := SL1->L1_OPERADO
				U57->U57_XPDV   := SL1->L1_PDV
				U57->U57_XESTAC := SL1->L1_ESTACAO
				U57->U57_XNUMMO	:= SL1->L1_NUMMOV
				U57->U57_DATAMO	:= SL1->L1_EMISNF
				U57->U57_XHORA	:= SL1->L1_HORA
			endif
		U57->(MsUnLock())
		U_UREPLICA("U57", 1, U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL), "A")

		QRYU57->(DbSkip())
	EndDo
	QRYU57->(DbCloseArea())

Return

//--------------------------------------------------------------------------------------
// Grava LOG de historico da conferência de caixa
// Operações (cOperac):
//	1 = Fechamento Caixa
//	2 = Forma Pagamento
//	3 = Cheque Troco
//	4 = Compensação
//	5 = Saque/Vale Motorista
//	6 = Depósito
//	7 = Vale Serviço
//	8 = Sangria
//	9 = Suprimento
//	A = Vale Haver
// Tipo Ação (cTpAcao)
//	I=Inclusão;A=Alteração;F=Fechamento;E=Estorno/Exclusão
//--------------------------------------------------------------------------------------
Static Function GrvLogConf(cOperac,cTpAcao,cObs,cDoc,cSerDoc,cCodBar,cChvCH)

	Local nPosForma := 0, nPosVlrApu := 0, nPosTI := 0, nTrocoIni := 0, nPosTF := 0, nTrocoFin := 0, nQtdCups := 0
	Default cObs := "" 
	Default cDoc := "" 
	Default cSerDoc := "" 
	Default cCodBar := "" 
	Default cChvCH := "" 

	If !ChkFile("U0H") //verifica existência de arquivo: U0H - Hist. Movim. Processos Venda
		Return
	EndIf

	//Se estorno do caixa
	If cOperac=="1" .AND. cTpAcao == "E"
		cObs := GetMotivoEst()
	EndIf

	//se fechamento do caixa
	If cOperac=="1" .AND. cTpAcao = "F" //F-Fechamento
		nPosForma  := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_FORMPG"})
		nPosVlrApu := aScan(oGridForma:aHeader, {|x| Alltrim(x[2]) == "LT_VLRAPU"})

		nPosTI := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "SU" }) //Troco Inicial: (+) Suprimento
		nTrocoIni := oGridForma:aCols[nPosTI][nPosVlrApu]

		nPosTF := aScan(oGridForma:aCols, {|x| Alltrim(x[nPosForma]) == "SG" }) //Troco Final: (-) Sangria
		nTrocoFin := oGridForma:aCols[nPosTF][nPosVlrApu]

		nQtdCups := RetQtdCup()
	EndIf

	RecLock("U0H",.T.)

		//chave do caixa
		U0H->U0H_FILIAL := SLW->LW_FILIAL
		U0H->U0H_OPERAD := SLW->LW_OPERADO
		U0H->U0H_NUMMOV := SLW->LW_NUMMOV
		U0H->U0H_ESTACA := SLW->LW_ESTACAO
		U0H->U0H_SERIE  := SLW->LW_SERIE
		U0H->U0H_PDV    := SLW->LW_PDV
		U0H->U0H_DTABER := SLW->LW_DTABERT
		U0H->U0H_HRABER := SLW->LW_HRABERT
		U0H->U0H_DTFECH := SLW->LW_DTFECHA
		U0H->U0H_HRFECH := SLW->LW_HRFECHA

		//definicao do log
		U0H->U0H_OPERAC := cOperac 
		U0H->U0H_TIPCON := cTpAcao //I=Inclusão;A=Alteração;F=Fechamento;E=Estorno/Exclusão
		U0H->U0H_DATA   := Date()
		U0H->U0H_HORA   := Time()
		U0H->U0H_USER   := RetCodUsr()

		//operacao de fechamento de caixa
		If cOperac=="1"
			If cTpAcao = "F" //F-Fechamento
				U0H->U0H_DIFOPE := nGetVDg
				U0H->U0H_DIFAPU := nGetVAp
				U0H->U0H_DIFCX  := nGetSld
				U0H->U0H_TRCINI := nTrocoIni
				U0H->U0H_TRCFIN := nTrocoFin
				U0H->U0H_QTDCUP := nQtdCups
			EndIf
		endif

		//Motivo/Observação da operação e Demais chaves
		U0H->U0H_MOTIVO := cObs
		U0H->U0H_DOC    := cDoc
		U0H->U0H_SERDOC := cSerDoc
		U0H->U0H_CODBAR := cCodBar
		U0H->U0H_CHEQUE := cChvCH

	SLW->(MsUnlock())

Return

//--------------------------------------------------------------------------------------
// Tela para lista o histórico de conferência
//--------------------------------------------------------------------------------------
Static Function ListHist()

	Local oPnlDet
	Local aSX3U0H := FWSX3Util():GetAllFields( "U0H" , .T./*lVirtual*/ )
	Local aCampos := {}
	Local aHeaderEx := {}

	Private oMSGetU0H
	Private aColsU0H := {}
	Private oObsU0H
	Private cObsU0H := ""
	Private oDlgDet

	//removendo do aSX3U0H os campos nao usado
	aEval(aSX3U0H, {|cCampo|  iif(X3Uso(GetSx3Cache(cCampo,"X3_USADO")) .and. cNivel >= GetSx3Cache(cCampo,"X3_NIVEL"), aadd(aCampos,cCampo) , )  })
	
	aHeaderEx := MontaHeader(aCampos)
	U0H->(DbSetOrder(1)) //U0H_FILIAL+U0H_OPERAD+U0H_NUMMOV+U0H_ESTACA+U0H_SERIE+U0H_PDV+DTOS(U0H_DTABER)+U0H_HRABER
	if U0H->(DbSeek(SLW->(LW_FILIAL+LW_OPERADO+LW_NUMMOV+LW_ESTACAO+LW_SERIE+LW_PDV)+DtoS(SLW->LW_DTABERT)+SLW->LW_HRABERT))
		While U0H->(!Eof()) .and. ;
			U0H->U0H_FILIAL  = SLW->LW_FILIAL  .and. ;
			U0H->U0H_OPERAD  = SLW->LW_OPERADO .and. ;
			U0H->U0H_NUMMOV  = SLW->LW_NUMMOV  .and. ;
			U0H->U0H_ESTACA  = SLW->LW_ESTACAO .and. ;
			U0H->U0H_SERIE   = SLW->LW_SERIE   .and. ;
			U0H->U0H_PDV     = SLW->LW_PDV     .and. ;
			DtoS(U0H->U0H_DTABER) = DtoS(SLW->LW_DTABERT) .and. ;
			U0H->U0H_HRABER  = SLW->LW_HRABERT

			aadd(aColsU0H, MontaDados("U0H", aCampos, .F.))

			U0H->(DbSkip())
		EndDo
	else
		aadd(aColsU0H, MontaDados("U0H",aCampos, .T.))
	endif
	
	DEFINE MSDIALOG oDlgDet TITLE "Histórico de Movimentação Processos Caixa" STYLE DS_MODALFRAME FROM 000, 000  TO 500, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,222,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Logs registrados:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	oMSGetU0H := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsU0H)
	oMSGetU0H:oBrowse:bchange := {|| U0H->(DbGoTo(oMSGetU0H:aCols[oMSGetU0H:nAt][len(aCampos)+1])), cObsU0H := U0H->U0H_MOTIVO, oObsU0H:Refresh() }
	oMSGetU0H:oBrowse:bHeaderClick := {|oBrw1,nCol| if(nCol > 0, OrdGrid(@oMSGetU0H, @nCol), )}

	@ 155, 005 SAY "Detalhe/Observações" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 157, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 165, 002 GET oObsU0H VAR cObsU0H OF oPnlDet MULTILINE SIZE 384, 050 COLORS 0, 16777215 PIXEL READONLY

	@ 232, 010 BUTTON oButton1 PROMPT "Imprimir" SIZE 037, 012 OF oDlgDet PIXEL Action U_TRA028IH()
	@ 232, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

Return

//---------------------------------------------
// Função para retornar tipo operacao log caixa
//---------------------------------------------
User Function TRA028OH
	Local cRet := ""
	cRet += "1=Fechamento Caixa;"
	cRet += "2=Forma Pagamento;"
	cRet += "3=Cheque Troco;"
	cRet += "4=Compensação;"
	cRet += "5=Saque/Vale Motorista;"
	cRet += "6=Depósito;"
	cRet += "7=Vale Serviço;"
	cRet += "8=Sangria;"
	cRet += "9=Suprimento;"
	cRet += "A=Vale Haver"
Return cRet

//--------------------------------------------------------------------------------------
// Tela para informar o motivo de estorno
//--------------------------------------------------------------------------------------
Static Function GetMotivoEst()

	Local cMotivo := ""
	Local nQtdMot := SuperGetMV("MV_XQTCEST",,1) // Quantidade mínima de caracteres no motivo de estorno da conferência de caixa.

	While Empty(cMotivo) .or. Len(AllTrim(cMotivo)) < nQtdMot

		//Define Font oFont Name "Mono AS" Size 5, 12
		Define MsDialog oDlgDet Title "Informe o motivo do estorno" From 3, 0 to 340, 417 Pixel

		@ 5, 5 Get oMemo Var cMotivo Memo Size 200, 145 Of oDlgDet Pixel
		oMemo:bRClicked := { || AllwaysTrue() }
		//oMemo:oFont := oFont

		Define SButton From 153, 175 Type 1 Action oDlgDet:End() Enable Of oDlgDet Pixel // OK
		Define SButton From 153, 145 Type 2 Action (oDlgDet:End()) Enable Of oDlgDet Pixel // Cancelar

		Activate MsDialog oDlgDet Center

		If Empty(cMotivo)
			MsgAlert("É obrigatório informar o motivo de estorno.","Atenção")

		ElseIf Len(AllTrim(cMotivo)) < nQtdMot
			MsgAlert("O motivo de estorno deve conter no mínimo "+cValToChar(nQtdMot)+" caracteres.","Atenção")

		EndIf

	EndDo

Return cMotivo

//--------------------------------------------------------------------------------------
// Retorna a quantidade de venda do caixa
//--------------------------------------------------------------------------------------
Static Function RetQtdCup()

	Local nQtdCups := 0
	Local cQry := ""
	Local cCondicao

	//busco vendas dentro do intervalo de datas do caixa
	cCondicao := GetFilSL1("TOP")
	cQry := " SELECT COUNT(*) QTDSL1 "
	cQry += " FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 "
	cQry += " WHERE SL1.D_E_L_E_T_= ' ' AND "+cCondicao

	If Select("QRYQTD") > 0
		QRYQTD->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYQTD" // Cria uma nova area com o resultado do query

	If QRYQTD->(!Eof())
		nQtdCups := QRYQTD->QTDSL1
	EndIf

	QRYQTD->(DbCloseArea())

Return nQtdCups

//--------------------------------------------------------------------------------
// Impressao do log - historico caixa
//--------------------------------------------------------------------------------
User Function TRA028IH()

	Private aParamU0H 	:= {}

	If !ChkFile("U0H") //verifica existência de arquivo: U0H - Hist. Movim. Processos Venda
		Return
	EndIf

	//Definição parametros
	aadd(aParamU0H, {STOD(""), Date()}) //1 data log
	aadd(aParamU0H, {.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.,.T.}) //2 operacao
	aadd(aParamU0H, {.T.,.T.,.T.,.T.}) //3 tipo acao
	aadd(aParamU0H, {Space(TamSX3("U0H_DOC")[1])   ,PADR("",TamSX3("U0H_DOC")[1],"Z")}) //4 doc 
	aadd(aParamU0H, {Space(TamSX3("U0H_SERDOC")[1]),PADR("",TamSX3("U0H_SERDOC")[1],"Z")}) //5 serie 
	aadd(aParamU0H, {Space(TamSX3("U0H_CODBAR")[1]),PADR("",TamSX3("U0H_CODBAR")[1],"Z")}) //6 codbar 
	aadd(aParamU0H, .T.) //7 Detalha Obs
	aadd(aParamU0H, .T.) //8 Filtrar Caixa
	aadd(aParamU0H, {;
		SLW->LW_DTABERT ,;
		SLW->LW_OPERADO ,;
		SLW->LW_ESTACAO ,;
		SLW->LW_PDV ,;
		SLW->LW_NUMMOV, ;
		SLW->LW_DTABERT ;
	}) //9 filtros caixa
	aadd(aParamU0H, "1") //10 Agrupamento
	aadd(aParamU0H, .T.) //11 Imp Total Agrupamento
	aadd(aParamU0H, .T.) //12 Imp Total Geral

	While FiltroU0H()
		CfgHistCX()
	Enddo

Return

//----------------------------------------------------
// configuração relatorio historico caixa
//----------------------------------------------------
Static Function CfgHistCX()

	Local oReport 
	Local oSection,oSection2
	Local nX
	Local aSX3U0H, aCampos := {}

	oReport := TReport():New("TRA028IH","Log Historico do Caixa",/*SX1*/,{|oReport| ImpHistCX(oReport)},"Este relatorio ira imprimir os logs do caixa.",.T.)
	if aParamU0H[10] >= "4"
		oReport:SetLandscape()		// Orientação paisagem 
	else
		oReport:SetPortrait() 		// Orientação retrato
	endif

	oSection := TRSection():New(oReport,OemToAnsi("Logs Caixa"),{"U0H"})
	oSection:SetHeaderPage(.T.)
	oSection:SetHeaderSection(.T.)

	aSX3U0H := FWSX3Util():GetAllFields( "U0H" , .T./*lVirtual*/ )
	//removendo do aSX3U0H os campos nao usado
	aEval(aSX3U0H, {|cCampo|  iif(X3Uso(GetSx3Cache(cCampo,"X3_USADO")) .and. cNivel >= GetSx3Cache(cCampo,"X3_NIVEL"), aadd(aCampos,cCampo) , )  })

	for nX := 1 to len(aCampos)
		if Alltrim(aCampos[nX]) $ "U0H_MOTIVO,U0H_DIFOPE,U0H_DIFAPU,U0H_DIFCX,U0H_TRCINI,U0H_TRCFIN,U0H_QTDCUP"
			//nao adiciona
		elseif GetSx3Cache(aCampos[nX],"X3_CONTEXT") = "V" //virtual
			TRCell():New(oSection,aCampos[nX] , "U0H",,,,, &("{|| CriaVar('"+aCampos[nX]+"') }") )
		else
			TRCell():New(oSection,aCampos[nX] ,"U0H")
		endif
	next nX

	TRCell():New(oSection,"CHAVECX", "U0H","Chave Caixa",,035,, {|| DTOC(U0H->U0H_DTABER)+" "+Alltrim(U0H->U0H_OPERAD) + "-" + Alltrim(Posicione('SA6',1,xFilial('SA6')+U0H->U0H_OPERAD,'A6_NOME')) +" "+Alltrim(U0H->U0H_ESTACA)+" "+Alltrim(U0H->U0H_PDV)+" "+U0H->U0H_NUMMOV } )

	if aParamU0H[7]
		oSection2 := TRSection():New(oSection,OemToAnsi("Observações"),{"U0H"})
		TRCell():New(oSection2,"U0H_MOTIVO", "U0H",,,200,, {|| cObserv } )
		oSection2:SetHeaderSection(.F.)
		oSection2:nLeftMargin := 5
	endif

	if aParamU0H[11] .OR. aParamU0H[12]
		TRFunction():New(oSection:Cell("U0H_TIPCON"),"TOTAL" ,"COUNT",,"Qtd. Operações Realizadas:","@E 999999",,aParamU0H[11],aParamU0H[12])
	endif

	oReport:PrintDialog()
	//oReport:Print()

	oReport := Nil
	oSection := Nil
	if aParamU0H[7]
		oSection2 := Nil
	endif

Return

//--------------------------------------------------------------------------------
// Processamento da impressao do relatorio
//--------------------------------------------------------------------------------
Static Function ImpHistCX(oReport)

	Local oSection 	:= oReport:Section(1)
	Local oSection2
	Local cQry := ""
	Local nX, cIn
	Local nOrdem := Val(aParamU0H[10]) //Agrupador do relatório
	Local cAgrup := ""
	Local cChvAg := ""
	Local aAgrup := {"CAIXA: ","OPERAÇÃO: ","DATA LOG: ","OPERADOR: ","ESTAÇÃO: "}
	Local aOperac := StrToKArr(U_TRA028OH(),";")
	Private cObserv := ""

	cQry := " SELECT U0H.R_E_C_N_O_ RECU0H "
	cQry += " FROM "+RetSqlName("U0H")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" U0H "
	cQry += " WHERE U0H.D_E_L_E_T_= ' ' "
	cQry += " 	AND U0H_FILIAL  = '" + xFilial("U0H")  + "' "
	cQry += " 	AND U0H_DATA   BETWEEN '"+DTOS(aParamU0H[1][1])+"' AND '"+DTOS(aParamU0H[1][2])+"' "
	cQry += " 	AND U0H_DOC    BETWEEN '"+aParamU0H[4][1]+"' AND '"+aParamU0H[4][2]+"' "
	cQry += " 	AND U0H_SERDOC BETWEEN '"+aParamU0H[5][1]+"' AND '"+aParamU0H[5][2]+"' "
	cQry += " 	AND U0H_CODBAR BETWEEN '"+aParamU0H[6][1]+"' AND '"+aParamU0H[6][2]+"' "

	cIn := ""
	for nX := 1 to len(aParamU0H[2])
		if aParamU0H[2][nX]
			cIn += "'" + iif(nX<10, cValToChar(nX), "A") + "',"
		endif
	next nX
	if !empty(cIn)
		cQry += " 	AND U0H_OPERAC IN ("+SubStr(cIn,1,len(cIn)-1)+") 
	endif
	
	cIn := ""
	if aParamU0H[3][1]
		cIn += "'I',"
	endif
	if aParamU0H[3][2]
		cIn += "'A',"
	endif
	if aParamU0H[3][3]
		cIn += "'E',"
	endif
	if aParamU0H[3][4]
		cIn += "'F',"
	endif
	if !empty(cIn)
		cQry += " 	AND U0H_TIPCON IN ("+SubStr(cIn,1,len(cIn)-1)+") 
	endif

	if aParamU0H[8]
		if !empty(aParamU0H[9][1]) .OR. !empty(aParamU0H[9][6])
			cQry += " 	AND U0H_DTABER  BETWEEN '"+DTOS(aParamU0H[9][1])+"' AND '"+DTOS(aParamU0H[9][6])+"' "
		endif
		if !empty(aParamU0H[9][2])
			cQry += " 	AND U0H_OPERAD  = '" + aParamU0H[9][2] + "' "
		endif
		if !empty(aParamU0H[9][3])
			cQry += " 	AND U0H_ESTACA  = '" + aParamU0H[9][3] + "' "
		endif
		if !empty(aParamU0H[9][4])
			cQry += " 	AND U0H_PDV     = '" + aParamU0H[9][4] + "' "
		endif
		if !empty(aParamU0H[9][5])
			cQry += " 	AND U0H_NUMMOV  = '" + aParamU0H[9][5] + "' "
		endif
	endif
	
	//"1=Caixa","2=Operação","3=Data Log","4=Operador","5=Estação"
	if nOrdem == 1
		cQry += " ORDER BY U0H_DTABER, U0H_OPERAD, U0H_ESTACA, U0H_PDV, U0H_NUMMOV, R_E_C_N_O_ "
		cChvAg := 'DTOC(U0H->U0H_DTABER)+" "+Alltrim(U0H->U0H_OPERAD)+"-"+Alltrim(Posicione("SA6",1,xFilial("SA6")+U0H->U0H_OPERAD,"A6_NOME"))+" "+Alltrim(U0H->U0H_ESTACA)+" "+Alltrim(U0H->U0H_PDV)+" "+U0H->U0H_NUMMOV'
		oSection:SetTotalText("Total do Caixa")
	elseif nOrdem == 2
		cQry += " ORDER BY U0H_OPERAC, R_E_C_N_O_ "
		cChvAg := "aOperac[aScan(aOperac,{|x| SubStr(x,1,1) == U0H->U0H_OPERAC })]"
		oSection:SetTotalText("Total da Operação")
	elseif nOrdem == 3
		cQry += " ORDER BY U0H_DATA, R_E_C_N_O_ "
		cChvAg := "DTOC(U0H->U0H_DATA)"
		oSection:SetTotalText("Total da Data")
	elseif nOrdem == 4
		cQry += " ORDER BY U0H_OPERAD, R_E_C_N_O_ "
		cChvAg := "U0H->U0H_OPERAD + ' - ' + Posicione('SA6',1,xFilial('SA6')+U0H->U0H_OPERAD,'A6_NOME')"
		oSection:SetTotalText("Total do Operador")
	elseif nOrdem == 5
		cQry += " ORDER BY U0H_ESTACA, R_E_C_N_O_ "
		cChvAg := "U0H->U0H_ESTACA"
		oSection:SetTotalText("Total da Estação")
	endif

	If Select("QRYU0H") > 0
		QRYU0H->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYU0H" // Cria uma nova area com o resultado do query

	//ajusto colunas conforme agrupamento selecionado
	//"1=Caixa","2=Operação","3=Data Log","4=Operador","5=Estação"
	if nOrdem == 1
		oSection:Cell("CHAVECX"):Disable()
	elseif nOrdem == 2
		oSection:Cell("U0H_OPERAC"):Disable()
	elseif nOrdem == 3
		oSection:Cell("U0H_DATA"):Disable()
	endif

	if aParamU0H[7]
		oSection2 := oReport:Section(1):Section(1)
	endif

	if QRYU0H->(!Eof())
		While QRYU0H->(!Eof())
			cObserv := ""

			If oReport:Cancel()
				Exit
			EndIf

			U0H->(DbGoTo( QRYU0H->RECU0H ))

			//agrupamento
			if cAgrup <> &(cChvAg)
				if !empty(cAgrup)
					if aParamU0H[7]
						oSection2:Finish()
					endif
					oSection:Finish()
				endif

				oReport:SkipLine()
				oReport:PrintText(UPPER(aAgrup[nOrdem] + &(cChvAg)))
	    		oReport:ThinLine()
				if empty(cAgrup)
					oReport:SkipLine()
				endif
				
				cAgrup := &(cChvAg)

				oSection:Init()

				if aParamU0H[7]
					oSection2:Init(.F.)
				endif
			endif

			oSection:PrintLine()

			if aParamU0H[7]
				cObserv := U0H->U0H_MOTIVO
				
				//se fechamento de caixa
				if U0H->U0H_OPERAC == "1" .AND. U0H->U0H_TIPCON == "F"
					cObserv += "Dif.Operador.: " + Alltrim(Transform(U0H->U0H_DIFOPE, "@E 999,999,999.99"))
					cObserv += "  Dif.Apurado.: " + Alltrim(Transform(U0H->U0H_DIFAPU, "@E 999,999,999.99"))
					cObserv += "  Dif.Caixa.: " + Alltrim(Transform(U0H->U0H_DIFCX, "@E 999,999,999.99"))
					cObserv += "  Suprimento.: " + Alltrim(Transform(U0H->U0H_TRCINI, "@E 999,999,999.99"))
					cObserv += "  Sangria.: " + Alltrim(Transform(U0H->U0H_TRCFIN, "@E 999,999,999.99"))
					cObserv += "  Qtd Cup.: " + Alltrim(Transform(U0H->U0H_QTDCUP, "@E 999,999,999"))
				endif

				if !empty(cObserv)
					oSection2:PrintLine()
				endif
			endif

			QRYU0H->(DbSkip())
		EndDo

		if aParamU0H[7]
			oSection2:Finish()
		endif
		oSection:Finish()

	endif
	QRYU0H->(DbCloseArea())

Return

Static Function FiltroU0H()

	Local oDlg
	Local lRet := .F.

  	DEFINE MSDIALOG oDlg TITLE "Filtros do Reltório" FROM 000, 000  TO 600, 470 COLORS 0, 16777215 PIXEL

    @ 011, 007 SAY oSay1 PROMPT "Data Log de" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 010, 065 MSGET oGet1 VAR aParamU0H[1][1] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 011, 150 SAY oSay2 PROMPT "até" SIZE 016, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 010, 167 MSGET oGet2 VAR aParamU0H[1][2] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    
    @ 030, 007 SAY oSay3 PROMPT "Operação" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 029, 065 GROUP oGroup1 TO 086, 227 OF oDlg COLOR 0, 16777215 PIXEL
    @ 035, 070 CHECKBOX oCheckBo1 VAR aParamU0H[2][1] PROMPT "Fechamento Caixa" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 045, 070 CHECKBOX oCheckBo2 VAR aParamU0H[2][2] PROMPT "Forma Pagamento" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 055, 070 CHECKBOX oCheckBo3 VAR aParamU0H[2][3] PROMPT "Cheque Troco" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 065, 070 CHECKBOX oCheckBo4 VAR aParamU0H[2][4] PROMPT "Compensação" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 075, 070 CHECKBOX oCheckBo5 VAR aParamU0H[2][5] PROMPT "Saque/Vale Motorista" SIZE 065, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 035, 157 CHECKBOX oCheckBo6 VAR aParamU0H[2][6] PROMPT "Depósito PDV" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 045, 157 CHECKBOX oCheckBo7 VAR aParamU0H[2][7] PROMPT "Vale Serviço" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 055, 157 CHECKBOX oCheckBo8 VAR aParamU0H[2][8] PROMPT "Sangria" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 065, 157 CHECKBOX oCheckBo9 VAR aParamU0H[2][9] PROMPT "Suprimento" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 075, 157 CHECKBOX oCheckBo10 VAR aParamU0H[2][10] PROMPT "Vale Haver" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL

    @ 092, 007 SAY oSay4 PROMPT "Tipo Ação" SIZE 033, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 091, 065 GROUP oGroup2 TO 118, 227 OF oDlg COLOR 0, 16777215 PIXEL
    @ 096, 070 CHECKBOX oCheckBo11 VAR aParamU0H[3][1] PROMPT "Inclusão" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 096, 157 CHECKBOX oCheckBo12 VAR aParamU0H[3][2] PROMPT "Alteração" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 106, 070 CHECKBOX oCheckBo13 VAR aParamU0H[3][3] PROMPT "Exclusão/Estorno" SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 106, 157 CHECKBOX oCheckBo14 VAR aParamU0H[3][4] PROMPT "Fechamento Cx." SIZE 060, 008 OF oDlg COLORS 0, 16777215 PIXEL

    @ 125, 007 SAY oSay5 PROMPT "Doc. De" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 124, 065 MSGET oGet3 VAR aParamU0H[4][1] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 125, 150 SAY oSay6 PROMPT "até" SIZE 016, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 124, 167 MSGET oGet4 VAR aParamU0H[4][2] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    
    @ 142, 007 SAY oSay7 PROMPT "Serie De" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 141, 065 MSGET oGet5 VAR aParamU0H[5][1] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 142, 150 SAY oSay8 PROMPT "até" SIZE 016, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 141, 167 MSGET oGet6 VAR aParamU0H[5][2] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    
    @ 158, 007 SAY oSay9 PROMPT "Cod.Bar. De" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 157, 065 MSGET oGet7 VAR aParamU0H[6][1] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 158, 150 SAY oSay10 PROMPT "até" SIZE 016, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 157, 167 MSGET oGet8 VAR aParamU0H[6][2] SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL


    @ 176, 007 GROUP oGroup3 TO 236, 227 PROMPT "       Filtrar Caixa" OF oDlg COLOR 0, 16777215 PIXEL
	@ 176, 012 CHECKBOX oCheckBo16 VAR aParamU0H[8] PROMPT space(20) SIZE 146, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 188, 014 SAY oSay11 PROMPT "Data Abertura De" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 186, 065 MSGET oGet9 VAR aParamU0H[9][1] SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 188, 134 SAY oSay12 PROMPT "Data Abertura Ate" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 186, 167 MSGET oGet10 VAR aParamU0H[9][6] SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 204, 014 SAY oSay13 PROMPT "Estação" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 202, 065 MSGET oGet11 VAR aParamU0H[9][3] SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 204, 134 SAY oSay12 PROMPT "Operador" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 202, 167 MSGET oGet10 VAR aParamU0H[9][2] SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 220, 014 SAY oSay14 PROMPT "PDV" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 218, 064 MSGET oGet12 VAR aParamU0H[9][4] SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

    @ 220, 134 SAY oSay15 PROMPT "Num Mov." SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 218, 167 MSGET oGet13 VAR aParamU0H[9][5] SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 240, 007 GROUP oGroup3 TO 277, 227 PROMPT " Configurações Relatório " OF oDlg COLOR 0, 16777215 PIXEL

	@ 252, 014 CHECKBOX oCheckBo15 VAR aParamU0H[7] PROMPT "Detalhar observações do log" SIZE 146, 008 OF oDlg COLORS 0, 16777215 PIXEL
	@ 252, 134 SAY oSay15 PROMPT "Agrupador" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 250, 167 MSCOMBOBOX oComboBo1 VAR aParamU0H[10] ITEMS {"1=Caixa","2=Operação","3=Data Log","4=Operador","5=Estação"} SIZE 053, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 264, 014 CHECKBOX oCheckBo15 VAR aParamU0H[11] PROMPT "Imprimir Total do Agrupador" SIZE 146, 008 OF oDlg COLORS 0, 16777215 PIXEL
	@ 264, 134 CHECKBOX oCheckBo15 VAR aParamU0H[12] PROMPT "Imprimir Total Geral" SIZE 146, 008 OF oDlg COLORS 0, 16777215 PIXEL

    @ 282, 187 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 012 OF oDlg PIXEL ACTION (lRet := .T., oDlg:end())
	oButton1:SetCSS( CSS_BTNAZUL )
    @ 282, 146 BUTTON oButton2 PROMPT "Cancelar" SIZE 037, 012 OF oDlg PIXEL ACTION (lRet := .F., oDlg:end())

  	ACTIVATE MSDIALOG oDlg CENTERED

Return lRet

//--------------------------------------------------------------------------------------
// Totalizador de PIX (PX)
//--------------------------------------------------------------------------------------
User Function T028TPX(nOpcX, aDados, aCampos)

	Local nRet := 0
	Local nX := 0
	Local aDadosAux
	Default nOpcX := ParamIxb[1]
	Default aDados := {}
	Default aCampos := {}

	If lSrvPDV
		If aScan(aCampos, "L4_VALOR") == 0
			aadd(aCampos, "L4_VALOR")
		EndIf
		aDadosAux := BuscaSL4("PDV", nOpcX, aCampos,,"Alltrim(SL4->L4_FORMA) == 'PX'")
		For nX:=1 To Len(aDadosAux)
			nRet+= aDadosAux[nX][aScan(aCampos,"L4_VALOR")]
			aadd(aDados, aClone(aDadosAux[nX]))
		Next
	Else
		If aScan(aCampos, "E1_VLRREAL") == 0
			aadd(aCampos, "E1_VLRREAL")
		EndIf
		aDados := BuscaSE1(aCampos, "E1_TIPO = 'PX'")
		For nX:=1 To Len(aDados)
			nRet+= aDados[nX][aScan(aCampos,"E1_VLRREAL")]
		Next
	EndIf

	If !empty(aCampos) .AND. empty(aDados)
		aadd(aDados, MontaDados("SE1",aCampos, .T.))
	EndIf

Return nRet

//--------------------------------------------------------------------------------------
// Detalhamento de PIX (PX)
//--------------------------------------------------------------------------------------
User Function T028DPX

	Local nX
	Local nOpcX := ParamIxb[1]
	Local oPnlDet
	Local aCampos
	Local aHeaderEx := {}
	Local bAtuPX := {|| oGridDet:aCols := {}, nTotalPX := U_T028TPX(nOpcX, @oGridDet:aCols, aCampos), oGridDet:oBrowse:Refresh(), oTotalPX:Refresh() }
	Private aColsDet := {}
	Private aColsAglut := {}
	Private oTotalPX := 0
	Private nTotalPX := 0
	Private lViewDet := .T.
	Private oButView
	Private oButAglu
	Private oButDeta
	Private oGridDet
	Private oDlgDet

	If lSrvPDV
		aCampos := {"L4_DATA","L4_VALOR","L4_ADMINIS","A1_NOME","L1_DOC","L1_SERIE","L4_OBS"}
	Else
		aCampos := {"A1_CGC","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_VLRREAL","E1_VENCREA","E1_NATUREZ","E1_HIST"}
	EndIf

	DEFINE MSDIALOG oDlgDet TITLE "Detalhamento PIX" STYLE DS_MODALFRAME FROM 000, 000  TO 400, 800 COLORS 0, 16777215 PIXEL

	oPnlDet := TScrollBox():New(oDlgDet,05,05,172,390,.F.,.T.,.T.)

	@ 005, 005 SAY "Registros do Sistema" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 007, 002 SAY Replicate("_",384) SIZE 384, 007 OF oPnlDet COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCampos)
	nTotalPX := U_T028TPX(nOpcX, @aColsDet, aCampos)

	//montando aglutinado
	For nX := 1 to len(aColsDet)
		If (nPosAux := aScan(aColsAglut, {|x| x[1] == aColsDet[nX][1] .AND. x[2] == aColsDet[nX][2] })) > 0
			aColsAglut[nPosAux][aScan(aCampos,"E1_VLRREAL")] += aColsDet[nX][aScan(aCampos,"E1_VLRREAL")]
		Else
			aadd(aColsAglut, aClone(aColsDet[nX]) )
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_PREFIXO")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_NUM")] := ""
			aColsAglut[len(aColsAglut)][aScan(aCampos,"E1_PARCELA")] := ""
			aColsAglut[len(aColsAglut)][len(aCampos)+1] := 0
		EndIf
	next nX

	oGridDet := MsNewGetDados():New( 015, 002, 150, 386,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oPnlDet, aHeaderEx, aColsDet)
	oGridDet:oBrowse:bHeaderClick := {|oBrw1,nCol| If(nCol > 0, OrdGrid(@oGridDet, @nCol), )}

	@ 158, 260 SAY "Total PIX:" SIZE 100, 007 OF oPnlDet COLORS 0, 16777215 PIXEL
	@ 155, 325 MSGET oTotalPX VAR nTotalPX When .F. Picture "@E 999,999,999.99" SIZE 060, 010 OF oPnlDet HASBUTTON COLORS 0, 16777215 PIXEL

	If !lSrvPDV
		@ 160, 010 BUTTON oButView PROMPT "Vizualizar Titulo" SIZE 045, 012 OF oDlgDet PIXEL Action VerTitSE1(oGridDet:aCols[oGridDet:nAt][len(aCampos)+1])
		If nOpcX == 4
			@ 160, 060 BUTTON oButton1 PROMPT "Manutenção" SIZE 045, 012 OF oDlgDet PIXEL Action ManutenPX("PX", oGridDet:aCols[oGridDet:nAt][len(aCampos)+1], bAtuPX)
		EndIf
		@ 160, 110 BUTTON oButAglu PROMPT "Ver Aglutinado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
		@ 160, 110 BUTTON oButDeta PROMPT "Ver Detalhado" SIZE 045, 012 OF oDlgDet PIXEL Action AtuAglDet()
		oButDeta:Hide()
	EndIf

	@ 182, 355 BUTTON oButton2 PROMPT "Fechar" SIZE 037, 012 OF oDlgDet PIXEL Action oDlgDet:End()
	oButton2:SetCSS( CSS_BTNAZUL )

	ACTIVATE MSDIALOG oDlgDet CENTERED

	AtuVlrGrid("PX", nOpcX, .T.)

Return

//--------------------------------------------------------------------------------------
// Tela de manutenção de PIX
//--------------------------------------------------------------------------------------
Static Function ManutenPX(cForma, nRecSE1, bRefresh)

	Local lOk := .T.
	Local bValTela
	Local aDadosAux := {}
	Local aDadosBkp := {}
	Local oPanelPX
	Local nOpcRet := 0
	Local nVlrAnt := 0
	Local aCpExtraSE1 := {}
	Local nDifMant := SuperGetMv("MV_XDIFMAN", .F., 0.10) //Valor máximo para acrescentar ou diminuir no valor da manutenção de PIX
	Local cLogCaixa := "AJUSTE MANUTENÇÃO DE PIX:" + CRLF + CRLF
	Local lLogCaixa := SuperGetMv("ES_LOGCCX",,.T.) //ativa log conferencia caixa
	Local nX := 0
	Private oDlgPX

	If Empty(nRecSE1)
		Return
	EndIf

	SE1->(DbGoTo(nRecSE1))

	If !Empty(SE1->E1_BAIXA)
		MsgInfo("O título se encontra baixado. Operação não permitida.","Atenção")
		Return
	EndIf

	nVlrAnt := iif(SE1->E1_VLRREAL > 0, SE1->E1_VLRREAL, SE1->E1_VALOR)

	SAE->(DbSetOrder(1)) //AE_FILIAL+AE_COD
	If !SAE->(DbSeek(xFilial("SAE")+SubStr(SE1->E1_CLIENTE, 1, TamSx3("AE_COD")[1])))
		SAE->(DbSetOrder(2)) //AE_FILIAL+AE_CODCLI
		SAE->(DbSeek(xFilial("SAE")+SE1->E1_CLIENTE))
		While SAE->(!Eof()) .and. (SE1->E1_CLIENTE == SAE->AE_CODCLI .and. SE1->E1_LOJA <> SAE->AE_LOJCLI)
			SAE->(DbSkip())
		EndDo
		If SAE->(Eof()) .or. .not.(SE1->E1_CLIENTE == SAE->AE_CODCLI .and. SE1->E1_LOJA == SAE->AE_LOJCLI)
			MsgInfo("Cadastro de administradora financeira não encontrada. Operação não permitida.","Atenção")
			Return
		EndIf
	EndIf

	If SAE->(Eof())
		MsgInfo("Cadastro de administradora financeira não encontrada. Operação não permitida.","Atenção")
		Return
	EndIf

	//{nValor, cAdmFin, dDataTran, nParcelas}
	aDadosAux := {;
		nVlrAnt,;
		SAE->AE_COD,;
		SE1->E1_EMISSAO,;
		1;
	}

	oDlgPX := TDialog():New(0,0,275,375,"Manutenção de PIX",,,,,,,,,.T.)

	cLogCaixa += "VALOR ANTERIOR: [VALOR] " +Transform(aDadosAux[1],"@E 999,999,999.99")+ " | [ADMIN.FINANCEIRA] " + aDadosAux[2] + CRLF + CRLF

	// crio o panel para mudar a cor da tela
	@ 0, 0 MSPANEL oPanelPX SIZE 100, 100 OF oDlgPX COLORS 0, 16777215
	oPanelPX:Align := CONTROL_ALIGN_ALLCLIENT

	MontaCpPX(cForma, oPanelPX, aDadosAux, .F.)
	bValTela := {|| aDadosAux[1]>0 .AND. !empty(aDadosAux[2]) .AND. aDadosAux[4]>0 .AND. ( aDadosAux[1]>=(nVlrAnt-nDifMant) .AND. aDadosAux[1]<=(nVlrAnt+nDifMant) )  }

	aDadosBkp := aClone(aDadosAux)

	@ 119, 145 BUTTON oBtnOK PROMPT "Confirmar" SIZE 040, 015 OF oDlgPX ACTION iif(Eval(bValTela),(nOpcRet := 1,oDlgPX:End()),MsgInfo("Campos obrigatórios nao preenchidos corretamente! (Valor máximo a ser corrigido no parâmetro [MV_XDIFMAN]: "+cValToChar(nDifMant)+")","Atenção")) PIXEL
	oBtnOK:SetCss(CSS_BTNAZUL)
	@ 119, 100 BUTTON oBtnCanc PROMPT "Cancelar" SIZE 040, 015 OF oDlgPX ACTION oDlgPX:End() PIXEL

	oDlgPX:lCentered := .T.
	oDlgPX:Activate()

	If nOpcRet == 1 //opção "Confirmar"
		nOpcRet := 0
		For nX := 1 to Len(aDadosAux) //verifica se houve alteração dos dados
			If .not.(aDadosAux[nX] == aDadosBkp[nX])
				nOpcRet := 1
				Exit //sai do For
			EndIf
		Next nX
	EndIf

	If nOpcRet <> 1
		Return
	EndIf

	BeginTran()

	SAE->(DbSetOrder(1)) //AE_FILIAL+AE_COD
	SAE->(DbSeek(xFilial("SAE")+SubStr(aDadosAux[2], 1, TamSx3("AE_COD")[1])))

	cCodCli := PadR( Iif(!Empty(SAE->AE_CODCLI), SAE->AE_CODCLI, SAE->AE_COD), TamSX3("A1_COD")[1] ) //adm fin
	cLojCli	:= PadR( Iif(!Empty(SAE->AE_LOJCLI), SAE->AE_LOJCLI, "01"), TamSX3("A1_LOJA")[1] )
	cNomCli := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_NOME")

	//processo alteraçao financeira
	LjMsgRun("Processando alteração dos dados...","Aguarde...",{|| lOk := ProcMntForm(cForma, cCodCli, cLojCli, cNomCli, aDadosAux[3], aDadosAux[1], .T., .T., .F., .T., aCpExtraSE1, .F., aDadosAux) })

	If !lOk
		DisarmTransaction()
	EndIf
	EndTran()

	If lOk .and. lLogCaixa
		cLogCaixa += "NOVO VALOR: [VALOR] " +Transform(aDadosAux[1],"@E 999,999,999.99")+ " | [ADMIN.FINANCEIRA] " + aDadosAux[2] + CRLF
		GrvLogConf("2","A", cLogCaixa, IIF(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC), IIF(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE))
	EndIf

	If bRefresh <> Nil
		EVal(bRefresh)
	EndIf

Return

//----------------------------------------------------------
// Monta campos do PIX - manutencao
//----------------------------------------------------------
Static Function MontaCpPX(cForma, oPnlPX, aDadosAux, lAltParc, nLinCp)

	Local oVlrRec, oAdmFin, oDataTran, oParcelas
	Local nPosAux
	Local aMyAdmFin
	Default nLinCp := 10

	//buscando adm financeiras
	aMyAdmFin := GetAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	
	//adicionando opção em branco no combobox da Adm Fin
	If empty(aMyAdmFin)
		aadd(aMyAdmFin, Space(TamSx3("AE_COD")[1]))
	Else
		aSize(aMyAdmFin, Len(aMyAdmFin)+1)
		aIns(aMyAdmFin,1)
		aMyAdmFin[1] := Space(TamSx3("AE_COD")[1])
	EndIf
	nPosAux := aScan(aMyAdmFin, {|x| x = aDadosAux[2]  } )
	If nPosAux > 0
		aDadosAux[2] := aMyAdmFin[nPosAux]
	EndIf

	@ nLinCp, 010 SAY "Valor do PIX" SIZE 100, 007 OF oPnlPX  PIXEL
	oVlrRec := TGet():New( nLinCp+10, 010,{|u| iif( PCount()==0,aDadosAux[1],aDadosAux[1]:= u)},oPnlPX,090, 013,"@E 999,999,999.99",{|| .T.},,,,,,.T.,,,{|| .T./*lModEdic*/},,,,.F.,.F.,,"L4_VALOR",,,,.T.,.F.)
	nLinCp += 30

  	@ nLinCp, 010 SAY "Adm. Financeira" SIZE 120, 010 OF oPnlPX COLORS 0, 16777215 PIXEL
	oAdmFin := TComboBox():New(nLinCp+10, 010, {|u| If(PCount()>0,aDadosAux[2]:=u,aDadosAux[2])}, aMyAdmFin , 170, 016, oPnlPX, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| .T. } )
	nLinCp += 30

    @ nLinCp, 010 SAY "Data" SIZE 070, 007 OF oPnlPX COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 010 MSGET oDataTran VAR aDadosAux[3] SIZE 090, 013 OF oPnlPX COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL

    @ nLinCp, 100 SAY "Parcelas" SIZE 057, 007 OF oPnlPX COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 100 MSGET oParcelas VAR aDadosAux[4] SIZE 040, 013 OF oPnlPX COLORS 0, 16777215 WHEN lAltParc HASBUTTON PIXEL

Return

//----------------------------------------------------------
// Monta campos do CTF - manutencao
//----------------------------------------------------------
Static Function MontaCpCTF(cForma, oPnlPX, aDadosAux, lAltParc, nLinCp)

	Local oVlrRec, oDataTran, oParcelas
	Local nPosAux
	Local aMyAdmFin
	Default nLinCp := 10

	//buscando adm financeiras
	aMyAdmFin := GetAdmFinan(Alltrim(cForma)) //busco adm fin da forma (funçao padrao)
	
	//adicionando opção em branco no combobox da Adm Fin
	If empty(aMyAdmFin)
		aadd(aMyAdmFin, Space(TamSx3("AE_COD")[1]))
	Else
		aSize(aMyAdmFin, Len(aMyAdmFin)+1)
		aIns(aMyAdmFin,1)
		aMyAdmFin[1] := Space(TamSx3("AE_COD")[1])
	EndIf
	nPosAux := aScan(aMyAdmFin, {|x| x = aDadosAux[2]  } )
	If nPosAux > 0
		aDadosAux[2] := aMyAdmFin[nPosAux]
	EndIf

	@ nLinCp, 010 SAY "Valor do CTF" SIZE 100, 007 OF oPnlPX  PIXEL
	oVlrRec := TGet():New( nLinCp+10, 010,{|u| iif( PCount()==0,aDadosAux[1],aDadosAux[1]:= u)},oPnlPX,090, 013,"@E 999,999,999.99",{|| .T.},,,,,,.T.,,,{|| .T./*lModEdic*/},,,,.F.,.F.,,"L4_VALOR",,,,.T.,.F.)
	nLinCp += 30

  	@ nLinCp, 010 SAY "Adm. Financeira" SIZE 120, 010 OF oPnlPX COLORS 0, 16777215 PIXEL
	aDadosAux[6] := TComboBox():New(nLinCp+10, 010, {|u| If(PCount()>0,aDadosAux[2]:=u,aDadosAux[2])}, aMyAdmFin , 170, 016, oPnlPX, Nil,/*bChange*/,/*bValid*/,,,.T.,,Nil,Nil,{|| .T. } )
	nLinCp += 30

    @ nLinCp, 010 SAY "Data" SIZE 070, 007 OF oPnlPX COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 010 MSGET oDataTran VAR aDadosAux[3] SIZE 090, 013 OF oPnlPX COLORS 0, 16777215 WHEN .F. HASBUTTON PIXEL

    @ nLinCp, 100 SAY "Parcelas" SIZE 057, 007 OF oPnlPX COLORS 0, 16777215 PIXEL
    @ nLinCp+10, 100 MSGET oParcelas VAR aDadosAux[4] SIZE 040, 013 OF oPnlPX COLORS 0, 16777215 WHEN lAltParc HASBUTTON PIXEL

Return

