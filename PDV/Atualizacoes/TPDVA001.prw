#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'
#include 'tbiconn.ch'
#include 'poscss.ch'
#include 'rwmake.ch'

Static aCpoItens := {"HEIGHT","L2_ITEM","L2_PRODUTO","L2_DESCRI","L2_QUANT","L2_VRUNIT","L2_VLRITEM","L2_DESC","L2_VALDESC","L2_LOCAL","L2_MIDCOD","L2_VEND"}

/*/{Protheus.doc} TPDVA001
Cadastro de Orçamentos no PDV

@author Pablo Nunes
@since 25/09/2018
@version 1.0
@return Nil

@type function
/*/
User Function TPDVA001()

	Local aRes := GetScreenRes()
	Local oPnlPrinc, oPnlMenu, oPnlRod, oPnlLogo, oImgTotvs, oPnlRight, oLogoCli, oPnlLeft, oPnlGrid, oPnlTop, oPnlBot, oPnlGdOrc, oPnlGdIts
	Local nWidth, nHeight
	Local cClientDir 	:= GetRemoteIniName()	//Caminho do diretorio do smartclient
	Local lUnix 		:= IsSrvUnix()					//Verifica se eh server linux
	Local nPos 			:= Rat( IIf( lUnix, "/", "\" ), cClientDir ) //Posicao da ultima barra
	Local lMostraCod	  := SuperGetMV("MV_XCODBAR",.T.,.F.) //Indica se eh obrigatorio na inclusao de produtos apenas pelo codigo (default .F.)
	Local cTpComiss		:= SuperGetMv("MV_LJTPCOM",,"1") // Tipo de calculo de comissao utilizado (1-Para toda a venda (padrao),2-Por item)
	Local lBlqAI0 		:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0
	Local cFiltro		:= ""
	Local aSM0, cNomeEmp, cEndEmp
	Local lPdvOpen := IsInCallStack("STIPOSMAIN")

	If !( nPos == 0 )
		cClientDir := SubStr( cClientDir, 1, nPos )
	EndIf

	Private oPnlMeio, oPnlListOrc, oBtnTroca, oSayTitle
	Private cTitle := "INCLUSÃO DE ORÇAMENTOS"
	Private lPnlListShow := .F.

	Private oMsgRod, cMsgRod := ""
	Private cGetPlaca := SPACE(8)  //SPACE(TamSX3("L1_PLACA")[1])
	Private oGetPlaca
	Private cGetCPF := SPACE(11) //SPACE(TamSX3("DA4_CGC")[1])
	Private oGetCPF
	Private cGetMotor := SPACE(TamSX3("DA4_NOME")[1])
	Private oGetMotor
	Private cGetCli := SPACE(TamSX3("A1_NOME")[1])
	Private oGetCli
	Private cGetCGC := SPACE(TamSX3("A1_CGC")[1])
	Private oGetCGC
	Private cGetCodCli := SPACE(TamSX3("L1_CLIENTE")[1])
	Private oGetCodCli
	Private cGetLoja := SPACE(TamSX3("L1_LOJA")[1])
	Private oGetLoja
	Private oGetVend
	Private cGetVend := Space(TamSX3("A3_COD")[1])
	Private oGetNVen
	Private cGetNVen := Space(TamSX3("A3_NOME")[1])
	Private oGridProd
	Private oGetProd
	Private cGetProd 	:= Space(TamSX3("B1_COD")[1])
	Private oGetBarras
	Private cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
	Private oGetDesc
	Private cGetDesc 	:= Space(TamSX3("B1_DESC")[1])
	Private nGetPreco 	:= 0
	Private oGetPreco
	Private nGetQtd 	:= 1
	Private oGetQtd

	Private nTotQtd		:= 0
	Private nTotSub		:= 0
	Private nTotPrc		:= 0
	Private nTotDes		:= 0
	Private oTotQtd
	Private oTotSub
	Private oTotPrc
	Private oTotDes

	Private cFilPlaca := SPACE(8)
	Private cFilMot := SPACE(11)
	Private cFilCli := SPACE(TamSX3("L1_CLIENTE")[1])
	Private cFilLoja := SPACE(TamSX3("L1_LOJA")[1])
	Private dFilData := dDataBase
	Private oFilPlaca
	Private oFilMot
	Private oFilCli
	Private oFilLoja
	Private oFilData 

	Private oGridOrc
	Private _nCont1	:= "0"
	Private _nCont2	:= 0

	//valido database com o date server
	if dDataBase <> Date()
		STFMessage(ProcName(),"STOP", "A data do sistema esta diferente da data do sistema operacional. Favor efetuar o logoff do sistema." )
		STFShowMessage(ProcName())
		Return
	endif

	/* Inicialização impressoras */
	If !lPdvOpen 
		if !STWOpenDevi()
			Return
		endif
		// Abre a tela em fullscreen
		FWVldFullScreen()
	EndIf

	SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
	If SA3->(DbSeek(xFilial("SA3") + RETCODUSR()))
		cGetVend := SA3->A3_COD
		cGetNVen  := SA3->A3_NOME
	else
		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
			cGetVend := SA3->A3_COD
			cGetNVen  := SA3->A3_NOME
		endif
	EndIf

	//limpa as tecla atalho
	U_UKeyCtr() 

	// -- FORÇA CONTEÚDO DE ALGUNS PARAMETROS DO SIGALOJA
	If cTpComiss != "2"
		PutMvPar("MV_LJTPCOM","2")
	EndIf

	DEFINE DIALOG oDlgOrc TITLE "Orçamentos" PIXEL STYLE nOr(WS_VISIBLE,WS_POPUP)
	oDlgOrc:nWidth := aRes[1]
	oDlgOrc:nHeight := aRes[2]
	nWidth := aRes[1]/2
	nHeight := aRes[2]/2

	//pnl Principal
	@ 0,0 MSPANEL oPnlPrinc SIZE 500, 500 OF oDlgOrc
	oPnlPrinc:Align := CONTROL_ALIGN_ALLCLIENT
	oPnlPrinc:SetCSS( POSCSS (GetClassName(oPnlPrinc), CSS_BG ))

	//pnl Menu
	@ 0,0 MSPANEL oPnlMenu SIZE nWidth, 25 OF oPnlPrinc
	oPnlMenu:SetCSS( POSCSS (GetClassName(oPnlPrinc), CSS_BAR_TOP ))

	@ 007, 010 SAY oSayTitle PROMPT cTitle SIZE nWidth,20 OF oPnlMenu PIXEL
	oSayTitle:SetCSS( POSCSS (GetClassName(oSayTitle), CSS_BAR_ALERT ))

	oBtn1 := TButton():New(002,nWidth-42,"Sair (F12)",oPnlMenu ,{|| oDlgOrc:End() },040,021,,,,.T.,,,,{|| .T.})
	oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BAR_BUTTON ))
	oBtn1:lCanGotFocus := .F.

	oBtnTroca := TButton():New(002,nWidth-109,"Ver Orçamentos",oPnlMenu ,{|| MudaPnl() },065,021,,,,.T.,,,,{|| .T.})
	oBtnTroca:SetCSS( POSCSS (GetClassName(oBtnTroca), CSS_BAR_BUTTON ))
	oBtnTroca:lCanGotFocus := .F.

	//pnl Rodape
	@ nHeight-25,0 MSPANEL oPnlRod SIZE nWidth, 25 OF oPnlPrinc
	oPnlRod:SetCSS( POSCSS (GetClassName(oPnlPrinc), CSS_BAR_BOTTOM ))

	@ 007, 010 SAY oMsgRod PROMPT cMsgRod SIZE nWidth,20 OF oPnlRod PIXEL PICTURE "@!"
	oMsgRod:SetCSS( POSCSS (GetClassName(oMsgRod), CSS_BAR_ALERT ))

	@ 005, nWidth-50 BITMAP oImgTotvs ResName "POS_LOGO_TOTVS_HOR_BRANCO.PNG" SIZE 50, 50 OF oPnlRod PIXEL NOBORDER //só visual


	//Painel do meio - Inclusao orçamento
	@ 030,0 MSPANEL oPnlMeio SIZE nWidth, nHeight-55 OF oPnlPrinc
	oPnlMeio:SetCSS( POSCSS (GetClassName(oPnlMeio), CSS_BG ))

	@ 000,000 MSPANEL oPnlLogo SIZE (nWidth/2), 070 OF oPnlMeio
	oPnlLogo:SetCSS( POSCSS( GetClassName(oPnlLogo), CSS_PANEL_LOGO, "FFFFFF" ) )
	If File( cClientDir + "logopos.jpg" )
		oLogoCli := TBitmap():New( 15,10,(oPnlLogo:nWidth/2)-(15),(oPnlLogo:nHeight/2)-(20),,,.T.,oPnlLogo,,{||},.F.,.F.,,,.F.,,.T.)
		oLogoCli:Load( Nil , cClientDir + "logopos.jpg" )
	else
		if Findfunction("FindClass") .AND. FindClass("FWSM0Util")
			If Empty(Select("SM0"))
				OpenSM0(cEmpAnt)
			EndIf
			aSM0 := FWSM0Util():GetSM0Data()
			nPos := aScan(aSM0, {|x| alltrim(x[1]) == "M0_NOMECOM" })
			cNomeEmp := 	aSM0[nPos][2] //SM0->M0_NOMECOM		 // Nome da Empresa
			nPos := aScan(aSM0, {|x| alltrim(x[1]) == "M0_ENDENT" })
			cEndEmp	:= 	aSM0[nPos][2] //SM0->M0_ENDENT		// Endereço Empresa
		else
			cNomeEmp := 	SM0->M0_NOMECOM		 // Nome da Empresa
			cEndEmp	:= 	SM0->M0_ENDENT		// Endereço Empresa
		endif
		@ 010,010 SAY oLogoCli PROMPT "<b>" + cNomeEmp + "</b><br>" + cEndEmp + "<br>" SIZE oPnlLogo:nWidth/2-35,40 CENTER OF oPnlLogo PIXEL HTML
		oLogoCli:SetCSS( POSCSS(GetClassName(oLogoCli), CSS_LABEL_HEADER )) 
	endif

	//Painel da Esquerda - Cabeçalho Orçamento
	@ 070,000 MSPANEL oPnlLeft SIZE (nWidth/2), (nHeight-130) OF oPnlMeio
	oPnlLeft:SetCSS( POSCSS (GetClassName(oPnlLeft), CSS_PANEL_CONTEXT ))

	oLblPla:= TSay():New(010, 010,{||"Informe a Placa"},oPnlLeft,,,,,,.T.,,,,)
	oLblPla:SetCSS( POSCSS (GetClassName(oLblPla), CSS_LABEL_FOCAL ))
	oGetPlaca := TGet():New(020, 010,{|u| If(PCount()>0,cGetPlaca:=u,cGetPlaca)},oPnlLeft, 073, 015,"@!R NNN-9N99",{|| ValidaPla() },,,,,,.T.,,,,,,,,,/*"DA3PST"*/,"cGetPlaca")
	oGetPlaca:SetCSS( POSCSS (GetClassName(oGetPlaca), CSS_GET_NORMAL ))

	@ 045, 010 SAY oLblCPF PROMPT "CPF Motorista" SIZE 080, 008 OF oPnlLeft FONT COLORS 0, 16777215 PIXEL
	oLblCPF:SetCSS( POSCSS (GetClassName(oLblCPF), CSS_LABEL_FOCAL ))
	@ 055, 010 MSGET oGetCPF VAR cGetCPF SIZE 090, 015 OF oPnlLeft VALID (ValidaMot()) FONT PICTURE "@R 999.999.999-99" COLORS 0, 16777215 PIXEL HASBUTTON //F3 "DA4PDV" 
	oGetCPF:SetCSS( POSCSS (GetClassName(oGetCPF), CSS_GET_NORMAL ))
	TSearchF3():New(oGetCPF,400,250,"DA4","DA4_CGC",{{"DA4_NOME",2}},"",{{"DA4_NOME"}})

	@ 045, 100 SAY oLblNome PROMPT "Nome Motorista" SIZE 080, 008 OF oPnlLeft FONT COLORS 0, 16777215 PIXEL
	oLblNome:SetCSS( POSCSS (GetClassName(oLblNome), CSS_LABEL_FOCAL ))
	@ 055, 100 MSGET oGetMotor VAR cGetMotor SIZE ((oPnlLeft:nWidth/2)-105), 015 OF oPnlLeft VALID (ValidaMot()) FONT PICTURE "@!" COLORS 0, 16777215 PIXEL HASBUTTON READONLY //F3 "DA4PDV" 
	oGetMotor:SetCSS( POSCSS (GetClassName(oGetMotor), CSS_GET_NORMAL ))

	@ 080, 010 SAY oLblCGC PROMPT "CPF/CNPJ" SIZE 050, 008 OF oPnlLeft FONT COLORS 0, 16777215 PIXEL
	oLblCGC:SetCSS( POSCSS (GetClassName(oLblCGC), CSS_LABEL_FOCAL ))
	@ 090, 010 MSGET oGetCGC VAR cGetCGC VALID (ValidaCli()) SIZE 090, 015 OF oPnlLeft FONT PICTURE "@R 99999999999999" COLORS 0, 16777215 PIXEL HASBUTTON //F3 "SA1PDV" 
	oGetCGC:SetCSS( POSCSS (GetClassName(oGetCGC), CSS_GET_NORMAL ))
	
	// bloqueio de filiais
	if lBlqAI0
		cFiltro := " .AND. Posicione('AI0',1,xFilial('AI0')+SA1->A1_COD+SA1->A1_LOJA,'AI0_XBLFIL')!='S'"
	elseIf SA1->(FieldPos("A1_XFILBLQ")) > 0 
		cFiltro := " .AND. (Empty(SA1->A1_XFILBLQ) .OR. !(cFilAnt $ SA1->A1_XFILBLQ))"
	EndIf
	TSearchF3():New(oGetCGC,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'"+cFiltro,{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}})

	@ 080, 100 SAY oLblCod PROMPT "Cliente" SIZE 050, 008 OF oPnlLeft FONT COLORS 0, 16777215 PIXEL
	oLblCod:SetCSS( POSCSS (GetClassName(oLblCod), CSS_LABEL_FOCAL ))
	@ 090, 100 MSGET oGetCodCli VAR cGetCodCli VALID (ValidaCli()) SIZE 060, 015 OF oPnlLeft FONT PICTURE "@!" COLORS 0, 16777215 PIXEL HASBUTTON READONLY //F3 "SA1"
	oGetCodCli:SetCSS( POSCSS (GetClassName(oGetCodCli), CSS_GET_NORMAL ))

	@ 080, 165 SAY oLblLj PROMPT "Loja" SIZE 030, 008 OF oPnlLeft FONT COLORS 0, 16777215 PIXEL
	oLblLj:SetCSS( POSCSS (GetClassName(oLblLj), CSS_LABEL_FOCAL ))
	@ 090, 165 MSGET oGetLoja VAR cGetLoja VALID (ValidaCli()) SIZE 025, 015 OF oPnlLeft FONT PICTURE "@!" COLORS 0, 16777215 PIXEL HASBUTTON READONLY 
	oGetLoja:SetCSS( POSCSS (GetClassName(oGetLoja), CSS_GET_NORMAL ))

	@ 115, 010 SAY oLblCli PROMPT "Nome do Cliente" SIZE 080, 008 OF oPnlLeft FONT COLORS 0, 16777215 PIXEL
	oLblCli:SetCSS( POSCSS (GetClassName(oLblCli), CSS_LABEL_FOCAL ))
	@ 125, 010 MSGET oGetCli VAR cGetCli  VALID (ValidaCli()) SIZE ((oPnlLeft:nWidth/2)-15), 015 OF oPnlLeft FONT PICTURE "@!" COLORS 0, 16777215 PIXEL HASBUTTON READONLY //F3 "SA1PDV"
	oGetCli:SetCSS( POSCSS (GetClassName(oGetCli), CSS_GET_NORMAL ))

	@ 150, 010 SAY oLblVend PROMPT "Vendedor" SIZE 040, 010 OF oPnlLeft COLOR 0, 16777215 PIXEL
	oLblVend:SetCSS( POSCSS (GetClassName(oLblVend), CSS_LABEL_FOCAL ))
	@ 160, 010 MSGET oGetVend VAR cGetVend SIZE 090, 015 HASBUTTON  OF oPnlLeft VALID (ValidaVend()) COLORS 0, 16777215 PIXEL //F3 "SA3"
	oGetVend:SetCSS( POSCSS (GetClassName(oGetVend), CSS_GET_NORMAL ))
	TSearchF3():New(oGetVend,400,180,"SA3","A3_COD",{{"A3_NOME",2}},"",)

	@ 150, 100 SAY oLblNomeV PROMPT "Nome Vendedor" SIZE 080, 010 OF oPnlLeft COLOR 0, 16777215 PIXEL
	oLblNomeV:SetCSS( POSCSS (GetClassName(oLblNomeV), CSS_LABEL_FOCAL ))
	@ 160, 100 MSGET oGetNVen VAR cGetNVen SIZE ((oPnlLeft:nWidth/2)-122), 015 OF oPnlLeft COLORS 0, 16777215 PIXEL READONLY
	oGetNVen:SetCSS( POSCSS (GetClassName(oGetNVen), CSS_GET_NORMAL ))

	//Painel da Direita - Lançamento de Itens
	@ 000,(nWidth/2) MSPANEL oPnlRight SIZE (nWidth/2), (nHeight-60) OF oPnlMeio

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,100 OF oPnlRight ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
	//oTop:SetCSS("TBitmap{ margin: 15px 10px 0px 5px; padding: 6px; border: 1px solid #FFFFFF; background-color: #FFFFFF; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,050 OF oPnlRight ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ))
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlRight ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlGrid := POSBrwContainer(oContent)

	@ 013, 010 SAY oTitItens PROMPT "Produtos do Orçamento" SIZE 100, 010 OF oPnlRight COLOR 0, 16777215 PIXEL
	oTitItens:SetCSS( POSCSS (GetClassName(oTitItens), CSS_BREADCUMB ))

	@ 035, 010 SAY oLblCdBrr PROMPT "Cód. Barras" SIZE 050, 010 OF oPnlRight COLOR 0, 16777215 PIXEL
	oLblCdBrr:SetCSS( POSCSS (GetClassName(oLblCdBrr), CSS_LABEL_FOCAL ))
	@ 045, 010 MSGET oGetBarras VAR cGetBarras SIZE 080, 013 HASBUTTON OF oPnlRight VALID (ValidaBarras())  COLORS 0, 16777215 PIXEL
	oGetBarras:SetCSS( POSCSS (GetClassName(oGetBarras), CSS_GET_NORMAL ))

	@ 035, 100 SAY oLblCdPrd PROMPT "Cod. Produto" SIZE 050, 010 OF oPnlRight COLOR 0, 16777215 PIXEL
	oLblCdPrd:SetCSS( POSCSS (GetClassName(oLblCdPrd), CSS_LABEL_FOCAL ))
	@ 045, 100 MSGET oGetProd VAR cGetProd SIZE 80, 013 HASBUTTON OF oPnlRight VALID (ValidaCodigo())  COLORS 0, 16777215 PIXEL WHEN !lMostraCod //F3 "SB1PDV" 
	oGetProd:SetCSS( POSCSS (GetClassName(oGetProd), CSS_GET_NORMAL ))
	TSearchF3():New(oGetProd,400,180,"SB1","B1_COD",{{"B1_DESC",3}},"SB1->B1_MSBLQL<>'1'",/*aFldList*/,/*lCssPdv*/,/*nPosition*/,/*nAjustPos*/,/*lBySeek*/,/*aFldRet*/, .T., "DA1", {{"DA1_FILIAL", "B1_FILIAL"},{"DA1_CODPRO","B1_COD"}})
	
	@ 035, 185 SAY oLblQtd PROMPT "Quantidade" SIZE 040, 010 OF oPnlRight COLOR 0, 16777215 PIXEL
	oLblQtd:SetCSS( POSCSS (GetClassName(oLblQtd), CSS_LABEL_FOCAL ))
	@ 045, 185 MSGET oGetQtd VAR nGetQtd SIZE 065, 013 HASBUTTON OF oPnlRight PICTURE "@E 9,999.99" VALID (nGetQtd >= 0)  COLORS 0, 16777215 PIXEL
	oGetQtd:SetCSS( POSCSS (GetClassName(oGetQtd), CSS_GET_NORMAL ))

	//Descrição do Produto
	@ 062, 010 MSGET oGetDesc VAR cGetDesc SIZE (oPnlRight:nWidth/2)-15, 013 OF oPnlRight COLORS 0, 16777215 PIXEL WHEN .F. //READONLY
	oGetDesc:SetCSS( POSCSS (GetClassName(oGetDesc), CSS_GET_NORMAL ))

	@ 080, 010 MSGET oGetPreco VAR ("Prc. Unitário: " + Alltrim(Transform(nGetPreco, "@E 999,999.99"))) SIZE 100, 013 OF oPnlRight COLORS 0, 16777215 PIXEL WHEN .F.//READONLY
	oGetPreco:SetCSS( POSCSS (GetClassName(oGetPreco), CSS_GET_NORMAL ))

	// BOTAO INCLUIR ITEM
	oBtn5 := TButton():New(080,;
							(oPnlRight:nWidth/2)-60,;
							"&Incluir",;
							oPnlRight	,;
							{|| AdicionarItem()},;
							50,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oBtn5:SetCSS( POSCSS (GetClassName(oBtn5), CSS_BTN_FOCAL ))

	// BOTAO EXCLUIR ITEM
	oBtn6 := TButton():New(080,;
							(oPnlRight:nWidth/2)-115,;
							"&Excluir",;
							oPnlRight	,;
							{|| CancelarItem(oGridProd:nAt)},;
							50,;
							15,;
							,,,.T.,;
							,,,{|| .T.})
	oBtn6:SetCSS( POSCSS (GetClassName(oBtn6), CSS_BTN_NORMAL ))

	// crio a msnewgetdados dos produtos
	oGridProd := MsGridProd(000,000,100,100,oPnlGrid)
	oGridProd:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGridProd:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oGridProd:oBrowse:lCanGotFocus := .F.
	oGridProd:oBrowse:nScrollType := 0

	//TOTAIS
	@ (oPnlRight:nHeight/2)-43, 010 SAY oLblVol PROMPT "Volumes:" SIZE 50, 010 OF oPnlRight COLORS 0, 16777215 PIXEL
	oLblVol:SetCSS( POSCSS (GetClassName(oLblVol), CSS_LABEL_NORMAL))
	@ (oPnlRight:nHeight/2)-45, 010 SAY oTotQtd VAR Alltrim(Transform(nTotQtd,"@E 99,999.99")) SIZE 080, 015 OF oPnlRight COLOR 0, 16777215 PIXEL RIGHT
	oTotQtd:SetCSS( POSCSS (GetClassName(oTotQtd), CSS_GET_NORMAL))
	oTotQtd:lActive := .F.

	@ (oPnlRight:nHeight/2)-33, 010 SAY oLblVol PROMPT "Subtotal:" SIZE 50, 010 OF oPnlRight COLORS 0, 16777215 PIXEL
	oLblVol:SetCSS( POSCSS (GetClassName(oLblVol), CSS_LABEL_NORMAL))
	@ (oPnlRight:nHeight/2)-35, 010 SAY oTotSub VAR Alltrim(Transform(nTotSub,"@E 99,999.99")) SIZE 080, 015 OF oPnlRight COLOR 0, 16777215 PIXEL RIGHT
	oTotSub:SetCSS( POSCSS (GetClassName(oTotSub), CSS_GET_NORMAL))
	oTotSub:lActive := .F.

	@ (oPnlRight:nHeight/2)-23, 010 SAY oLblCab PROMPT "Desconto:" SIZE 50, 010 OF oPnlRight COLORS 0, 16777215 PIXEL
	oLblCab:SetCSS( POSCSS (GetClassName(oLblCab), CSS_LABEL_NORMAL))
	@ (oPnlRight:nHeight/2)-25, 010 SAY oTotDes VAR Alltrim(Transform(nTotDes,"@E 99,999.99")) SIZE 080, 015 OF oPnlRight COLOR 0, 16777215 PIXEL RIGHT
	oTotDes:SetCSS( POSCSS (GetClassName(oTotDes), CSS_GET_NORMAL))
	oTotDes:lActive := .F.

	@ (oPnlRight:nHeight/2)-43, (oPnlRight:nWidth/2)-25 SAY oLblTot PROMPT "Total" SIZE 50, 010 OF oPnlRight COLORS 0, 16777215 PIXEL
	oLblTot:SetCSS( POSCSS (GetClassName(oLblTot), CSS_LABEL_NORMAL))

	@ (oPnlRight:nHeight/2)-33, (oPnlRight:nWidth/2)-110 SAY oTotPrc VAR AllTrim(Transform(nTotPrc,"@E 99,999.99")) SIZE 100, 040 OF oPnlRight RIGHT COLOR 0, 16777215 PIXEL
	oTotPrc:SetCSS( POSCSS (GetClassName(oTotPrc), CSS_LABEL_TOTAL))

	// BOTAO CONFIRMAR
	oBtn4 := TButton():New((oPnlLeft:nHeight/2)-40,;
						(oPnlLeft:nWidth/2)-90,;
						"&Gravar Orçamento"+Chr(13)+chr(10)+"(Alt+G)",;
						oPnlLeft	,;
						{|| ConcluiOrc(3) },;
						80,;
						25,;
						,,,.T.,;
						,,,{|| .T.})
	oBtn4:SetCSS( POSCSS (GetClassName(oBtn4), CSS_BTN_FOCAL ))

	oBtn5 := TButton():New((oPnlLeft:nHeight/2)-40,;
						(oPnlLeft:nWidth/2)-175,;
						"Im&primir sem Gravar"+Chr(13)+chr(10)+"(Alt+P)",;
						oPnlLeft	,;
						{|| ImpOrcamento(1, oGridProd:aCols) },;
						80,;
						25,;
						,,,.T.,;
						,,,{|| .T.})
	oBtn5:SetCSS( POSCSS (GetClassName(oBtn5), CSS_BTN_NORMAL ))
	If SuperGetMV("MV_XIMPORC",,.F.)
		oBtn5:Hide()
	EndIf

	// BOTAO LIMPAR
	oBtn3 := TButton():New((oPnlLeft:nHeight/2)-40,010,"&Limpar Tela"+Chr(13)+chr(10)+"(Alt+L)",oPnlLeft,{|| LimpaTela()},080,025,,,,.T.,,,,{|| .T.})
	oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_NORMAL ))


	//Painel do meio - LISTAGEM ORÇAMENTO
	@ 030,0 MSPANEL oPnlListOrc SIZE nWidth, nHeight-55 OF oPnlPrinc
	oPnlListOrc:SetCSS( POSCSS (GetClassName(oPnlListOrc), CSS_BG ))

	//painel cima, orçamentos
	@ 000, 000 MSPANEL oPnlTop SIZE nWidth, (nHeight-180) OF oPnlListOrc

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,050 OF oPnlTop ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
	//oTop:SetCSS("TBitmap{ margin: 15px 10px 0px 5px; padding: 6px; border: 1px solid #FFFFFF; background-color: #FFFFFF; border-top-right-radius: 8px; border-top-left-radius: 8px; }")
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,035 OF oPnlTop ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ))
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlTop ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlGdOrc := POSBrwContainer(oContent)

	@ 013, 010 SAY oTitFil PROMPT "Orçamentos - Filtrar" SIZE 100, 010 OF oPnlTop COLOR 0, 16777215 PIXEL
	oTitFil:SetCSS( POSCSS (GetClassName(oTitFil), CSS_BREADCUMB ))

	oLblPla:= TSay():New(033, 010,{||"Placa:"},oPnlTop,,,,,,.T.,,,,)
	oLblPla:SetCSS( POSCSS (GetClassName(oLblPla), CSS_LABEL_FOCAL ))
	oFilPlaca := TGet():New(030, 035,{|u| If(PCount()>0,cFilPlaca:=u,cFilPlaca)},oPnlTop, 050, 012,"@!R NNN-9N99",{|| DoFiltra() },,,,,,.T.,,,,,,,,,/*"DA3PST"*/,"oFilPlaca")
	oFilPlaca:SetCSS( POSCSS (GetClassName(oFilPlaca), CSS_GET_NORMAL ))

	@ 033, 095 SAY oLblCPF PROMPT "CPF Motorista:" SIZE 080, 008 OF oPnlTop FONT COLORS 0, 16777215 PIXEL
	oLblCPF:SetCSS( POSCSS (GetClassName(oLblCPF), CSS_LABEL_FOCAL ))
	@ 030, 145 MSGET oFilMot VAR cFilMot SIZE 075, 012 OF oPnlTop VALID DoFiltra() FONT PICTURE "@R 999.999.999-99" COLORS 0, 16777215 PIXEL HASBUTTON //F3 "DA4PDV"
	oFilMot:SetCSS( POSCSS (GetClassName(oFilMot), CSS_GET_NORMAL ))
	TSearchF3():New(oFilMot,400,250,"DA4","DA4_CGC",{{"DA4_NOME",2}},"",{{"DA4_NOME"}})

	@ 033, 230 SAY oLblCod PROMPT "Cliente:" SIZE 050, 008 OF oPnlTop FONT COLORS 0, 16777215 PIXEL
	oLblCod:SetCSS( POSCSS (GetClassName(oLblCod), CSS_LABEL_FOCAL ))
	@ 030, 260 MSGET oFilCli VAR cFilCli VALID DoFiltra() SIZE 060, 012 OF oPnlTop FONT PICTURE "@!" COLORS 0, 16777215 PIXEL HASBUTTON //F3 "SA1PDV" 
	oFilCli:SetCSS( POSCSS (GetClassName(oFilCli), CSS_GET_NORMAL ))
	TSearchF3():New(oFilCli,400,250,"SA1","A1_CGC",{{"A1_NOME",2},{"A1_CGC",3},{"A1_COD",1}},"SA1->A1_MSBLQL<>'1'",{{"A1_NOME","A1_EST","A1_MUN"},{"A1_CGC","A1_NOME","A1_EST","A1_MUN"},{"A1_COD","A1_LOJA","A1_NOME","A1_EST","A1_MUN"}})

	@ 033, 330 SAY oLblLj PROMPT "Loja:" SIZE 030, 008 OF oPnlTop FONT COLORS 0, 16777215 PIXEL
	oLblLj:SetCSS( POSCSS (GetClassName(oLblLj), CSS_LABEL_FOCAL ))
	@ 030, 350 MSGET oFilLoja VAR cFilLoja VALID DoFiltra() SIZE 025, 012 OF oPnlTop FONT PICTURE "@!" COLORS 0, 16777215 PIXEL HASBUTTON
	oFilLoja:SetCSS( POSCSS (GetClassName(oFilLoja), CSS_GET_NORMAL ))

	@ 033, 390 SAY oLblDt PROMPT "Data.:" SIZE 035, 008 OF oPnlTop /*FONT oFntLblCab*/ COLORS 0, 16777215 PIXEL
	oLblDt:SetCSS( POSCSS (GetClassName(oLblDt), CSS_LABEL_FOCAL ))
	@ 030, 420 MSGET oFilData VAR dFilData SIZE 060, 013 OF oPnlTop VALID DoFiltra() COLORS 0, 16777215 HASBUTTON PIXEL
	oFilData:SetCSS( POSCSS (GetClassName(oFilData), CSS_GET_NORMAL ))

	oGridOrc := MsGridOrc(oPnlGdOrc, 000, 000, 100, 100 )
	oGridOrc:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGridOrc:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oGridOrc:oBrowse:lCanGotFocus := .F.
	oGridOrc:oBrowse:nScrollType := 0

	// função chamada na mudança de linha do grid de orçamentos para atualizar os itens do orçamento
	oGridOrc:oBROWSE:bChange := {|| RefreshItem()}
	// função chamada no duplo clique do grid de orçamentos
	oGridOrc:oBrowse:bLDblClick := {|| DbClique(oGridOrc)}
	// função chamada no clique do cabeçalho do grid de orçamentos
	oGridOrc:oBrowse:bHeaderClick := {|oBrw1,nCol| if(oGridOrc:oBrowse:nColPos <> 111 .And. nCol == 1,(MarcaTodos(oGridOrc),oBrw1:SetFocus()),)}

	// BOTAO Excluir
	oBtn3 := TButton():New((nHeight-208),nWidth-65,"Excluir",oPnlTop,{|| ExcOrcamento() },050,015,,,,.T.,,,,{|| .T.})
	oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_FOCAL ))

	// BOTAO Imprimir
	oBtn3 := TButton():New((nHeight-208),nWidth-120,"Imprimir",oPnlTop,{|| ImpOrcamento(2) },050,015,,,,.T.,,,,{|| .T.})
	oBtn3:SetCSS( POSCSS (GetClassName(oBtn3), CSS_BTN_FOCAL ))

	//painel baixo itens orçamento
	@ (nHeight-185), 000 MSPANEL oPnlBot SIZE nWidth, 125 OF oPnlListOrc

	@ 000,000 BITMAP oTop RESOURCE "x.png" NOBORDER SIZE 000,025 OF oPnlBot ADJUST PIXEL
	oTop:Align := CONTROL_ALIGN_TOP
	oTop:SetCSS( POSCSS (GetClassName(oTop), CSS_PANEL_HEADER ))
	oTop:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oBottom RESOURCE "x.png" NOBORDER SIZE 000,015 OF oPnlBot ADJUST PIXEL
	oBottom:Align := CONTROL_ALIGN_BOTTOM
	oBottom:SetCSS( POSCSS (GetClassName(oBottom), CSS_PANEL_FOOTER ))
	oBottom:ReadClientCoors(.T.,.T.)

	@ 000,000 BITMAP oContent RESOURCE "x.png" NOBORDER SIZE 000,000 OF oPnlBot ADJUST PIXEL
	oContent:Align := CONTROL_ALIGN_ALLCLIENT
	oContent:ReadClientCoors(.T.,.T.)
	oPnlGdIts := POSBrwContainer(oContent)

	@ 011, 010 SAY oTitItens PROMPT "Itens do Orçamento" SIZE 100, 010 OF oPnlBot COLOR 0, 16777215 PIXEL
	oTitItens:SetCSS( POSCSS (GetClassName(oTitItens), CSS_BREADCUMB ))

	oGridItem := MsGridItem(oPnlGdIts, 000, 000, 100, 100)
	oGridItem:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGridItem:oBrowse:SetCSS( POSCSS("TGRID", CSS_BROWSE) ) //CSS do totvs pdv
	//oGridItem:oBrowse:lCanGotFocus := .F.
	oGridItem:oBrowse:nScrollType := 0

	oPnlListOrc:Hide()

	SetKey(VK_F12, {|| oDlgOrc:End() })

	ACTIVATE DIALOG oDlgOrc CENTER ON INIT (LimpaTela())

	//restaura as teclas atalho
	U_UKeyCtr(.T.) 

	/* Inicialização */
	If !lPdvOpen
		//Fecha comunicacao com perifericos
		STWCloseDevice() 
	EndIf

