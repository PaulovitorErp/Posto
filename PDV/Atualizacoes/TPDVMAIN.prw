#include 'protheus.ch'
#include 'parmtype.ch'
#include 'hbutton.ch'
#include 'topconn.ch'
#include 'tbiconn.ch'
#include 'poscss.ch'
#include 'rwmake.ch'

Static aIDEnt := {}
Static cFunClear := ""

/*/{Protheus.doc} TPDVMAIN
Painel Posto Inteligente, para operações diversas

@author Danilo Brito
@since 09/04/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVMAIN()

	Local oTimerAbs
	Local aRes := GetScreenRes()
	Local nWidth, nHeight
	Local cClientDir := GetRemoteIniName()	//Caminho do diretorio do smartclient
	Local lUnix 		:= IsSrvUnix()					//Verifica se eh server linux
	Local nPos 		:= Rat( IIf( lUnix, "/", "\" ), cClientDir ) //Posicao da ultima barra
	Local oImgTotvs
	Local oTotal   := STFGetTot() // Recebe o Objeto totalizador
	Local nTotSale := oTotal:GetValue( "L1_VLRTOT" ) //Total da venda que esta em andamento
	Local lOpenCash := STBOpenCash()

	Private aSavKeys := {}
	Private aMnuKeys := {}

	If !lOpenCash
		STFMessage(ProcName(),"STOP", "Realize a abertura do caixa para executar esta opção." )
		STFShowMessage(ProcName())
		Return .F.
	Endif

	If nTotSale > 0
		STFMessage(ProcName(),"STOP", "Não é possível acessar o painel, venda já iniciada. Fechar ou cancelar a venda." )
		STFShowMessage(ProcName())
		Return .F.
	EndIf

	//valido database com o date server
	if dDataBase <> Date()
		STFMessage(ProcName(),"STOP", "A data do sistema esta diferente da data do sistema operacional. Favor efetuar o logoff do sistema." )
		STFShowMessage(ProcName())
		Return .F.
	endif

	//se vendedor não logou
	if !U_TPVendOn()
		U_TPDVE013() 
	endif

	If !( nPos == 0 )
		cClientDir := SubStr( cClientDir, 1, nPos )
	EndIf

	Private oDlgTPdv
	Private cCadastro := "PAINEL POSTO INTELIGENTE"
	Private bClsTPDVM := {|| iif(ValType(oDlgTPdv)=="O",oDlgTPdv:End(),.T.) }
	Private oMsgRod, cMsgRod := ""
	Private oPnlPrinc, oPnlTop, oPnlMeio, oPnlRod, oPnlMenu, oPnlRotina
	Private aMenusMain := {}
	Private nWPnlMenu := 130
	Private oSayOper, oSayData

	//limpa as tecla atalho
	//LoadKeys()
	U_UKeyCtr() 
	SetKey(VK_F12, bClsTPDVM)

	DEFINE DIALOG oDlgTPdv TITLE cCadastro PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)
	oDlgTPdv:lEscClose := .F.
	oDlgTPdv:nWidth := aRes[1]
	oDlgTPdv:nHeight := aRes[2]
	nWidth := aRes[1]/2
	nHeight := aRes[2]/2

	//pnl Principal
	@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgTPdv
	oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT
	oPnlPrinc:SetCSS( POSCSS (GetClassName(oPnlPrinc), CSS_BG ))

	//pnl Menu topo
	@ 0,0 MSPANEL oPnlTop SIZE nWidth, 25 OF oPnlPrinc
	oPnlTop:SetCSS( POSCSS (GetClassName(oPnlTop), CSS_BAR_TOP ))

	@ 007, 005 SAY oSayTitle PROMPT cCadastro SIZE nWidth,20 OF oPnlTop PIXEL
	oSayTitle:SetCSS( POSCSS (GetClassName(oSayTitle), CSS_BAR_ALERT ))

	@ 005, nWidth-160 SAY oSayOper PROMPT ("PDV: " + cEstacao + "  |  Operador: " + ALLTRIM(cUserName) ) SIZE 100,010 OF oPnlTop COLORS 16777215, 16777215 PIXEL RIGHT
	@ 013, nWidth-160 SAY oSayOper PROMPT ("Vendedor: " + Alltrim(U_TPGetVend(2))) SIZE 100,010 OF oPnlTop COLORS 16777215, 16777215 PIXEL RIGHT

	oBtn1 := TButton():New(002,nWidth-52,"Sair (F12)",oPnlTop ,bClsTPDVM,050,021,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BAR_BUTTON ))
	oBtn1:lCanGotFocus := .F.

	//pnl Rodape
	@ nHeight-25,0 MSPANEL oPnlRod SIZE nWidth, 25 OF oPnlPrinc
	oPnlRod:SetCSS( POSCSS (GetClassName(oPnlRod), CSS_BAR_BOTTOM ))

	@ 007, 010 SAY oMsgRod PROMPT cMsgRod SIZE nWidth,20 OF oPnlRod PIXEL PICTURE "@!"
	oMsgRod:SetCSS( POSCSS (GetClassName(oMsgRod), CSS_BAR_ALERT ))

	@ 009, nWidth-160 SAY oSayData PROMPT (Alltrim(DiaSemana(dDataBase)) + iif(Dow(dDataBase)==1.OR.Dow(dDataBase)==7,"","-Feira") + ", " + DTOC(dDataBase) + "  |  " + SubStr(Time(),1,5)) SIZE 100,010 OF oPnlRod COLORS 16777215, 16777215 PIXEL RIGHT

	@ 005, nWidth-50 BITMAP oImgTotvs ResName "POS_LOGO_TOTVS_HOR_BRANCO.PNG" SIZE 50, 50 OF oPnlRod PIXEL NOBORDER //só visual

	//Painel do meio - Area fora menus e barra rodape
	@ 030,0 MSPANEL oPnlMeio SIZE nWidth, nHeight-55 OF oPnlPrinc
	oPnlMeio:SetCSS( POSCSS (GetClassName(oPnlMeio), CSS_BG ))

	//PAINEL MENU
	@ 000,000 MSPANEL oPnlMenu SIZE nWPnlMenu, (nHeight-55) OF oPnlMeio
	oPnlMenu:SetCSS( POSCSS (GetClassName(oPnlMenu), CSS_PANEL_CONTEXT ))
	AddMainMenus(oPnlMenu)

	@ (nHeight-75), 010 SAY oLblAtalho PROMPT "* CTRL+(NUM.) para abrir rotina" SIZE nWPnlMenu, 010 OF oPnlMenu COLORS 0, 16777215 PIXEL
	oLblAtalho:SetCSS( POSCSS (GetClassName(oLblAtalho), CSS_LABEL_NORMAL))

	//Painel Rotinas
	@ 003,nWPnlMenu+4 MSPANEL oPnlRotina SIZE (nWidth-nWPnlMenu-10), (nHeight-65) OF oPnlMeio
	oPnlRotina:SetCSS( "TPanel{ background-color: #F4F4F4; border-radius: 8px; border: 1px solid #F4F4F4;}" )

	@ 020, 020 SAY oSay1 PROMPT "<h1>Seja Bem Vindo!</h1><br>Este é o Painel Posto Inteligente. Utilize os botões laterais para acessar a rotina desejada." SIZE (nWidth-nWPnlMenu-50), 100 OF oPnlRotina COLORS 0, 16777215 PIXEL HTML
	oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))

	//timer para atualização da hora, a cada 30 segundos
	oTimerAbs := TTimer():New(30000, {|| oSayData:Refresh() }, oDlgTPdv )
	oTimerAbs:Activate()

	ACTIVATE DIALOG oDlgTPdv CENTER

	oDlgTPdv := Nil
	//restaura as teclas atalho
	LoadKeys(.T.)
	U_UKeyCtr(.T.) 
	cFunClear := ""

Return

//----------------------------------------
// Menus
//----------------------------------------
Static Function AddMainMenus(oPnl)

	Local nX := 1
	Local nTop := 5
	Local nSpace := 3
	Local nHeightBtn := 20
	Local cBlExec
	Local cCSSBtn := ""
	Local aRetPE

	//Posições do array menu
	//1 - Objeto Botão
	//2 - Nome do menu a aprecer
	//3 - Função a executar para montagem dos componentes da tela (primeira execução)
	//4 - Função a executar para reset da tela (demais execuções)
	//5 - oPnlRotina - painel da rotina a ser aberta
	//6 - lIsActive - Uso interno para controle da opção aberta
	//7 - cCodUser - codigo do usuário que tem acesso (controle de acesso)
	if SuperGetMV("TP_ACTCMP",,.F.)
		aadd(aMenusMain, {Nil , "Compensação", "TPDVA005", "TPDVA5CL", Nil, .F., "" } )
	endif
	if SuperGetMV("TP_ACTVLS",,.F.)
		aadd(aMenusMain, {Nil , "Vale Serviço", "TPDVA006", "TPDVA6CL", Nil, .F., "" } )
	endif
	if SuperGetMV("TP_ACTSQ",,.F.)
		aadd(aMenusMain, {Nil , "Saque/Vale Motorista", "TPDVA007", "TPDVA7CL", Nil, .F., "" } )
	endif
	if SuperGetMV("TP_ACTDP",,.F.)
		aadd(aMenusMain, {Nil , "Depósito", "TPDVA008", "TPDVA8CL", Nil, .F., "" } )
	endif
	if SuperGetMV("TP_ACTBXTR",,.F.)
		aadd(aMenusMain, {Nil , "Baixa Trocada", "TPDVA009", "TPDVA9CL", Nil, .F., "" } )
	endif
	if !SuperGetMV("MV_LJPLNAB", ,.F.)
		aadd(aMenusMain, {Nil , "Abastecimentos Baixados", "TPDVA002", "TPDVA2CL", Nil, .F., "" } )
	endif
	aadd(aMenusMain, {Nil , "Reimpressão de Documentos", "TPDVA011", "TPDVA11C", Nil, .F., "" } )

	//Ponto de entrada para adicionar novas formas
	if ExistBlock("TPDVMROT")
		aRetPE := ExecBlock("TPDVMROT",.F.,.F.)
		if valtype(aRetPE) == "A"
			For nX := 1 to len(aRetPE)
				aadd(aMenusMain, {Nil , aRetPE[nX][1], aRetPE[nX][2], aRetPE[nX][3], Nil, .F., "" } )
			next nX
		endif
	endif

	For nX := 1 to len(aMenusMain)

		cBlExec := "{|| TrocaPnl("+cValToChar(nX)+") }"
		nTop += nSpace

		aMenusMain[nX][1] := TButton():New(nTop,010,"   " + cValToChar(nX) + " - " + aMenusMain[nX][2],oPnl, &cBlExec ,nWPnlMenu-18,nHeightBtn,,,,.T.,,,,{|| .T.})
		if empty(cCSSBtn)
			cCSSBtn := POSCSS (GetClassName(aMenusMain[nX][1]), CSS_BTN_NORMAL )
			cCSSBtn := StrTran(cCSSBtn, "TButton{", "TButton{text-align: left; ")
		endif
		aMenusMain[nX][1]:SetCSS( cCSSBtn )

		//teclas de atalho para rotinas
		if nX < 10
			//de 50 a 58 são as teclas Ctrl+1 até Ctrl+9
			aadd(aSavKeys, {50+(nX-1), SetKey(50+(nX-1))})
			aadd(aMnuKeys, {50+(nX-1), cBlExec } )
			SetKey(50+(nX-1), &cBlExec )
		endif

		nTop += nHeightBtn

	Next nX

Return

//----------------------------------------
// Ativa painel da opção do menu
//----------------------------------------
Static Function TrocaPnl(nOpcMenu)

	Local nX := 0
	Local cCSSBtn := ""
	Local nRotAtu := ""

	//limpo atalhos menus
	for nX := 1 to len(aMnuKeys)
		SetKey(aMnuKeys[nX][1], Nil)
	next nX

	//ajusta o CSS dos botões
	For nX := 1 to len(aMenusMain)
		If nX == nOpcMenu
			cCSSBtn := POSCSS (GetClassName(aMenusMain[nOpcMenu][1]), CSS_BTN_FOCAL )
			cCSSBtn := StrTran(cCSSBtn, "TButton{", "TButton{text-align: left; ")
			aMenusMain[nOpcMenu][1]:SetCSS( cCSSBtn )
		Else
			cCSSBtn := POSCSS (GetClassName(aMenusMain[nX][1]), CSS_BTN_NORMAL )
			cCSSBtn := StrTran(cCSSBtn, "TButton{", "TButton{text-align: left; ")
			aMenusMain[nX][1]:SetCSS( cCSSBtn )
		EndIf
		if aMenusMain[nX][6]
			nRotAtu := nX
		endif
	Next nX

	//reset na tela nao ativa no momento
	For nX := 1 to len(aMenusMain)
		If nX == nOpcMenu //se é o mesmo menu, nao faz nada
			aMenusMain[nX][6] := .T.
		Else
			aMenusMain[nX][6] := .F.
			If aMenusMain[nX][5] <> Nil
				ExecBlock(aMenusMain[nX][4] ,.F.,.F.) //reset da tela
				aMenusMain[nX][5]:Hide()
			EndIf
		EndIf
	Next nX

	//chamo criação do painel caso ainda nao esteja pronto
	If aMenusMain[nOpcMenu][5] == Nil .or. aMenusMain[nOpcMenu][7] = Nil .or. Empty(aMenusMain[nOpcMenu][7])
		If aMenusMain[nOpcMenu][7] = Nil .or. Empty(aMenusMain[nOpcMenu][7])
			If aMenusMain[nOpcMenu][5] <> Nil
				//FreeObj(aMenusMain[nOpcMenu][5])
				aMenusMain[nOpcMenu][5] := Nil
			EndIf
		EndIf
		@ 0,0 MSPANEL aMenusMain[nOpcMenu][5] SIZE oPnlRotina:nWidth/2, oPnlRotina:nHeight/2 OF oPnlRotina
		aMenusMain[nOpcMenu][7] := &("U_"+aMenusMain[nOpcMenu][3]+"(aMenusMain["+cValToChar(nOpcMenu)+"][5])")
	Else
		if nRotAtu <> nOpcMenu
			ExecBlock(aMenusMain[nOpcMenu][4] ,.F.,.F.) 
		endif
		aMenusMain[nOpcMenu][5]:Show()
	EndIf

	cFunClear := aMenusMain[nOpcMenu][4]

	U_SetMsgRod("") //limpo mensagem

	//restauro atalhos menus
	for nX := 1 to len(aMnuKeys)
		SetKey(aMnuKeys[nX][1], &(aMnuKeys[nX][2]) )
	next nX

Return

//----------------------------------------
//Teclas de atalho
//----------------------------------------
Static Function LoadKeys(lRestaura)

	Local nX
	Default lRestaura := .F.

	if lRestaura
		for nX := 1 to len(aSavKeys)
			SetKey(aSavKeys[nX][1], aSavKeys[nX][2])
		next nX
	endif

Return

/*/{Protheus.doc} SetMsgRod
Seta mensagem no rodape
@author thebr
@since 12/02/2019
@version 1.0
@return Nil
@param cMensagem, characters, descricao
@type function
/*/
User Function SetMsgRod(cMensagem)
	cMsgRod := cMensagem
	oMsgRod:Refresh()
Return


User Function TpGetFClear()
Return cFunClear