Return()

/*/{Protheus.doc} MsGridProd
Monta grid de Produtos
@author thebr
@since 07/02/2019
@version 1.0
@return oGetDados
@type function
/*/
Static Function MsGridProd(nTop, nLeft, nBottom, nRight, oObj)

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aAlterFields := {}

	For nX := 1 to Len(aCpoItens)
		if aCpoItens[nX] == "HEIGHT"
			Aadd(aHeaderEx,{" ","HEIGHT",'@BMP',0,0,'','€€€€€€€€€€€€€€','C','','','',''})
		Else
			aadd(aHeaderEx, U_UAHEADER(aCpoItens[nX]) )
		Endif
	Next nX

	// Define field values
	For nX := 1 to Len(aHeaderEx)
		if aHeaderEx[nX][2] == "HEIGHT"
			Aadd(aFieldFill, "FWSKIN_BTN_DIV")
		else
			if aHeaderEx[nX][8] == "N"
				Aadd(aFieldFill, 0)
			elseif aHeaderEx[nX][8] == "D"
				Aadd(aFieldFill, stod(""))
			else
				Aadd(aFieldFill, "")
			endif
		endif
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aClone(aFieldFill))

Return(MsNewGetDados():New( nTop, nLeft, nBottom, nRight, , "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oObj, aHeaderEx, aColsEx))

/*/{Protheus.doc} MsGridOrc
Monta grid de orçamentos
@author thebr
@since 07/02/2019
@version 1.0
@return oGetDados
@type function
/*/
Static Function MsGridOrc(oPanel, nTop, nLeft, nWidth, nHeigth)

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFields := {"MARK","L1_NUM","L1_PLACA","L1_CGCCLI","L1_CLIENTE","L1_LOJA","A1_NOME","L1_EMISSAO","L1_VLRTOT","L1_HORA","L1_VEND","A3_NOME","L1_VALMERC"}
	Local aAlterFields := {}
	Static oMSNewGe1

	If SL1->(FieldPos("L1_CGCMOTO")) > 0
		aFields := {"MARK","L1_NUM","L1_PLACA","L1_CGCMOTO","L1_CLIENTE","L1_LOJA","A1_NOME","L1_EMISSAO","L1_VLRTOT","L1_HORA","L1_VEND","A3_NOME","L1_VALMERC"}
	EndIf

	For nX := 1 to Len(aFields)
		If AllTrim(aFields[nX]) == "MARK"
			Aadd(aHeaderEx,{Space(10),'MARK','@BMP',2,0,'','€€€€€€€€€€€€€€','C','','','',''})
		else
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		EndIf
	Next nX

	// Define field values
	For nX := 1 to Len(aHeaderEx)
		if aHeaderEx[nX][2] == "MARK"
			Aadd(aFieldFill, "LBNO")
		else
			if aHeaderEx[nX][8] == "N"
				Aadd(aFieldFill, 0)
			elseif aHeaderEx[nX][8] == "D"
				Aadd(aFieldFill, stod(""))
			else
				Aadd(aFieldFill, "")
			endif
		endif
	Next nX

	Aadd(aFieldFill, {} ) //itens
	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( nTop, nLeft, nWidth, nHeigth, /*GD_UPDATE*/, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aHeaderEx, aColsEx))

/*/{Protheus.doc} MsGridItem
Monta grid de itens do orçamento
@author thebr
@since 07/02/2019
@version 1.0
@return oGetDados
@type function
/*/
Static Function MsGridItem(oPanel, nTop, nLeft, nWidth, nHeigth)

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFields := {"L2_PRODUTO","L2_DESCRI","L2_LOCAL","L2_QUANT","L2_PRCTAB","L2_VRUNIT","L2_VLRITEM","L2_DESC","L2_VALDESC","L2_VEND","A3_NOME"}
	Local aAlterFields := {}
	Static oMSNewGe1

	For nX := 1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	// Define field values
	For nX := 1 to Len(aHeaderEx)
		if aHeaderEx[nX][8] == "N"
			Aadd(aFieldFill, 0)
		elseif aHeaderEx[nX][8] == "D"
			Aadd(aFieldFill, stod(""))
		else
			Aadd(aFieldFill, "")
		endif
	Next nX

	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)

Return(MsNewGetDados():New( nTop, nLeft, nWidth, nHeigth, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPanel, aHeaderEx, aColsEx))


//----------------------------------------------------------
// Muda painel visualizar orçamentos/incluir orçamento
//----------------------------------------------------------
Static Function MudaPnl()

	SetMsgRod("")

	if lPnlListShow
		oPnlListOrc:Hide()
		oPnlMeio:Show()
		lPnlListShow := .F.
		cTitle := "INCLUSÃO DE ORÇAMENTOS"
		oBtnTroca:cTitle := "Ver Orçamentos"
	else
		oPnlListOrc:Show()
		oPnlMeio:Hide()
		lPnlListShow := .T.
		cTitle := "VISUALIZAÇÃO DE ORÇAMENTOS EM ABERTO"
		oBtnTroca:cTitle := "Inclui Orçamento"
		RefreshOrc()
		RefreshItem()
	endif

Return

//----------------------------------------------------------------------
// Mostra uma mensagem no rodapé
//----------------------------------------------------------------------
Static Function SetMsgRod(cMensagem)
	cMsgRod := cMensagem
	oMsgRod:Refresh()
Return

/*/{Protheus.doc} DoFiltra
Função chamada na validação do campo de placa.
@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function DoFiltra()
	SetMsgRod("Buscando orçamentos... aguarde...")	
	CursorWait()
	RefreshOrc()
	RefreshItem()
	CursorArrow()
Return .T.

/*/{Protheus.doc} RefreshOrc
Função que atualiza o Grid dos orçamentos.

@author pablo
@since 25/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function RefreshOrc()

	Local lRet := .T.
	Local nX
	Local aParam, aResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.

	if ValType(oGridOrc)<>"O"
		Return()
	endif

	oGridOrc:Acols := {}

	aParam := {cFilPlaca, cFilMot, cFilCli, cFilLoja, dFilData}
	aParam := {"U_TPDVA01B",aParam}
	If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@aResult,/*cType*/,/*cKeyOri*/, @nCodRet )
		// Se retornar esses codigos siginifica que a central esta off
		lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
		// Verifica erro de execucao por parte do host
		//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
		lHostError := (nCodRet == -103 .OR. nCodRet == -106)

		If lHostError
			SetMsgRod("Erro de conexão central PDV: " + cValtoChar(nCodRet))
			//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		EndIf

	ElseIf nCodRet == -101 .OR. nCodRet == -108
		SetMsgRod( "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		//Conout( "TPDVA002 - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		lRet := .F.
	Else
		SetMsgRod( "Erro de conexão central PDV: " + cValtoChar(nCodRet))
		//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
		lRet := .F.
	EndIf

	If lRet .AND. lHasConnect .AND. ValType(aResult)=="A" .AND. len(aResult)>0
		oGridOrc:Acols := aClone(aResult)
	endif

	If Empty(oGridOrc:Acols)

		SetMsgRod("Não foram encontrados orçamentos em aberto!")

		aFieldFill := {}

		For nX := 1 To Len(oGridOrc:aHeader)

			If AllTrim(oGridOrc:aHeader[nX,2]) == "MARK"
				Aadd(aFieldFill, "LBNO")
			ElseIf AllTrim(oGridOrc:aHeader[nX,2]) == "LEG"
				Aadd(aFieldFill, "BR_BRANCO")
			ElseIf oGridOrc:aHeader[nX,8] == "N"
				Aadd(aFieldFill,0)
			ElseIf oGridOrc:aHeader[nX,8] == "D"
				Aadd(aFieldFill,CTOD("  /  /    "))
			Else
				Aadd(aFieldFill,"")
			EndIf

		Next nX

		Aadd(aFieldFill, {})
		Aadd(aFieldFill, .F.)
		aadd(oGridOrc:Acols,aFieldFill)
	else
		if len(oGridOrc:Acols) == 1
			SetMsgRod("Foi encontrado " + cValToChar(len(oGridOrc:Acols)) + " orçamento.")
		else
			SetMsgRod("Foram encontrados " + cValToChar(len(oGridOrc:Acols)) + " orçamentos.")
		endif
	EndIf
		
	// atualizo o grid
	oGridOrc:oBrowse:Refresh()

Return

/*/{Protheus.doc} TPDVA01B
Função que atualiza busca orçamentos no host superior

@author thebr
@since 06/09/2019
@version 1.0
@return Nil

@type function
/*/
User Function TPDVA01B(cFilPlaca, cFilMot, cFilCli, cFilLoja, dFilData)

	Local aItens 	:= {}
	Local aFieldIt 	:= {}
	Local aFieldFill 	:= {}
	Local cCondicao		:= ""
	Local aRet := {}
	
	SL1->(DbSetOrder(4)) //L1_FILIAL+DTOS(L1_EMISSAO)

	cCondicao := " SL1->L1_FILIAL = '" + xFilial("SL1") + "'"
	cCondicao += " .AND. DtoS(SL1->L1_EMISSAO) >= '" + DTOS(dFilData) + "'"
	cCondicao += " .AND. Empty(SL1->L1_DOC) "
	cCondicao += " .AND. SL1->L1_SITUA <> '07' " //retiro os cancelados

	If !Empty(cFilPlaca)
		cCondicao += " .AND. SL1->L1_PLACA = '" + cFilPlaca + "' "
	EndIf

	If SL1->(FieldPos("L1_CGCMOTO")) > 0 .and. !Empty(cFilMot)
		cCondicao += " .AND. SL1->L1_CGCMOTO = '" + cFilMot + "' "
	ElseIf !Empty(cFilMot)
		cCondicao += " .AND. SL1->L1_CGCCLI = '" + cFilMot + "' "
	EndIf

	If !Empty(cFilCli)
		cCondicao += " .AND. SL1->L1_CLIENTE = '" + cFilCli + "' "
	EndIf

	If !Empty(cFilLoja)
		cCondicao += " .AND. SL1->L1_LOJA = '" + cFilLoja + "' "
	EndIf

	SL1->(DbGoTop())
	SL1->(DbSeek(xFilial("SL1")+DTOS(dFilData), .T.))
	While SL1->(!EOF()) .and. ;
		SL1->L1_FILIAL == xFilial("SL1") .and. DTOS(SL1->L1_EMISSAO) >= DTOS(dFilData)

		If &(AllTrim(cCondicao))

			aFieldFill := {}
			aItens := {}

			// Comentado por Wellington Gonçalves dia 13/11/2015
			// Foi solicitado pelo Éder que os orçamentos venham desmarcados
			// aadd(aFieldFill, "LBOK")
			aadd(aFieldFill, "LBNO")
			aadd(aFieldFill, SL1->L1_NUM)
			aadd(aFieldFill, SL1->L1_PLACA)
			aadd(aFieldFill, Iif(SL1->(FieldPos("L1_CGCMOTO")) > 0,SL1->L1_CGCMOTO,SL1->L1_CGCCLI))
			aadd(aFieldFill, SL1->L1_CLIENTE)
			aadd(aFieldFill, SL1->L1_LOJA)
			aadd(aFieldFill, Alltrim(RetField("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,'A1_NOME')))
			aadd(aFieldFill, SL1->L1_EMISSAO)
			aadd(aFieldFill, SL1->L1_VLRTOT)
			aadd(aFieldFill, SL1->L1_HORA)
			aadd(aFieldFill, SL1->L1_VEND)
			aadd(aFieldFill, Alltrim(RetField("SA3",1,xFilial("SA3")+SL1->L1_VEND,'A3_NOME')))
			aadd(aFieldFill, SL1->L1_VALMERC)
			
			//buscando itens
			SL2->(DbSetOrder(1)) // L2_FILIAL + L2_NUM + L2_ITEM + L2_PRODUTO
			If SL2->(DbSeek(xFilial("SL2") + SL1->L1_NUM))
		
				While SL2->(!EOF()) .AND. SL2->L2_FILIAL == xFilial("SL2") .AND. SL2->L2_NUM == SL1->L1_NUM
		
					aFieldIt := {}
		
					aadd(aFieldIt, SL2->L2_PRODUTO)
					aadd(aFieldIt, SL2->L2_DESCRI)
					aadd(aFieldIt, SL2->L2_LOCAL)
					aadd(aFieldIt, SL2->L2_QUANT)
					aadd(aFieldIt, SL2->L2_PRCTAB)
					aadd(aFieldIt, SL2->L2_VRUNIT)
					aadd(aFieldIt, SL2->L2_VLRITEM)
					aadd(aFieldIt, SL2->L2_DESC)
					aadd(aFieldIt, SL2->L2_VALDESC)
					aadd(aFieldIt, SL2->L2_VEND)
					aadd(aFieldIt, Alltrim(RetField("SA3",1,xFilial("SA3")+SL2->L2_VEND,'A3_NOME')))
					aadd(aFieldIt, .F.)
					aadd(aItens,aFieldIt)
		
					SL2->(DbSkip())
		
				EndDo
			endif

			Aadd(aFieldFill, aItens)
			Aadd(aFieldFill, .F.)
			aadd(aRet,aFieldFill)

		EndIf

		SL1->(DbSkip())
	EndDo

Return(aRet)


/*/{Protheus.doc} RefreshItem
Função que atualiza o Grid dos itens do orçamento.

@author pablo
@since 25/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function RefreshItem()

	Local aItens, aFieldFill
	Local nX

	if ValType(oGridItem)<>"O"
		Return()
	endif

	aItens	:= oGridOrc:aCols[oGridOrc:oBrowse:nat][len(oGridOrc:aHeader)+1]
	oGridItem:Acols := aClone(aItens)

	if empty(oGridItem:Acols)

		aFieldFill := {}
		For nX := 1 To Len(oGridItem:aHeader)
			If AllTrim(oGridItem:aHeader[nX,2]) == "MARK"
				Aadd(aFieldFill, "LBNO")
			ElseIf AllTrim(oGridItem:aHeader[nX,2]) == "LEG"
				Aadd(aFieldFill, "BR_BRANCO")
			ElseIf oGridItem:aHeader[nX,8] == "N"
				Aadd(aFieldFill,0)
			ElseIf oGridItem:aHeader[nX,8] == "D"
				Aadd(aFieldFill,CTOD("  /  /    "))
			Else
				Aadd(aFieldFill,"")
			EndIf
		Next nX

		Aadd(aFieldFill, .F.)
		Aadd(oGridItem:Acols,aFieldFill)

	EndIf

	// atualizo o grid
	oGridItem:oBrowse:Refresh()

Return()

/*/{Protheus.doc} DbClique
Função chamada pelo duplo clique no grid.

@author pablo
@since 25/09/2018
@version 1.0
@return Nil
@param _obj, , descricao
@type function
/*/
Static Function DbClique(_obj)

	If _obj:aCols[_obj:nAt][1] == "LBOK"
		_obj:aCols[_obj:nAt][1] := "LBNO"
	Else
		_obj:aCols[_obj:nAt][1] := "LBOK"
	EndIf
	_obj:oBrowse:Refresh()

Return()

/*/{Protheus.doc} MarcaTodos
Função chamada pela ação de clicar no cabeçalho dos grids para selecionar todos os checkbox.
@author pablo
@since 25/09/2018
@version 1.0
@return Nil
@param _obj, , descricao
@type function
/*/
Static Function MarcaTodos(_obj)

	Local nX := 1

	If _nCont1 == "0"
		_nCont1 := "1"
	Else
		If _nCont1 == "1"
			_nCont1 := "2"
		EndIf
	EndIf

	If _nCont1 == "2"
		If _nCont2 == 0
			For nX := 1 TO Len(_obj:aCols)
				_obj:aCols[nX][1] := "LBOK"
			Next
			_nCont2 := 1
		Else
			For nX := 1 TO LEN(_obj:aCols)
				_obj:aCols[nX][1] := "LBNO"
			Next
			_nCont2 := 0
		Endif

		_nCont1:="0"
		_obj:oBrowse:Refresh()
	EndIf

Return()

/*/{Protheus.doc} ValidaPla
Função chamada na validação do campo de placa.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function ValidaPla()
	
	Local aCliByGrp := {}
	Local nPosCliGrp := 1
	Local lBlqAI0 	:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	DbSelectArea("DA3")
	DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
	if DA3->(DbSeek(xFilial("DA3")+cGetPlaca ))

		if empty(cGetCodCli) .OR. (Alltrim(cGetCodCli) == AllTrim(GetMv("MV_CLIPAD")) .AND. Alltrim(cGetLoja) == AllTrim(GetMv("MV_LOJAPAD")))
			if !empty(DA3->DA3_XCODCL)
				cGetCodCli := DA3->DA3_XCODCL
				cGetLoja := DA3->DA3_XLOJCL
				ValidaCli(.T.)

			elseif !empty(DA3->DA3_XGRPCL)
				SA1->(DbSetOrder(6)) //A1_FILIAL+A1_GRPVEN
				If SA1->(DbSeek(xFilial("SA1")+DA3->DA3_XGRPCL)) 
					While SA1->(!Eof()) .AND. SA1->A1_FILIAL+SA1->A1_GRPVEN == xFilial("SA1")+DA3->DA3_XGRPCL
						// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
						If lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
						ElseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
						Else
							aadd(aCliByGrp, {SA1->A1_COD, SA1->A1_LOJA, SA1->A1_NOME, SA1->A1_MUN, SA1->A1_EST, SA1->A1_CGC } )
						EndIf
						SA1->(DbSkip())
					EndDo
				EndIf
				If len(aCliByGrp) > 0
					aSort(aCliByGrp,,,{|x,y| x[1]+x[2] < y[1]+y[2]}) //ordem crescente: A1_COD + A1_LOJA
					If len(aCliByGrp) > 1
						//abrir tela para seleçao cliente
						nPosCliGrp := U_TPDVP08B(aCliByGrp, DA3->DA3_XGRPCL, cGetPlaca)
					EndIf
					cGetCodCli := aCliByGrp[nPosCliGrp][1]
					cGetLoja := aCliByGrp[nPosCliGrp][2]
					ValidaCli(.T.)
				EndIf
			endif
		endif

		if !empty(DA3->DA3_MOTORI)
			cGetCPF := Posicione("DA4",1,xFilial("DA4")+DA3->DA3_MOTORI,"DA4_CGC")
			ValidaMot(.T.)
		endif
	endif

Return .T.

/*/{Protheus.doc} ValidaMot
Função chamada na validação dos campos que consultam o motorista.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function ValidaMot(lGatilho)

	Local lRet 		:= .F.
	Local cCampo	:= ReadVar()
	Default lGatilho := .F.

	if lGatilho
		cCampo := "cGetCpf"
	endif

	if Empty(&cCampo)

		// limpo todos os campos do motorista
		cGetMotor	:= SPACE(TamSX3("DA4_NOME")[1])
		cGetCPF		:= SPACE(TamSX3("DA4_CGC")[1])

		oGetMotor:Refresh()
		oGetCPF:Refresh()

		lRet := .T.

	else

		if Upper(AllTrim(cCampo)) == 'CGETCPF'
			DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
			lRet :=  DA4->(DbSeek(xFilial("DA4") + RTrim(cGetCPF),.T.))
		elseif Upper(AllTrim(cCampo)) == 'CGETMOTOR'
			if empty(cGetCPF)
				DA4->(DbSetOrder(2)) //DA4_FILIAL+DA4_NOME
				lRet := DA4->(DbSeek(xFilial("DA4") + RTrim(cGetMotor)))
			else
				lRet := .T.
			endif
		endif

		if lRet
			// atualizo as variáveis
			cGetMotor	:= PADR(DA4->DA4_NOME,TamSX3("DA4_NOME")[1])
			cGetCPF		:= PADR(DA4->DA4_CGC,TamSX3("DA4_CGC")[1])

			// faço o refresh dos objetos
			oGetMotor:Refresh()
			oGetCPF:Refresh()

		elseif Upper(AllTrim(cCampo)) == 'CGETCPF' .AND. !empty(cGetCPF) .AND. !CGC(AllTrim(cGetCPF))
			lRet := .F.
		else
			SetMsgRod("O motorista informado não está cadastrado!")
			lRet := .F.
		endif

	endif

	if lRet
		SetMsgRod("")
	endif

Return(lRet)

/*/{Protheus.doc} ValidaCli
Função chamada na validação dos campos que consultam o cliente.

@author pablo
@since 26/09/2018
@version 1.0
@return Nil
@param lCliPad, logical, descricao
@type function
/*/
Static Function ValidaCli(lCliPad)

	Local lRet 			:= .T.
	Local cCampo		:= ReadVar()
	Local lBlqAI0 		:= SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	Default lCliPad 	:= .F.

	If lCliPad
		cCampo := "cGetCodCli"
	EndIf

	If !Empty(&cCampo)

		// posiciono no cliente pelo CPF/CNPJ
		If Upper(AllTrim(cCampo)) == 'CGETCGC' .and. !Empty(cGetCGC)

			SA1->(DbSetOrder(3)) //A1_FILIAL+A1_CGC
			If !SA1->(DbSeek(xFilial("SA1") + RTrim(cGetCGC)))
				lRet := .F.
			EndIf

		// posiciono no cliente pelo código e loja
		ElseIf Upper(AllTrim(cCampo)) == 'CGETCODCLI' .or. Upper(AllTrim(cCampo)) == 'CGETLOJA'

			If !Empty(cGetCodCli) .And. Empty(cGetLoja)

				SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
				If !SA1->(DbSeek(xFilial("SA1") + RTrim(cGetCodCli) )) // + iif(Empty(cGetLoja),iif(Alltrim(cGetCodCli)==AllTrim(GetMv("MV_CLIPAD")),AllTrim(GetMv("MV_LOJAPAD")),""),cGetLoja)
					lRet := .F.
				EndIf

			ElseIf !Empty(cGetLoja) // posiciono no cliente pelo código e loja

				If Empty(cGetCodCli) .AND. cGetLoja == AllTrim(GetMv("MV_LOJAPAD"))
					cGetCodCli := AllTrim(GetMv("MV_CLIPAD"))
				EndIf

				SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
				If !SA1->(DbSeek(xFilial("SA1") + cGetCodCli + cGetLoja ))
					lRet := .F.
				EndIf

			EndIf

		// posiciono no cliente pelo nome
		ElseIf Upper(AllTrim(cCampo)) == 'CGETCLI' .and. !Empty(cGetCli)

			SA1->(DbSetOrder(2)) //A1_FILIAL+A1_NOME+A1_LOJA
			If !SA1->(DbSeek(xFilial("SA1") + RTrim(cGetCli)))
				lRet := .F.
			EndIf

		EndIf

		// se encontrou o cliente
		If lRet

			// se o cliente não estiver bloqueado
			If SA1->A1_MSBLQL <> "1"

				// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
				if lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
					lRet := .F.
					Aviso("Atenção!", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial.", {"OK"}, 2)
				elseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
					lRet := .F.
					Aviso("Atenção!", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial.", {"OK"}, 2)
				endif

				If lRet

					// atualizo o conteúdo dos campos da tela do posto
					cGetCli 	:= PADR(SA1->A1_NOME,TamSX3("A1_NOME")[1])
					cGetCGC		:= PADR(SA1->A1_CGC,TamSX3("A1_CGC")[1])
					cGetCodCli	:= PADR(SA1->A1_COD,TamSX3("A1_COD")[1])
					cGetLoja	:= PADR(SA1->A1_LOJA,TamSX3("A1_LOJA")[1])

					// faço o refresh dos objetos
					oGetCli:Refresh()
					oGetCGC:Refresh()
					oGetCodCli:Refresh()
					oGetLoja:Refresh()

				EndIf

			Else
				SetMsgRod("O cadastro deste cliente está bloqueado!")
				lRet := .F.
			EndIf

		Else
			SetMsgRod("O cliente informado é inválido!")
		EndIf

	EndIf

	if lRet
		SetMsgRod("")
	endif

Return(lRet)

/*/{Protheus.doc} ValidaVend
Valida e gatilha vendedor
@author thebr
@since 11/02/2019
@version 1.0
@return nil
@type function
/*/
Static Function ValidaVend()

	Local lRet 			:= .T.

	if !Empty(cGetVend)

		SA3->(DbSetOrder(1))
		if SA3->(DbSeek(xFilial("SA3") + cGetVend))
			If U_TPDVP23A(cGetVend)
				cGetNVen := SA3->A3_NOME
				oGetNVen:Refresh()
			else
				lRet := .F.
				SetMsgRod("O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV.")
			EndIf
		else
			cGetVend := padl(AllTrim(cGetVend),tamsx3("A3_COD")[1],"0")
			oGetVend:Refresh()
			if SA3->(DbSeek(xFilial("SA3") + cGetVend))
				If U_TPDVP23A(cGetVend)
					cGetNVen := SA3->A3_NOME
					oGetNVen:Refresh()
				else
					lRet := .F.
					SetMsgRod("O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV.")
				EndIf
			else
				lRet 	 := .F.
				cGetNVen := ""
				SetMsgRod("O Vendedor informado é inválido!")
			endif
		endif

	else
		cGetNVen := ""
		oGetNVen:Refresh()
	endif

	if lRet
		SetMsgRod("")
	endif

Return(lRet)


/*/{Protheus.doc} ValidaBarras
Valida codigo de barras
@author thebr
@since 11/02/2019
@version 1.0
@return Nil
@type function
/*/
Static Function ValidaBarras()

	Local lRet 			:= .T.
	Local cTpProd	 	:= SuperGetMv("MV_XTPPROD", Nil, "") //Lista de tipos de produtos que podem ser usados no PDV (Ex.: "ME/KT")
	Local cMsgErro		:= ""

	if !Empty(cGetBarras)

		SB1->(DbSetOrder(5)) //B1_FILIAL+B1_CODBAR
		If SB1->(DbSeek(xFilial("SB1")+cGetBarras))

			MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
	    	If SB1->B1_MSBLQL == "1" // se o produto estiver bloqueado para venda

				cGetDesc 	:= ""
				cGetProd	:= Space(TamSX3("B1_COD")[1])
				lRet 		:= .F.
				SetMsgRod("Produto bloqueado para venda.")

			ElseIf MHZ->(DbSeek(xFilial("MHZ")+SB1->B1_COD)) //verifica se é combustivel
				
				cGetDesc 	:= ""
				cGetProd	:= Space(TamSX3("B1_COD")[1])
				lRet := .F.
				Aviso( "", "Produto [combutível] sem permissão para venda via seleção de produto.", {"Ok"} )

	    	ElseIf !Empty(cTpProd) .and. !(SB1->B1_TIPO $ cTpProd)
				
				lRet := .F.
	    		Aviso( "", "O Produto '"+AllTrim(SB1->B1_COD)+" - "+AllTrim(SB1->B1_DESC)+"' está cadastrado com um Tipo de Produto "+;
	    			"('"+SB1->B1_TIPO+" - "+Alltrim(Posicione("SX5",1,xFilial("SX5")+"02"+SB1->B1_TIPO,"X5_DESCRI"))+"') que não está liberado para ser usado no PDV.", {"Ok"} )

	    	Else

				// verifico o preço do produto
				nGetPreco := U_URetPrec(SB1->B1_COD,@cMsgErro, .F.)

				// se o produto está apto a ser vendido
				if Empty(cMsgErro) .and. nGetPreco > 0

					cGetDesc 	:= SB1->B1_DESC
					cGetProd	:= SB1->B1_COD

				else

					if nGetPreco <= 0
						SetMsgRod(cMsgErro)
					endif

					cGetDesc 	:= ""
					cGetProd	:= Space(TamSX3("B1_COD")[1])
					lRet 		:= .F.

				endif

			endif

		Else

			SLK->(DbSetOrder(1)) //SB1->(DbSetOrder(5)) // B1_FILIAL + B1_CODBAR
			if SLK->(DbSeek(xFilial("SLK") + cGetBarras)) //SB1->(DbSeek(xFilial("SB1") + cGetBarras))

				SB1->(DbSetOrder(1))
				if SB1->(DbSeek(xFilial("SB1") + SLK->LK_CODIGO))

					MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
					
			    	if SB1->B1_MSBLQL == "1" // se o produto estiver bloqueado para venda

						cGetDesc 	:= ""
						cGetProd	:= Space(TamSX3("B1_COD")[1])
						lRet 		:= .F.
						SetMsgRod("Produto bloqueado para venda.")

					elseif MHZ->(DbSeek(xFilial("MHZ")+SB1->B1_COD)) //verifica se é combustivel
						lRet := .F.
						SetMsgRod("Produto combustível sem permissão para venda via orçamento.")

			    	elseif !Empty(cTpProd) .and. !(SB1->B1_TIPO $ cTpProd)
			    		lRet := .F.
			    		Aviso( "", "O Produto '"+AllTrim(SB1->B1_COD)+" - "+AllTrim(SB1->B1_DESC)+"' está cadastrado com um Tipo de Produto "+;
			    			"('"+SB1->B1_TIPO+" - "+Alltrim(Posicione("SX5",1,xFilial("SX5")+"02"+SB1->B1_TIPO,"X5_DESCRI"))+"') que não está liberado para ser usado no PDV.", {"Ok"} )

			    	else

						// verifico o preço do produto
						nGetPreco := U_URetPrec(SB1->B1_COD,@cMsgErro)

						// se o produto está apto a ser vendido
						if Empty(cMsgErro) .and. nGetPreco > 0

							cGetDesc 	:= SB1->B1_DESC
							cGetProd	:= SB1->B1_COD
							nGetQtd		:= SLK->LK_QUANT

						else

							if nGetPreco <= 0
								SetMsgRod("Produto sem preço de tabela.")
							endif

							cGetDesc 	:= ""
							cGetProd	:= Space(TamSX3("B1_COD")[1])
							lRet 		:= .F.

						endif

					endif

				else

					cGetDesc 	:= ""
					cGetProd	:= Space(TamSX3("B1_COD")[1])
					lRet 		:= .F.
					SetMsgRod("Produto inválido!")
				endif

			else

				cGetDesc 	:= ""
				cGetProd	:= Space(TamSX3("B1_COD")[1])
				lRet 		:= .F.
				SetMsgRod("Produto inválido!")
			endif

		EndIf

	else

		cGetDesc 	:= ""
		cGetProd	:= Space(TamSX3("B1_COD")[1])
		nGetPreco 	:= 0

	endif

	oGetProd:Refresh()
	oGetDesc:Refresh()
	oGetPreco:Refresh()
	oGetQtd:Refresh()

	if lRet
		SetMsgRod("")
	endif

Return(lRet)


/*/{Protheus.doc} ValidaCodigo
Valida produto
@author thebr
@since 11/02/2019
@version 1.0
@return Nil
@type function
/*/
Static Function ValidaCodigo()

	Local lRet 			:= .T.
	Local cTpProd	 	:= SuperGetMv("MV_XTPPROD", Nil, "") //Lista de tipos de produtos que podem ser usados no PDV (Ex.: "ME/KT")
	Local cMsgErro		:= ""

	if !Empty(cGetProd)

		SB1->(DbSetOrder(1))
		if SB1->(DbSeek(xFilial("SB1") + cGetProd))
			
			MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL

			if SB1->B1_MSBLQL == "1" //se o produto estiver bloqueado para venda
				cGetDesc 	:= ""
				cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
				lRet 		:= .F.
				SetMsgRod("Produto bloqueado para venda!")

			elseif MHZ->(DbSeek(xFilial("MHZ")+SB1->B1_COD)) //verifica se é combustivel
				lRet := .F.
				SetMsgRod("Produto combustível sem permissão para venda via orçamento.")

			elseif !Empty(cTpProd) .and. !(SB1->B1_TIPO $ cTpProd)
	    		lRet := .F.
	    		Aviso( "", "O Produto '"+AllTrim(SB1->B1_COD)+" - "+AllTrim(SB1->B1_DESC)+"' está cadastrado com um Tipo de Produto "+;
	    			"('"+SB1->B1_TIPO+" - "+Alltrim(Posicione("SX5",1,xFilial("SX5")+"02"+SB1->B1_TIPO,"X5_DESCRI"))+"') que não está liberado para ser usado no PDV.", {"Ok"} )

			else
				// verifico o preço do produto
				nGetPreco 	:= U_URetPrec(SB1->B1_COD,@cMsgErro, .F.)

				// se o produto está apto a ser vendido
				if Empty(cMsgErro)

					cGetDesc 	:= SB1->B1_DESC
					cGetBarras	:= SB1->B1_CODBAR

				else

					cGetDesc 	:= ""
					cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
					lRet 		:= .F.
					SetMsgRod("Produto sem preço de tabela.")

				endif

			endif

		else

			cGetDesc 	:= ""
			cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
			lRet 		:= .F.
			SetMsgRod("Produto inválido!")
		endif

	else

		cGetDesc 	:= ""
		cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
		nGetPreco 	:= 0

	endif

	oGetBarras:Refresh()
	oGetDesc:Refresh()
	oGetPreco:Refresh()

	if lRet
		SetMsgRod("")
	endif

Return(lRet)


/*/{Protheus.doc} AdicionarItem
Adiciona item no orçamento
@author thebr
@since 11/02/2019
@version 1.0
@return Nil
@type function
/*/
Static Function AdicionarItem()

	Local nPos 		:= 0
	Local cNumItem 	:= "0"
	Local nPerDesc	:= 0
	Local nValDesc	:= 0

	// se o usuário não informar o vendedor não inclui
	if !Empty(cGetVend)

		// se o usuário não informar o produto não inclui
		if !Empty(cGetProd)

			// se o usuário não informar a quantidade não inclui
			if nGetQtd > 0

				// se existir a primeira linha no acols mas as informações estiverem vazias substitui a primeira linha
				if Len(oGridProd:aCols) == 1 .AND. Empty(oGridProd:aCols[1][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})])
					nPos := 1
				else
					cNumItem := oGridProd:aCols[Len(oGridProd:aCols)][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])=="L2_ITEM"})]
					aadd(oGridProd:aCols,aClone(oGridProd:aCols[1]))
					nPos := Len(oGridProd:aCols)
				endif

				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_ITEM"})] 	:= PADL(Soma1(cNumItem),TamSX3("L2_ITEM")[1],"0")
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_PRODUTO"})]	:= cGetProd
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_DESCRI"})]	:= cGetDesc
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_VRUNIT"})]	:= nGetPreco - nValDesc
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_QUANT"})]	:= nGetQtd
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_VLRITEM"})]	:= (nGetPreco - nValDesc) * nGetQtd
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_DESC"})]		:= nPerDesc
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_VALDESC"})]	:= nValDesc * nGetQtd
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_LOCAL"})]	:= RetLocal(cGetProd)
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_MIDCOD"})]	:= ""
				oGridProd:aCols[nPos][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_VEND"})]	:= cGetVend

				nTotQtd += nGetQtd
				nTotSub	+= (nGetPreco) * nGetQtd
				nTotPrc	+= (nGetPreco - nValDesc) * nGetQtd
				nTotDes += nValDesc * nGetQtd

				// faço um refresh no grid de acerto
				oGridProd:oBrowse:Refresh()

				// faço um refresh nos totalizadores
				oTotQtd:Refresh()
				oTotPrc:Refresh()
				oTotDes:Refresh()

				// limpo os campos
				cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
				cGetProd 	:= Space(TamSX3("B1_COD")[1])
				cGetDesc 	:= Space(TamSX3("B1_DESC")[1])
				nGetPreco 	:= 0
				nGetQtd 	:= 1

				// mudo o foco para o campo de código de barras
				oGetBarras:SetFocus()

			else
				SetMsgRod("Informe a quantidade do item!")
			endif

		else
			SetMsgRod("Informe o produto!")
		endif

	else
		SetMsgRod("Informe o vendedor!")
	endif

Return()


/*/{Protheus.doc} CancelarItem
Cancela item
@author thebr
@since 11/02/2019
@version 1.0
@return Nil
@type function
/*/
Static Function CancelarItem(nPosNat)

	Local nX	   		:= 1
	Local aAux			:= {}
	Local aFieldFill	:= {}

	// se a linha do grid estiver preenchida faz a deleção
	if Len (oGridProd:aCols) > 0 .AND. !Empty(oGridProd:aCols[nPosNat][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_ITEM"})])

		// atualizo as variaveis totalizadoras -> AtuTotais()
		nTotQtd -= oGridProd:aCols[nPosNat][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_QUANT"})]
		nTotSub -= (oGridProd:aCols[nPosNat][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VLRITEM"})] + oGridProd:aCols[nPosNat][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_VALDESC"})])
		nTotPrc -= oGridProd:aCols[nPosNat][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VLRITEM"})]
		nTotDes -= oGridProd:aCols[nPosNat][aScan(oGridProd:aHeader,{|x| AllTrim(x[2])== "L2_VALDESC"})]

		// a função aDel deixa a última posição do array com o conteúdo NIL
		aDel(oGridProd:aCols,nPosNat)

		// faço um loop no array para excluir as posições que tem conteúdo igual a NIL
		For nX := 1 To Len(oGridProd:aCols)

			if oGridProd:aCols[nX] <> NIL
				aadd(aAux,oGridProd:aCols[nX])
			endif

		Next nX

		oGridProd:aCols := aAux

		if Empty(oGridProd:aCols)
			For nX := 1 to Len(oGridProd:aHeader)

				if oGridProd:aHeader[nX][2] == "HEIGHT"
					Aadd(aFieldFill,"FWSKIN_BTN_DIV")
				else
					if oGridProd:aHeader[nX][8] == "N"
						Aadd(aFieldFill, 0)
					elseif oGridProd:aHeader[nX][8] == "D"
						Aadd(aFieldFill, stod(""))
					else
						Aadd(aFieldFill, "")
					endif
				endif

			Next nX

			Aadd(aFieldFill, .F.)
			aadd(oGridProd:Acols,aFieldFill)
		endif

		// faço um refresh no grid de produtos
		oGridProd:oBrowse:Refresh()

		// faço um refresh nos totalizadores
		oTotQtd:Refresh()
		oTotPrc:Refresh()
		oTotDes:Refresh()

	endif

Return()

/*/{Protheus.doc} RetLocal
Retorna o local padrão do produto

@author pablo
@since 26/09/2018
@version 1.0
@return Nil
@param cProd, characters, descricao
@type function
/*/
Static Function RetLocal(cProd)

	Local aArea		:= GetArea()
	Local cLocal 	:= Space(TamSX3("L2_LOCAL")[1])
	Local cPriorid  := SuperGetMv("TP_LOCPRI",,"0") //Define prioridade a ser considerada na busca do local de estoque: 0=Estação/Exposição/Produto ou 1=Exposição/Estação/Produto

	//Verifica se possui Estoque de Exposição (no proceso da Marajó só pode haver 01 (um))
	If ChkFile("U59")
		DbSelectArea("U59")
		U59->(DbSetOrder(2)) //U59_FILIAL+U59_PRODUT
	EndIf

	/*
		Pablo Nunes
		Data: 12/12/2017
		Ajuste: com a finalidade de atender clientes que possuem mais de um estoque de exposição para o mesmo produto.
		Neste caso, deverá ser criado o campo "LG_XLOCAL" no cadastro de estação e alimenta-lo com o estoque de exposição do PDV.
	*/
	if cPriorid == "1"
		If ChkFile("U59") .and. U59->(DbSeek(xFilial("U59")+cProd))
			cLocal := U59->U59_LOCAL
		ElseIf SLG->(FieldPos("LG_XLOCAL"))>0 .and. !Empty(SLG->LG_XLOCAL)
			cLocal := SLG->LG_XLOCAL
		Else
			//Senão, utilização almoxarifado padrão
			DbSelectArea("SB1")
			SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD

			If SB1->(DbSeek(xFilial("SB1")+cProd))
				cLocal := SB1->B1_LOCPAD
			Endif
		Endif
	else
		If SLG->(FieldPos("LG_XLOCAL"))>0 .and. !Empty(SLG->LG_XLOCAL)
			cLocal := SLG->LG_XLOCAL
		ElseIf ChkFile("U59") .and. U59->(DbSeek(xFilial("U59")+cProd))
			cLocal := U59->U59_LOCAL
		Else
			//Senão, utilização almoxarifado padrão
			DbSelectArea("SB1")
			SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD

			If SB1->(DbSeek(xFilial("SB1")+cProd))
				cLocal := SB1->B1_LOCPAD
			Endif
		Endif
	endif

	RestArea(aArea)

Return cLocal

/*/{Protheus.doc} LimpaTela
Função que limpa tela
@author pablo
@since 26/09/2018
@version 1.0
@return Nil

@type function
/*/
Static Function LimpaTela()

	Local nX
	Local aFieldFill := {}

	cGetPlaca := SPACE(8)  //SPACE(TamSX3("L1_PLACA")[1])
	cGetCPF := SPACE(11) //SPACE(TamSX3("DA4_CGC")[1])
	cGetMotor := SPACE(TamSX3("DA4_NOME")[1])
	
	cGetCli := SPACE(TamSX3("A1_NOME")[1])
	cGetCGC := SPACE(TamSX3("A1_CGC")[1])
	cGetCodCli := SPACE(TamSX3("L1_CLIENTE")[1])
	cGetLoja := SPACE(TamSX3("L1_LOJA")[1])
	cGetVend := Space(TamSX3("A3_COD")[1])
	cGetNVen := Space(TamSX3("A3_NOME")[1])
	cGetProd 	:= Space(TamSX3("B1_COD")[1])
	cGetBarras	:= Space(TamSX3("B1_CODBAR")[1])
	cGetDesc 	:= Space(TamSX3("B1_DESC")[1])
	nGetPreco 	:= 0
	nGetQtd 	:= 1
	nTotQtd	:= 0
	nTotSub	:= 0
	nTotPrc	:= 0
	nTotDes	:= 0

	oGridProd:aCols := {}
	if Empty(oGridProd:aCols)
		For nX := 1 to Len(oGridProd:aHeader)
			if oGridProd:aHeader[nX][2] == "HEIGHT"
				Aadd(aFieldFill,"FWSKIN_BTN_DIV")
			else
				if oGridProd:aHeader[nX][8] == "N"
					Aadd(aFieldFill, 0)
				elseif oGridProd:aHeader[nX][8] == "D"
					Aadd(aFieldFill, stod(""))
				else
					Aadd(aFieldFill, "")
				endif
			endif
		Next nX
		Aadd(aFieldFill, .F.)
		aadd(oGridProd:Acols,aFieldFill)
	endif
	oGridProd:oBrowse:Refresh()
	
	cGetCodCli := GETMV("MV_CLIPAD")
	cGetLoja := GETMV("MV_LOJAPAD")
	cGetCli := Posicione("SA1",1,xFilial("SA1")+cGetCodCli+cGetLoja, "A1_NOME")

	SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
	If SA3->(DbSeek(xFilial("SA3") + RETCODUSR()))
		cGetVend := SA3->A3_COD
		cGetNVen  := SA3->A3_NOME
	else
		SA3->(DbSetOrder(1))
		If SA3->(DbSeek(xFilial("SA3") + GetMV("MV_VENDPAD") ))
			cGetVend := SA3->A3_COD
			cGetNVen  := SA3->A3_NOME
		endif
	EndIf

	oGetPlaca:Refresh()
	oGetCPF:Refresh()
	oGetMotor:Refresh()
	oGetCli:Refresh()
	oGetCGC:Refresh()
	oGetCodCli:Refresh()
	oGetLoja:Refresh()
	oGetVend:Refresh()
	oGetNVen:Refresh()
	oGetProd:Refresh()
	oGetBarras:Refresh()
	oGetDesc:Refresh()
	oGetPreco:Refresh()
	oGetQtd:Refresh()
	oTotQtd:Refresh()
	oTotSub:Refresh()
	oTotPrc:Refresh()
	oTotDes:Refresh()

	oGetPlaca:SetFocus()

Return()

/*/{Protheus.doc} ConcluiOrc
Faz a graçao do orçamento

@author thebr
@since 11/02/2019
@version 1.0
@return Nil
@param nOpc, numeric, descricao
@type function
/*/
Static Function ConcluiOrc(nOpc)
	
	Local lRet			:= .T.
	Local aParam, aResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.

	//Validações
	if empty(cGetPlaca)
		SetMsgRod("Informe uma placa!")
		Return .F.
	endif

	if empty(cGetVend)
		SetMsgRod("Informe o vendedor!")
		Return .F.
	endif

	// valido se existe pelo menos um produto no orçamento
	if Len(oGridProd:aCols) > 0 .AND. !Empty(oGridProd:aCols[1][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_PRODUTO"})])
		
		SetMsgRod("Incluindo orçamento... aguarde...")
		CursorWait()

		aParam := {nOpc, cGetPlaca, cGetCPF, cGetCodCli, cGetLoja, cGetVend, aClone(oGridProd:aCols)}
		aParam := {"U_TPDVA01A",aParam}
		If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@aResult,/*cType*/,/*cKeyOri*/, @nCodRet )
			// Se retornar esses codigos siginifica que a central esta off
			lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
			// Verifica erro de execucao por parte do host
			//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
			lHostError := (nCodRet == -103 .OR. nCodRet == -106)

			If lHostError
				SetMsgRod("Erro de conexão central PDV: " + cValtoChar(nCodRet))
				//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
				lRet := .F.
			EndIf

		ElseIf nCodRet == -101 .OR. nCodRet == -108
			SetMsgRod( "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
			//Conout( "TPDVA002 - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		Else
			SetMsgRod( "Erro de conexão central PDV: " + cValtoChar(nCodRet))
			//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		EndIf

		If lRet .AND. lHasConnect .AND. ValType(aResult)=="A" .AND. len(aResult)>0
			SetMsgRod(aResult[2])
			lRet := aResult[1]
			if lRet
				//Imprime orçamento
				ImpOrcamento(1, oGridProd:aCols, aResult[3])
				LimpaTela()
			endif
		endif

		CursorArrow()
	else
		SetMsgRod("Informe pelo menos um produto!")
		lRet := .F.
	endif

Return lRet

/*/{Protheus.doc} TPDVA01A
Faz a gravaçao do orçamento no host superior

@author thebr
@since 06/09/2019
@version 1.0
@return Nil
@param nOpc, numeric, descricao
@type function
/*/
User Function TPDVA01A(nOpc, _cGetPlaca, _cGetCPF, _cGetCodCli, _cGetLoja, _cGetVend, _aProds)

	Local aRet			:= {.T., "", ""} //{lRet, cMsgErr, cNumOrc}
	Local aArea			:= GetArea()
	Local aCabec   		:= {} //Array do Cabeçalho do Orçamento
	Local aItens  		:= {} //Array dos Itens do Orçamento
	Local aParcelas		:= {} //Array das formas de pagamento
	Local aItem			:= {}
	Local aParcela		:= {}
	Local nX			:= 1
	Local nValTot		:= 0
	Local cCodCli		:= GetMV("MV_CLIPAD")
	Local cLojCli		:= GetMv("MV_LOJAPAD")
	Local lCallFrt		:= nModulo == 23

	Private lMsHelpAuto := .F. // Variavel de controle interno do ExecAuto
	Private lMsErroAuto := .F. // Variavel que informa a ocorrência de erros no ExecAuto
	Private INCLUI
	Private ALTERA
	Private lAutomatoX := .T. //variavel para evitar mostrar aviso de certificado proximo do vencimento

	if nOpc == 3
		INCLUI	:= .T.
		ALTERA 	:= .F.
	else
		INCLUI	:= .F.
		ALTERA 	:= .T.
	endif

	if !empty(_cGetCodCli) .and. !empty(_cGetLoja)
		cCodCli := _cGetCodCli
		cLojCli := _cGetLoja
	endif

	SA1->(DbSetOrder(1))
	if SA1->(DbSeek(xFilial("SA1") + cCodCli + cLojCli))

		// monto o array do cabeçalho
		aadd(aCabec, {"LQ_FILIAL"  		, xFilial("SLQ")	, NIL} )
		aadd(aCabec, {"LQ_VEND"  		, _cGetVend   	   	, NIL} )
		aadd(aCabec, {"LQ_COMIS"     	, 0        			, NIL} )
		aadd(aCabec, {"LQ_CLIENTE" 		, SA1->A1_COD  		, NIL} )
		aadd(aCabec, {"LQ_LOJA"  		, SA1->A1_LOJA		, NIL} )
		//aadd(aCabec, {"LQ_TIPOCLI" 	, SA1->A1_TIPO		, NIL} )
		aadd(aCabec, {"LQ_PLACA" 		, _cGetPlaca  		, NIL} )
		//aadd(aCabec, {"LQ_NROPCLI"	, "         "		, NIL} )
		aadd(aCabec, {"LQ_DTLIM"		, Date() 		    , NIL} )
		aadd(aCabec, {"LQ_EMISSAO"		, Date() 		    , NIL} )
		aadd(aCabec, {"LQ_HORA"	   		, Time()			, NIL} )
		///aadd(aCabec, {"LQ_NUMMOV"	, "01"				, NIL} )
		aadd(aCabec, {"LQ_CGCCLI"		, _cGetCPF			, NIL} )

		For nX := 1 To Len(_aProds)

			aItem	:= {}

			SB1->(DbSetOrder(1))
			if SB1->(DbSeek(xFilial("SB1") + _aProds[nX][aScan(aCpoItens,"L2_PRODUTO")]))

				aadd(aItem, {"LR_FILIAL"  		, xFilial("SLR")				   														, NIL} )
				aadd(aItem, {"LR_PRODUTO"		, SB1->B1_COD																			, NIL} )
				aadd(aItem, {"LR_QUANT"  		, _aProds[nX][aScan(aCpoItens,"L2_QUANT")]		, NIL} )
				aadd(aItem, {"LR_PRCTAB"  		, _aProds[nX][aScan(aCpoItens,"L2_VRUNIT")] + _aProds[nX][aScan(aCpoItens,"L2_VALDESC")] , NIL} )
				aadd(aItem, {"LR_VALDESC"       , _aProds[nX][aScan(aCpoItens,"L2_VALDESC")]     , NIL} )
				aadd(aItem, {"LR_UM"	   		, SB1->B1_UM																			, NIL} )
				//aadd(aItem, {"LR_TABELA"  		, ""							   														, NIL} )
				aadd(aItem, {"LR_LOCAL"   		, _aProds[nX][aScan(aCpoItens,"L2_LOCAL")]		, NIL} )
				aadd(aItem, {"LR_MIDCOD"  		, _aProds[nX][aScan(aCpoItens,"L2_MIDCOD")]		, NIL} )
				aadd(aItem, {"LR_VEND"  		, _aProds[nX][aScan(aCpoItens,"L2_VEND")]		, NIL} )
				aadd(aItens,aItem)

				nValTot	+= _aProds[nX][aScan(aCpoItens,"L2_VRUNIT")] * _aProds[nX][aScan(aCpoItens,"L2_QUANT")]

			endif

		Next nX

		// adiciono os totalizadores do cabeçalho do orçamento
		aadd(aCabec, {"LQ_VLRTOT"		, nValTot	  	, NIL} )
		aadd(aCabec, {"LQ_VLRLIQ"		, nValTot		, NIL} )
		aadd(aCabec, {"LQ_DINHEIR" 		, nValTot 	 	, NIL} )
		aadd(aCabec, {"LQ_CHEQUES" 		, 0 	 		, NIL} )
		aadd(aCabec, {"LQ_CARTAO" 		, 0				, NIL} )
		aadd(aCabec, {"LQ_VLRDEBI" 		, 0				, NIL} )
		aadd(aCabec, {"LQ_CONVENI" 		, 0 			, NIL} )
		aadd(aCabec, {"LQ_VALES" 		, 0 			, NIL} )
		aadd(aCabec, {"LQ_OUTROS" 		, 0   			, NIL} )

		// monto o array das formas de pagamento, será considerado o dinheiro por padrão
		aadd(aParcela, {"L4_FORMA"  	, "R$"					 	, NIL} )
		aadd(aParcela, {"L4_DATA"  		, Date()  				, NIL} )
		aadd(aParcela, {"L4_VALOR"  	, nValTot	                , NIL} )
		aadd(aParcela, {"L4_ADMINIS" 	, "                    " 	, NIL} )
		aadd(aParcela, {"L4_FORMAID"	, " "              			, NIL} )
		aadd(aParcela, {"L4_MOEDA"  	, SuperGetMV("MV_MOEDA1",,0), NIL} )
		aadd(aParcelas,aParcela)

		SetFunName("LOJA701")
		nModulo := 12

		MSExecAuto({|a,b,c,d,e,f,g,h| Loja701(a,b,c,d,e,f,g,h)},.F.,nOpc,"","",{},aCabec,aItens,aParcelas)

		if lCallFrt
			SetFunName("SIGAFRT")
			nModulo := 23
		endif

		if !lMsErroAuto .AND. SL1->(Eof())
			LjGrvLog( /*cNumControl*/, "TPDVA001 - falha ao incluir orçamento.", "SL1->(Eof())" )

			// Libera sequencial
			RollBackSx8()

			lMsHelpAuto := NIL
			lMsErroAuto := NIL
			
			aRet[1] := .F.
			aRet[2] := "Não foi possível incluir o orçamento no host superior!"
			
		elseif lMsErroAuto

			// mostra a tela de erros do Execauto
			cMsgErr := MostraErro("\temp") //MostraErro()
			LjGrvLog( /*cNumControl*/, "TPDVA001 - falha ao incluir orçamento.", cMsgErr )

			// Libera sequencial
			RollBackSx8()

			lMsHelpAuto := NIL
			lMsErroAuto := NIL
			
			aRet[1] := .F.
			aRet[2] := "Não foi possível incluir o orçamento no host superior!"

		Else

			// Confirmo a numeração
			ConfirmSX8()

			lMsHelpAuto := NIL
			lMsErroAuto := NIL
			
			RecLock("SL1",.F.)
				if SL1->(FieldPos("L1_CGCMOTO")) > 0 .and. !Empty(_cGetCPF) .and. Empty(SL1->L1_CGCMOTO)
					SL1->L1_CGCMOTO := _cGetCPF
				elseif !Empty(_cGetCPF) .and. Empty(SL1->L1_CGCCLI)
					SL1->L1_CGCCLI := _cGetCPF
				endif
				SL1->L1_HORA := Time()
			SL1->(MsUnlock())
			
			aRet[1] := .T.
			aRet[2] := "Operação realizada com sucesso! Num. Orçamento: " + SL1->L1_NUM
			aRet[3] := SL1->L1_NUM

		EndIf

	else
		aRet[1] := .F.
		aRet[2] := "O cliente informado não foi encontrado no host superior!"
	endif

	RestArea(aArea)

Return(aRet)


/*/{Protheus.doc} ExcOrcamento
Exclusao do orçamento
@author thebr
@since 11/02/2019
@version 1.0
@return Nil
@type function
/*/
Static Function ExcOrcamento()

	Local lOK := .F.
	Local aArea		:= GetArea()
	Local aAreaSL1  := SL1->(GetArea())
	Local nX 		:= 1
	Local cUsrExc	:= ""
	
	//verifica se o usuário tem permissão para acesso a rotina
	U_TRETA37B("EXCORC", "EXCLUSAO DE ORCAMENTO PDV")
	cUsrExc := U_VLACESS1("EXCORC", RetCodUsr())
	If cUsrExc == Nil .OR. Empty(cUsrExc)
		SetMsgRod("Usuário não tem permissão de acesso a opção de Exclusão de Orçamento.")
		Return .F.
	EndIf

	If MsgYesNo("Confirma excluir o(s) orçamento(s) selecionado(s)?","Atenção")

		aL1_NUM := {}

		// percorro todos os orçamentos que estão selecionados
		For nX := 1 To Len(oGridOrc:aCols)
			If AllTrim(oGridOrc:aCols[nX][aScan(oGridOrc:aHeader,{|x| AllTrim(x[2])=="MARK"})]) == "LBOK"
				aadd(aL1_NUM, oGridOrc:aCols[nX][aScan(oGridOrc:aHeader,{|x| AllTrim(x[2])=="L1_NUM"})])
			EndIf
		Next nX

		// se não existir um orçamento na tela ou o mesmo estiver sendo usado por outro, aviso o usuário
		If Len(aL1_NUM) == 0 
			If Empty(oGridOrc:aCols[oGridOrc:nAt][aScan(oGridOrc:aHeader,{|x| AllTrim(x[2])=="L1_NUM"})])
				SetMsgRod("Selecione um orçamento para realizar exclusão!")
			else
				aadd(aL1_NUM, oGridOrc:aCols[oGridOrc:nAt][aScan(oGridOrc:aHeader,{|x| AllTrim(x[2])=="L1_NUM"})])
			EndIf
		endif

		if Len(aL1_NUM) > 0
			// chamo função que faz a exclusão do orçamento (SL1,SL2 e SL4)
			LjMsgRun("Excluindo Orçamento(s)...",,{|| lOK := ExcluiOrc(aL1_NUM) })

			if lOK
				// faço um refresh no grid de orçamentos
				RefreshOrc()

				// faço um refresh nos itens do orçamento posicionado
				RefreshItem()

				SetMsgRod("Orçamento(s) excluido(s) com sucesso!")
			endif
		endif

	EndIf

	RestArea(aAreaSL1)
	RestArea(aArea)

Return

/*/{Protheus.doc} EXCLUIORC
@author Totvs GO
@since 10/04/2014
@version 1.0
@param cNumOrc, caracter, numero do orçamento a ser excluido
@return Nil
@description
Funcao generica que faz a exclusao de um orcamento.
Esta funcao nao valida se o orcamento esta finalizado,
ficando por conta do desenvolvedor fazer as devidas
validacoes antes de chama-la
@example
ExcluiOrc(aNumOrc)
/*/
Static Function ExcluiOrc(aNumOrc)
	
	Local lRet := .T.
	Local aParam, aResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.

	aParam := {aNumOrc}
	aParam := {"U_TPDVA01D",aParam}
	If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@aResult,/*cType*/,/*cKeyOri*/, @nCodRet )
		// Se retornar esses codigos siginifica que a central esta off
		lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
		// Verifica erro de execucao por parte do host
		//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
		lHostError := (nCodRet == -103 .OR. nCodRet == -106)

		If lHostError
			SetMsgRod("Erro de conexão central PDV: " + cValtoChar(nCodRet))
			//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		EndIf

	ElseIf nCodRet == -101 .OR. nCodRet == -108
		SetMsgRod( "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		//Conout( "TPDVA002 - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
		lRet := .F.
	Else
		SetMsgRod( "Erro de conexão central PDV: " + cValtoChar(nCodRet))
		//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
		lRet := .F.
	EndIf

	If lRet .AND. lHasConnect .AND. ValType(aResult)=="A" .AND. len(aResult)>0
		if !aResult[1]
			SetMsgRod( aResult[2] )
		endif
	endif

Return lRet

//----------------------------------------------------------------
// faz exclusao do orçamento no host superior
//----------------------------------------------------------------
User Function TPDVA01D(aNumOrc)
	
	Local nX
	Local aRet := {.T., ""}

	BeginTran()

	for nX := 1 to len(aNumOrc)
		SL1->(DbSetOrder(1))
		if SL1->(DbSeek(xFilial("SL1") + aNumOrc[nX])) 
			if Empty(SL1->L1_DOC) //so exclui orçamento em aberto (sem CUPOM ou sem NFCe)

				SL2->(DbSetOrder(1))
				if SL2->(DbSeek(xFilial("SL2") + aNumOrc[nX]))
					while SL2->(!Eof()) .AND. SL2->L2_NUM == aNumOrc[nX]
						if Reclock("SL2",.F.)
							SL2->(DbDelete())
							SL2->(MsUnlock())
						endif
						SL2->(DbSkip())
					enddo
				endif

				SL4->(DbSetOrder(1))
				if SL4->(DbSeek(xFilial("SL4") + aNumOrc[nX]))
					While SL4->(!Eof()) .AND. SL4->L4_NUM == aNumOrc[nX]
						if Reclock("SL4",.F.)
							SL4->(DbDelete())
							SL4->(MsUnlock())
						endif
						SL4->(DbSkip())
					EndDo
				endif

				if Reclock("SL1",.F.)
					SL1->(DbDelete())
					SL1->(MsUnlock())
				endif
			else
				aRet[1] := .F.
				aRet[2] += "Orçamento "+aNumOrc[nX]+" com NF emitida. Operação Abortada!"
				DisarmTransaction()
				EXIT
			endif
		endif
	next nX

	EndTran()

Return (aRet)

/*/{Protheus.doc} ImpOrcamento
Imprime cupom de orçamento/pre-venda.
nTipo: 1=Imprime antes de gravar; 2=Imprime depois de gravado

@author pablo
@since 25/09/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ImpOrcamento(nTipo, _aProds, cNumOrc)

	Local lRet := .T.
	Local aSL2Imp := {}
	Local aSL4Imp := {}
	Local nValTot := 0
	Local nX, cTexto := ""
	Local aParam, cResult
	Local nCodRet := 0
	Local lHasConnect := .F.
	Local lHostError := .F.

	If nTipo == 1

		For nX := 1 To Len(_aProds)
			if !empty(_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_PRODUTO"})])

				aadd(aSL2Imp, { _aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_PRODUTO"})],;
				_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_QUANT"})],;
				_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VRUNIT"})] + _aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VALDESC"})],;
				_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_QUANT"})] * (_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VRUNIT"})] + _aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VALDESC"})] ),;
				_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VALDESC"})],;
				_aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VEND"})] } )

				//ja tirando descontos
				nValTot	+= _aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_VRUNIT"})] * _aProds[nX][aScan(oGridProd:aHeader,{|x| AllTrim(x[2]) == "L2_QUANT"})]

			endif
		Next nX

		if len(aSL2Imp) > 0
			aadd(aSL4Imp, { "R$", nValTot} )

			//chama impressao
			cTexto := GetTxtImp(,cNumOrc,cGetCodCli,cGetLoja,cGetPlaca, aSL2Imp, aSL4Imp)
			if !empty(cTexto) 
				CallPrintIF(cTexto)
			endif
		else
			SetMsgRod("Inclua produtos para que seja possível a impressão.")
		endif

	Else

		If Empty(oGridOrc:aCols[oGridOrc:nAt][aScan(oGridOrc:aHeader,{|x| AllTrim(x[2])=="L1_NUM"})])
			SetMsgRod("Selecione um orçamento para impressao!")
			Return
		EndIf

		aParam := {oGridOrc:aCols[oGridOrc:nAt][aScan(oGridOrc:aHeader,{|x| AllTrim(x[2])=="L1_NUM"})]}
		aParam := {"U_TPDVA01C",aParam}
		If FWHostPing() .AND. STBRemoteExecute("_EXEC_CEN", aParam,,,@cResult,/*cType*/,/*cKeyOri*/, @nCodRet )
			// Se retornar esses codigos siginifica que a central esta off
			lHasConnect := !(nCodRet == -105 .OR. nCodRet == -107 .OR. nCodRet == -104)
			// Verifica erro de execucao por parte do host
			//-103 : erro na execução ,-106 : 'erro deserializar os parametros (JSON)
			lHostError := (nCodRet == -103 .OR. nCodRet == -106)

			If lHostError
				SetMsgRod("Erro de conexão central PDV: " + cValtoChar(nCodRet))
				//("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
				lRet := .F.
			EndIf

		ElseIf nCodRet == -101 .OR. nCodRet == -108
			SetMsgRod( "Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
			//Conout( "TPDVA002 - Servidor PDV nao Preparado. Funcionalidade nao existe ou host responsavel não associado. Cadastre a funcionalidade e vincule ao Host da Central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		Else
			SetMsgRod( "Erro de conexão central PDV: " + cValtoChar(nCodRet))
			//Conout("TPDVA002 - Erro de conexão central PDV: " + cValtoChar(nCodRet))
			lRet := .F.
		EndIf

		If lRet .AND. lHasConnect .AND. ValType(cResult)=="C" 
			if !empty(cResult)
				CallPrintIF(cResult)
			else
				SetMsgRod( "Não foi possível a impressao do orçamento!")
			endif
		endif

	EndIf

Return

/*/{Protheus.doc} TPDVA01C
Pega texto do cupom a com dados do orçamento do host superior

@author thebr
@since 06/09/2019
@version 1.0
@return Nil
@type function
/*/
User Function TPDVA01C(cNumOrc)
	
	Local aSL2Imp := {}
	Local aSL4Imp := {}
	Local nPosFor
	Local cRet := ""
	
	SL1->(DbSetOrder(1))
	If !SL1->(DbSeek(xFilial("SL1") + cNumOrc))
		Return cRet
	EndIf

	SL2->(DbSetOrder(1)) // L2_FILIAL + L2_NUM + L2_ITEM + L2_PRODUTO
	SL2->( DbSeek( xFilial("SL2") + SL1->L1_NUM) )
	While !SL2->( EOF() ) .and. SL2->L2_FILIAL == xFilial("SL2") .AND. SL2->L2_NUM == SL1->L1_NUM
		aadd(aSL2Imp, { SL2->L2_PRODUTO, SL2->L2_QUANT, SL2->L2_PRCTAB, A410Arred(SL2->L2_QUANT*SL2->L2_PRCTAB,"LR_VLRITEM"), SL2->L2_VALDESC, SL2->L2_VEND } )
		SL2->( DbSkip() )
	EndDo

	SL4->( DbSetOrder(1) ) //L4_FILIAL + L4_NUM + L4_ORIGEM
	SL4->( DbSeek(xFilial("SL4") + SL1->L1_NUM) )
	While SL4->(!EOF()) .AND. SL4->L4_FILIAL == xFilial("SL4") .AND. SL4->L4_NUM == SL1->L1_NUM

		If (nPosFor := aScan(aSL4Imp, {|x| x[1] == Alltrim(SL4->L4_FORMA) }) ) > 0
			aSL4Imp[nPosFor][2] += SL4->L4_VALOR
		Else
			aadd(aSL4Imp, {Alltrim(SL4->L4_FORMA), SL4->L4_VALOR} )
		EndIf

		SL4->( DbSkip() )

	EndDo

	//--chama impressao
	cRet := GetTxtImp(SL1->L1_OPERADO, SL1->L1_NUM, SL1->L1_CLIENTE, SL1->L1_LOJA, SL1->L1_PLACA, aSL2Imp, aSL4Imp, SL1->L1_EMISSAO, SL1->L1_HORA)

Return cRet

/*/{Protheus.doc} GetTxtImp
Gera texto da impressao do orçamento

@author Danilo Brito
@since 30/07/2014
@version 1.0

@return Nil
@param cOpeCaixa, characters, operador
@param cNroOrc, characters, numero orçamento
@param cCli, characters, cliente
@param cLoj, characters, loja
@param cPlaca, characters, placa
@param _aProds, array, produtos
@param _aFormas, array, pagamentos
@param _dDataOrc, date, data
@param _cHoraOrc, characters, hora
@obs

 LAYOUT IMPRESSAO CUPOM ORCAMENTO
         1         2         3         4
123456789012345678901234567890123456789012345678

------------------------------------------------
       *** ORÇAMENTO DE VENDA ***
------------------------------------------------
DOCUMENTO NAO FISCAL
Efetuar pagamento mediante emissão de Documento Fiscal
------------------------------------------------
NRO. ORÇAMENTO...: 000000
DATA.....: XX/XX/XXXX  HORA...: HH:MM:SS
OPERADOR.: CAIXA X
COD. CLI.: XXXXXXXX    PLACA..: AAA-9X99
CLIENTE..: FULANO DE TAL

CODIGO DESCRICAO QTD.UN. VL.UNIT(R$) VL.TOT(R$)
------------------------------------------------
000649 DESCRICAO DO PRODUTO AQUI
				     112,00L X 10,00 = 1.120,00
   Desconto: 120,00
000999 DESCRICAO DO PRODUTO AQUI
                         10,00UN X 1,00 = 10,00
------------------------------------------------
TOTAL  R$      			     	    R$ 1.010,00

DINHEIRO								 500,00
CHEQUE									 510,00
------------------------------------------------
APLICATIVO: MICROSIGA PROTHEUS - TOTVS

@type function
/*/
Static Function GetTxtImp(cOpeCaixa, cNroOrc, cCli, cLoj, cPlaca, _aProds, _aFormas, _dDataOrc, _cHoraOrc)

	Local aArea    := GetArea()
	Local aAreaSA1 := SA1->( GetArea() )
	Local aAreaSA6 := SA6->( GetArea() )
	Local aAreaSB1 := SB1->( GetArea() )

	Local nLarg         := 48 //considera o cupom de 40 posições
	Local _nRet			:= 0
	Local nX			:= 0
	Local _aMsg			:= {} //mensagens do cupom
	Local _cMsg         := ""
	Local _cAux			:= ""
	Local nTotProds		:= 0
	Local lMesmoVend	:= .T.

	Default cOpeCaixa 	:= xNumCaixa()
	Default cNroOrc		:= ""
	Default cCli		:= ""
	Default cLoj		:= ""
	Default cPlaca		:= ""
	Default _aProds		:= {} //{codigo, Quant, VlUnit, VlTot, vlDesconto}
	Default _aFormas	:= {} //{Forma, Valor}
	Default _dDataOrc	:= Date()
	Default _cHoraOrc	:= Time()

	if empty(cCli)
		cCli		:= PadR(GetMV("MV_CLIPAD"), TamSx3("A1_COD")[2] )
		cLoj		:= PadR(GetMv("MV_LOJAPAD"), TamSx3("A1_COD")[2] )
	endif
	
	_cAux:= ""
	for nX := 1 to len(_aProds)
		if nX > 1 .AND. Len(_aProds[nX]) > 5 .AND. _cAux <> _aProds[nX][6]
			lMesmoVend := .F.
		endif
		_cAux := _aProds[nX][6]
	next nX

	Posicione("SA1",1,xFilial("SA1") + cCli + cLoj,"A1_NOME")
	Posicione("SA6",1,xFilial("SA6") + cOpeCaixa,"A6_NOME")

	//mensagem
	AAdd( _aMsg, Space(nLarg) )

	AAdd( _aMsg, Replicate("-",nLarg) )
	_nRet := len("*** ORÇAMENTO / PRÉ-VENDA *** ")
	AAdd( _aMsg, "-" + Space((nLarg-_nRet-2)/2) + "*** ORÇAMENTO / PRÉ-VENDA *** " + Space((nLarg-_nRet-2)/2) + "-"  )
	AAdd( _aMsg, Replicate("-",nLarg) )
	_nRet := len("***** DOCUMENTO NAO FISCAL *****")
	AAdd( _aMsg, "-" + Space((nLarg-_nRet-2)/2) + "***** DOCUMENTO NAO FISCAL *****" + Space((nLarg-_nRet-2)/2) + "-"  )
	AAdd( _aMsg, "Efetuar pagamento mediante emissão de Documento Fiscal" )
	AAdd( _aMsg, Replicate("-",nLarg) )
	AAdd( _aMsg, Space(nLarg) )
	if !empty(cNroOrc)
		AAdd( _aMsg, PadR("NRO. ORÇAMENTO...: " + cNroOrc , nLarg) )
	endif
	AAdd( _aMsg, PadR("DATA.....: "+DtoC(_dDataOrc)+"      HORA...: "+_cHoraOrc , nLarg) )
	AAdd( _aMsg, PadR("OPERADOR.: "+AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME),nLarg) )
	if lMesmoVend
		Posicione("SA3",1,xFilial("SA3")+_aProds[1][6],"A3_COD") //A3_FILIAL+A3_COD
		AAdd( _aMsg, PadR("VEND.: " + AllTrim(SA3->A3_COD) + " - " + AllTrim(SA3->A3_NOME) ,nLarg) ) //codigo e nome do vendedor
	endif
	AAdd( _aMsg, PadR("CLIENTE..: "+AllTrim(SA1->A1_COD)+"/"+AllTrim(SA1->A1_LOJA)+"       PLACA..: "+Alltrim(Transform(cPlaca,"@!R NNN-9N99")), nLarg) )
	AAdd( _aMsg, PadR("CPF/CNPJ.: "+Transform(SA1->A1_CGC,iif(SA1->A1_PESSOA=="J","@R 99.999.999/9999-99","@R 999.999.999-99")), nLarg) )
	AAdd( _aMsg, PadR("NOME:....: "+AllTrim(SA1->A1_NOME), nLarg) )
	AAdd( _aMsg, Space(nLarg) )

	AAdd( _aMsg, "CODIGO DESCRICAO  QTD.UN. VL.UNIT(R$) VL.TOT(R$)" )
	AAdd( _aMsg, Replicate("-",nLarg) )
	For nX := 1 to len(_aProds)

		Posicione("SB1",1,xFilial("SB1")+_aProds[nX][1],"B1_COD")
		AAdd( _aMsg, PadR(AllTrim(SB1->B1_COD) + " " + AllTrim(SB1->B1_DESC) ,nLarg) ) //codigo produto + descriçao

		if Len(_aProds[nX]) > 5 .AND. !lMesmoVend
			Posicione("SA3",1,xFilial("SA3")+_aProds[nX][6],"A3_COD") //A3_FILIAL+A3_COD
			AAdd( _aMsg, PadR("VEND.: " + AllTrim(SA3->A3_COD) + " - " + AllTrim(SA3->A3_NOME) ,nLarg) ) //codigo e nome do vendedor
		endif

		_cAux := AllTrim(Transform(_aProds[nX][2],"@E 999,999,999.99")) + SB1->B1_UM + " x " + AllTrim(Transform(_aProds[nX][3],"@E 999,999,999.99")) + " = " + AllTrim(Transform(_aProds[nX][4],"@E 999,999,999.99"))
		AAdd( _aMsg, Space(nLarg-len(_cAux)) + _cAux )  //Quant x Valor = total

		if _aProds[nX][5] > 0
			_cAux := "-" +  AllTrim(Transform(_aProds[nX][5],"@E 999,999,999.99"))
			AAdd( _aMsg, "desconto " + Space(nLarg-9-len(_cAux)) + _cAux ) //codigo produto + descriçao
		endif

		nTotProds += (_aProds[nX][4] - _aProds[nX][5])  //total - desconto
	Next nX
	AAdd( _aMsg, Replicate("-",nLarg) )

	_cAux := AllTrim(Transform(nTotProds, "@E 999,999,999.99"))
	AAdd( _aMsg, "TOTAL  R$" + Space(nLarg-9-len(_cAux)) + _cAux )  //Quant x Valor = total

	AAdd( _aMsg, Space(nLarg) )

	For nX := 1 to len(_aFormas)
		_cAux := alltrim(Posicione("SX5",1,xFilial("SX5")+"24"+_aFormas[nX][1],"X5_DESCRI"))
		AAdd( _aMsg, _cAux + Space(nLarg-len(_cAux)-len(AllTrim(Transform(_aFormas[nX][2],"@E 999,999,999.99")))) + AllTrim(Transform(_aFormas[nX][2],"@E 999,999,999.99")) )  //valor da forma
	Next nX

	AAdd( _aMsg, Replicate("-",nLarg) )

	AAdd( _aMsg, PadR("APLICATIVO: MICROSIGA PROTHEUS - TOTVS", nLarg) )

	For nX:=1 to Len( _aMsg )
		_cMsg += _aMsg[nX] + chr(10)
	Next nX

	RestArea( aAreaSB1 )
	RestArea( aAreaSA6 )
	RestArea( aAreaSA1 )
	RestArea( aArea )

Return _cMsg

//--------------------------------------------------------------
// Chama a impressao na impressora conectada
//--------------------------------------------------------------
Static Function CallPrintIF(cTexto)
	
	Local nX
	Local nVias         := 1 //numero de vias (2 - uma para o cliente outra para a marajo)

	//fim da montagem da mensagem
	For nX:=1 To nVias 
		LjMsgRun("Aguarde Impressão do cupom não fiscal",,{|| STWManagReportPrint( cTexto , 1/*nVias*/ ) })
	Next nX

Return
